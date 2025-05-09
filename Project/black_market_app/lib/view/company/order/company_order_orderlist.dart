///발주 리스트 보기
import 'package:black_market_app/vm/database_handler.dart';
import 'package:flutter/material.dart';

class CompanyOrderOrderlist extends StatefulWidget {
  const CompanyOrderOrderlist({super.key});

  @override
  State<CompanyOrderOrderlist> createState() => _CompanyOrderOrderlistState();
}

class _CompanyOrderOrderlistState extends State<CompanyOrderOrderlist> {
  late DatabaseHandler handler;
  List<Map<String, dynamic>> orders = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    loadOrders();
  }

  Future<void> loadOrders() async {
    final result = await handler.getAllOrders();
    setState(() {
      orders = result;
    });
  }

  List<Map<String, dynamic>> get filteredOrders {
    if (searchQuery.isEmpty) return orders;
    return orders.where((order) =>
      order['productsName'].toString().toLowerCase().contains(searchQuery.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('발주 내역',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        ),
        backgroundColor: Colors.black,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SizedBox(
              width: 200,
              child: TextField(
                onChanged: (val) => setState(() => searchQuery = val),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: '상품명 검색',
                  hintStyle: TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                ),
              ),
            ),
          )
        ],
      ),
      body: ListView.builder(
        itemCount: filteredOrders.length,
        itemBuilder: (context, index) {
          final order = filteredOrders[index];
          return ListTile(
            title: Text(
              '${order['productsName']} (코드: ${order['oproductCode']})',
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              '수량: ${order['orderQuantity']}, 가격: ${order['orderPrice']}원\n상태: ${order['orderStatus']}',
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: Text(
              '제조사: ${order['omamufacturer']}',
              style: const TextStyle(color: Colors.white38),
            ),
          );
        },
      ),
    );
  }
}