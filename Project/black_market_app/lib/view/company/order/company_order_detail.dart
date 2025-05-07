// 상신 상세보기
import 'package:black_market_app/vm/database_handler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CompanyOrderDetail extends StatefulWidget {
  final Map<String, dynamic> approvalData;

  const CompanyOrderDetail({super.key, required this.approvalData});

  @override
  State<CompanyOrderDetail> createState() => _CompanyOrderDetailState();
}

class _CompanyOrderDetailState extends State<CompanyOrderDetail> {
  late DatabaseHandler handler;
  final TextEditingController rejectReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
  }

  @override
  void dispose() {
    rejectReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle labelStyle = const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold);
    final TextStyle valueStyle = const TextStyle(color: Colors.white);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('결재서 상세'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('제목', style: labelStyle),
            Text(widget.approvalData['title'] ?? '', style: valueStyle),
            const SizedBox(height: 12),

            Text('작성자', style: labelStyle),
            Text(widget.approvalData['name'] ?? '', style: valueStyle),
            const SizedBox(height: 12),

            Text('내용', style: labelStyle),
            Text(widget.approvalData['content'] ?? '', style: valueStyle),
            const SizedBox(height: 12),

            Text('품의비', style: labelStyle),
            Text('${widget.approvalData['approvalRequestExpense']} 원', style: valueStyle),
            const SizedBox(height: 12),

            Text('결재 상태', style: labelStyle),
            Text(widget.approvalData['approvalStatus'] ?? '', style: valueStyle),
            const SizedBox(height: 12),

            Text('작성일자', style: labelStyle),
            Text(widget.approvalData['date'] ?? '', style: valueStyle),
            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    Get.defaultDialog(
                      title: "승인",
                      middleText: "결재를 승인하시겠습니까?",
                      onConfirm: () async {
                        await handler.updateApprovalStatus(
                          userId: widget.approvalData['cuserid'],
                          date: widget.approvalData['date'],
                          status: '승인됨',
                        );
                        Get.back();
                        Get.back();
                      },
                      onCancel: () {},
                      textConfirm: "예",
                      textCancel: "아니오",
                    );
                  },
                  child: const Text("승인"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    Get.defaultDialog(
                      title: "반려 사유 입력",
                      content: Column(
                        children: [
                          const Text("반려 사유를 입력하세요", style: TextStyle(color: Colors.white)),
                          const SizedBox(height: 10),
                          TextField(
                            controller: rejectReasonController,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: '예: 예산 초과, 내용 보완 필요 등',
                              hintStyle: TextStyle(color: Colors.white54),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                      onConfirm: () async {
                        await handler.rejectApproval(
                          userId: widget.approvalData['cuserid'],
                          date: widget.approvalData['date'],
                          reason: rejectReasonController.text,
                        );
                        Get.back();
                        Get.back();
                      },
                      onCancel: () {},
                      textConfirm: "반려",
                      textCancel: "취소",
                    );
                  },
                  child: const Text("반려"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
