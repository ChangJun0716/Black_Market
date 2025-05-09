//재고 보기
import 'package:black_market_app/view/company/company_management_list.dart';
import 'package:black_market_app/view/company/company_product_delivery.dart';
import 'package:black_market_app/view/company/company_product_stock.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:black_market_app/vm/database_handler.dart';

class CompanyCheckInventory extends StatefulWidget {
  const CompanyCheckInventory({super.key});

  @override
  State<CompanyCheckInventory> createState() => _CompanyCheckInventoryState();
}

class _CompanyCheckInventoryState extends State<CompanyCheckInventory> {
  late DatabaseHandler handler;
  List<Map<String, dynamic>> allList = [];
  List<Map<String, dynamic>> filteredList = [];
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    loadInventory();
  }

  Future<void> loadInventory() async {
    final List<Map<String, dynamic>> result = [];
    final rawList = await handler.getAllProducts1();

    for (final product in rawList) {
      final productCode = product.productsCode;
      final manufacturer = await handler.getManufacturerByProduct('$productCode!');
      final stockIn = await handler.getTotalStockIn('$productCode');
      final stockOut = await handler.getTotalStockOut('$productCode');
      final currentStock = stockIn - stockOut;

      result.add({
        'productsCode': productCode,
        'productsName': product.productsName,
        'productsColor': product.productsColor,
        'productsSize': product.productsSize,
        'manufacturerName': manufacturer,
        'currentStock': currentStock,
      });
    }

    setState(() {
      allList = result;
      filteredList = List.from(allList);
    });
  }

  void filterInventory(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      filteredList = allList.where((item) =>
          item['productsName'].toString().toLowerCase().contains(lowerQuery) ||
          item['productsCode'].toString().contains(lowerQuery)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('본사 재고 관리',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        ),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: searchController,
              onChanged: filterInventory,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '제품 ID 또는 이름 검색',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const Divider(color: Colors.grey),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: filteredList.isEmpty
                      ? const Center(child: Text('재고 없음', style: TextStyle(color: Colors.white)))
                      : ListView.builder(
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final item = filteredList[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              color: Colors.grey.shade900,
                              child: ListTile(
                                title: Text(
                                  '${item['productsName']} (ID: ${item['productsCode']})',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  '컬러: ${item['productsColor']} / 사이즈: ${item['productsSize']} / 재고: ${item['currentStock']}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.download, color: Colors.green),
                                      onPressed: () {
                                        Get.to(() => CompanyProductStock(), arguments: item)?.then((_) => {
                                          setState(() {
                                            loadInventory();
                                          })
                                        });
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.upload, color: Colors.red),
                                      onPressed: () {
                                        Get.to(() => CompanyProductDelivery(), arguments: item)?.then((_) {
                                          setState(() {
                                            loadInventory();
                                          });
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      onPressed: () {
                        Get.to(CompanyManagementList());
                      },
                      child: const Text('입출고 내역 보러 가기'),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
