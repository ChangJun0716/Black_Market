import 'package:black_market_app/model/grouped_products.dart';
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

  final TextEditingController searchCon = TextEditingController();
  String searchKeyword = '';

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    uid = box.read('uid') ?? '';
  }

  Future<List<GroupedProduct>> fetchData() {
    return handler.queryGroupedProducts(keyword: searchKeyword);
  }

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
          // 🔍 검색창
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
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      searchKeyword = searchCon.text.trim();
                    });
                  },
                  child: const Text('검색'),
                ),
              ],
            ),
          ),
          // 📦 상품 그리드
          Expanded(
            child: FutureBuilder(
              future: fetchData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('오류 발생: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('등록된 상품이 없습니다.'));
                }

                final products = snapshot.data!;

                return GridView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: products.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.8,
                  ),
                  itemBuilder: (context, index) {
                    final item = products[index];
                    return GestureDetector(
                      onTap: () {
                        Get.to(
                          const CustomerProductDetail(),
                          arguments: item.ptitle,
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
                                child: Image.memory(
                                  item.introductionPhoto,
                                  fit: BoxFit.cover,
                                ),
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
                                    item.ptitle,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    '${item.productsPrice}원',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '색상: ${item.productsColor}',
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
