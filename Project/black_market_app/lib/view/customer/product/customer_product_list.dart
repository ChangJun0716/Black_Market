// 제품 리스트
import 'package:black_market_app/view/customer/customer_announcement.dart';
import 'package:black_market_app/view/customer/product/customer_product_detail.dart';
import 'package:black_market_app/view/customer/purchase/customer_purchase_list.dart';
import 'package:black_market_app/view/customer/purchase/customer_shopping_cart_list.dart';
import 'package:black_market_app/vm/database_handler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomerProductList extends StatefulWidget {
  const CustomerProductList({super.key});

  @override
  State<CustomerProductList> createState() => _CustomerProductListState();
}

class _CustomerProductListState extends State<CustomerProductList> {
  late DatabaseHandler handler;
  @override
  Widget build(BuildContext context) {
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
          Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(''), 
                  accountEmail: Text('')
                ),
                ListTile(
                  leading: Icon(Icons.money),
                  title: Text('결재 내역'),
                  onTap: () => Get.to(CustomerPurchaseList()),
                ),
                ListTile(
                  leading: Icon(Icons.money),
                  title: Text('공지사항'),
                  onTap: () => Get.to(CustomerAnnouncement()),
                ),
              ],
            ),
          )
        ],
      ),
      body: FutureBuilder(
        future: handler.queryGroupedProducts(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Get.to(CustomerProductDetail(), arguments: snapshot.data![index].productsName);
                  },
                  child: Card(
                    child: Row(
                      children: [
                        Image.memory(snapshot.data![index].productsImage),
                        Text(snapshot.data![index].productsName),
                      ],
                    ),
                  ),
                );
              },
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
