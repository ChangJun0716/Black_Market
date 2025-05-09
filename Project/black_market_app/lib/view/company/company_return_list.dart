// 반품 관리
import 'package:black_market_app/view/company/company_return_detail.dart';
import 'package:black_market_app/vm/database_handler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CompanyReturnList extends StatefulWidget {
  const CompanyReturnList({super.key});

  @override
  State<CompanyReturnList> createState() => _CompanyReturnListState();
}

class _CompanyReturnListState extends State<CompanyReturnList> {
  late DatabaseHandler handler;
  List<Map<String, dynamic>> returnList = [];
  String selectedStatus = '전체';
  final List<String> statusOptions = ['전체', '처리중', '완료', '반려'];

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    loadReturns();
  }

  Future<void> loadReturns() async {
    returnList = await handler.loadFilteredReturns(
      status: selectedStatus,
      
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("반품 관리 리스트",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        ),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.grey[900],
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: selectedStatus,
                  dropdownColor: Colors.grey[800],
                  style: const TextStyle(color: Colors.white),
                  items: statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                    setState(() => selectedStatus = val!);
                    loadReturns();
                  },
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Colors.grey[850],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("총 ${returnList.length}건", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
          Container(
            color: Colors.grey[850],
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: const [
                Expanded(flex: 4, child: Text('반품 사유', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('신청자', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('상태', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.black,
              child: ListView.separated(
                itemCount: returnList.length,
                separatorBuilder: (_, __) => Divider(color: Colors.grey[700]),
                itemBuilder: (context, index) {
                  final item = returnList[index];
                  final reason = item['returnReason'] ?? '';
                  final shortReason = reason.length > 15 ? '${reason.substring(0, 15)}...' : reason;
                  return GestureDetector(
                    onTap: () {
                      Get.to(() => CompanyReturnDetail(),
                        arguments: item,
                      )!.then((Value)=>{
                        loadReturns(),
                        setState(() {
                          
                        })
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(flex: 4, child: Text(shortReason, style: const TextStyle(color: Colors.white))),
                          Expanded(flex: 3, child: Text(item['ruserId'] ?? '', style: const TextStyle(color: Colors.white))),
                          Expanded(flex: 3, child: Text(item['processionStatus'] ?? '', style: const TextStyle(color: Colors.white))),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}