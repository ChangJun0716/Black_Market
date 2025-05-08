// 구매 내역
import 'package:black_market_app/vm/database_handler.dart';
import 'package:flutter/material.dart';

class CustomerPurchaseList extends StatefulWidget {
  const CustomerPurchaseList({super.key});

  @override
  State<CustomerPurchaseList> createState() => _CustomerPurchaseListState();
}

class _CustomerPurchaseListState extends State<CustomerPurchaseList> {
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
        title: Text('결재 내역'),
      ),
    );
  }
}