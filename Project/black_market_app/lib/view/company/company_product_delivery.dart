// 출고 페이지: 변경된 쿼리 방식 적용 (UI에서 재고 계산 → DB에는 update만)

import 'package:black_market_app/vm/database_handler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../model/dispatch.dart';
import '../../model/store.dart';

class CompanyProductDelivery extends StatefulWidget {
  const CompanyProductDelivery({super.key});

  @override
  State<CompanyProductDelivery> createState() => _CompanyProductDeliveryState();
}

class _CompanyProductDeliveryState extends State<CompanyProductDelivery> {
  late DatabaseHandler handler;
  late List<Map<String, dynamic>> selectedItems;
  final Map<String, TextEditingController> quantityControllers = {};

  List<Store> storeList = [];
  Store? selectedStore;
  //나중에 로그인 구현이 돼서 로그인 정보를 받아오면 그 정보가 입력될 곳 
  String userId = "user01";
  String jobGradeCode = "G3";

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    selectedItems = List<Map<String, dynamic>>.from(Get.arguments);
    for (var item in selectedItems) {
      quantityControllers[item['productsCode']] = TextEditingController();
    }
    loadStores();
  }

  Future<void> loadStores() async {
    final stores = await handler.getStoreList();
    setState(() {
      storeList = stores;
      if (stores.isNotEmpty) selectedStore = stores.first;
    });
  }

  void submitDispatch() async {
    if (selectedStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('대리점을 선택해주세요.')),
      );
      return;
    }

    for (var item in selectedItems) {
      final code = item['productsCode'];
      final currentStock = item['currentStock'];
      final controller = quantityControllers[code];
      final input = controller?.text ?? '';
      final qty = int.tryParse(input);

      if (qty == null || qty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item['productsName']} 수량을 올바르게 입력해주세요.')),
        );
        return;
      }

      if (qty > currentStock) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("출고 실패"),
            content: Text("출고 수량이 재고($currentStock)를 초과했습니다."),
            actions: [
              TextButton(
                child: const Text("확인"),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
        return;
      }

      final dispatch = Dispatch(
        dUserid: userId,
        daJobGradeCode: jobGradeCode,
        dProductCode: code,
        dispatchDate: DateTime.now(),
        dispatchedQuantity: qty,
        dstoreCode: selectedStore!.storeCode,
      );

      await handler.insertDispatch(dispatch);
      await handler.updateStock(code, currentStock - qty);
      await handler.updatePurchaseDeliveryStatus(code, selectedStore!.storeCode);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('출고 처리가 완료되었습니다.')),
    );
    Get.back();
  }

  @override
  void dispose() {
    for (var controller in quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("출고 페이지")),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[850],
            child: DropdownButton<Store>(
              dropdownColor: Colors.grey[900],
              value: selectedStore,
              isExpanded: true,
              items: storeList.map((store) {
                return DropdownMenuItem<Store>(
                  value: store,
                  child: Text(store.storeName, style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedStore = value;
                });
              },
              hint: const Text('대리점 선택', style: TextStyle(color: Colors.white54)),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: selectedItems.length,
              itemBuilder: (context, index) {
                final item = selectedItems[index];
                final controller = quantityControllers[item['productsCode']]!;
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: index % 2 == 0 ? Colors.grey[850] : Colors.grey[800],
                    border: const Border(bottom: BorderSide(color: Colors.grey)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          item['productsName'],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: '수량',
                            hintStyle: TextStyle(color: Colors.white54),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: submitDispatch,
              child: const Text('출고하기'),
            ),
          ),
        ],
      ),
    );
  }
}