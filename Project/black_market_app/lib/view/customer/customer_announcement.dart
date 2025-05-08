// 공지사항
import 'package:black_market_app/view/customer/customer_announcement_detail.dart';
import 'package:black_market_app/vm/database_handler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomerAnnouncement extends StatefulWidget {
  const CustomerAnnouncement({super.key});

  @override
  State<CustomerAnnouncement> createState() => _CustomerAnnouncementState();
}

class _CustomerAnnouncementState extends State<CustomerAnnouncement> {
  late DatabaseHandler handler;

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('공지사항'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder(
        future: handler.queryAnnouncment(), 
        builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    // 에러가 발생한 경우
    if (snapshot.hasError) {
      return Center(
        child: Text('에러 발생: ${snapshot.error}'),
      );
    }

    // 데이터가 없는 경우
    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return Center(
        child: Text('공지사항이 없습니다.'),
      );
    }
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Get.to(CustomerAnnouncementDetail(), arguments: snapshot.data![index].title);
                  },
                  child: Card(
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.memory(snapshot.data![index].photo,
                          width: 100,
                          height: 100,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('제목 : ${snapshot.data![index].title}'),
                            Text('날짜 : ${snapshot.data![index].date}'),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          }else{
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}