//입출고 한 내역 확인 

import 'package:black_market_app/vm/database_handler.dart';
import 'package:flutter/material.dart';

class CompanyManagementList extends StatefulWidget {
  const CompanyManagementList({super.key});

  @override
  State<CompanyManagementList> createState() => _CompanyManagementListState();
}

class _CompanyManagementListState extends State<CompanyManagementList> {
  late DatabaseHandler handler;

  String selectedType = '입고'; // 입고 or 출고
  List<Map<String, dynamic>> displayList = [];
  List<Map<String, dynamic>> allList = [];

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    loadData();
  }

  Future<void> loadData() async {
    List<Map<String, dynamic>> data = [];

    if (selectedType == '입고') {
      data = await handler.getAllStockReceipts(); // 입고 테이블에서 모든 데이터
    } else {
      data = await handler.getAllDispatches(); // 출고 테이블에서 모든 데이터
    }

    setState(() {
      allList = data;
      displayList = data;
    });
  }

  void filterList(String keyword) {
    final filtered = allList.where((item) {
      if (selectedType == '입고') {
        return item['saUserid'].toString().contains(keyword);
      } else {
        return item['storeName']?.toString().contains(keyword) ?? false;
      }
    }).toList();

    setState(() {
      displayList = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("입출고 내역",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // 입출고 드롭다운
                DropdownButton<String>(
                  dropdownColor: Colors.black,
                  value: selectedType,
                  items: const [
                    DropdownMenuItem(value: '입고', child: Text('입고',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                    )),
                    DropdownMenuItem(value: '출고', child: Text('출고',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                    )),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedType = value;
                        searchController.clear();
                      });
                      loadData();
                    }
                  },
                ),
                const SizedBox(width: 16),
                // 검색 입력창
                Expanded(
                child: TextField(
                  controller: searchController,
                  onChanged: filterList,
                  decoration: InputDecoration(
                    hintText: selectedType == '입고' ? '작업자 ID 검색' : '대리점명 검색',
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white, 
                  ),
                ),
              ),

              ],
            ),
          ),
          const Divider(),
          // 결과 리스트
          Expanded(
            child: ListView.builder(
              itemCount: displayList.length,
              itemBuilder: (context, index) {
                final item = displayList[index];
                return ListTile(
                  title: Text(
                    selectedType == '입고'
                        ? '제품: ${item['sproductCode']} / 수량: ${item['stockReceiptsQuantityReceived']}'
                        : '제품: ${item['dProductCode']} / 수량: ${item['dispatchedQuantity']}',
                  ),
                  subtitle: Text(
                    selectedType == '입고'
                        ? '처리자: ${item['saUserid']} / 날짜: ${item['stockReceiptsReceipDate']}'
                        : '대리점: ${item['storeName'] ?? item['dstoreCode']} / 날짜: ${item['dispatchDate']}',
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

