//결재서 작성
import 'package:black_market_app/model/create_approval_document.dart';
import 'package:black_market_app/vm/database_handler.dart';
import 'package:flutter/material.dart';

class CompanyOrder extends StatefulWidget {
  final List<Map<String, dynamic>> selectedProducts;
  final String userId;
  final String userName;
  final String jobGradeCode;

  const CompanyOrder({
    super.key,
    required this.selectedProducts,
    required this.userId,
    required this.userName,
    required this.jobGradeCode,
  });

  @override
  State<CompanyOrder> createState() => _CompanyOrderState();
}

class _CompanyOrderState extends State<CompanyOrder> {
  late DatabaseHandler handler;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final List<TextEditingController> quantityControllers = [];
  final List<String> approverGrades = ['대리', '과장', '부장', '이사'];
  String? selectedApproverGrade;
  int totalExpense = 0;

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    quantityControllers.addAll(widget.selectedProducts.map((_) => TextEditingController()));
  }

  @override
  void dispose() {
    for (var controller in quantityControllers) {
      controller.dispose();
    }
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  void calculateTotalExpense() {
    int sum = 0;
    for (int i = 0; i < widget.selectedProducts.length; i++) {
      final price = int.tryParse(widget.selectedProducts[i]['productsPrice'].toString()) ?? 0;
      final qty = int.tryParse(quantityControllers[i].text) ?? 0;
      sum += price * qty;
    }
    setState(() => totalExpense = sum);
  }

  Future<void> submitApproval() async {
    final now = DateTime.now();
    final approval = CreateApprovalDocument(
      cUserid: widget.userId,
      cajobGradeCode: widget.jobGradeCode,
      name: widget.userName,
      title: titleController.text,
      content: contentController.text,
      date: now,
      rejectedReason: '',
      approvalStatus: '신청됨',
      approvalRequestExpense: totalExpense,
    );

    await handler.insertCreateApprovalDocument(approval);

    // 추가: 발주 테이블에 각 제품 insert
    for (int i = 0; i < widget.selectedProducts.length; i++) {
      final product = widget.selectedProducts[i];
      final qty = int.tryParse(quantityControllers[i].text) ?? 0;
      final price = int.tryParse(product['productsPrice'].toString()) ?? 0;

      if (qty > 0) {
        await handler.insertOrder(
          quantity: qty,
          date: now.toIso8601String(),
          status: '신청됨',
          price: price,
          jobGradeCode: widget.jobGradeCode,
          userId: widget.userId,
          productCode: product['productsCode'],
          manufacturer: product['manufacturerName'] ?? '',
        );
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('결재서가 작성되었습니다.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('결재서 작성')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: '제목', labelStyle: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: contentController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: const InputDecoration(labelText: '내용', labelStyle: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedApproverGrade,
              dropdownColor: Colors.black,
              style: const TextStyle(color: Colors.white),
              items: approverGrades.map((grade) => DropdownMenuItem(value: grade, child: Text(grade))).toList(),
              onChanged: (val) => setState(() => selectedApproverGrade = val),
              decoration: const InputDecoration(labelText: '결재선 직급 선택', labelStyle: TextStyle(color: Colors.white)),
            ),
            const Divider(height: 32, color: Colors.white),
            const Text('발주 제품 및 수량 입력', style: TextStyle(color: Colors.white)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.selectedProducts.length,
              itemBuilder: (context, index) {
                final product = widget.selectedProducts[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(product['productsName'] ?? '', style: const TextStyle(color: Colors.white))),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: quantityControllers[index],
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: '수량', labelStyle: TextStyle(color: Colors.white)),
                          onChanged: (_) => calculateTotalExpense(),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text('총 품의비: $totalExpense 원', style: const TextStyle(color: Colors.white)),
                const Spacer(),
                ElevatedButton(
                  onPressed: calculateTotalExpense,
                  child: const Text('입력하기'),
                )
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: submitApproval,
                  child: const Text('결재서 작성 완료'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소', style: TextStyle(color: Colors.white)),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
