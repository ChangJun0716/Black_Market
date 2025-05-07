// 입고 페이지

import 'package:black_market_app/vm/database_handler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../model/stock_receipts.dart';

class CompanyProductStock extends StatefulWidget {
  const CompanyProductStock({super.key});

  @override
  State<CompanyProductStock> createState() => _CompanyProductStockState();
}

class _CompanyProductStockState extends State<CompanyProductStock> {
  late DatabaseHandler handler;
  late List<Map<String, dynamic>> selectedItems;
  final Map<String, TextEditingController> quantityControllers = {};

  // 나중에 로그인이 완성이 되면 로그인한 관리자의 정보를 받아올 곳!
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
  }

  void submitStockReceipts() async {
    for (var item in selectedItems) {
      final code = item['productsCode'];
      final currentStock = item['currentStock'];
      final manufacturer = item['manufacturerName'];
      final controller = quantityControllers[code];
      final input = controller?.text ?? '';
      final qty = int.tryParse(input);

      if (qty == null || qty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item['productsName']} 수량을 올바르게 입력해주세요.')),
        );
        return;
      }

      final receipt = StockReceipts(
        saUserid: userId,
        saJobGradeCode: jobGradeCode,
        stockReceiptsQuantityReceived: qty,
        stockReceiptsReceipDate: DateTime.now(),
        sproductCode: code,
        smanufacturerName: manufacturer ?? '',
      );

      // 1. 입고 내역 저장
      await handler.insertStockReceipt(receipt);

      // 2. 재고 증가
      await handler.updateStock(code, currentStock + qty);

      // 3. 발주 상태 초기화
      await handler.updateOrderStateToEmpty(code);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('입고 처리가 완료되었습니다.')),
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
      appBar: AppBar(
        title: const Text("입고 페이지"),
      ),
      body: Column(
        children: [
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
              onPressed: submitStockReceipts,
              child: const Text('입고하기'),
            ),
          ),
        ],
      ),
    );
  }
}
