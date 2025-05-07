// store_product_condition.dart
import 'package:flutter/material.dart';
import 'package:black_market_app/vm/database_handler.dart'; // DatabaseHandler 임포트
import 'package:black_market_app/utility/custom_textfield.dart'; // CustomTextField 사용
import 'package:black_market_app/utility/custom_button.dart'; // CustomButton 사용
import 'package:get/get.dart'; // GetX 임포트 (Snackbar 등을 위해 필요할 수 있습니다)

// 픽업 대기 주문 정보를 상태 관리를 위해 담는 클래스
class PickupOrderState {
  final Map<String, dynamic> orderData; // DB에서 가져온 원본 데이터 (Map)
  String currentStatus; // 현재 DropdownButton에서 선택된 상태
  late final String originalStatus; // DB에서 가져온 초기 상태

  PickupOrderState({
    required this.orderData,
    required this.currentStatus,
    required this.originalStatus,
  });
}

class StoreProductCondition extends StatefulWidget {
  const StoreProductCondition({super.key});

  @override
  _StoreProductConditionState createState() => _StoreProductConditionState();
}

class _StoreProductConditionState extends State<StoreProductCondition> {
  final TextEditingController _searchController = TextEditingController();
  List<PickupOrderState> allPickupOrders =
      []; // 모든 픽업 대기 주문 목록 (PickupOrderState 객체)
  List<PickupOrderState> filteredPickupOrders =
      []; // 검색어에 따라 필터링된 목록 (PickupOrderState 객체)

  // 로그인한 대리점 코드 (예시, 실제 앱에서는 로그인 정보나 다른 방식으로 가져와야 합니다.)
  // TODO: 실제 로그인된 대리점의 storeCode를 가져오는 로직 구현 필요
  String loggedInStoreCode =
      'YOUR_LOGGED_IN_STORE_CODE'; // <<< 중요: 여기를 실제 대리점 코드로 바꿔주세요!

  // DropdownButton에 표시될 상태 목록 (실제 DB purchaseDeliveryStatus 값과 일치해야 함)
  // TODO: 실제 purchaseDeliveryStatus 필드의 가능한 모든 상태 값을 정의해야 합니다.
  final List<String> _deliveryStatuses = [
    'Ready for Pickup',
    'Picked Up',
    'Cancelled',
  ]; // <<< 중요: 실제 상태 값으로 변경!

  @override
  void initState() {
    super.initState();
    // 페이지 로드 시 모든 픽업 대기 주문 목록 가져오기
    _fetchPickupOrders();

    // 검색 TextField의 텍스트 변경을 감지하여 목록 필터링
    // debounce 시간을 주어 입력이 잠시 멈췄을 때만 검색하도록 하면 성능 향상에 도움이 될 수 있습니다.
    // _searchController.addListener(() {
    //   if (_debounce?.isActive ?? false) _debounce!.cancel();
    //   _debounce = Timer(const Duration(milliseconds: 500), () {
    //     _filterOrders();
    //   });
    // });
    _searchController.addListener(_filterOrders); // 간단하게 실시간 검색 유지
  }

  // Timer? _debounce; // Debounce Timer 변수 (필요시 주석 해제)

  @override
  void dispose() {
    // 컨트롤러 메모리 해제 및 리스너 제거
    _searchController.removeListener(_filterOrders);
    // _debounce?.cancel(); // Debounce Timer 해제 (필요시 주석 해제)
    _searchController.dispose();
    super.dispose();
  }

