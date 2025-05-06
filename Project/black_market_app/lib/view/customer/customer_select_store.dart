// 대리점 선택
import 'package:flutter/material.dart';

class CustomerSelectStore extends StatefulWidget {
  const CustomerSelectStore({super.key});

  @override
  State<CustomerSelectStore> createState() => _CustomerSelectStoreState();
}

class _CustomerSelectStoreState extends State<CustomerSelectStore> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('대리점 선택 페이지'),
      ),
    );
  }
}