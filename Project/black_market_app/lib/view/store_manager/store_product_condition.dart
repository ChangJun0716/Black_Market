// store_product_condition.dart
import 'package:flutter/material.dart';
import 'package:black_market_app/vm/database_handler.dart'; // DatabaseHandler 임포트
import 'package:black_market_app/utility/custom_textfield.dart'; // CustomTextField 사용
import 'package:black_market_app/utility/custom_button.dart'; // CustomButton 사용
import 'package:get/get.dart'; // GetX 임포트 (Snackbar 사용)
import 'package:get_storage/get_storage.dart'; // GetStorage 임포트

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

  // GetStorage에서 읽어온 사용자 ID
  String? _loggedInUserId;

  // 로그인된 대리점 코드 (사용자 ID로 조회)
  String? _loggedInStoreCode; // 초기값 null
  bool _isLoadingStoreCode = true; // storeCode 로딩 상태

  // DatabaseHandler 인스턴스
  late DatabaseHandler _handler;
  final box = GetStorage(); // GetStorage 인스턴스

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
    _handler = DatabaseHandler(); // 핸들러 인스턴스 생성

    // GetStorage에서 로그인된 사용자 ID 읽어오기
    _loggedInUserId = box.read('uid');
    print(
      '>>> StoreProductCondition: GetStorage에서 읽어온 uid=$_loggedInUserId',
    ); // 로깅

    // 사용자 ID가 유효한 경우 해당 사용자의 storeCode 가져오기 시작
    if (_loggedInUserId != null) {
      _fetchStoreCodeByUserId(_loggedInUserId!); // storeCode 가져온 후 데이터 로딩
    } else {
      // 사용자 ID를 찾지 못한 경우 처리
      print('>>> StoreProductCondition: GetStorage에 유효한 사용자 ID가 없습니다.');
      _isLoadingStoreCode = false; // 로딩 완료 처리 (실패)
      _loggedInStoreCode = null; // storeCode 상태 초기화
      // 사용자에게 알림 또는 로그인 페이지로 강제 이동 고려
      Get.snackbar(
        '오류',
        '로그인 정보를 가져올 수 없습니다. 다시 로그인해주세요.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }

    // 검색 TextField의 텍스트 변경을 감지하여 목록 필터링
    _searchController.addListener(_filterOrders);
  }

  @override
  void dispose() {
    // 컨트롤러 메모리 해제 및 리스너 제거
    _searchController.removeListener(_filterOrders);
    _searchController.dispose();
    super.dispose();
  }

  // 사용자 ID로 대리점 코드를 가져오는 메서드 및 데이터 로딩 시작
  Future<void> _fetchStoreCodeByUserId(String userId) async {
    print('>>> StoreProductCondition: 사용자 ID ($userId)로 대리점 코드 가져오기 시도'); // 로깅
    try {
      // DatabaseHandler의 getStoreCodeByUserId 메서드를 사용하여 storeCode 가져오기
      final String? storeCode = await _handler.getStoreCodeByUserId(userId);
      print('>>> StoreProductCondition: 검색된 storeCode = $storeCode'); // 로깅

      setState(() {
        _loggedInStoreCode = storeCode; // storeCode 상태 업데이트
        _isLoadingStoreCode = false; // storeCode 로딩 완료
      });

      if (storeCode != null) {
        // storeCode를 가져온 후 초기 데이터 로딩 시작
        _fetchPickupOrders(); // _fetchPickupOrders 내부에서 _loggedInStoreCode 사용
      } else {
        // storeCode를 찾을 수 없는 경우 (daffiliation 테이블에 정보 없음)
        print(
          '>>> StoreProductCondition: 사용자 ID ($userId)에 연결된 대리점 코드를 찾을 수 없습니다.',
        ); // 로깅
        Get.snackbar(
          '오류',
          '소속 대리점 정보를 찾을 수 없습니다. 관리자에게 문의하세요.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print(
        '>>> StoreProductCondition: 대리점 코드 가져오는 중 오류 발생: ${e.toString()}',
      ); // 로깅
      setState(() {
        _loggedInStoreCode = null; // 오류 시 storeCode 초기화
        _isLoadingStoreCode = false; // storeCode 로딩 완료 (오류)
      });
      Get.snackbar(
        '오류',
        '대리점 정보를 가져오는데 실패했습니다: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // 로그인한 대리점의 픽업 대기 주문 목록을 가져오는 메서드
  // 메서드 인자에서 storeCode 제거하고 상태 변수 _loggedInStoreCode 사용
  void _fetchPickupOrders({String? searchQuery}) async {
    // 검색어 인자 추가
    // storeCode 상태 변수 유효성 다시 확인
    if (_loggedInStoreCode == null) {
      print(
        '>>> _fetchPickupOrders: _loggedInStoreCode 상태 변수가 null입니다. 데이터 로딩 중단.',
      );
      setState(() {
        allPickupOrders = [];
        filteredPickupOrders = [];
      });
      return; // 함수 종료
    }

    try {
      // DatabaseHandler에서 'Ready for Pickup' 주문 목록 가져오기 (검색어 포함 호출)
      final fetchedOrdersMaps = await DatabaseHandler()
          .getPickupReadyOrdersByStore(
            _loggedInStoreCode!,
            searchQuery: searchQuery,
          ); // _loggedInStoreCode 상태 변수 사용

      // Map 리스트를 PickupOrderState 객체 리스트로 변환
      final fetchedOrdersState =
          fetchedOrdersMaps.map((orderMap) {
            final status =
                orderMap['purchaseDeliveryStatus']?.toString() ?? 'Unknown';
            return PickupOrderState(
              orderData: orderMap, // 원본 Map 데이터 저장
              currentStatus: status, // 초기 상태를 현재 선택된 상태로 설정
              originalStatus: status, // 초기 상태를 원본 상태로 저장
            );
          }).toList();

      setState(() {
        allPickupOrders = fetchedOrdersState; // 가져온 목록 업데이트
        filteredPickupOrders = List.from(allPickupOrders); // 필터링된 목록 표시
      });
    } catch (e) {
      // 에러 처리 로직 추가
      print('픽업 대기 주문 목록 가져오는 중 오류 발생: ${e.toString()}');
      setState(() {
        allPickupOrders = []; // 오류 발생 시 전체 목록 초기화
        filteredPickupOrders = []; // 오류 발생 시 필터링된 목록 초기화
      });
      Get.snackbar(
        '오류',
        '픽업 대기 주문 목록을 가져오는데 실패했습니다: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // 검색어에 따라 목록을 필터링하는 메서드
  void _filterOrders() {
    final query = _searchController.text.trim();

    // storeCode 로딩 완료된 경우에만 필터링 실행
    if (_loggedInStoreCode != null) {
      _fetchPickupOrders(searchQuery: query); // 검색어를 인자로 전달하여 데이터 다시 가져오기
    } else {
      print('>>> _filterOrders: _loggedInStoreCode가 null이라 필터링 건너뜀.');
    }
  }

  // 변경 사항을 데이터베이스에 저장하는 메서드
  void _saveChanges() async {
    List<PickupOrderState> changedOrders =
        allPickupOrders
            .where((item) => item.currentStatus != item.originalStatus)
            .toList();

    if (changedOrders.isEmpty) {
      print('변경할 내용이 없습니다.');
      Get.snackbar(
        '알림',
        '변경할 내용이 없습니다.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    try {
      for (var order in changedOrders) {
        final int? purchaseId = order.orderData['purchaseId'] as int?;
        if (purchaseId != null) {
          await DatabaseHandler().updatePurchaseDeliveryStatus(
            purchaseId.toString(),
            order.currentStatus,
          );
          order.originalStatus = order.currentStatus;
        }
      }
      print('변경 사항이 성공적으로 저장되었습니다.');
      Get.snackbar(
        '성공',
        '변경 사항이 성공적으로 저장되었습니다.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      _fetchPickupOrders();
    } catch (e) {
      print('변경 사항 저장 중 오류 발생: ${e.toString()}');
      Get.snackbar(
        '오류',
        '변경 사항 저장 중 오류가 발생했습니다: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(context) {
    // GetX 사용을 위해 context 대신 build(context) 사용
    // storeCode 로딩 중이거나 로딩 실패 시 로딩 인디케이터 또는 오류 메시지 표시
    if (_isLoadingStoreCode) {
      return Scaffold(
        appBar: AppBar(title: Text('픽업 대기 정보 로딩 중...')),
        body: Center(child: CircularProgressIndicator()),
      );
    } else if (_loggedInStoreCode == null) {
      return Scaffold(
        appBar: AppBar(title: Text('픽업 대기 목록 오류')),
        body: Center(
          child: Text(
            '대리점 정보를 가져오는데 실패했습니다.',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('픽업 대기 목록')), // 제목 (필요하다면 대리점 이름 추가)
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
                      child:
                          filteredPickupOrders.isEmpty
                              ? Center(
                                child: Text(
                                  _searchController.text.isEmpty
                                      ? '픽업 대기 중인 제품이 없습니다.'
                                      : '검색 결과가 없습니다.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                              : ListView.builder(
                                itemCount:
                                    filteredPickupOrders.length, // 필터링된 목록 사용
                                itemBuilder: (context, index) {
                                  final orderState =
                                      filteredPickupOrders[index]; // PickupOrderState 객체
                                  final orderData =
                                      orderState.orderData; // 원본 Map 데이터

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                      horizontal: 8.0,
                                    ), // 목록 항목 패딩 조정
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
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
                                            orderData['purchaseId']
                                                    ?.toString() ??
                                                '',
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
                                            orderData['productsSize']
                                                    ?.toString() ??
                                                '',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ), // productsSize 케이스 반영
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            orderData['purchaseQuanity']
                                                    ?.toString() ??
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
                                                orderState
                                                    .currentStatus, // 현재 선택된 상태 값
                                            items:
                                                _deliveryStatuses.map((
                                                  String status,
                                                ) {
                                                  return DropdownMenuItem<
                                                    String
                                                  >(
                                                    value: status,
                                                    child: Text(
                                                      status,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                    ), // 드롭다운 항목 글씨 크기 조정
                                                  );
                                                }).toList(),
                                            onChanged: (String? newValue) {
                                              if (newValue != null) {
                                                setState(() {
                                                  // 해당 항목의 currentStatus 업데이트
                                                  orderState.currentStatus =
                                                      newValue;
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
