// 공지사항
import 'dart:convert';
import 'package:black_market_app/global.dart';
import 'package:black_market_app/view/customer/customer_announcement_detail.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class CustomerAnnouncement extends StatefulWidget {
  const CustomerAnnouncement({super.key});

  @override
  State<CustomerAnnouncement> createState() => _CustomerAnnouncementState();
}

class _CustomerAnnouncementState extends State<CustomerAnnouncement> {
// ------------------------------- Property ------------------------------------- //
  List data = [];
// ------------------------------------------------------------------------------ //
  @override
  void initState() {
    super.initState();
    getJSONData();
  }
// ------------------------------------------------------------------------------ //
// ------------------------------- Functions ------------------------------------ //
getJSONData()async{
  var response = await http.get(Uri.parse("http://$globalip:8000/changjun/select/notice"));
  data.clear();
  data.addAll(json.decode(utf8.decode(response.bodyBytes))['results']);
  setState(() {});
}
// ------------------------------------------------------------------------------ //


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('공지사항'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Get.to(CustomerAnnouncementDetail(), arguments: data[index]['title']);
                  },
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('제목 : ${data[index]["title"]}'),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                            child: Text('날짜 : ${data[index]["date"]}'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
    );
  }
}