// 구매 상세 내역
import 'package:flutter/material.dart';

class CustomerPurchaseDetail extends StatefulWidget {
  const CustomerPurchaseDetail({super.key});

  @override
  State<CustomerPurchaseDetail> createState() => _CustomerPurchaseDetailState();
}

class _CustomerPurchaseDetailState extends State<CustomerPurchaseDetail> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('결재 내역 상세 정보'),
      ),
    );
  }
}