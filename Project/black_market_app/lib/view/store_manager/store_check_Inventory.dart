// store_check_inventory.dart
import 'package:flutter/material.dart';
import 'package:black_market_app/vm/database_handler.dart'; // DatabaseHandler 임포트
import 'package:black_market_app/utility/custom_button_calender.dart'; // CustomButtonCalender 사용
import 'package:get/get.dart'; // GetX 임포트 (Snackbar 등을 위해 필요할 수 있습니다)

class StoreCheckInventory extends StatefulWidget {
  const StoreCheckInventory({super.key});

  @override
  _StoreCheckInventoryState createState() => _StoreCheckInventoryState();
}

class _StoreCheckInventoryState extends State<StoreCheckInventory> {
  DateTime? startDate; // 시작 날짜
  DateTime? endDate; // 종료 날짜
  List<Map<String, dynamic>> receivedInventoryList = []; // 입고된 재고 목록 (Map 형태)
  int totalReceivedQuantity = 0; // 총 입고 수량 합계

  // 로그인한 대리점 관리자 ID (예시, 실제 앱에서는 로그인 정보나 다른 방식으로 가져와야 합니다.)
  // TODO: 실제 로그인된 사용자 (대리점 관리자)의 userId를 가져오는 로직 구현 필요
  String loggedInUserId =
      'YOUR_LOGGED_IN_USER_ID'; // <<< 중요: 여기를 실제 사용자 ID로 바꿔주세요!

  @override
  void initState() {
    super.initState();
    // 페이지 로드 시 초기 데이터 로딩 필요시 주석 해제
    // 현재 날짜 기준 1주일 범위 등으로 설정하여 로딩할 수 있습니다.
    // DateTime now = DateTime.now();
    // startDate = now.subtract(Duration(days: 7));
    // endDate = now;
    // fetchReceivedInventory(startDate!, endDate!, loggedInUserId);
  }

