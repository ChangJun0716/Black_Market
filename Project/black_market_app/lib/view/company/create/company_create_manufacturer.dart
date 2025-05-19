//재조사 입력 페이지 - 2조 팀원 김수아 개발 
//목적 : 
//제조사를 입력하는 페이지 새로운 제조사의 물건을 들어오데 되면 제조사를 등록 할 수 있다.
//차후 더 이상 팔지 않는 제조사의 이름은 지울 수 도 있게 하려고 한다 
//개발 일지 : 
//2025_05_18
// 원래 있던 sqlite의 내용을 mysql로 바꿨다.
//global ip 적용 완료!

import 'package:black_market_app/global.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class CompanyCreateManufacturer extends StatefulWidget {
  const CompanyCreateManufacturer({super.key});

  @override
  State<CompanyCreateManufacturer> createState() => _CompanyCreateManufacturerState();
}

class _CompanyCreateManufacturerState extends State<CompanyCreateManufacturer> {
  final TextEditingController _nameController = TextEditingController();


  @override
  void initState() {
    super.initState();

  }

  submit() async {
    if (_nameController.text.trim().isNotEmpty) {
      
      try {
        var request = http.MultipartRequest(
          "POST",
          Uri.parse("http://$globalip:8000/kimsua/insert/manufacturers"),
        );
        request.fields['manufacturerName'] = _nameController.text.trim();
        
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('제조사가 등록되었습니다.')),
        );
        Navigator.pop(context);
      
      } catch (e) {
        errorSnackBar();
      }
       



    } else{
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제조사명을 입력해주세요.')),
      );
    }
    }
  errorSnackBar() {
    Get.snackbar(
      'Error',
      '입력시 문제가 발생했습니다.',
      duration: Duration(seconds: 2),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('제조사 등록')),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: '제조사명',
                labelStyle: TextStyle(color: Colors.white),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: submit,
                child: const Text('등록하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
