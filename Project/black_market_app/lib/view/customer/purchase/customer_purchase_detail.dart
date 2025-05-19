import 'dart:convert';
import 'package:black_market_app/global.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class CustomerPurchaseDetail extends StatefulWidget {
  const CustomerPurchaseDetail({super.key});

  @override
  State<CustomerPurchaseDetail> createState() => _CustomerPurchaseDetailState();
}

class _CustomerPurchaseDetailState extends State<CustomerPurchaseDetail> {
// --------------------------------- Property ----------------------------------- //
  late int purchaseId;
  List data =[]; // 사용자가 결제한 상품의 상세보기 data를 담을 list
// ------------------------------------------------------------------------------ //
  @override
  void initState() {
    super.initState();
    purchaseId = Get.arguments ?? -1;
    getJSONData();
  }
// ------------------------------- Functions ------------------------------------ //
// 사용자가 주문한 상품 list 중 상태가 '장바구니' 가 아닌 data 들을 불러오는 함수
getJSONData()async{
var response = await http.get(Uri.parse("http://$globalip:8000/changjun/select/selectedPurchase/?purchaseId=$purchaseId"));
  data.clear();
  data.addAll(json.decode(utf8.decode(response.bodyBytes))['results']);
  // print(data); // --- 1
  setState(() {});
}
// ------------------------------------------------------------------------------ //
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('결제 내역 상세 정보')),
      body: data.isEmpty
      ? Text('데이터가 없습니다.', textAlign: TextAlign.center)
      : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Image.network("http://$globalip:8000/changjun/select/selectedPurchase/image/$purchaseId}?t=${DateTime.now().microsecondsSinceEpoch}",
                    width: MediaQuery.of(context).size.width,
                    height: 200,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    data[0]['productsName'],
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text('색상: ${data[0]['productsColor']}'),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('사이즈: ${data[0]['productsSize']}'),
                ),
                Text('수량: ${data[0]['purchaseQuanity']}개'),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '총 결제금액: ${data[0]['purchasePrice']}원',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 24),
                Text(
                  '배송 상태: ${data[0]['PurchaseDeliveryStatus']}',
                  style: TextStyle(color: Colors.blueAccent),
                ),
                Text('수령 지점: ${data[0]['storeName']}'),
              ],
            ),
          ),
        ),
      )
    );
  }
}
