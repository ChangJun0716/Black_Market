import 'dart:convert';
import 'package:black_market_app/global.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class CustomerAnnouncementDetail extends StatefulWidget {
  const CustomerAnnouncementDetail({super.key});

  @override
  State<CustomerAnnouncementDetail> createState() =>
      _CustomerAnnouncementDetailState();
}

class _CustomerAnnouncementDetailState extends State<CustomerAnnouncementDetail> {
// ------------------------------- Property ------------------------------------- //
  late String announcementTitle;
  late String title;
  List data = [];
  String date = '';
  String content = '';
// ------------------------------------------------------------------------------ //
  @override
  void initState() {
    super.initState();
    title = Get.arguments ?? '__';
    // print(title); --- 1
    getJSONData();
  }
// ------------------------------------------------------------------------------ //
// ------------------------------ Functions ------------------------------------- //
// 선택한 card 로 부터 title 값을 받아와 database 에서 검색하여 image 를 제외한 data 를 불러와
// 변수에 대입하는 함수! <- 리스트로 불러와 바로 화면에 대입할 경우 오류가 발생!
getJSONData()async{

  var response = await http.get(Uri.parse("http://$globalip:8000/changjun/select/notice/detail?title=$title"));
  data.clear();
  data.addAll(json.decode(utf8.decode(response.bodyBytes))['results']);
  // print(data[0]); --- 2
  date = data[0]['date'];
  content = data[0]['content'];
  setState(() {});
}
// ------------------------------------------------------------------------------ //
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('공지사항 상세보기'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.network("http://$globalip:8000/changjun/select/notive/detail/image/$title?t=${DateTime.now().microsecondsSinceEpoch}",
                        width: MediaQuery.of(context).size.width,
                        height: 200,
                        ),
                      ),
                      _text('제목', title),
                      _text('날짜', date),
                      _text('제목', content),
                    ],
                ),
              ),
            ),
          )
    );
  }// build
// ------------------------- Widget ----------------------------------------- //
// 선택한 공지사항의 제목, 내용, 날짜 등을 카드에 표시하기 위한 text widget
Widget _text(String title, String content){
  return Row(
    children: [
      Text(
        '$title : ',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15
        ),
      ),
      Text(content)
    ],
  );
}
// -------------------------------------------------------------------------- //
}// class
