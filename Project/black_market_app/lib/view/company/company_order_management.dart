//재고 발주 페이지 
import 'package:black_market_app/view/company/order/company_order.dart';
import 'package:black_market_app/view/company/order/company_order_list.dart';
import 'package:black_market_app/view/company/order/company_order_orderlist.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:black_market_app/vm/database_handler.dart';

class CompanyOrderManagement extends StatefulWidget {
  const CompanyOrderManagement({super.key});

  @override
  State<CompanyOrderManagement> createState() => _CompanyOrderManagementState();
}

class _CompanyOrderManagementState extends State<CompanyOrderManagement> {
  late DatabaseHandler handler;
  List<Map<String, dynamic>> lowStockList = []; // 30개 미만 필터링된 재고
  final Map<String, bool> checkStates = {}; // 체크박스 상태

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    loadLowStockInventory();
  }

  Future<void> loadLowStockInventory() async {
    final List<Map<String, dynamic>> result = [];
    final rawList = await handler.getAllProducts1();

    for (final product in rawList) {
      final productCode = product.productsCode;
      final manufacturer = await handler.getManufacturerByProduct('$productCode!');
      final stockIn = await handler.getTotalStockIn('$productCode');
      final stockOut = await handler.getTotalStockOut('$productCode');
      final currentStock = stockIn - stockOut;

      if (currentStock < 30) {
        result.add({
          'productsCode': productCode,
          'productsName': product.productsName,
          'productsColor': product.productsColor,
          'productsSize': product.productsSize,
          'manufacturerName': manufacturer,
          'currentStock': currentStock,
        });
      }
    }

    setState(() {
      lowStockList = result;
      for (var item in lowStockList) {
        checkStates[item['productsCode'].toString()] = false;
      }
    });
  }

  void submitOrder() {
    final selectedItems = lowStockList.where((item) => checkStates[item['productsCode'].toString()] == true).toList();
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('발주할 항목을 선택해주세요.')),
      );
      return;
    }
    // 페이지 이동 및 데이터 전달
    Get.to(CompanyOrder(selectedProducts: selectedItems));
  }

  void goToOrderList() {
    Get.to(CompanyOrderList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('발주 대상 제품 목록',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          const Divider(color: Colors.grey),
          Expanded(
            child: lowStockList.isEmpty
              ? const Center(child: Text('발주 대상 제품이 없습니다.', style: TextStyle(color: Colors.white)))
              : ListView.builder(
                  itemCount: lowStockList.length,
                  itemBuilder: (context, index) {
                    final item = lowStockList[index];
                    final key = item['productsCode'].toString();
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      color: Colors.grey.shade900,
                      child: CheckboxListTile(
                        value: checkStates[key] ?? false,
                        onChanged: (value) {
                          setState(() {
                            checkStates[key] = value ?? false;
                          });
                        },
                        title: Text(
                          '${item['productsName']} (ID: ${item['productsCode']})',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          '컬러: ${item['productsColor']} / 사이즈: ${item['productsSize']} / 재고: ${item['currentStock']}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    );
                  },
                ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: submitOrder,
                    child: const Text('선택한 제품 발주하기'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                  onPressed: (){
                    Get.to(CompanyOrderOrderlist());
                  },
                  child: const Text('발주 내역'),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
