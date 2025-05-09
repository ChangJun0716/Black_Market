// 제품 리스트 
import 'package:black_market_app/model/products.dart';
import 'package:black_market_app/view/company/create/company_create_product.dart';
import 'package:black_market_app/vm/database_handler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CompanyProductList extends StatefulWidget {
  const CompanyProductList({super.key});

  @override
  State<CompanyProductList> createState() => _CompanyProductListState();
}

class _CompanyProductListState extends State<CompanyProductList> {
  late DatabaseHandler handler;
  List<Products> filteredList = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    _loadProducts();
  }

  void _loadProducts() async {
    final list = await handler.getAllProducts1(); // your method name
    setState(() {
      filteredList = list;
    });
  }

  void _filterProducts(String query) async {
    final list = await handler.getAllProducts1();
    setState(() {
      filteredList = list
          .where((product) =>
              product.productsName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("제품 리스트", style: TextStyle(color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 180,
              child: TextField(
                controller: searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "제품명 검색",
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.black26,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () => _filterProducts(searchController.text),
                  ),
                ),
                onSubmitted: _filterProducts,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("제품 ID", style: TextStyle(color: Colors.white)),
                Text("제품명", style: TextStyle(color: Colors.white)),
                Text("색상", style: TextStyle(color: Colors.white)),
                Text("사이즈", style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final product = filteredList[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${product.productsCode ?? "-"}', style: const TextStyle(color: Colors.white)),
                      Text(product.productsName, style: const TextStyle(color: Colors.white)),
                      Text(product.productsColor, style: const TextStyle(color: Colors.white)),
                      Text('${product.productsSize}', style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () async {
              await Get.to(() => const CompanyCreateProduct());
              _loadProducts(); // 제품 등록 후 재로딩
                 },

              child: const Text('제품 등록'),
            ),
          ),
        ],
      ),
    );
  }
}
