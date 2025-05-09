//반품  딕테일 
import 'package:black_market_app/vm/database_handler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CompanyReturnDetail extends StatefulWidget {
  const CompanyReturnDetail({super.key});

  @override
  State<CompanyReturnDetail> createState() => _CompanyReturnDetailState();
}

class _CompanyReturnDetailState extends State<CompanyReturnDetail> {
  late DatabaseHandler handler;
  late Map<String, dynamic> returnData;
  late String selectedStatus;
  final TextEditingController resolutionController = TextEditingController();

  final List<String> statusOptions = ['처리중', '완료', '반려'];

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    returnData = Get.arguments;
    selectedStatus = returnData['processionStateus'] ?? '처리중';
  }

  Future<void> updateStatus() async {
    try {
      await handler.updateReturnStatus(
        returnCode: returnData['returnCode'],
        newStatus: selectedStatus,
      );
      await handler.insertReturnInvestigation(
        raUserid: returnData['ruserId'],
        raJobGradeCode: '', // null 대체
        rreturnCode: returnData['returnCode'],
        rmanufacturerName: '', // null 대체
        recordDate: DateTime.now().toIso8601String(),
        resolutionDetails: resolutionController.text,
      );
      Get.snackbar('성공', '상태와 처리내용이 업데이트되었습니다.', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('오류', '업데이트 실패: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle labelStyle = const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold);
    final TextStyle valueStyle = const TextStyle(color: Colors.white);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('반품 상세', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('고객 ID : ${returnData['ruserId']}', style: labelStyle),
                    const SizedBox(height: 10),
                    Text('제품 코드 : ${returnData['rProductCode']}', style: labelStyle),
                    const SizedBox(height: 10),
                    Text('반품 사유 : ${returnData['returnReason']}', style: labelStyle),
                    const SizedBox(height: 10),
                    Text('카테고리 : ${returnData['returnCategory']}', style: labelStyle),
                    const SizedBox(height: 10),
                    Text('반품 날짜 : ${returnData['returnDate']}', style: labelStyle),
                    const SizedBox(height: 10),
                    const Text('처리 상태 변경', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      dropdownColor: Colors.grey[900],
                      value: selectedStatus,
                      onChanged: (val) {
                        if (val != null) setState(() => selectedStatus = val);
                      },
                      items: statusOptions.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status, style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Text('처리 상황 입력', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                    TextField(
                      controller: resolutionController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: '예: 환불 완료, 교환 발송 등',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: updateStatus,
              child: const Text('수정하기'),
            )
          ],
        ),
      ),
    );
  }
}