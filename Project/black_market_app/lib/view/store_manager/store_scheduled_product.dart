// store_scheduled_product.dart
import 'package:flutter/material.dart';
import 'package:black_market_app/vm/database_handler.dart'; // DatabaseHandler 임포트
// import 'package:black_market_app/model/purchase.dart'; // Purchase 모델은 여기서 직접 사용되지 않습니다.
import 'package:black_market_app/utility/custom_button_calender.dart'; // CustomButtonCalender 사용
import 'package:get/get.dart'; // GetX 임포트 (Snackbar 사용)
import 'package:get_storage/get_storage.dart'; // GetStorage 임포트

class StoreScheduledProduct extends StatefulWidget {
  const StoreScheduledProduct({super.key});

  @override
  _StoreScheduledProductState createState() => _StoreScheduledProductState();
}

class _StoreScheduledProductState extends State<StoreScheduledProduct> {
  DateTime? selectedDate; // 선택한 날짜
  List<Map<String, dynamic>> scheduledProducts = []; // 입고 예정 제품 목록 (Map 형태)

  // GetStorage에서 읽어온 사용자 ID
  String? _loggedInUserId;

  // 로그인된 대리점 코드 (사용자 ID로 조회)
  String? _loggedInStoreCode; // 초기값 null
  bool _isLoadingStoreCode = true; // storeCode 로딩 상태

  // DatabaseHandler 인스턴스
  late DatabaseHandler _handler;
  final box = GetStorage(); // GetStorage 인스턴스

