// 게시글 리스트 - CompanyPostList.dart (제품명, 작성자, 제목만 표시, 인덱스 포함)
import 'dart:convert';
import 'package:black_market_app/global.dart';
import 'package:black_market_app/model/product_registration.dart';
import 'package:black_market_app/view/company/create/company_create_product_post.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class CompanyPostList extends StatefulWidget {
  const CompanyPostList({super.key});

  @override
  State<CompanyPostList> createState() => _CompanyPostListState();
}

class _CompanyPostListState extends State<CompanyPostList> {
  List<Map<String, dynamic>> postList = [];
  List<Map<String, dynamic>> filteredList = [];
  TextEditingController searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      final response = await http.get(Uri.parse('http://${globalip}:8000/kimsua/select/product/posts'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final loadedPosts = jsonList.cast<Map<String, dynamic>>();
        setState(() {
          postList = loadedPosts;
          filteredList = loadedPosts;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterPosts(String query) {
    setState(() {
      filteredList = postList.where((post) =>
        post['productsName'].toLowerCase().contains(query.toLowerCase()) ||
        post['ptitle'].toLowerCase().contains(query.toLowerCase()) ||
        post['paUserid'].toLowerCase().contains(query.toLowerCase())
      ).toList();
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
                  hintText: "검색어 입력",
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(flex: 1, child: Text("번호", style: TextStyle(color: Colors.white))),
                      Expanded(flex: 3, child: Text("작성자", style: TextStyle(color: Colors.white))),
                      Expanded(flex: 4, child: Text("제품명", style: TextStyle(color: Colors.white))),
                      Expanded(flex: 4, child: Text("제목", style: TextStyle(color: Colors.white))),
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
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          border: Border.all(color: Colors.white24),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(flex: 1, child: Text('${index + 1}', style: const TextStyle(color: Colors.white))),
                            Expanded(flex: 3, child: Text(post['paUserid'], style: const TextStyle(color: Colors.white))),
                            Expanded(flex: 4, child: Text(post['productsName'], style: const TextStyle(color: Colors.white))),
                            Expanded(flex: 4, child: Text(post['ptitle'], style: const TextStyle(color: Colors.white))),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () => Get.to(() => const CompanyCreatePost())?.then((_) => _loadPosts()),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: const Text('게시글 추가'),
                  ),
                ),
              ],
            ),
    );
  }
}
