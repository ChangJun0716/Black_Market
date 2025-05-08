import 'package:black_market_app/vm/database_handler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:black_market_app/model/purchase_detail.dart'; // 모델 임포트

class CustomerPurchaseDetail extends StatefulWidget {
  const CustomerPurchaseDetail({super.key});

  @override
  State<CustomerPurchaseDetail> createState() => _CustomerPurchaseDetailState();
}

class _CustomerPurchaseDetailState extends State<CustomerPurchaseDetail> {
  late DatabaseHandler handler;
  late int purchaseId;

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    purchaseId = Get.arguments ?? -1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('결제 내역 상세 정보')),
      body: FutureBuilder<PurchaseDetail?>(
        future: handler.queryPurchaseDetail(purchaseId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('오류 발생: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('상세 정보를 찾을 수 없습니다.'));
          }

          final data = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data.productImage.isNotEmpty)
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(data.productImage, height: 200),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      data.productName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('색상: ${data.productColor}'),
                    Text('사이즈: ${data.productSize}'),
                    Text('수량: ${data.purchaseQuantity}개'),
                    Text('단가: ${data.purchasePrice ~/ data.purchaseQuantity}원'),
                    Text(
                      '총 결제금액: ${data.purchasePrice}원',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 24),
                    Text(
                      '배송 상태: ${data.purchaseDeliveryStatus}',
                      style: TextStyle(color: Colors.blueAccent),
                    ),
                    Text('수령 지점: ${data.storeName}'),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