  // 로그인한 대리점의 픽업 대기 주문 목록을 가져오는 메서드
  void _fetchPickupOrders({String? searchQuery}) async {
    // 검색어 인자 추가
    // TODO: 실제 로그인된 대리점 코드를 사용하도록 수정해야 합니다.
    try {
      // DatabaseHandler에서 'Ready for Pickup' 주문 목록 가져오기 (검색어 포함 호출)
      // DatabaseHandler는 Map 리스트를 반환합니다.
      // DatabaseHandler의 쿼리가 purchaseId 검색 시 int로 변환함을 반영합니다.
      final fetchedOrdersMaps = await DatabaseHandler()
          .getPickupReadyOrdersByStore(
            loggedInStoreCode,
            searchQuery: searchQuery,
          );

      // Map 리스트를 PickupOrderState 객체 리스트로 변환
      final fetchedOrdersState =
          fetchedOrdersMaps.map((orderMap) {
            // Map에서 가져온 현재 상태 (컬럼 이름 케이스 반영)
            final status =
                orderMap['purchaseDeliveryStatus']?.toString() ?? 'Unknown';
            return PickupOrderState(
              orderData: orderMap, // 원본 Map 데이터 저장
              currentStatus: status, // 초기 상태를 현재 선택된 상태로 설정
              originalStatus: status, // 초기 상태를 원본 상태로 저장
            );
          }).toList();

      setState(() {
        // 검색어가 없는 경우에만 allPickupOrders 업데이트 (전체 데이터 필요 시)
        // 현재 로직은 검색 시에도 fetchOrdersByStore를 호출하므로 allPickupOrders는 항상 Ready for Pickup 상태 데이터만 가짐.
        // 검색 결과는 filteredPickupOrders에만 적용
        allPickupOrders = fetchedOrdersState; // 검색 결과도 일단 전체 목록으로 저장 (변경사항 추적용)
        filteredPickupOrders = List.from(allPickupOrders); // 필터링된 목록 표시
      });
    } catch (e) {
      // 에러 처리 로직 추가
      print('픽업 대기 주문 목록 가져오는 중 오류 발생: $e');
      setState(() {
        allPickupOrders = []; // 오류 발생 시 전체 목록 초기화
        filteredPickupOrders = []; // 오류 발생 시 필터링된 목록 초기화
      });
      // TODO: 사용자에게 오류 발생 알림 (예: SnackBar)
      Get.snackbar(
        '오류',
        '픽업 대기 주문 목록을 가져오는데 실패했습니다.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // 검색어에 따라 목록을 필터링하는 메서드 (이제는 단순히 _fetchPickupOrders 호출)
  void _filterOrders() {
    final query = _searchController.text.trim(); // 검색어 가져오기

    // 검색어 입력이 멈췄을 때 또는 검색 버튼을 눌렀을 때만 검색 실행 고려 가능
    // 현재는 입력될 때마다 실행 (성능 고려 필요)
    _fetchPickupOrders(searchQuery: query); // 검색어를 인자로 전달하여 데이터 다시 가져오기
  }

  // 변경 사항을 데이터베이스에 저장하는 메서드
  void _saveChanges() async {
    // allPickupOrders 목록 전체를 순회하며 상태가 변경된 항목 찾기
    List<PickupOrderState> changedOrders =
        allPickupOrders
            .where(
              (item) =>
                  item.currentStatus !=
                  item.originalStatus, // 현재 상태가 원본 상태와 다른 항목
            )
            .toList();

    if (changedOrders.isEmpty) {
      // 변경 사항이 없으면 사용자에게 알림
      print('변경할 내용이 없습니다.');
      Get.snackbar(
        '알림',
        '변경할 내용이 없습니다.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // 변경된 각 주문의 상태를 데이터베이스에 업데이트
    try {
      for (var order in changedOrders) {
        // purchaseId는 이제 Map에서 int? 타입으로 가져옴
        final int? purchaseId = order.orderData['purchaseId'] as int?;
        if (purchaseId != null) {
          await DatabaseHandler().updatePurchaseDeliveryStatus(
            purchaseId.toString(), // 주문 번호 (int)
            order.currentStatus, // 변경된 새로운 상태 값
          );
          // 업데이트 성공 시 해당 항목의 originalStatus를 currentStatus로 업데이트
          order.originalStatus = order.currentStatus; // 로컬 상태 업데이트
        }
      }
      // 모든 변경 사항 저장 성공 후 사용자에게 알림
      print('변경 사항이 성공적으로 저장되었습니다.');
      Get.snackbar(
        '성공',
        '변경 사항이 성공적으로 저장되었습니다.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      // 저장 성공 후 목록을 새로고침하여 'Ready for Pickup'이 아닌 항목 제거
      _fetchPickupOrders(); // 전체 목록 (Ready for Pickup 상태만 가져옴) 새로고침
    } catch (e) {
      // 변경 사항 저장 중 오류 발생 시 알림
      print('변경 사항 저장 중 오류 발생: $e');
      Get.snackbar(
        '오류',
        '변경 사항 저장 중 오류가 발생했습니다: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      // TODO: 저장 실패 시 원래 상태로 되돌리는 로직 고려 (선택 사항)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('픽업 대기 목록')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // 자식들을 가로로 늘이기
          children: [
            // 검색 TextField
            CustomTextField(
              // CustomTextField 사용
              label: '주문 번호 검색', // label 사용
              controller: _searchController,
              // prefixIcon: Icon(Icons.search), // CustomTextField에 prefixIcon 기능이 있다면 사용
              // decoration: InputDecoration( // CustomTextField 내부에서 Decoration 처리
              //   hintText: '주문 번호 검색',
              //   prefixIcon: Icon(Icons.search),
              //   border: OutlineInputBorder(
              //     borderRadius: BorderRadius.circular(8.0),
              //   ),
              // ),
            ),
            SizedBox(height: 16),
            // 픽업 대기 목록 표시 영역
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
                              '고객명',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ), // 글씨 크기 조정
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
                              '상태 변경',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ), // 새로운 헤더 컬럼
                        ],
                      ),
                    ),
                    Divider(height: 1, thickness: 1), // 헤더와 목록 구분선, 높이 조정
                    // 픽업 대기 목록 표시
                    Expanded(
                      // Column 내에서 ListView가 남은 공간을 차지하도록 Expanded 사용
                      child: ListView.builder(
                        itemCount: filteredPickupOrders.length, // 필터링된 목록 사용
                        itemBuilder: (context, index) {
                          final orderState =
                              filteredPickupOrders[index]; // PickupOrderState 객체
                          final orderData = orderState.orderData; // 원본 Map 데이터

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
                                    orderData['customerName'] ?? '',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ), // customerName 케이스 반영
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    orderData['purchaseId']?.toString() ?? '',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ), // purchaseId (int) toString()
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    orderData['oproductCode'] ?? '',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ), // oproductCode 케이스 반영
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    orderData['productsColor'] ?? '',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ), // productsColor 케이스 반영
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    orderData['productsSize']?.toString() ?? '',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ), // productsSize 케이스 반영
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    orderData['purchaseQuanity']?.toString() ??
                                        '',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ), // purchaseQuanity 케이스 반영
                                // 수령 상태 변경 DropdownButton
                                Expanded(
                                  flex: 2, // 상태 변경 컬럼에 할당할 공간 비율 조정
                                  child: DropdownButton<String>(
                                    // TODO: dropdownButtonStyle을 적절히 설정하여 공간 활용도를 높이거나 디자인 조정
                                    isExpanded: true, // 가로 공간 최대한 사용
                                    value:
                                        orderState.currentStatus, // 현재 선택된 상태 값
                                    items:
                                        _deliveryStatuses.map((String status) {
                                          return DropdownMenuItem<String>(
                                            value: status,
                                            child: Text(
                                              status,
                                              style: TextStyle(fontSize: 12),
                                            ), // 드롭다운 항목 글씨 크기 조정
                                          );
                                        }).toList(),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          // 해당 항목의 currentStatus 업데이트
                                          orderState.currentStatus = newValue;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    if (filteredPickupOrders.isEmpty) // 필터링 결과 데이터가 없을 때 메시지 표시
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            _searchController.text.isEmpty
                                ? '픽업 대기 중인 제품이 없습니다.'
                                : '검색 결과가 없습니다.',
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
            // 변경 사항 저장 버튼
            CustomButton(
              // CustomButton 사용
              text: '변경 사항 저장', // 버튼 텍스트
              onPressed: _saveChanges, // 널이 아닌 함수 전달
              // CustomButton 스타일 조정은 위젯 내부에서 처리
            ),
            SizedBox(height: 16), // 하단 간격
          ],
        ),
      ),
    );
  }
}
