// 공지사항
import 'package:flutter/material.dart';

class CustomerAnnouncement extends StatefulWidget {
  const CustomerAnnouncement({super.key});

  @override
  State<CustomerAnnouncement> createState() => _CustomerAnnouncementState();
}

class _CustomerAnnouncementState extends State<CustomerAnnouncement> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('공지사항 list'),
      ),
    );
  }
}