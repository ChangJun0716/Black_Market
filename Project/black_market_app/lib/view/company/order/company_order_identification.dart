// 원인규명 기록
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../vm/database_handler.dart';
import '../../../model/return_investigation.dart';

class CompanyOrderDetail extends StatefulWidget {
  final Map<String, dynamic> returnData;
  final String userId;
  final String jobGradeCode;

  const CompanyOrderDetail({
    super.key,
    required this.returnData,
    required this.userId,
    required this.jobGradeCode,
  });

  @override
  State<CompanyOrderDetail> createState() => _CompanyOrderDetailState();
}

class _CompanyOrderDetailState extends State<CompanyOrderDetail> {
  final TextEditingController resolutionController = TextEditingController();
  String? selectedStatus;
  late DatabaseHandler handler;

  final List<String> statusOptions = ['처리중', '완료됨'];

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    selectedStatus = widget.returnData['prosessionStateus'];
  }

  @override
  void dispose() {
    resolutionController.dispose();
    super.dispose();
  }

  Future<void> saveResolution() async {
    final record = ReturnInvestigation(
      raUserid: widget.userId,
      raJobGradeCode: widget.jobGradeCode,
      rreturnCode: widget.returnData['returnCode'],
      rmanufacturerName: widget.returnData['rmanufacturerName'] ?? '미확인',
      recordDate: DateTime.now(),
      resolutionDetails: resolutionController.text,
    );

    await handler.saveReturnInvestigation(record);

    if (selectedStatus != null && selectedStatus != widget.returnData['prosessionStateus']) {
      await handler.updateReturnStatus(
        returnCode: widget.returnData['returnCode'],
        newStatus: selectedStatus!,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("처리 내용이 저장되었습니다.")),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.returnData;
    const labelStyle = TextStyle(color: Colors.white70, fontWeight: FontWeight.bold);
    const valueStyle = TextStyle(color: Colors.white);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("반품 상세"), backgroundColor: Colors.black),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildInfoRow("반품 코드", data['returnCode'].toString()),
            buildInfoRow("제품 코드", data['rProductCode']),
            buildInfoRow("반품 사유", data['returnReason']),
            buildInfoRow("반품 날짜", data['returnDate']),
            buildInfoRow("분류", data['returnCategory']),
            buildInfoRow("처리 상태", data['prosessionStateus']),
            const SizedBox(height: 20),
            const Text("처리 상태 변경", style: labelStyle),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedStatus,
              dropdownColor: Colors.grey[900],
              style: const TextStyle(color: Colors.white),
              items: statusOptions.map((status) => DropdownMenuItem(value: status, child: Text(status))).toList(),
              onChanged: (val) => setState(() => selectedStatus = val),
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.grey,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text("처리 내용", style: labelStyle),
            const SizedBox(height: 10),
            TextField(
              controller: resolutionController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "처리 상황을 입력하세요",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: saveResolution,
                    child: const Text("저장"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                    child: const Text("취소"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label, style: const TextStyle(color: Colors.white70))),
          Expanded(flex: 6, child: Text(value, style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}