  // 선택한 날짜 범위와 사용자 ID에 맞는 재고 수령 정보를 가져오는 메서드
  void fetchReceivedInventory(
    DateTime start,
    DateTime end,
    String userId,
  ) async {
    // TODO: 실제 로그인된 사용자 ID를 사용하도록 수정해야 합니다.

    // 종료일의 시간을 하루의 끝으로 설정 (해당 날짜 전체 범위 포함)
    DateTime adjustedEndDate = DateTime(
      end.year,
      end.month,
      end.day,
      23,
      59,
      59,
    );

    try {
      // DatabaseHandler를 통해 데이터 가져오기 (Map 형태로 반환됨)
      // DatabaseHandler의 쿼리가 'sproductCode' 등 컬럼 이름 케이스를 사용함을 반영합니다.
      final fetchedInventory = await DatabaseHandler()
          .getReceivedInventoryByDateRangeAndUser(
            start,
            adjustedEndDate,
            userId,
          );
      int calculatedTotal = 0;

      // 가져온 목록을 순회하며 총 수량 계산
      for (var item in fetchedInventory) {
        // 'receivedQuantity' 필드가 Map에 있고 null이 아니며 정수형으로 변환 가능하면 더함
        // SQL에서 SUM은 기본적으로 INTEGER 또는 REAL을 반환하므로 int로 캐스팅합니다.
        if (item.containsKey('receivedQuantity') &&
            item['receivedQuantity'] != null) {
          calculatedTotal +=
              (item['receivedQuantity'] as int); // Map에서 가져온 수량 더하기
        }
      }

      setState(() {
        receivedInventoryList = fetchedInventory; // 가져온 Map 리스트로 상태 업데이트
        totalReceivedQuantity = calculatedTotal; // 총 입고 수량 업데이트
      });
    } catch (e) {
      // 에러 처리 로직 추가 (예: 에러 메시지 표시)
      print('재고 입고 정보를 가져오는 중 오류 발생: $e');
      setState(() {
        receivedInventoryList = []; // 오류 발생 시 목록 초기화
        totalReceivedQuantity = 0; // 총 입고 수량도 초기화
      });
      // TODO: 사용자에게 오류 발생 알림 (예: SnackBar) 또는 Dialog
      Get.snackbar(
        '오류',
        '재고 입고 정보를 가져오는데 실패했습니다.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('매장 재고 확인')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // 자식들을 가로로 늘이기
          children: [
            // 날짜 선택 버튼 (시작일, 종료일)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  // 버튼이 가로 공간을 차지하도록 Expanded 사용
                  child: CustomButtonCalender(
                    // CustomButtonCalender 사용
                    label:
                        startDate == null
                            ? '시작일 선택'
                            : '${startDate!.toLocal()}'.split(
                              ' ',
                            )[0], // 선택된 날짜 표시
                    onDateSelected: (DateTime date) {
                      // CustomButtonCalender에서 날짜 선택 시 호출
                      setState(() {
                        startDate = date; // 시작 날짜 상태 업데이트
                        // 시작일 선택 후 종료일이 시작일 이전이라면 종료일도 시작일로 업데이트 (선택 사항)
                        if (endDate != null && endDate!.isBefore(startDate!)) {
                          endDate = startDate;
                        }
                      });
                      // 시작일과 종료일 모두 선택되었으면 데이터 가져오기
                      if (startDate != null && endDate != null) {
                        fetchReceivedInventory(
                          startDate!,
                          endDate!,
                          loggedInUserId,
                        );
                      }
                    },
                  ),
                ),
                SizedBox(width: 10), // 버튼 사이 간격
                Expanded(
                  // 버튼이 가로 공간을 차지하도록 Expanded 사용
                  child: CustomButtonCalender(
                    // CustomButtonCalender 사용
                    label:
                        endDate == null
                            ? '종료일 선택'
                            : '${endDate!.toLocal()}'.split(
                              ' ',
                            )[0], // 선택된 날짜 표시
                    onDateSelected: (DateTime date) {
                      // CustomButtonCalender에서 날짜 선택 시 호출
                      // 선택된 종료일이 시작일보다 이전이면 경고 또는 조정 (필수)
                      if (startDate != null && date.isBefore(startDate!)) {
                        // 사용자에게 알림 또는 종료일을 시작일과 같게 설정
                        print('종료일이 시작일보다 이전입니다. 종료일을 시작일과 같게 설정합니다.');
                        date = startDate!; // 종료일을 시작일로 강제 조정
                      }

                      setState(() {
                        endDate = date; // 종료 날짜 상태 업데이트
                      });
                      // 시작일과 종료일 모두 선택되었으면 데이터 가져오기
                      if (startDate != null && endDate != null) {
                        fetchReceivedInventory(
                          startDate!,
                          endDate!,
                          loggedInUserId,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // 재고 입고 목록 표시 영역
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
                            flex: 3,
                            child: Text(
                              '제품명',
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
                        ],
                      ),
                    ),
                    Divider(height: 1, thickness: 1), // 헤더와 목록 구분선, 높이 조정
                    // 재고 목록 표시
                    Expanded(
                      // Column 내에서 ListView가 남은 공간을 차지하도록 Expanded 사용
                      child: ListView.builder(
                        itemCount: receivedInventoryList.length,
                        itemBuilder: (context, index) {
                          final item =
                              receivedInventoryList[index]; // Map 형태의 데이터 항목
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
                                  flex: 3,
                                  child: Text(
                                    item['productsName'] ?? '',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ), // productsName 케이스 반영
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    item['productsColor'] ?? '',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ), // productsColor 케이스 반영
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    item['productsSize']?.toString() ?? '',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ), // productsSize 케이스 반영
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    item['receivedQuantity']?.toString() ?? '',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ), // 수량 (핸들러에서 정의한 별칭)
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    if (receivedInventoryList.isEmpty &&
                        startDate != null &&
                        endDate != null) // 날짜 선택 후 데이터가 없을 때 메시지 표시
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            '선택하신 기간 (${startDate!.toLocal().toString().split(' ')[0]} - ${endDate!.toLocal().toString().split(' ')[0]}) 내 입고된 제품이 없습니다.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      ),
                    if (startDate == null ||
                        endDate == null) // 날짜를 선택하지 않았을 때 초기 메시지
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            '시작일과 종료일을 선택하여 입고된 재고를 확인하세요.',
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
            // 총 입고 수량 표시
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.blueAccent,
                ), // 강조를 위한 다른 테두리 색상
                borderRadius: BorderRadius.circular(8),
                color: Colors.blueAccent.withOpacity(0.1), // 약간의 배경색 추가
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '총 입고 수량:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$totalReceivedQuantity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ), // 총 수량 표시
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
