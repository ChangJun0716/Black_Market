// store_return_list.dart
import 'package:flutter/material.dart';
import 'package:black_market_app/vm/database_handler.dart'; // DatabaseHandler 임포트
// import 'package:black_market_app/model/purchase.dart'; // 모델은 직접 사용되지 않습니다.
import 'package:black_market_app/utility/custom_button_calender.dart'; // CustomButtonCalender 사용
import 'store_return_application.dart'; // 반품 신청 페이지 임포트
import 'package:get/get.dart'; // GetX 임포트

class StoreReturnList extends StatefulWidget {
  const StoreReturnList({super.key});

  @override
  _StoreReturnListState createState() => _StoreReturnListState();
}

class _StoreReturnListState extends State<StoreReturnList> {
  DateTime? selectedDate; // 선택한 날짜
  List<Map<String, dynamic>> returnList = []; // 반품 목록 (Map 형태)

  @override
  void initState() {
    super.initState();
    // 페이지 로드 시 초기 반품 목록 가져오기 (오늘 날짜 기준)
    // fetchReturns(DateTime.now()); // 초기 로딩 필요시 주석 해제
  }

  // 선택한 날짜에 맞는 반품 기록을 가져오는 메서드
  void fetchReturns(DateTime date) async {
    try {
      // DatabaseHandler를 통해 데이터 가져오기 (Map 형태로 반환됨)
      // DatabaseHandler의 쿼리가 'returnCode'(int), 'ruserId', 'rProductCode', 'processionStatus' 등 컬럼 이름 케이스를 사용함을 반영합니다.
      final fetchedReturns = await DatabaseHandler().getReturnsByDate(date);
      setState(() {
        returnList = fetchedReturns; // 가져온 Map 리스트로 상태 업데이트
      });
    } catch (e) {
      // 에러 처리 로직 추가 (예: 에러 메시지 표시)
      print('반품 기록을 가져오는 중 오류 발생: $e');
      setState(() {
        returnList = []; // 오류 발생 시 목록 초기화
      });
      // TODO: 사용자에게 오류 발생 알림 (예: SnackBar) 또는 Dialog
      Get.snackbar(
        '오류',
        '반품 목록을 가져오는데 실패했습니다.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('매장 반품 목록')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // 자식들을 가로로 늘이기
          children: [
            // 날짜 선택 버튼
            CustomButtonCalender(
              // CustomButtonCalender 사용
              label:
                  selectedDate == null
                      ? '날짜 선택'
                      : '${selectedDate!.toLocal()}'.split(' ')[0], // 선택된 날짜 표시
              onDateSelected: (DateTime date) {
                // CustomButtonCalender에서 날짜 선택 시 호출
                setState(() {
                  selectedDate = date; // 선택한 날짜 상태 업데이트
                });
                // 날짜 선택 후 해당 날짜의 반품 기록 가져오기
                fetchReturns(date);
              },
            ),
            SizedBox(height: 16),
            // 반품 목록 표시 영역
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
                          // 반품 코드를 주문 번호 대신 표시합니다.
                          Expanded(
                            flex: 2,
                            child: Text(
                              '주문 번호 (반품 코드)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ), // 글씨 크기 조정
                          Expanded(
                            flex: 2,
                            child: Text(
                              '회원 ID',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ), // 글씨 크기 조정
                          Expanded(
                            flex: 2,
                            child: Text(
                              '제품 번호',
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
                        ],
                      ),
                    ),
                    Divider(height: 1, thickness: 1), // 헤더와 목록 구분선, 높이 조정
                    // 반품 목록 표시
                    Expanded(
                      // Column 내에서 ListView가 남은 공간을 차지하도록 Expanded 사용
                      child: ListView.builder(
                        itemCount: returnList.length,
                        itemBuilder: (context, index) {
                          final returnData =
                              returnList[index]; // Map 형태의 데이터 항목
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
                                    returnData['returnCode']?.toString() ?? '',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ), // returnCode는 int
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    returnData['ruserId'] ?? '',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ), // ruserId 케이스 반영
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    returnData['rProductCode'] ?? '',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ), // rProductCode 케이스 반영
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    returnData['productsColor'] ?? '',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ), // productsColor 케이스 반영
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    returnData['productsSize']?.toString() ??
                                        '',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ), // productsSize 케이스 반영
                                // 만약 반품 날짜나 처리 상태도 표시하고 싶다면 컬럼 추가 및 Map 키 사용
                                // Expanded(flex: 2, child: Text(returnData['returnDate'] ?? '', style: TextStyle(fontSize: 12))),
                                // Expanded(flex: 2, child: Text(returnData['processionStatus'] ?? '', style: TextStyle(fontSize: 12))), // processionStatus 케이스 반영
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    if (returnList.isEmpty &&
                        selectedDate != null) // 날짜 선택 후 데이터가 없을 때 메시지 표시
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            '선택하신 날짜 (${selectedDate!.toLocal().toString().split(' ')[0]})에 해당하는 반품 기록이 없습니다.',
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
                            '날짜를 선택하여 반품 기록을 확인하세요.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            // 반품 신청 페이지로 이동하는 버튼
            Align(
              // 오른쪽 아래 정렬
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                // 표준 ElevatedButton 사용 (CustomButton 아님)
                onPressed: () {
                  // 널이 아닌 함수 전달
                  // 반품 신청 페이지로 이동 (Get.to 사용)
                  // TODO: StoreReturnApplication 페이지에서 반품 신청 성공 후 StoreReturnList로 돌아왔을 때
                  // 목록을 새로고침해야 한다면 `await Get.to(...)` 후 `fetchReturns(selectedDate!)` 호출 필요
                  Get.to(() => StoreReturnApplication());
                },
                child: Text('반품 신청'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
