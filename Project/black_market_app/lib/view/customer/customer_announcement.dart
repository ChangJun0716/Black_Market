// 공지사항
import 'package:black_market_app/vm/database_handler.dart';
import 'package:flutter/material.dart';

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
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return Card(
                  child: Row(
                    children: [
                      Image.memory(snapshot.data![index].photo,
                      width: 100,
                      height: 100,
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