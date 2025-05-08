//게시글 리스트 import 'package:black_market_app/model/product_registration.dart';
import 'package:black_market_app/model/product_registration.dart';
import 'package:black_market_app/view/company/create/company_create_product_post.dart';
import 'package:black_market_app/vm/database_handler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CompanyPostList extends StatefulWidget {
  const CompanyPostList({super.key});

  @override
  State<CompanyPostList> createState() => _CompanyPostListState();
}

class _CompanyPostListState extends State<CompanyPostList> {
  late DatabaseHandler handler;
  List<ProductRegistration> postList = [];
  List<ProductRegistration> filteredList = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    _loadPosts();
  }

  void _loadPosts() async {
    final list = await handler.getAllProductPosts();
    setState(() {
      postList = list;
      filteredList = list;
    });
  }

  void _filterPosts(String query) {
    setState(() {
      filteredList = postList
          .where((post) =>
              post.pProductCode.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("게시글 리스트", style: TextStyle(color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 200,
              child: TextField(
                controller: searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "제품 코드 검색",
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () => _filterPosts(searchController.text),
                  ),
                ),
                onSubmitted: _filterPosts,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("게시글 ID", style: TextStyle(color: Colors.white)),
                Text("작성자", style: TextStyle(color: Colors.white)),
                Text("제목", style: TextStyle(color: Colors.white)),
                Text("제품 코드", style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final post = filteredList[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('게시글 ID: ${index + 1}'),
                      Text('작성자: ${post.paUserid}'),
                      Text('제목: ${post.ptitle}'),
                      Text('제품 코드: ${post.pProductCode}'),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => Get.to(() => const CompanyCreatePost())!
                  .then((_) => _loadPosts()),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('게시글 추가'),
            ),
          ),
        ],
      ),
    );
  }
}
