// 제품 리스트 - 2팀 팀원 : 김수아 개발 
//목적 : 
//등록된 제품들을 볼 수 있다 
//개발일지
//2025_05_18
//디비 라이트로 구현 헀던 핸드러를 빼고 mysql 파이썬 서버로 바꾸기 

import 'dart:convert';

import 'package:black_market_app/global.dart';
import 'package:black_market_app/model/products.dart';
import 'package:black_market_app/view/company/create/company_create_product.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class CompanyProductList extends StatefulWidget {
  const CompanyProductList({super.key});

  @override
  State<CompanyProductList> createState() => _CompanyProductListState();
}

class _CompanyProductListState extends State<CompanyProductList> {
  
  //검색한 결과를 받아 오는 리스트
  List data = [];
  List<Products> filteredList = [];
  //검색창에 용으로 쓰임 
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getJSONData();
  }
  //전부 보이는 데이타 
  getJSONData()async{
  var response = await http.get(Uri.parse("http://$globalip:8000/kimsua/select/products"));
  data.clear();
  data.addAll(json.decode(utf8.decode(response.bodyBytes))['results']);
  setState(() {});
  // print(data);
}
  getJSONData1()async{
    final keyword = searchController.text.trim();
      if (keyword.isEmpty) {
        getJSONData(); 
        return;
      }
      final response = await http.get(
        Uri.parse("http://$globalip:8000/kimsua/select/products/$keyword"),
      );
      if (response.statusCode == 200) {
            data.clear();
            final decoded = json.decode(utf8.decode(response.bodyBytes));
            if (decoded['result'] is List) {
              data.addAll(decoded['result']);
            }
            setState(() {});
          } else {
            // 에러 처리
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("검색 실패")),
            );
          }
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
                        onPressed: getJSONData1,
                      ),
                    ),
                    onSubmitted: (value) => getJSONData1(),
                  
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
            child: data.isEmpty
            ?Center(
              child: Text("등록된 제품이 없습니다.",
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold
              ),
              ),
            )
            
            :ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: data.length,
              itemBuilder: (context, index) {
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
                      //int 형들은 괄호안에 넣어서 보내주기 
                      Text('${data[index]['productsCode'] ?? "-"}', style: const TextStyle(color: Colors.white)),
                      Text(data[index]['productsName'], style: const TextStyle(color: Colors.white)),
                      Text(data[index]['productsColor'], style: const TextStyle(color: Colors.white)),
                      Text('${data[index]['productsSize']}', style: const TextStyle(color: Colors.white)),
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
              getJSONData1(); // 제품 등록 후 재로딩
                 },

              child: const Text('제품 등록'),
            ),
          ),
        ],
      ),
    );
  }
}
