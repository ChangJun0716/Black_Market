// 30% 미만 재고 확인 -  2팀 팀원 김수아 개발 
// 목적  : 
// 관리자가 30% 미만으로 떨어진 재고는 다시 채우기 위해 확인 하는 페이지이다.
// 본 페이지에서 적은 수량의 제품을 확인하고 체크 후 발주를 신청하는 페이지로 갈 수 있으며
// 발주 기록을 확인 할 수 있는 페이지도 연결 되어 있다.
// 개발 일지 :
// 2025_05_19
// sqllite을 이용했던 소스를 mysql로 python을 이용하여 다시 개발해 보았다.
// 계속 수량 오류 때문에 시간이 좀 걸렸지만 타입 문제를 찾아 해결 하였다.
// global ip 설정 완!

import 'dart:convert';
import 'package:black_market_app/global.dart';
import 'package:black_market_app/view/company/order/company_order.dart';
import 'package:black_market_app/view/company/order/company_order_list.dart';
import 'package:black_market_app/view/company/order/company_order_orderlist.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class CompanyOrderManagement extends StatefulWidget {
  const CompanyOrderManagement({super.key});

  @override
  State<CompanyOrderManagement> createState() => _CompanyOrderManagementState();
}

class _CompanyOrderManagementState extends State<CompanyOrderManagement> {
  List<Map<String, dynamic>> lowStockList = []; // 30개 미만 필터링된 재고
  final Map<String, bool> checkStates = {}; // 체크박스 상태
  //재고 카운팅 변수 
  int currentStock = 0;

  @override
  void initState() {
    super.initState();
    loadLowStockInventory();
  }
  // 일단 제품 다 받아옴  이렇게도 할 수 있고 서버에서 30% 미반의 재고를 샐랙해서 줬을 수도 있음 
  loadLowStockInventory() async {
    final List<Map<String, dynamic>> result = [];
    List<Map<String, dynamic>> data = [];

     try {
        final response = await http.get(Uri.parse('http://$globalip:8000/kimsua/select/products'));
        if (response.statusCode == 200) {
          final decoded = json.decode(utf8.decode(response.bodyBytes));
          setState(() {
            data = List<Map<String, dynamic>>.from(decoded['result']);
          });
      }
      }catch(e){
        print(e);
      }

    for (int index=0 ;index<data.length;index++) {
         try {
        final response = await http.post(
          Uri.parse("http://$globalip:8000/kimsua/select/currentStock"),
          body: {'productsCode': data[index]['productsCode'].toString()},
        );

        if (response.statusCode == 200) {
          final decoded = json.decode(utf8.decode(response.bodyBytes));
          currentStock = decoded['result']; 
        } 
      } catch (e) {
        print(e);
      }
      //30% 미만의 제품이 많으면 좀 무거울 수 있음 ㅇㅇ
      if (currentStock< 30) {
        result.add({
          'productsCode': data[index]['productsCode'].toString(),
          'productsName': data[index]['productsName'].toString(),
          'productsColor': data[index]['productsColor'].toString(),
          'productsSize':data[index]['productsSize'].toString(),
          'currentStock': currentStock.toString(),
        
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
