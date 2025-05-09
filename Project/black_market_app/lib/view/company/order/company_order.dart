//발주하기 
import 'package:black_market_app/model/create_approval_document.dart';
import 'package:black_market_app/model/order.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:black_market_app/vm/database_handler.dart';

class CompanyOrder extends StatefulWidget {
  final List<Map<String, dynamic>> selectedProducts;

  const CompanyOrder({required this.selectedProducts});

  @override
  State<CompanyOrder> createState() => _CompanyOrderState();
}

class _CompanyOrderState extends State<CompanyOrder> {
  late DatabaseHandler handler;
  late String userId;
  String userGrade = '';
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final List<TextEditingController> quantityControllers = [];
  final List<String> manufacturerList = [];
  final List<String?> selectedManufacturers = [];
  final List<String> approverGrades = [];
  String? selectedApproverGrade;
  int totalExpense = 0;
  final Map<String, int> productOPriceMap = {};

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    final box = GetStorage();
    userId = box.read('uid') ?? '';
    loadUserGrade();
    loadManufacturers();
    loadApproverGrades();
    quantityControllers.addAll(widget.selectedProducts.map((_) => TextEditingController()));
    selectedManufacturers.addAll(widget.selectedProducts.map((p) => p['manufacturerName']));
    loadProductOPrices();
  }

  Future<void> loadUserGrade() async {
    try {
      final result = await handler.getJobGradeByUserId(userId);
      setState(() {
        userGrade = result;
      });
    } catch (e) {
      debugPrint('직급 로딩 실패: $e');
    }
  }

  Future<void> loadManufacturers() async {
    try {
      final list = await handler.getManufacturers();
      setState(() {
        manufacturerList.addAll(list);
      });
    } catch (e) {
      debugPrint('제조사 로딩 실패: $e');
    }
  }

  Future<void> loadApproverGrades() async {
    try {
      final grades = await handler.getAllGrades();
      setState(() {
        approverGrades.clear();
        approverGrades.addAll(grades.map((g) => g.gradeName));
      });
    } catch (e) {
      debugPrint('결재 라인 로딩 실패: $e');
    }
  }

  Future<void> loadProductOPrices() async {
    for (final product in widget.selectedProducts) {
      final code = product['productsCode'];
      final price = await handler.getProductOPriceByCode(code);
      productOPriceMap[code.toString()] = price;
    }
    calculateTotalExpense();
  }

  void calculateTotalExpense() {
    int sum = 0;
    for (int i = 0; i < widget.selectedProducts.length; i++) {
      final product = widget.selectedProducts[i];
      final qty = int.tryParse(quantityControllers[i].text) ?? 0;
      final price = productOPriceMap[product['productsCode'].toString()] ?? 0;
      sum += qty * price;
    }
    setState(() => totalExpense = sum);
  }

  Future<void> submitOrder() async {
    if (selectedApproverGrade == null || titleController.text.isEmpty || contentController.text.isEmpty) {
      Get.snackbar('알림', '제목, 내용, 결재선을 모두 입력해주세요.', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    try {
      final userInfo = await handler.getUserInfoById(userId);
      final now = DateTime.now();
      final orderGroupId = await handler.getNextOrderId();

      final approverGradeCode = await handler.getGradeCodeByName(selectedApproverGrade!);
      if (approverGradeCode == null) {
        throw Exception('선택한 결재선의 ID(gradeCode)를 찾을 수 없습니다.');
      }

      final approvalDoc = CreateApprovalDocument(
        cUserid: userId.toString(),
        cajobGradeCode: userGrade.toString(),
        checkGradeCode: approverGradeCode,
        name: userInfo['name'].toString(),
        title: titleController.text,
        content: contentController.text,
        date: now,
        approvalStatus: '승인신청',
        approvalRequestExpense: totalExpense,
        corderID: orderGroupId,
      );

      await handler.insertCreateApprovalDocument(approvalDoc);

      for (int i = 0; i < widget.selectedProducts.length; i++) {
        final product = widget.selectedProducts[i];
        final quantity = int.tryParse(quantityControllers[i].text) ?? 0;
        final price = productOPriceMap[product['productsCode']] ?? 0;

        final order = Orders(
          orderID: orderGroupId,
          orderQuantity: quantity.toString(),
          orderDate: null,
          orderStatus: '발주승인신청',
          orderPrice: quantity * price,
          oajobGradCode: userGrade.toString(),
          oaUserid: userId.toString(),
          oproductCode: product['productsCode'].toString(),
          omamufacturer: selectedManufacturers[i]?.toString() ?? '',
        );

        await handler.insertOrder(order);
      }

      // ✅ ApprovalStep 자동 생성 추가
      await handler.insertApprovalSteps(
        documentId: orderGroupId,
        requesterGrade: int.parse(userGrade),
        finalGrade: int.parse(approverGradeCode),
      );

      Get.snackbar('성공', '발주 신청이 완료되었습니다.', backgroundColor: Colors.green, colorText: Colors.white);
      Navigator.pop(context);
    } catch (e, stack) {
      debugPrint('🛑 발주 신청 실패: $e');
      debugPrint('📍 STACK TRACE: $stack');
      Get.snackbar('오류', '발주 신청 중 오류 발생', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('발주서 작성'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('선택된 직급: $userGrade', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: '제목',
                labelStyle: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: contentController,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '내용',
                labelStyle: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedApproverGrade,
              items: approverGrades.map((grade) => DropdownMenuItem(
                value: grade,
                child: Text(grade, style: const TextStyle(color: Colors.black)),
              )).toList(),
              onChanged: (val) => setState(() => selectedApproverGrade = val),
              dropdownColor: Colors.white,
              decoration: const InputDecoration(
                labelText: '결재선 직급 선택',
                labelStyle: TextStyle(color: Colors.white),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text('선택된 발주 제품 목록', style: TextStyle(color: Colors.white)),
            const Divider(color: Colors.white24),
            Expanded(
              child: ListView.builder(
                itemCount: widget.selectedProducts.length,
                itemBuilder: (context, index) {
                  final product = widget.selectedProducts[index];
                  return ListTile(
                    title: Text('${product['productsName']} (ID: ${product['productsCode']})', style: const TextStyle(color: Colors.white)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('재고: ${product['currentStock']}', style: const TextStyle(color: Colors.white70)),
                        Row(
                          children: [
                            const Text('수량:', style: TextStyle(color: Colors.white)),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: quantityControllers[index],
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: '0',
                                  hintStyle: TextStyle(color: Colors.white38),
                                  filled: true,
                                  fillColor: Colors.black26,
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (_) => calculateTotalExpense(),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: manufacturerList.contains(selectedManufacturers[index]) ? selectedManufacturers[index] : null,
                                items: manufacturerList.map((name) => DropdownMenuItem(
                                  value: name,
                                  child: Text(name, style: const TextStyle(color: Colors.black)),
                                )).toList(),
                                onChanged: (value) => setState(() => selectedManufacturers[index] = value),
                                decoration: const InputDecoration(
                                  labelText: '제조사 선택',
                                  labelStyle: TextStyle(color: Colors.white),
                                  filled: true,
                                  fillColor: Colors.white10,
                                  border: OutlineInputBorder(),
                                ),
                                dropdownColor: Colors.white,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('총 품의비: $totalExpense 원', style: const TextStyle(color: Colors.white)),
                const Spacer(),
                ElevatedButton(
                  onPressed: submitOrder,
                  child: const Text('발주 신청하기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
