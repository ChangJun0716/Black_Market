// 장바구니
import 'package:black_market_app/message/custom_dialogue.dart';
import 'package:black_market_app/vm/database_handler.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class CustomerShoppingCartList extends StatefulWidget {
  const CustomerShoppingCartList({super.key});

  @override
  State<CustomerShoppingCartList> createState() =>
      _CustomerShoppingCartListState();
}

class _CustomerShoppingCartListState extends State<CustomerShoppingCartList> {
  late DatabaseHandler handler;
  final box = GetStorage();
  late String uid;

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    initStorage();
  }
  initStorage(){
    uid = box.read('uid');
    setState(() {});
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('장바구니'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder(
        future: handler.queryShoppingCart(uid), 
        builder:(context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return Card(
                  child: Row(
                    children: [
                      Image.memory(snapshot.data![index].productsImage),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('제품 명 : ${snapshot.data![index].productsName}'),
                          Text('수량 : ${snapshot.data![index].purchaseQuantity}'),
                        ],
                      )
                    ],
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
  }// build
  creditDialogue(String productName, int quantity, int price, String storeName){
    CustomDialogue().showDialogue(
      title: '구매 진행', 
      middleText: 
      '''
      선택하신 상품은 $productName 이며
      $quantity 개, 가격은 $price 입니다.
      픽업 장소 : $storeName 으로 주문 하시겠습니까? 
      '''
    );
    
  }
}// class