  @override
  void initState() {
    super.initState();
    _handler = DatabaseHandler(); // 핸들러 인스턴스 생성

    // GetStorage에서 로그인된 사용자 ID 읽어오기
    _loggedInUserId = box.read('uid');
    print(
      '>>> StoreScheduledProduct: GetStorage에서 읽어온 uid=$_loggedInUserId',
    ); // 로깅

    // 사용자 ID가 유효한 경우 해당 사용자의 storeCode 가져오기 시작
    if (_loggedInUserId != null) {
      _fetchStoreCodeByUserId(_loggedInUserId!); // storeCode 가져온 후 데이터 로딩
    } else {
      // 사용자 ID를 찾지 못한 경우 처리
      print('>>> StoreScheduledProduct: GetStorage에 유효한 사용자 ID가 없습니다.');
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
  }

  // 사용자 ID로 대리점 코드를 가져오는 메서드 및 데이터 로딩 시작
  Future<void> _fetchStoreCodeByUserId(String userId) async {
    print('>>> StoreScheduledProduct: 사용자 ID ($userId)로 대리점 코드 가져오기 시도'); // 로깅
    try {
      // DatabaseHandler의 getStoreCodeByUserId 메서드를 사용하여 storeCode 가져오기
      final String? storeCode = await _handler.getStoreCodeByUserId(userId);
      print('>>> StoreScheduledProduct: 검색된 storeCode = $storeCode'); // 로깅

      setState(() {
        _loggedInStoreCode = storeCode; // storeCode 상태 업데이트
        _isLoadingStoreCode = false; // storeCode 로딩 완료
      });

      if (storeCode != null) {
        // storeCode를 가져온 후 초기 데이터 로딩 시작 (오늘 날짜 기준)
        selectedDate = DateTime.now(); // 오늘 날짜로 설정
        fetchScheduledProducts(
          selectedDate!,
          _loggedInStoreCode!,
        ); // storeCode 사용
      } else {
        // storeCode를 찾을 수 없는 경우 (daffiliation 테이블에 정보 없음)
        print(
          '>>> StoreScheduledProduct: 사용자 ID ($userId)에 연결된 대리점 코드를 찾을 수 없습니다.',
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
        '>>> StoreScheduledProduct: 대리점 코드 가져오는 중 오류 발생: ${e.toString()}',
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

  // 선택한 날짜와 대리점 코드에 맞는 입고 예정 제품 정보를 가져오는 메서드
  // 메서드 인자에서 storeCode 추가 및 사용
  void fetchScheduledProducts(DateTime date, String storeCode) async {
    // storeCode 인자 추가
    // storeCode 인자 유효성 체크
    if (storeCode == null || storeCode.isEmpty) {
      print('>>> fetchScheduledProducts: storeCode 인자가 유효하지 않습니다.');
      setState(() {
        scheduledProducts = [];
      });
      return; // 함수 종료
    }

    try {
      // DatabaseHandler를 통해 데이터 가져오기 (Map 형태로 반환됨)
      final fetchedProducts = await DatabaseHandler()
          .getScheduledProductsByDateAndStore(date, storeCode); // storeCode 사용
      setState(() {
        scheduledProducts = fetchedProducts; // 가져온 Map 리스트로 상태 업데이트
      });
    } catch (e) {
      // 에러 처리 로직 추가 (예: 에러 메시지 표시)
      print('입고 예정 제품 정보를 가져오는 중 오류 발생: ${e.toString()}');
      setState(() {
        scheduledProducts = []; // 오류 발생 시 목록 초기화
      });
      // TODO: 사용자에게 오류 발생 알림 (예: SnackBar)
      Get.snackbar(
        '오류',
        '입고 예정 제품 목록을 가져오는데 실패했습니다: ${e.toString()}',
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
        appBar: AppBar(title: Text('입고 예정 정보 로딩 중...')),
        body: Center(child: CircularProgressIndicator()),
      );
    } else if (_loggedInStoreCode == null) {
      // storeCode 로딩 실패
      return Scaffold(
        appBar: AppBar(title: Text('입고 예정 제품 오류')),
        body: Center(
          child: Text(
            '대리점 정보를 가져오는데 실패했습니다.',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('입고 예정 제품')), // 제목 (필요하다면 대리점 이름 추가)
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
                if (_loggedInStoreCode != null) {
                  // storeCode 유효성 체크 추가
                  fetchScheduledProducts(
                    date,
                    _loggedInStoreCode!,
                  ); // storeCode 사용
                } else {
                  Get.snackbar(
                    '오류',
                    '대리점 정보가 로딩되지 않았습니다.',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
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
                          // 필요한 경우 고객 이름, 대리점 이름 등을 추가 (SELECT 절에 포함된 경우)
                          // Expanded(flex: 2, child: Text(productData['customerName'] ?? '', style: TextStyle(fontSize: 12))),
                        ],
                      ),
                    ),
                    Divider(height: 1, thickness: 1), // 헤더와 목록 구분선, 높이 조정
                    // 입고 예정 제품 목록 표시
                    Expanded(
                      // Column 내에서 ListView가 남은 공간을 차지하도록 Expanded 사용
                      child:
                          scheduledProducts.isEmpty &&
                                  selectedDate !=
                                      null // 날짜 선택 후 데이터가 없을 때 메시지 표시
                              ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Text(
                                    '선택하신 날짜 (${selectedDate!.toLocal().toString().split(' ')[0]})에는 입고 예정 제품이 없습니다.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              )
                              : selectedDate ==
                                  null // 날짜를 선택하지 않았을 때 초기 메시지
                              ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Text(
                                    '날짜를 선택하여 입고 예정 제품을 확인하세요.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              )
                              : ListView.builder(
                                // 데이터가 있을 때 목록 표시
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Map 키 이름은 DatabaseHandler 쿼리의 SELECT 절 이름과 일치해야 합니다.
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            productData['purchaseId']
                                                    ?.toString() ??
                                                '',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ), // purchaseId는 int
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            productData['oproductCode']
                                                    ?.toString() ??
                                                '',
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
                                            productData['productsSize']
                                                    ?.toString() ??
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
                                            productData['purchaseDeliveryStatus'] ??
                                                '',
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
