import 'package:black_market_app/vm/database_handler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomerAnnouncementDetail extends StatefulWidget {
  const CustomerAnnouncementDetail({super.key});

  @override
  State<CustomerAnnouncementDetail> createState() => _CustomerAnnouncementDetailState();
}

class _CustomerAnnouncementDetailState extends State<CustomerAnnouncementDetail> {
  late DatabaseHandler handler;
  late String announcementTitle;

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    announcementTitle = Get.arguments ?? '__';
  } 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('상세보기'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder(
        future: handler.queryAnnouncementByTitle(announcementTitle), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('오류 발생: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('공지사항을 불러오지 못했습니다.'));
          }
          final notice = snapshot.data!.first;
          return Center(
            child: Column(
              children: [
                Image.memory(notice.photo,
                width: MediaQuery.sizeOf(context).width,
                height: 200,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('제목 : ${notice.title}'),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text('날짜 : ${notice.date}'),
                ),
Padding(
  padding: const EdgeInsets.all(16.0),
  child: Text(
    '내용: ${notice.content}',
    style: TextStyle(fontSize: 16),
    softWrap: true, // 자동 줄바꿈 허용
    overflow: TextOverflow.visible, // 넘치는 텍스트도 그대로 보여줌
  ),
),
              ],
            ),
          );
        },
      ),
    );
  }
}