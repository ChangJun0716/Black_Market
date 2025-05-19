//입출고 한 내역 확인 - 2팀 팀원 김수아 개발 
//목적 : 
//어떤 관리자가 언제 어떤 제품을 입고 했는지 출고 했는지 로그를 볼 수 있는 페이지이다.
//관리자 ID 혹은 대리점 코드을를 검색하여 해당하는 글을 따로 볼 수 있다. 
//개발 일지 :
//2025_05_19
//sqlite로 개발된 소스를 mysql python을 이용하여 서버로 이어주었다 .
//global 아이피 설정 완료!


import 'dart:convert';

import 'package:black_market_app/global.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CompanyManagementList extends StatefulWidget {
  const CompanyManagementList({super.key});

  @override
  State<CompanyManagementList> createState() => _CompanyManagementListState();
}

class _CompanyManagementListState extends State<CompanyManagementList> {
  //드롭 다운 선태된거 담는 거 
  String selectedType = '입고';
  List<Map<String, dynamic>> displayList = [];
  List<Map<String, dynamic>> allList = [];
  //검색창 
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  loadData() async {
    List<Map<String, dynamic>> data = [];
    //드롭 다운 입고 or 출고 확인 그에 맞는 값 들고 오기
    if (selectedType == '입고') {
      try {
        final response = await http.post(Uri.parse('http://$globalip:8000/kimsua/select/products/stockReceipts'));
        if (response.statusCode == 200) {
          final decoded = json.decode(utf8.decode(response.bodyBytes));
          setState(() {
            data = List<Map<String, dynamic>>.from(decoded['result']);
          });
      }
      }catch(e){
        print(e);
      }
    } else {
      try {
        final response = await http.post(Uri.parse('http://$globalip:8000/kimsua/select/products/dispatch'));
        if (response.statusCode == 200) {
          final decoded = json.decode(utf8.decode(response.bodyBytes));
          setState(() {
            data = List<Map<String, dynamic>>.from(decoded['result']);
          });
      }
      }catch(e){
        print(e);
      }
    }

    setState(() {
      allList = data;
      displayList = data;
    });
  }
  //검색 필터 그냥 디비 말고 가져온 정보에서 찾게 만듦ㅋㅋ 개꿀 
  filterList(String keyword) {
    final filtered = allList.where((item) {
      if (selectedType == '입고') {
        return item['users_userid'].toString().contains(keyword);
      } else {
        return item['Purchase_store_storeCode']?.toString().contains(keyword) ?? false;
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
                        ? '제품: ${item['products_productsCode']} / 수량: ${item['stockReceiptsQuantityReceived']}'
                        : '제품: ${item['Purchase_products_productsCode']} / 수량: ${item['dispatchedQuantity']}',
                      style: TextStyle(
                        color: Colors.white
                      ),
                  ),
                  subtitle: Text(
                    selectedType == '입고'
                        ? '처리자: ${item['users_userid']} / 날짜: ${item['stockReceiptsReceipDate']}'
                        : '대리점: ${item['Purchase_store_storeCode'] ?? item['Purchase_store_storeCode']} / 날짜: ${item['dispatchDate']}',
                    style: TextStyle(
                      color: Colors.white
                    ),
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

