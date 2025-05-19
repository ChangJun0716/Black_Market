// 입고 페이지 - 2팀 팀원 : 김수아 개발 
// 목적 : 
// 제품을 발주를 하고 제조사라 부터 제품을 받고 수량을 전산상에 등록하기 위해 쓰는 페이지이다. 
// 개발 일지  :
//sqlite로 개발 했던 소스를 mysql로 바꾸기 
// global 변수로 ip 설정 완료 

import 'dart:convert';

import 'package:black_market_app/global.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class CompanyProductStock extends StatefulWidget {
  const CompanyProductStock({super.key});

  @override
  State<CompanyProductStock> createState() => _CompanyProductStockState();
}

class _CompanyProductStockState extends State<CompanyProductStock> {
  //get arguments 벋울꺼
  late Map<String, dynamic> selectedItem;
  //입고 수량 입력창
  final TextEditingController quantityController = TextEditingController();
  final box = GetStorage();
  //아이디
  late String userId;
  //제조사 리스트
  List<String> manufacturerList = [];
  //제조사 선택된거
  String? selectedManufacturer;

  @override
  void initState() {
    super.initState();
    selectedItem = Map<String, dynamic>.from(Get.arguments);
    userId = box.read('uid') ?? '';
    loadManufacturers();
  }
  //제조사 검색
 loadManufacturers() async {
  try {
    final response = await http.get(Uri.parse('http://$globalip:8000/kimsua/select/manufacturers'));
    if (response.statusCode == 200) {
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      manufacturerList = List<String>.from(decoded['result']);
      setState(() {
      });
    }
  } catch (e) {
    print("Error: $e");
  }
}
//입력
  _submit() async {
  if (selectedManufacturer == null || quantityController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("제조사와 수량을 입력해주세요.")),
    );
    return;
  }
  try {
 
      var request = http.MultipartRequest(
          "POST",
          Uri.parse("http://$globalip:8000/kimsua/insert/products/stockReceipts"),
        );
        request.fields['stockReceiptsQuantityReceived'] = quantityController.text.trim();
        request.fields['stockReceiptsReceipDate'] = DateTime.now().toString();
        request.fields['manufacturers_manufacturerName'] = selectedManufacturer!.toString();
        request.fields['users_userid'] = userId;
        request.fields['products_productsCode'] =selectedItem['productsCode'].toString();
        var res = await request.send();
        if (res.statusCode == 200) {
          _showDialog();
        } else {
          errorSnackBar();
        }
        
  } catch (e) {
    print(e);
    errorSnackBar();
  }
}

_showDialog(){
  Get.defaultDialog(
    title: "입력 결과",
    middleText: "입력이 완료 되었습니다.",
    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
    barrierDismissible: false,
    actions: [
      TextButton(
        onPressed: () {
          Get.back();
          Get.back();
        }, 
        child: Text('OK')
      ),
    ]
  );
}

errorSnackBar(){
  Get.snackbar(
    'Error', 
    '입력시 문제가 발생 했습니다.',
    duration: Duration(seconds: 2)
  );
}
 



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("입고 페이지",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        ),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: Colors.grey[900],
              child: ListTile(
                title: Text(
                  '${selectedItem['productsName']} (ID: ${selectedItem['productsCode']})',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '컬러: ${selectedItem['productsColor']} / 사이즈: ${selectedItem['productsSize']} ',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              style: TextStyle(
                color: Colors.pink
              ),
              value: selectedManufacturer,
              hint: const Text('제조사 선택'),
              items: manufacturerList.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedManufacturer = newValue;
                });
              },
              validator: (value) => value == null ? '제조사를 선택해주세요' : null,
            ),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '입고 수량 입력',
                hintStyle: TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('입고하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
