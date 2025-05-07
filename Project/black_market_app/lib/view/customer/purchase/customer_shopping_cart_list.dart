// 장바구니
import 'package:flutter/material.dart';

class CustomerShoppingCartList extends StatefulWidget {
  const CustomerShoppingCartList({super.key});

  @override
  State<CustomerShoppingCartList> createState() => _CustomerShoppingCartListState();
}

class _CustomerShoppingCartListState extends State<CustomerShoppingCartList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('장바구니'),
      ),
    );
  }
}