//입출고 관리
import 'package:black_market_app/view/company/company_product_delivery.dart';
import 'package:black_market_app/view/company/company_product_stock.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../vm/database_handler.dart';

class CompanyOrderManagement extends StatefulWidget {
  const CompanyOrderManagement({super.key});

  @override
  State<CompanyOrderManagement> createState() => _CompanyOrderManagementState();
}

class _CompanyOrderManagementState extends State<CompanyOrderManagement> {
  late DatabaseHandler handler;
  List<Map<String, dynamic>> stockList = [];
  Map<String, bool> checkStates = {};

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    loadStock();
  }

  Future<void> loadStock() async {
    stockList = await handler.getCompanyStockList();
    setState(() {
      for (var item in stockList) {
        checkStates[item['productsCode']] = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('입출고 관리',
        style: TextStyle(
          color: Colors.white
        ),
        ),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.grey[900],
            padding: const EdgeInsets.all(12),
            child: Row(
              children: const [
                Expanded(flex: 1, child: Text('     ', style: TextStyle(color: Colors.white))),
                Expanded(flex: 2, child: Text('제품ID', style: TextStyle(color: Colors.white))),
                Expanded(flex: 3, child: Text('제품명', style: TextStyle(color: Colors.white))),
                Expanded(flex: 2, child: Text('제조사', style: TextStyle(color: Colors.white))),
                Expanded(flex: 2, child: Text('색상', style: TextStyle(color: Colors.white))),
                Expanded(flex: 2, child: Text('사이즈', style: TextStyle(color: Colors.white))),
                Expanded(flex: 2, child: Text('재고', style: TextStyle(color: Colors.white))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: stockList.length,
              itemBuilder: (context, index) {
                final item = stockList[index];
                return Container(
                  color: index % 2 == 0 ? Colors.grey[850] : Colors.grey[800],
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Checkbox(
                          value: checkStates[item['productsCode']],
                          onChanged: (val) {
                            setState(() => checkStates[item['productsCode']] = val ?? false);
                          },
                        ),
                      ),
                      Expanded(flex: 2, child: Text(item['productsCode'], style: const TextStyle(color: Colors.white))),
                      Expanded(flex: 3, child: Text(item['productsName'], style: const TextStyle(color: Colors.white))),
                      Expanded(flex: 2, child: Text(item['manufacturerName'] ?? '', style: const TextStyle(color: Colors.white))),
                      Expanded(flex: 2, child: Text(item['productsColor'].toString(), style: const TextStyle(color: Colors.white))),
                      Expanded(flex: 2, child: Text(item['productsSize'].toString(), style: const TextStyle(color: Colors.white))),
                      Expanded(flex: 2, child: Text(item['currentStock'].toString(), style: const TextStyle(color: Colors.white))),
                    ],
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final selectedItems = stockList
                          .where((item) => checkStates[item['productsCode']] == true)
                          .toList();
                
                      if (selectedItems.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('입고할 항목을 선택해주세요.')),
                        );
                        return;
                      }
                
                      Get.to(() => CompanyProductStock(), arguments: selectedItems);
                    },
                    child: const Text('입고하기'),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final selectedItems = stockList
                          .where((item) => checkStates[item['productsCode']] == true)
                          .toList();
                
                      if (selectedItems.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('출고할 항목을 선택해주세요.')),
                        );
                        return;
                      }
                
                      Get.to(() => CompanyProductDelivery(), arguments: selectedItems);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    child: const Text('출고하기',
                    style: TextStyle(
                      color: Colors.black
                
                    ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

