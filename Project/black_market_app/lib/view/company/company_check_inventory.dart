//재고관리
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:black_market_app/vm/database_handler.dart';

class CompanyCheckInventory extends StatefulWidget {
  const CompanyCheckInventory({super.key});

  @override
  State<CompanyCheckInventory> createState() => _CompanyCheckInventoryState();
}

class _CompanyCheckInventoryState extends State<CompanyCheckInventory> {
  late DatabaseHandler handler;
  List<Map<String, dynamic>> inventoryList = [];
  String selectedType = '본사 재고 확인';
  String selectedOrderStatus = '전체 보기';
  String selectedManufacturer = '전체 제조사';
  String selectedStore = '전체 대리점';

  List<String> manufacturerList = ['전체 제조사'];
  List<String> storeList = ['전체 대리점'];

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadFilters();
      loadInventoryData();
    });
  }

  Future<void> loadFilters() async {
    final db = await handler.initializeDB();
    final result = await db.rawQuery("SELECT DISTINCT manufacturerName FROM manufacturers");
    final stores = await db.rawQuery("SELECT storeName FROM store");

    if (mounted) {
      setState(() {
        manufacturerList = ['전체 제조사', ...result.map((e) => e['manufacturerName'].toString())];
        storeList = ['전체 대리점', ...stores.map((e) => e['storeName'].toString())];
      });
    }
  }

  Future<void> loadInventoryData() async {
    final db = await handler.initializeDB();
    final products = await db.rawQuery("SELECT * FROM products");
    List<Map<String, dynamic>> data = [];

    for (var product in products) {
      final code = product['productsCode'];
      final name = product['productsName'];
      final color = product['productsColor'];
      final size = product['productsSize'];

      final manufacturerMatch = await db.rawQuery(
        "SELECT smanufacturerName FROM stockReceipts WHERE sproductCode = ? LIMIT 1",
        [code],
      );
      final manufacturer = manufacturerMatch.isNotEmpty ? manufacturerMatch.first['smanufacturerName'] : '없음';
      if (selectedManufacturer != '전체 제조사' && selectedManufacturer != manufacturer) continue;

      if (selectedType == '본사 재고 확인') {
        final received = Sqflite.firstIntValue(await db.rawQuery(
              "SELECT SUM(stockReceiptsQuantityReceived) FROM stockReceipts WHERE sproductCode = ?",
              [code],
            )) ?? 0;
        final dispatched = Sqflite.firstIntValue(await db.rawQuery(
              "SELECT SUM(dispatchedQuantity) FROM dispatch WHERE dProductCode = ?",
              [code],
            )) ?? 0;
        final currentStock = received - dispatched;

        final order = await db.rawQuery(
          "SELECT * FROM `order` WHERE oproductCode = ? ORDER BY orderDate DESC LIMIT 1",
          [code],
        );

        String statusText = '';
        bool showCheckbox = false;

        if (currentStock < 30) {
          if (order.isEmpty) {
            if (selectedOrderStatus == '전체 보기' || selectedOrderStatus == '발주 필요') {
              showCheckbox = true;
            }
          } else {
            final status = order.first['orderStatus'];
            final orderDate = DateTime.tryParse(order.first['orderDate'].toString());
            final receiptAfterOrder = await db.rawQuery(
              "SELECT * FROM stockReceipts WHERE sproductCode = ? AND stockReceiptsReceipDate > ?",
              [code, orderDate?.toIso8601String() ?? ''],
            );
            if (receiptAfterOrder.isNotEmpty) {
              statusText = '';
            } else if (status == '승인됨') {
              if (selectedOrderStatus == '전체 보기' || selectedOrderStatus == '발주 완료') {
                statusText = '발주 완료';
              }
            } else if (status == '신청됨') {
              if (selectedOrderStatus == '전체 보기' || selectedOrderStatus == '발주 신청됨') {
                statusText = '발주 신청 승인 예정중';
              }
            } else {
              showCheckbox = true;
            }
          }
        } else {
          if (selectedOrderStatus != '전체 보기') continue;
        }

        data.add({
          'code': code,
          'name': name,
          'color': color,
          'size': size,
          'currentStock': currentStock,
          'statusText': statusText,
          'showCheckbox': showCheckbox,
        });
      } else {
        final storeCodeResult = await db.rawQuery(
          "SELECT storeCode FROM store WHERE storeName = ?",
          [selectedStore],
        );
        if (selectedStore != '전체 대리점' && storeCodeResult.isEmpty) continue;
        final storeCode = storeCodeResult.isNotEmpty ? storeCodeResult.first['storeCode'] : null;

        final dispatched = Sqflite.firstIntValue(await db.rawQuery(
              "SELECT SUM(dispatchedQuantity) FROM dispatch d JOIN daffiliation a ON d.dUserid = a.duserId WHERE dProductCode = ? ${storeCode != null ? "AND a.dstoreCode = '$storeCode'" : ''}",
              [code],
            )) ?? 0;
        final sold = Sqflite.firstIntValue(await db.rawQuery(
              "SELECT SUM(purchaseQuanity) FROM purchase WHERE oproductCode = ? ${storeCode != null ? "AND pStoreCode = '$storeCode'" : ''}",
              [code],
            )) ?? 0;
        final currentStock = dispatched - sold;

        data.add({
          'code': code,
          'store': selectedStore,
          'name': name,
          'color': color,
          'size': size,
          'currentStock': currentStock,
          'statusText': '',
          'showCheckbox': false,
        });
      }
    }

    if (mounted) {
      setState(() {
        inventoryList = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("재고 확인"),
        backgroundColor: Colors.black,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  DropdownButton<String>(
                    value: selectedType,
                    dropdownColor: Colors.black,
                    style: const TextStyle(color: Colors.white),
                    items: ['본사 재고 확인', '대리점 재고 확인']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      setState(() => selectedType = val!);
                      loadInventoryData();
                    },
                  ),
                  if (selectedType == '본사 재고 확인')
                    DropdownButton<String>(
                      value: selectedOrderStatus,
                      dropdownColor: Colors.black,
                      style: const TextStyle(color: Colors.white),
                      items: ['전체 보기', '발주 필요', '발주 신청됨', '발주 완료']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) {
                        setState(() => selectedOrderStatus = val!);
                        loadInventoryData();
                      },
                    ),
                  if (selectedType == '대리점 재고 확인')
                    DropdownButton<String>(
                      value: selectedStore,
                      dropdownColor: Colors.black,
                      style: const TextStyle(color: Colors.white),
                      items: storeList
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) {
                        setState(() => selectedStore = val!);
                        loadInventoryData();
                      },
                    ),
                  DropdownButton<String>(
                    value: selectedManufacturer,
                    dropdownColor: Colors.black,
                    style: const TextStyle(color: Colors.white),
                    items: manufacturerList
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      setState(() => selectedManufacturer = val!);
                      loadInventoryData();
                    },
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.grey),
            Expanded(
              child: inventoryList.isEmpty
                  ? const Center(
                      child: Text('재고 없음', style: TextStyle(color: Colors.white)),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowHeight: 48,
                        dataRowHeight: 52,
                        columnSpacing: 20,
                        columns: selectedType == '본사 재고 확인'
                            ? const [
                                DataColumn(label: Text('제품 ID', style: TextStyle(color: Colors.white))),
                                DataColumn(label: Text('제품명', style: TextStyle(color: Colors.white))),
                                DataColumn(label: Text('컬러', style: TextStyle(color: Colors.white))),
                                DataColumn(label: Text('사이즈', style: TextStyle(color: Colors.white))),
                                DataColumn(label: Text('현재 수량', style: TextStyle(color: Colors.white))),
                                DataColumn(label: Text('발주 상태', style: TextStyle(color: Colors.white))),
                              ]
                            : const [
                                DataColumn(label: Text('대리점명', style: TextStyle(color: Colors.white))),
                                DataColumn(label: Text('제품 ID', style: TextStyle(color: Colors.white))),
                                DataColumn(label: Text('제품명', style: TextStyle(color: Colors.white))),
                                DataColumn(label: Text('컬러', style: TextStyle(color: Colors.white))),
                                DataColumn(label: Text('사이즈', style: TextStyle(color: Colors.white))),
                                DataColumn(label: Text('현재 수량', style: TextStyle(color: Colors.white))),
                              ],
                        rows: inventoryList.map((item) {
                          return DataRow(cells: selectedType == '본사 재고 확인'
                              ? [
                                  DataCell(Text(item['code'], style: const TextStyle(color: Colors.white))),
                                  DataCell(Text(item['name'], style: const TextStyle(color: Colors.white))),
                                  DataCell(Text(item['color'], style: const TextStyle(color: Colors.white))),
                                  DataCell(Text(item['size'].toString(), style: const TextStyle(color: Colors.white))),
                                  DataCell(Text(item['currentStock'].toString(), style: const TextStyle(color: Colors.white))),
                                  DataCell(
                                    item['showCheckbox']
                                        ? Checkbox(
                                            value: false,
                                            onChanged: (val) {},
                                          )
                                        : Text(item['statusText'] ?? '', style: const TextStyle(color: Colors.white)),
                                  ),
                                ]
                              : [
                                  DataCell(Text(item['store'] ?? '', style: const TextStyle(color: Colors.white))),
                                  DataCell(Text(item['code'], style: const TextStyle(color: Colors.white))),
                                  DataCell(Text(item['name'], style: const TextStyle(color: Colors.white))),
                                  DataCell(Text(item['color'], style: const TextStyle(color: Colors.white))),
                                  DataCell(Text(item['size'].toString(), style: const TextStyle(color: Colors.white))),
                                  DataCell(Text(item['currentStock'].toString(), style: const TextStyle(color: Colors.white))),
                                ]);
                        }).toList(),
                      ),
                    ),
            )
          ],
        ),
      ),
    );
  }
}