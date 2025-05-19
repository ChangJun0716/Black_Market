//재고 보기 - 2팀 팀원 : 김수아 개발 
//목적 : 
// 입고 출고를 이어주는 페이지이다 지금 있는 물건의 수량을 확인 할 수 있고 발주와 입고 목록을 볼 수 있다
//개발 일지 :
//2025_05_18
//sqlite로 개발 했던 소스 mysql python 소스로 바꾸기 
//global ip 구현 ok
// 저번에는 sqllate가 게속 리드 형식으로 바껴서 합산을 받아서 ui에서 계산을 했는데 
// 이번에는 제품의 수량을 입고 + 발주 동시에 셀렉하고 그 수량을 서버에서 값을 반환하게 만듦


import 'dart:convert';

import 'package:black_market_app/global.dart';
import 'package:black_market_app/view/company/company_management_list.dart';
import 'package:black_market_app/view/company/company_product_delivery.dart';
import 'package:black_market_app/view/company/company_product_stock.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class CompanyCheckInventory extends StatefulWidget {
  const CompanyCheckInventory({super.key});

  @override
  State<CompanyCheckInventory> createState() => _CompanyCheckInventoryState();
}

class _CompanyCheckInventoryState extends State<CompanyCheckInventory> {
  //제품 검색한 결과를 받아 오는 리스트
  List data = [];
  List datasum = [];
  
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getJSONData();
  }

//검색 안하고 전체
getJSONData()async{
    try {
      var response = await http.get(Uri.parse("http://$globalip:8000/kimsua/select/products"));
      data.clear();
      data.addAll(json.decode(utf8.decode(response.bodyBytes))['result']);
      _loadAllStocks();
      setState(() {});
        
        }catch (e) {
      print(e);
    }
        
  }
  // 검색할 때
  getJSONData1()async{
    final keyword = searchController.text.trim();
      if (keyword.isEmpty) {
        getJSONData(); 
        return;
      }
      final response = await http.get(
        Uri.parse("http://$globalip:8000/kimsua/select/products/$keyword"),
      );
      if (response.statusCode == 200) {
            data.clear();
            data.addAll(json.decode(utf8.decode(response.bodyBytes))['result']);
            _loadAllStocks();
            
            setState(() {});
          } 
        }
  //재고 저장 
  _loadAllStocks() async {
  datasum.clear();
    for (var item in data) {
      final code = item['productsCode'].toString();

      try {
        final response = await http.post(
          Uri.parse("http://$globalip:8000/kimsua/select/currentStock"),
          body: {'productsCode': code},
        );

        if (response.statusCode == 200) {
          final decoded = json.decode(utf8.decode(response.bodyBytes));

          final stock = decoded['result'] ?? 0; 
          datasum.add(stock);
        } else {
          datasum.add(0);
        }
      } catch (_) {
        datasum.add(0); 
      }
    }

    setState(() {});
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
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "제품명 혹은 ID 검색 검색",
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.black26,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: IconButton(
                        icon: const Icon(Icons.search, color: Colors.white),
                        onPressed: getJSONData1,
                      ),
                    ),
                    onSubmitted: (value) => getJSONData1(),
                  
              ),
          ),
          const Divider(color: Colors.grey),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: datasum.isEmpty
                      ? const Center(child: Text('재고 없음', style: TextStyle(color: Colors.white)))
                      : ListView.builder(
                          itemCount: data.length,
                          itemBuilder: (context, index) {
                            final item = data[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              color: Colors.grey.shade900,
                              child: ListTile(
                                title: Text(
                                  '${item['productsName']} (ID: ${item['productsCode']})',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  '컬러: ${item['productsColor']} / 사이즈: ${item['productsSize']} / 재고: ${datasum[index]})}',
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
                                            getJSONData();
                                          })
                                        });
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.upload, color: Colors.red),
                                      onPressed: () {
                                        Get.to(() => CompanyProductDelivery(), arguments: item)?.then((_) {
                                          setState(() {
                                            getJSONData();
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
