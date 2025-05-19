import 'dart:convert';
import 'package:black_market_app/global.dart';
import 'package:black_market_app/utility/custom_button.dart';
import 'package:black_market_app/view/customer/customer_announcement.dart';
import 'package:black_market_app/view/customer/product/customer_product_detail.dart';
import 'package:black_market_app/view/customer/purchase/customer_purchase_list.dart';
import 'package:black_market_app/view/customer/purchase/customer_shopping_cart_list.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class CustomerProductList extends StatefulWidget {
  const CustomerProductList({super.key});

  @override
  State<CustomerProductList> createState() => _CustomerProductListState();
}

class _CustomerProductListState extends State<CustomerProductList> {
// ------------------------------- Property ------------------------------------- //
  final box = GetStorage();
  late String uid;

  final TextEditingController searchCon = TextEditingController();
// ------------------------------------------------------------------------------ //
  String searchKeyword = ' ';
  List data = [];
// ------------------------------------------------------------------------------ //
  @override
  void initState() {
    super.initState();
    uid = box.read('uid') ?? '';
    getJSONData();
  }
// ------------------------------- Functions ------------------------------------ //
// 1. 시작은 전체 리스트가 나오고 이후 검색어를 입력 한 뒤 검색 버튼을 누르게 되면 검색어가 포함된 data 들을 불러오는 함수
// 아무것도 입력하지 않고 검색 버튼을 눌러도 전체 data 가 나타난다.
getJSONData()async{
  searchKeyword = searchCon.text.trim().isEmpty
  ? ' '
  : searchCon.text;
var response = await http.get(Uri.parse("http://$globalip:8000/changjun/select/allProductsRegistration/$searchKeyword"));
  data.clear();
  data.addAll(json.decode(utf8.decode(response.bodyBytes))['results']);
  setState(() {});
}
// ------------------------------------------------------------------------------ //

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('상품 리스트'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => Get.to(const CustomerShoppingCartList()),
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
              decoration: const BoxDecoration(color: Colors.black),
            ),
            ListTile(
              leading: const Icon(Icons.money),
              title: const Text('결제 내역'),
              onTap: () => Get.to(const CustomerPurchaseList()),
            ),
            ListTile(
              leading: const Icon(Icons.announcement),
              title: const Text('공지사항'),
              onTap: () => Get.to(const CustomerAnnouncement()),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 검색창
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchCon,
                    decoration: const InputDecoration(
                      hintText: '상품명을 입력하세요',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CustomButton(
                  text: '검색', 
                  onPressed: () {
                    searchKeyword = searchCon.text.trim();
                    getJSONData();
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          //  상품 리스트
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: data.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.8,
            ),
              itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                Get.to(
                  const CustomerProductDetail(),
                  arguments: {
                    'productsName' : data[index]['productsName'],
                    'productsCode' : data[index]['productsCode']
                  },
                );
              },
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Image.network("http://$globalip:8000/changjun/select/allProductsRegistration/image/${data[index]['productsCode']}?t=${DateTime.now().microsecondsSinceEpoch}")
                    ),  
                  ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4.0,
                            horizontal: 8,
                          ),
                          child: Column(
                            children: [
                              Text(
                                data[index]['ptitle'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                '${data[index]['productsPrice']}원',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '색상: ${data[index]['productsColor']}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }// build
}// class
