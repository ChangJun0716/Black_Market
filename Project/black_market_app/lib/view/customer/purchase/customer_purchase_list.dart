// 구매 내역
import 'package:black_market_app/view/customer/purchase/customer_purchase_detail.dart';
import 'package:black_market_app/vm/database_handler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class CustomerPurchaseList extends StatefulWidget {
  const CustomerPurchaseList({super.key});

  @override
  State<CustomerPurchaseList> createState() => _CustomerPurchaseListState();
}

class _CustomerPurchaseListState extends State<CustomerPurchaseList> {
  late DatabaseHandler handler;
  final box = GetStorage();
  late String uid;
  bool isReady = false;
  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    initStorage();
  }
// ------------------------- //
  initStorage(){
    uid = box.read('uid');
    isReady = true;
    setState(() {});
  }
// ------------------------- //

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('결재 내역'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder(
        future: handler.queryUserPurchaseList(uid), 
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final purchaseList = snapshot.data!;
              return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final item = purchaseList[index];
                return GestureDetector(
                  onTap: () => Get.to(CustomerPurchaseDetail(), arguments: item['purchaseId']),
                  child: Card(
                    child: Row(
                      children: [
                        Text("주문 번호 : ${item['purchaseId']}"),
                        Text("제품 명 : ${item['productsName']}"),
                        Text("구매 총 가격 : ${item['purchasePrice']}"),
                        Text("배송 상태  : ${item['purchaseDeliveryStatus']}"),
                      ],
                    ),
                  ),
                );
              },
            );
          }else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
    
  }
}
