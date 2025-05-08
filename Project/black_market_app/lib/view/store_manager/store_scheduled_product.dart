// store_scheduled_product.dart
import 'package:flutter/material.dart';
import 'package:black_market_app/vm/database_handler.dart'; // DatabaseHandler 임포트
// import 'package:black_market_app/model/purchase.dart'; // Purchase 모델은 여기서 직접 사용되지 않습니다.
import 'package:black_market_app/utility/custom_button_calender.dart'; // CustomButtonCalender 사용
import 'package:get/get.dart'; // GetX 임포트 (Snackbar 등을 위해 필요할 수 있습니다)

class StoreScheduledProduct extends StatefulWidget {
  const StoreScheduledProduct({super.key});

  @override
  _StoreScheduledProductState createState() => _StoreScheduledProductState();
}

class _StoreScheduledProductState extends State<StoreScheduledProduct> {
  DateTime? selectedDate; // 선택한 날짜
  List<Map<String, dynamic>> scheduledProducts = []; // 입고 예정 제품 목록 (Map 형태)

  // 로그인한 대리점 코드 (예시, 실제 앱에서는 로그인 정보나 다른 방식으로 가져와야 합니다.)
  // TODO: 실제 로그인된 대리점의 storeCode를 가져오는 로직 구현 필요
  String loggedInStoreCode =
      'YOUR_LOGGED_IN_STORE_CODE'; // <<< 중요: 여기를 실제 대리점 코드로 바꿔주세요!

  @override
  void initState() {
    super.initState();
    // 페이지 로드 시 초기 입고 예정 제품 목록 가져오기 (오늘 날짜 기준)
    // fetchScheduledProducts(DateTime.now(), loggedInStoreCode); // 초기 로딩 필요시 주석 해제
  }

  // 선택한 날짜와 대리점 코드에 맞는 입고 예정 제품 정보를 가져오는 메서드
  void fetchScheduledProducts(DateTime date, String storeCode) async {
    // TODO: 실제 로그인된 대리점 코드를 사용하도록 수정해야 합니다.

    try {
      // DatabaseHandler를 통해 데이터 가져오기 (Map 형태로 반환됨)
      // DatabaseHandler의 쿼리가 'oproductCode' 등 컬럼 이름 케이스를 사용함을 반영합니다.
      final fetchedProducts = await DatabaseHandler()
          .getScheduledProductsByDateAndStore(date, storeCode);
      setState(() {
        scheduledProducts = fetchedProducts; // 가져온 Map 리스트로 상태 업데이트
      });
    } catch (e) {
      // 에러 처리 로직 추가 (예: 에러 메시지 표시)
      print('입고 예정 제품 정보를 가져오는 중 오류 발생: $e');
      setState(() {
        scheduledProducts = []; // 오류 발생 시 목록 초기화
      });
      // TODO: 사용자에게 오류 발생 알림 (예: SnackBar)
      Get.snackbar(
        '오류',
        '입고 예정 제품 목록을 가져오는데 실패했습니다.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('입고 예정 제품')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // 자식들을 가로로 늘이기
          children: [
            // 날짜 선택 버튼
            CustomButtonCalender(
              label:
                  selectedDate == null
                      ? '날짜 선택'
                      : '${selectedDate!.toLocal()}'.split(' ')[0], // 선택된 날짜 표시
              onDateSelected: (DateTime date) {
                // CustomButtonCalender에서 날짜 선택 시 호출
                setState(() {
                  selectedDate = date; // 선택한 날짜 상태 업데이트
                });
                // 날짜 선택 후 해당 날짜의 입고 예정 제품 정보 가져오기
                fetchScheduledProducts(date, loggedInStoreCode);
              },
            ),
            SizedBox(height: 16),
            // 입고 예정 제품 목록 표시 영역
            Expanded(
              // Column 내에서 남은 공간을 차지하도록 Expanded 사용
              child: Container(
                padding: EdgeInsets.all(8.0), // Container 내부 패딩 조정
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // 헤더와 목록 정렬
                  children: [
                    // 데이터 목록의 헤더 (컬럼 이름)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4.0,
                        horizontal: 8.0,
                      ), // 헤더 패딩 조정
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              '주문 번호',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ), // 글씨 크기 조정
                          Expanded(
                            flex: 2,
                            child: Text(
                              '물건 ID',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ), // 글씨 크기 조정
                          Expanded(
                            flex: 1,
                            child: Text(
                              '색상',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ), // 글씨 크기 조정
                          Expanded(
                            flex: 1,
                            child: Text(
                              '사이즈',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ), // 글씨 크기 조정
                          Expanded(
                            flex: 1,
                            child: Text(
                              '수량',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ), // 글씨 크기 조정
                          Expanded(
                            flex: 2,
                            child: Text(
                              '배송 상태',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ), // 글씨 크기 조정
                          // 필요한 경우 고객 이름, 대리점 이름 등을 추가
                          // Expanded(flex: 2, child: Text(productData['customerName'] ?? '', style: TextStyle(fontSize: 12))),
                        ],
                      ),
                    ),
                    Divider(height: 1, thickness: 1), // 헤더와 목록 구분선, 높이 조정
                    // 입고 예정 제품 목록 표시
                    Expanded(
                      // Column 내에서 ListView가 남은 공간을 차지하도록 Expanded 사용
                      child: ListView.builder(
                        itemCount: scheduledProducts.length,
                        itemBuilder: (context, index) {
                          final productData =
                              scheduledProducts[index]; // Map 형태의 데이터 항목
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4.0,
                              horizontal: 8.0,
                            ), // 목록 항목 패딩 조정
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Map 키 이름은 DatabaseHandler 쿼리의 SELECT 절 이름과 일치해야 합니다.
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    productData['purchaseId']?.toString() ?? '',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ), // purchaseId는 int
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    productData['oproductCode'] ?? '',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ), // oproductCode 케이스 반영
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    productData['productsColor'] ?? '',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ), // productsColor 케이스 반영
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    productData['productsSize']?.toString() ??
                                        '',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ), // productsSize 케이스 반영
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    productData['purchaseQuanity']
                                            ?.toString() ??
                                        '',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ), // purchaseQuanity 케이스 반영
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    productData['purchaseDeliveryStatus'] ?? '',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ), // purchaseDeliveryStatus 케이스 반영
                                // 필요한 경우 고객 이름, 대리점 이름 등을 추가 (SELECT 절에 포함된 경우)
                                // Expanded(flex: 2, child: Text(productData['customerName'] ?? '', style: TextStyle(fontSize: 12))),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    if (scheduledProducts.isEmpty &&
                        selectedDate != null) // 날짜 선택 후 데이터가 없을 때 메시지 표시
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            '선택하신 날짜 (${selectedDate!.toLocal().toString().split(' ')[0]})에는 입고 예정 제품이 없습니다.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      ),
                    if (selectedDate == null) // 날짜를 선택하지 않았을 때 초기 메시지
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            '날짜를 선택하여 입고 예정 제품을 확인하세요.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
