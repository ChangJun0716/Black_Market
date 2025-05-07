import 'package:black_market_app/view/company/order/company_order_detail.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:black_market_app/vm/database_handler.dart';

class ApprovalListPage extends StatefulWidget {
  const ApprovalListPage({super.key});

  @override
  State<ApprovalListPage> createState() => _ApprovalListPageState();
}

class _ApprovalListPageState extends State<ApprovalListPage> {
  late DatabaseHandler handler;
  List<Map<String, dynamic>> approvals = [];
  String selectedStatus = '전체';
  DateTime? startDate;
  DateTime? endDate;

  final List<String> statusOptions = ['전체', '신청됨', '승인됨', '반려됨'];

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    loadApprovals();
  }

  Future<void> loadApprovals() async {
    approvals = await handler.loadFilteredApprovals(
      status: selectedStatus,
      start: startDate,
      end: endDate,
    );
    setState(() {});
  }

  Future<void> pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      loadApprovals();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("결재 리스트"),
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
                  items: statusOptions
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    setState(() => selectedStatus = val!);
                    loadApprovals();
                  },
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: pickDateRange,
                  child: const Text("날짜 선택"),
                )
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Colors.grey[850],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("총 ${approvals.length}건", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
          Container(
            color: Colors.grey[850],
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: const [
                Expanded(flex: 4, child: Text('결재서 제목', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('작성자', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('상태', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.black,
              child: ListView.separated(
                itemCount: approvals.length,
                separatorBuilder: (_, __) => Divider(color: Colors.grey[700]),
                itemBuilder: (context, index) {
                  final doc = approvals[index];
                  final title = doc['title'] ?? '';
                  final shortTitle = title.length > 15 ? '${title.substring(0, 15)}...' : title;

                  return GestureDetector(
                    onTap: () {
                      Get.to(() => CompanyOrderDetail(approvalData: doc));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(flex: 4, child: Text(shortTitle, style: const TextStyle(color: Colors.white))),
                          Expanded(flex: 3, child: Text(doc['name'] ?? '', style: const TextStyle(color: Colors.white))),
                          Expanded(flex: 3, child: Text(doc['approvalStatus'] ?? '', style: const TextStyle(color: Colors.white))),
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

