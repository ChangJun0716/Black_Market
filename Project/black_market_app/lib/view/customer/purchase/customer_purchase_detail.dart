// 제품 리스트
import 'package:black_market_app/view/customer/customer_announcement.dart';
import 'package:black_market_app/view/customer/product/customer_product_detail.dart';
import 'package:black_market_app/view/customer/purchase/customer_purchase_list.dart';
import 'package:black_market_app/view/customer/purchase/customer_shopping_cart_list.dart';
import 'package:black_market_app/vm/database_handler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class CustomerProductList extends StatefulWidget {
  const CustomerProductList({super.key});

  @override
  State<CustomerProductList> createState() => _CustomerProductListState();
}

class _CustomerProductListState extends State<CustomerProductList> {
  late DatabaseHandler handler;
  final box = GetStorage();
  late String uid;
  late int memberType;
  bool isReady = false;
  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    initStorage();
  }

  initStorage() async {
    uid = await box.read('uid');
    memberType = box.read('memberType');
    isReady = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!isReady) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('상품 리스트'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => Get.to(CustomerShoppingCartList()),
            icon: Icon(Icons.shopping_cart),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(uid),
              accountEmail: Text(''),
              decoration: BoxDecoration(color: Colors.black),
            ),
            ListTile(
              leading: Icon(Icons.money),
              title: Text('결재 내역'),
              onTap: () => Get.to(CustomerPurchaseList()),
            ),
            ListTile(
              leading: Icon(Icons.announcement),
              title: Text('공지사항'),
              onTap: () => Get.to(CustomerAnnouncement()),
            ),
          ],
        ),
      ),
      body: FutureBuilder(
        future: handler.queryGroupedProducts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Get.to(
                    CustomerProductDetail(),
                    arguments: data[index].productsName,
                  );
                },
                child: Card(
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.memory(
                          data[index].productsImage,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Text('제품명 : ${data[index].productsName}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
