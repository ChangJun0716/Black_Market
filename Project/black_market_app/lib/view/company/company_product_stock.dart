// 입고 페이지
import 'package:black_market_app/vm/database_handler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../model/stock_receipts.dart';

class CompanyProductStock extends StatefulWidget {
  const CompanyProductStock({super.key});

  @override
  State<CompanyProductStock> createState() => _CompanyProductStockState();
}

class _CompanyProductStockState extends State<CompanyProductStock> {
  late DatabaseHandler handler;
  late Map<String, dynamic> selectedItem;
  final TextEditingController quantityController = TextEditingController();

  final box = GetStorage();
  late String userId;

  List<String> manufacturerList = [];
  String? selectedManufacturer;

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    selectedItem = Map<String, dynamic>.from(Get.arguments);
    userId = box.read('uid') ?? '';
    loadManufacturers();
  }

  Future<void> loadManufacturers() async {
    try {
      final list = await handler.getManufacturers();
      setState(() {
        manufacturerList = list;
        selectedManufacturer = selectedItem['manufacturerName'];
        if (!manufacturerList.contains(selectedManufacturer)) {
          selectedManufacturer = manufacturerList.isNotEmpty ? manufacturerList.first : null;
        }
      });
    } catch (e) {
      debugPrint("제조사 로딩 오류: $e");
    }
  }

  void submitStockReceipts() async {
    try {
      debugPrint('[입고 시작]');

      final code = selectedItem['productsCode'];
      final currentStock = selectedItem['currentStock'];
      final input = quantityController.text;
      final qty = int.tryParse(input);
      final receiptDate = DateTime.now();

      if (qty == null || qty <= 0 || selectedManufacturer == null) {
        debugPrint('[입력 오류] 수량: $qty, 제조사: $selectedManufacturer');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('수량 또는 제조사를 올바르게 입력해주세요.')),
        );
        return;
      }

      debugPrint('[입력 확인 완료]');

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('입고 확인'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('제품코드: $code'),
              Text('입고 수량: $qty'),
              Text('입고 날짜: ${receiptDate.toIso8601String().split("T")[0]}'),
              Text('제조사: $selectedManufacturer'),
              Text('처리자 ID: $userId'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('확인'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        debugPrint('[사용자 취소]');
        return;
      }

      final receipt = StockReceipts(
      saUserid: userId,
      stockReceiptsQuantityReceived: qty,
      stockReceiptsReceipDate: receiptDate,
      sproductCode: code.toString(), // 여기 수정
      smanufacturerName: selectedManufacturer!,
      );


      debugPrint('[입고 모델 생성 완료]');
      await handler.insertStockReceipt(receipt);
      debugPrint('[입고 DB 저장 완료]');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('입고 처리가 완료되었습니다.')),
      );
      Get.back();
    } catch (e, stack) {
      debugPrint('[에러 발생]');
      debugPrint(e.toString());
      debugPrint(stack.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('입고 중 오류 발생: $e')),
      );
    }
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
        title: const Text("입고 페이지",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        ),
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
            DropdownButtonFormField<String>(
              value: manufacturerList.contains(selectedManufacturer) ? selectedManufacturer : null,
              items: manufacturerList.map((name) => DropdownMenuItem(
                value: name,
                child: Text(name),
              )).toList(),
              onChanged: (value) => setState(() => selectedManufacturer = value),
              decoration: const InputDecoration(
                labelText: '제조사 선택',
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(),
              ),
              dropdownColor: Colors.black,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '입고 수량 입력',
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
                onPressed: submitStockReceipts,
                child: const Text('입고하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
