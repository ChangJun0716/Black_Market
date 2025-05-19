// 구매 내역
import 'dart:convert';
import 'package:black_market_app/global.dart';
import 'package:black_market_app/view/customer/purchase/customer_purchase_detail.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class CustomerPurchaseList extends StatefulWidget {
  const CustomerPurchaseList({super.key});

  @override
  State<CustomerPurchaseList> createState() => _CustomerPurchaseListState();
}

class _CustomerPurchaseListState extends State<CustomerPurchaseList> {
// ------------------------------- Property  ------------------------------------ //
  final box = GetStorage();
  List data = []; // 사용자의 결제 리스트 data 를 불러와 담을 변수
  late String uid;
  bool isReady = false;
  @override
// ------------------------------------------------------------------------------ //
  void initState() {
    super.initState();
    initStorage();
    getJSONData();
  }
// ------------------------------------------------------------------------------ //
// ------------------------------- Functions ------------------------------------ //
// 사용자가 주문한 상품 list 중 상태가 '장바구니' 가 아닌 data 들을 불러오는 함수
getJSONData()async{
var response = await http.get(Uri.parse("http://$globalip:8000/changjun/select/Purchase/?userid=$uid"));
  data.clear();
  data.addAll(json.decode(utf8.decode(response.bodyBytes))['results']);
  // print(data); // --- 1
  setState(() {});
}
// ------------------------------------------------------------------------------ //
  initStorage(){
    uid = box.read('uid');
    isReady = true;
    setState(() {});
  }
// ------------------------------------------------------------------------------ //
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('결제 내역'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: data.isEmpty
      ? Text('결제 내역이 없습니다', textAlign: TextAlign.center)
      : ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => Get.to(CustomerPurchaseDetail(), arguments: data[index]['purchaseId']),
            child: Card(
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("주문번호 : ${data[index]['purchaseId']}"),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("제품명 : ${data[index]['productsName']}"),
                        Text("총 가격 : ${data[index]['purchasePrice']}"),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("결제날짜   : ${(data[index]['PurchaseDate'].toString().substring(0,10))}"),
                      Text("배송상태  : ${data[index]['PurchaseDeliveryStatus']}"),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      )
    );
  }
}
