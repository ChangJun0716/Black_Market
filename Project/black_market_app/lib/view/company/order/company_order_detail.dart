// 상신 상세보기
import 'package:black_market_app/vm/database_handler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class CompanyOrderDetail extends StatefulWidget {
  final Map<String, dynamic> approvalData;

  const CompanyOrderDetail({super.key, required this.approvalData});

  @override
  State<CompanyOrderDetail> createState() => _CompanyOrderDetailState();
}

class _CompanyOrderDetailState extends State<CompanyOrderDetail> {
  late DatabaseHandler handler;
  final TextEditingController rejectReasonController = TextEditingController();
  List<Map<String, dynamic>> approvalSteps = [];
  String currentUserId = '';
  String approvalStatus = '';

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    final box = GetStorage();
    currentUserId = box.read('uid') ?? '';
    approvalStatus = widget.approvalData['approvalStatus'] ?? '';
    loadApprovalSteps();
  }

  Future<void> loadApprovalSteps() async {
    try {
      final steps = await handler.getApprovalStepsByDocumentId(widget.approvalData['corderID']);
      if (mounted) {
        setState(() => approvalSteps = steps);
      }
    } catch (e) {
      debugPrint('🔴 결재 단계 로딩 실패: $e');
    }
  }

  bool isCurrentApprover() {
    if (approvalSteps.isEmpty) return false;
    final step = approvalSteps.firstWhere(
      (step) => step['status'] == '대기',
      orElse: () => {},
    );
    return step['approverId'] == currentUserId;
  }

  @override
  void dispose() {
    rejectReasonController.dispose();
    super.dispose();
  }

  Widget buildApprovalProgress() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: approvalSteps.map((step) {
          final isApproved = step['status'] == '승인';
          final isRejected = step['status'] == '반려';
          final statusColor = isApproved
              ? Colors.green
              : isRejected
                  ? Colors.red
                  : Colors.grey;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  step['approverId'],
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  step['status'],
                  style: const TextStyle(color: Colors.white70),
                ),
                if (step['comment'] != null && step['comment'].toString().isNotEmpty)
                  Text(
                    step['comment'],
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  )
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> handleApprove() async {
    try {
      if (!isCurrentApprover()) {
        Get.snackbar('권한 없음', '해당 결재 단계의 담당자가 아닙니다.', backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      await handler.approveStep(
        documentId: widget.approvalData['corderID'],
        approverId: currentUserId,
      );

      final updatedSteps = await handler.getApprovalStepsByDocumentId(widget.approvalData['corderID']);
      final hasNextStep = updatedSteps.any((step) => step['status'] == '대기');
      if (!hasNextStep) {
        await handler.finalizeApproval(documentId: widget.approvalData['corderID']);
        if (mounted) setState(() => approvalStatus = '승인');
      } else {
        await handler.updateApprovalDocumentStatus(
          documentId: widget.approvalData['corderID'],
          newStatus: '승인진행중',
        );
        if (mounted) setState(() => approvalStatus = '승인진행중');
      }

      await loadApprovalSteps();
      if (mounted) {
        Get.snackbar('성공', '승인 처리되었습니다.', backgroundColor: Colors.green, colorText: Colors.white);
      }
    } catch (e, stack) {
      debugPrint('🔥 승인 중 오류: $e');
      debugPrint('📌 스택트레이스: $stack');
      if (mounted) {
        Get.snackbar('오류', '승인 처리 중 문제가 발생했습니다.', backgroundColor: Colors.red, colorText: Colors.white);
      }
    }
  }

  Future<void> handleReject() async {
    if (!isCurrentApprover()) {
      Get.snackbar('권한 없음', '해당 결재 단계의 담당자가 아닙니다.', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("반려 사유 입력", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: rejectReasonController,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '예: 예산 초과, 내용 보완 필요 등',
            hintStyle: TextStyle(color: Colors.white54),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await handler.rejectStep(
                  documentId: widget.approvalData['corderID'],
                  approverId: currentUserId,
                  comment: rejectReasonController.text,
                );
                if (mounted) setState(() => approvalStatus = '반려');
                Navigator.of(context).pop();
                Get.snackbar('반려됨', '결재가 반려되었습니다.', backgroundColor: Colors.red, colorText: Colors.white);
              } catch (e, stack) {
                debugPrint('🔥 반려 처리 오류: $e');
                debugPrint('📌 스택: $stack');
                Navigator.of(context).pop();
                Get.snackbar('오류', '반려 처리 중 문제가 발생했습니다.', backgroundColor: Colors.red, colorText: Colors.white);
              }
            },
            child: const Text("반려", style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("취소", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle labelStyle = const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold);
    final TextStyle valueStyle = const TextStyle(color: Colors.white);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('결재서 상세',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        ),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 400,top: 100),
        child: Container(
          
          child: SizedBox(
            
            width: 400,
            height: 500,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 100),
                  child: buildApprovalProgress(),
                ),
                const SizedBox(height: 20),
            
                Text('제목', style: labelStyle),
                Text(widget.approvalData['title'] ?? '', style: valueStyle,),
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
                Text(approvalStatus, style: valueStyle),
                const SizedBox(height: 12),
            
                Text('작성일자', style: labelStyle),
                Text(widget.approvalData['date'] ?? '', style: valueStyle),
                const SizedBox(height: 30),
            
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: handleApprove,
                      child: const Text("승인"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: handleReject,
                      child: const Text("반려"),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}