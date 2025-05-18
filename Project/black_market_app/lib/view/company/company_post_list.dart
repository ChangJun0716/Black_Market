// 게시글 리스트 _ 2팀 팀원 : 김수아 개발 
// 목적 :
// 사용자가 그 물건에 대한 게시글을 확인 할 수 있다 
// 차후 이 페이지 에선 추가 말고도 업데이트 + 삭제를 페이지로 갈 수 있도록 연결고리가 되어 줄 것이다. 
// 개발일지 : 
//2025_05_17 
//파이썬 코드로 연동 ok 
// 실시간 검색 db에서 안하고 그냥 있는 함수로 수정함 
//모든 코드 ip global ip적용 완료 

import 'dart:convert';
import 'package:black_market_app/global.dart';
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
  //검색 전 모든 정보가 들어갈 리스트
  List<Map<String, dynamic>> postList = [];
  //겁색 완료된 리스트가 저장될 리스트 
  List<Map<String, dynamic>> filteredList = [];
  //검색 받을 텍스트 피드 
  TextEditingController searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      final response = await http.get(Uri.parse('http://${globalip}:8000/kimsua/select/products/post/list'));
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
// 검색 기능 
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
                      // 위에 바 
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
                            // 값이 들어가는 곳 
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
