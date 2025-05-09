import 'package:black_market_app/vm/database_handler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../model/dispatch.dart';
import '../../model/store.dart';
import '../../model/purchase.dart';

class CompanyProductDelivery extends StatefulWidget {
  const CompanyProductDelivery({super.key});

  @override
  State<CompanyProductDelivery> createState() => _CompanyProductDeliveryState();
}

class _CompanyProductDeliveryState extends State<CompanyProductDelivery> {
  late DatabaseHandler handler;
  late Map<String, dynamic> selectedItem;
  final TextEditingController quantityController = TextEditingController();
  final box = GetStorage();
  late String userId;

  List<Store> storeList = [];
  Store? selectedStore;
  List<int> pendingOrderIds = [];
  int? selectedOrderId;
  Purchase? selectedOrderInfo;

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    selectedItem = Map<String, dynamic>.from(Get.arguments);
    userId = box.read('uid') ?? '';
    loadStores();
  }

  Future<void> loadStores() async {
    final stores = await handler.getStoreList();
    setState(() {
      storeList = stores;
      if (stores.isNotEmpty) selectedStore = stores.first;
    });
    loadPendingOrders();
  }

  Future<void> loadPendingOrders() async {
    final storeCode = selectedStore?.storeCode;

    if (storeCode != null && storeCode.isNotEmpty) {
      try {
        debugPrint("🔍 대리점 선택됨: $storeCode");

        final list = await handler.getPendingOrderIdsForDispatch(
          selectedItem['productsCode'],
          storeCode,
        );

        debugPrint("✅ 주문 ID 리스트: $list");
        setState(() {
          pendingOrderIds = list;
          selectedOrderId = list.isNotEmpty ? list.first : null;
        });

        if (selectedOrderId != null) {
          final order = await handler.getPurchaseById(selectedOrderId!);
          setState(() => selectedOrderInfo = order);
        }
      } catch (e, stack) {
        debugPrint("❌ 주문 목록 로딩 오류: $e");
        debugPrint("📌 StackTrace: $stack");
      }
    } else {
      debugPrint("⚠️ 선택된 대리점의 storeCode가 null이거나 비어 있습니다.");
    }
  }

  void submitDispatch() async {
    final int code = selectedItem['productsCode'];
    final int currentStock = selectedItem['currentStock'];
    final input = quantityController.text;
    final qty = int.tryParse(input);

    if (qty == null || qty <= 0 || selectedStore == null || selectedOrderId == null || selectedOrderInfo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('수량, 대리점, 주문 ID를 모두 정확히 입력해주세요.')),
      );
      return;
    }

    if (qty > currentStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('출고 수량이 재고($currentStock)를 초과했습니다.')),
      );
      return;
    }

    if (qty > selectedOrderInfo!.purchaseQuanity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('출고 수량이 주문 수량(${selectedOrderInfo!.purchaseQuanity})을 초과했습니다.')),
      );
      return;
    }

    final dispatch = Dispatch(
      dUserid: userId,
      dProductCode: code,
      dispatchDate: DateTime.now(),
      dispatchedQuantity: qty,
      dstoreCode: selectedStore!.storeCode,
      dipurchaseId: selectedOrderId!,
    );

    await handler.insertDispatch(dispatch);
   await handler.updatePurchaseDeliveryStatus(selectedOrderId!);


    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('출고 처리가 완료되었습니다.')),
    );
    Get.back();
  }

  @override
  void dispose() {
    quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("출고 페이지"),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: Colors.grey[900],
              child: ListTile(
                title: Text(
                  '${selectedItem['productsName']} (ID: ${selectedItem['productsCode']})',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '컬러: ${selectedItem['productsColor']} / 사이즈: ${selectedItem['productsSize']} / 재고: ${selectedItem['currentStock']}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Store>(
              value: selectedStore,
              items: storeList.map((store) => DropdownMenuItem(
                value: store,
                child: Text(store.storeName),
              )).toList(),
              onChanged: (value) async {
                setState(() => selectedStore = value);
                await loadPendingOrders();
              },
              decoration: const InputDecoration(
                labelText: '대리점 선택',
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(),
              ),
              dropdownColor: Colors.black,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: selectedOrderId,
              items: pendingOrderIds.map((id) => DropdownMenuItem<int>(
                value: id,
                child: Text('주문 ID: $id'),
              )).toList(),
              onChanged: (value) async {
                setState(() => selectedOrderId = value);
                if (value != null) {
                  final order = await handler.getPurchaseById(value);
                  setState(() => selectedOrderInfo = order);
                }
              },
              decoration: const InputDecoration(
                labelText: '주문 선택',
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(),
              ),
              dropdownColor: Colors.black,
              style: const TextStyle(color: Colors.white),
            ),
            if (selectedOrderInfo != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  '주문 수량: ${selectedOrderInfo!.purchaseQuanity} / 고객 ID: ${selectedOrderInfo!.pUserId}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '출고 수량 입력',
                hintStyle: TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: submitDispatch,
                child: const Text('출고하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
