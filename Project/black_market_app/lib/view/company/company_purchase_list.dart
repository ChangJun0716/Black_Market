// company_purchase_list.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // GetX 임포트 (firstWhereOrNull, Snackbar 등 사용)
import 'package:intl/intl.dart'; // 날짜 포맷을 위해 intl 패키지 사용
import 'package:black_market_app/vm/database_handler.dart'; // DatabaseHandler 임포트
// 커스텀 위젯 임포트 (실제 프로젝트 경로에 맞게 수정 필요)
import 'package:black_market_app/utility/custom_button.dart';
import 'package:black_market_app/utility/custom_button_calender.dart';

class CompanyPurchaseList extends StatefulWidget {
  const CompanyPurchaseList({super.key});

  @override
  State<CompanyPurchaseList> createState() => _CompanyPurchaseListState();
}

class _CompanyPurchaseListState extends State<CompanyPurchaseList> {
  late DatabaseHandler handler;

  // 날짜 범위 상태
  DateTime? _startDate;
  DateTime? _endDate;

  // 대리점 선택 상태
  String? _selectedStoreCode; // 선택된 대리점 코드
  List<Map<String, dynamic>> _stores = []; // 모든 대리점 목록 (Map 리스트)
  bool _isLoadingStores = true; // 대리점 목록 로딩 상태
  // DropdownButton의 초기값으로 사용할 '전체 대리점' 항목
  static const String ALL_STORES_CODE = 'ALL';
  static const String ALL_STORES_NAME = '전체 대리점';

  // 조회된 데이터 상태
  int _overallTotal = 0; // 전체 기간/대리점 조건에 맞는 총액
  List<Map<String, dynamic>> _purchaseList = []; // 구매 목록 상세

  // 사용자 정보 및 권한 상태 (총액 표시에만 memberType 사용)
  // TODO: 실제 로그인된 본사 사용자의 ID와 memberType을 가져오는 로직 구현 필요
  String _loggedInUserId =
      'YOUR_LOGGED_IN_USER_ID'; // <<< 중요: 실제 사용자 ID로 바꿔주세요!
  int? _loggedInUserMemberType; // 로그인 사용자의 memberType

  // 권한 관련 플래그 (memberType 0번이 대리점 선택 시 특정 대리점 총액을 볼 수 있다고 가정)
  // TODO: 실제 직급 코드 기반 권한 로직으로 대체해야 합니다.
  bool _canViewSpecificStoreTotal = false; // 대리점 선택 시 해당 대리점 총액을 볼 수 있는 권한

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler(); // 핸들러 인스턴스 생성

    // 초기 로딩: 현재 날짜 기준 기본 범위 설정 및 사용자 정보 가져오기
    DateTime now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1); // 이번 달 1일
    _endDate = DateTime(now.year, now.month, now.day); // 오늘 날짜
    _selectedStoreCode = ALL_STORES_CODE; // 초기값은 전체 대리점

    // 사용자 정보 가져오기, 대리점 목록 가져오기, 초기 데이터 로딩 시작
    _loadInitialData();
  }

  @override
  void dispose() {
    // 컨트롤러 메모리 해제 (이 페이지에는 TextField 없음)
    super.dispose();
  }

  // ------------ functions ---------------- //

  // 초기 데이터 로딩 (사용자 정보, 대리점 목록, 구매 데이터)
  void _loadInitialData() async {
    // 비동기 함수 호출 (await의 결과를 변수에 할당하지 않음)
    await _fetchUserInfo(); // 사용자 정보 먼저 가져오기
    await _fetchStores(); // 대리점 목록 가져오기

    // 사용자 정보 로딩 완료 후 데이터 가져오기
    if (_loggedInUserMemberType != null) {
      _fetchPurchaseData();
    } else {
      Get.snackbar(
        '오류',
        '사용자 정보를 가져오는데 실패했습니다. 권한을 확인할 수 없습니다.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // 로그인 사용자 정보 가져오기
  // 반환 타입을 Future<void>로 명시
  Future<void> _fetchUserInfo() async {
    // TODO: 실제 로그인된 사용자의 ID를 사용하고, 필요하다면 직급 코드도 가져오도록 수정
    try {
      // memberType만 가져오는 간단한 예시
      int? memberType = await handler.userMemberType(_loggedInUserId);

      // TODO: getUserInfoWithGrade 메서드를 사용하여 직급 코드를 가져오고 권한 로직에 활용
      // final userInfo = await handler.getUserInfoWithGrade(_loggedInUserId);
      // final String? jobGradeCode = userInfo?['aJobGradeCode'];

      setState(() {
        _loggedInUserMemberType = memberType;
        // _loggedInUserJobGradeCode = jobGradeCode; // 직급 코드 사용 시 상태 업데이트

        // memberType 기반 권한 설정 (예시: memberType 0번이 대리점 선택 시 특정 대리점 총액 확인 가능)
        // TODO: 실제 직급 코드 기반 권한 로직으로 대체
        _canViewSpecificStoreTotal =
            (_loggedInUserMemberType == 0); // 권한 플래그 이름 변경
      });
      print(
        '>>> 로그인 사용자 정보 로딩 완료: UserID=$_loggedInUserId, MemberType=$_loggedInUserMemberType, CanViewSpecificStoreTotal=$_canViewSpecificStoreTotal',
      ); // 로깅
    } catch (e) {
      print('>>> 사용자 정보 가져오는 중 오류 발생: ${e.toString()}'); // 로깅
      setState(() {
        _loggedInUserMemberType = null;
        _canViewSpecificStoreTotal = false; // 오류 시 권한 없음
      });
      Get.snackbar(
        '오류',
        '사용자 정보를 가져오는데 실패했습니다: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // 모든 대리점 목록을 가져오는 메서드
  // 반환 타입을 Future<void>로 명시
  Future<void> _fetchStores() async {
    print('>>> 대리점 목록 로딩 시도...'); // setState 전에 로깅 (순서 조정)
    try {
      // DatabaseHandler에서 모든 대리점 목록 가져오기
      final fetchedStores = await handler.getAllStores();

      // '전체 대리점' 옵션을 목록 맨 앞에 추가
      List<Map<String, dynamic>> storesWithOptions = [
        {'storeCode': ALL_STORES_CODE, 'storeName': ALL_STORES_NAME},
        ...fetchedStores,
      ];

      // setState 호출
      setState(() {
        _stores = storesWithOptions; // 대리점 목록 업데이트
        _isLoadingStores = false; // 로딩 완료
        // _selectedStoreCode는 이미 초기화됨 (ALL_STORES_CODE)
      });
      // setState 호출 바로 뒤에 print 문 배치
      print('>>> 대리점 목록 로딩 완료: ${_stores.length} 개'); // setState 후에 로깅
    } catch (e) {
      print('>>> 대리점 목록 가져오는 중 오류 발생: ${e.toString()}'); // 로깅
      setState(() {
        _isLoadingStores = false; // 로딩 완료 (오류 발생 시)
        _stores = [
          {'storeCode': ALL_STORES_CODE, 'storeName': ALL_STORES_NAME},
        ]; // 오류 시 전체 옵션만 남김
      });
      // catch 블록의 setState 호출 바로 뒤에 print 문 배치
      print('>>> 대리점 목록 로딩 오류 처리 완료.'); // 로깅
      Get.snackbar(
        '오류',
        '대리점 목록을 가져오는데 실패했습니다: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // 선택된 조건에 맞는 구매 데이터 (총액 및 목록) 가져오기
  void _fetchPurchaseData() async {
    // 날짜 범위가 유효한지 확인
    if (_startDate == null ||
        _endDate == null ||
        _startDate!.isAfter(_endDate!)) {
      Get.snackbar(
        '오류',
        '유효한 날짜 범위를 선택해주세요.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return; // 함수 종료
    }

    // 로그인 사용자 정보가 로딩되지 않았다면 중단
    if (_loggedInUserMemberType == null) {
      // 사용자 정보 로딩 실패 메시지는 _loadInitialData 또는 _fetchUserInfo에서 이미 표시됨
      // Get.snackbar('오류', '사용자 정보 로딩 중. 잠시 후 다시 시도해주세요.', backgroundColor: Colors.orange, colorText: Colors.white);
      return; // 함수 종료
    }

    try {
      // 총액 계산 시 사용할 storeCode 결정
      String? totalCalculationStoreCode;
      if (_selectedStoreCode == ALL_STORES_CODE) {
        // '전체 대리점' 선택 시, 권한과 상관없이 전체 총액 계산
        totalCalculationStoreCode = null;
      } else {
        // 특정 대리점 선택 시, 권한이 있어야 해당 대리점의 총액 계산 요청
        // 권한이 없으면 특정 대리점 총액을 계산하지 않고 (또는 null을 전달하여 전체 총액을 가져오도록 유도),
        // UI에서 전체 총액을 표시하게 됩니다.
        totalCalculationStoreCode =
            _canViewSpecificStoreTotal ? _selectedStoreCode : null;
      }

      // 1. 총액 가져오기 (권한 및 선택 조건에 따라)
      print(
        '>>> 총 구매 금액 조회 시도 (계산 대상 StoreCode: $totalCalculationStoreCode): ${_startDate!.toIso8601String().split('T')[0]} ~ ${_endDate!.toIso8601String().split('T')[0]}',
      ); // 로깅
      final overallTotal = await handler.getTotalPurchaseAmount(
        startDate: _startDate!,
        endDate: _endDate!,
        storeCode: totalCalculationStoreCode, // 계산 요청할 storeCode 전달 (권한 고려됨)
      );
      print('>>> 총 구매 금액 조회 결과: $overallTotal'); // 로깅

      // 2. 구매 목록 상세 가져오기
      print('>>> 구매 목록 상세 조회 시도: StoreCode=${_selectedStoreCode}'); // 로깅
      final purchaseList = await handler.getPurchaseList(
        startDate: _startDate!,
        endDate: _endDate!,
        storeCode:
            (_selectedStoreCode == ALL_STORES_CODE)
                ? null
                : _selectedStoreCode, // 목록은 선택된 대리점 기준으로 가져옴 (권한과 무관)
      );
      print('>>> 구매 목록 상세 조회 결과 (${purchaseList.length} 개 항목)'); // 로깅

      setState(() {
        _overallTotal = overallTotal; // 총액 상태 업데이트
        _purchaseList = purchaseList; // 구매 목록 상세 업데이트
      });
    } catch (e) {
      // 에러 처리 로직 추가
      print('>>> 구매 데이터 가져오는 중 오류 발생: ${e.toString()}'); // 로깅
      setState(() {
        _overallTotal = 0;
        _purchaseList = []; // 오류 발생 시 목록 초기화
      });
      Get.snackbar(
        '오류',
        '구매 데이터를 가져오는데 실패했습니다: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(context) {
    // GetX 사용을 위해 context 대신 build(context) 사용
    // 사용자 정보 로딩 중이거나 대리점 목록 로딩 중이면 로딩 인디케이터 표시
    if (_loggedInUserMemberType == null || _isLoadingStores) {
      return Scaffold(
        appBar: AppBar(title: Text('회사 구매 목록 및 통계')),
        body: Center(
          child:
              _isLoadingStores
                  ? CircularProgressIndicator()
                  : Text('사용자 정보 또는 대리점 목록 로딩 실패.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('회사 구매 목록 및 통계'), // 제목
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // 가로로 늘이기
          children: [
            // 날짜 범위 선택
            Row(
              children: [
                Expanded(
                  child: CustomButtonCalender(
                    label:
                        _startDate == null
                            ? '시작일 선택'
                            : '시작일: ${_startDate!.toLocal().toString().split(' ')[0]}',
                    onDateSelected: (date) {
                      setState(() {
                        _startDate = date;
                      });
                      // 날짜 선택 후 데이터 다시 가져오기
                      _fetchPurchaseData();
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: CustomButtonCalender(
                    label:
                        _endDate == null
                            ? '종료일 선택'
                            : '종료일: ${_endDate!.toLocal().toString().split(' ')[0]}',
                    onDateSelected: (date) {
                      setState(() {
                        _endDate = date;
                      });
                      // 날짜 선택 후 데이터 다시 가져오기
                      _fetchPurchaseData();
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // 대리점 선택
            Text(
              '대리점 선택',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 15,
                ),
              ),
              hint: Text('대리점을 선택하세요'),
              value: _selectedStoreCode, // 현재 선택된 코드
              items:
                  _stores.map((store) {
                    // Map에서 storeCode와 storeName 가져오기 (키 이름 케이스 반영)
                    final String storeCode =
                        store['storeCode']?.toString() ?? '';
                    final String storeName =
                        store['storeName']?.toString() ?? '';
                    return DropdownMenuItem<String>(
                      value: storeCode, // 값은 storeCode 사용
                      child: Text(storeName), // 표시되는 텍스트는 storeName
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedStoreCode = newValue; // 선택된 코드 업데이트
                  });
                  // 대리점 선택 후 데이터 다시 가져오기
                  _fetchPurchaseData();
                }
              },
              // 유효성 검사는 필수 필드가 아니므로 필요 없을 수 있습니다.
              // validator: (value) => value == null ? '대리점을 선택해주세요.' : null,
            ),
            SizedBox(height: 24),

            // 총 판매 금액 표시 영역
            Text(
              '총 판매 금액',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
                color: Colors.blueGrey.withOpacity(0.1), // 배경색 추가
              ),
              child: Text(
                // 권한 및 선택 조건에 따라 라벨 변경
                // 권한 있고 특정 대리점 선택 시 -> [대리점 이름] 총액: [총액] 원
                // 권한 없거나 전체 대리점 선택 시 -> 전체 총액: [총액] 원
                (_selectedStoreCode != ALL_STORES_CODE &&
                        _canViewSpecificStoreTotal)
                    ? '${_getStoreNameByCodeS(_selectedStoreCode)} 총액: ${NumberFormat('#,###').format(_overallTotal)} 원' // <-- 변경된 이름 사용
                    : '전체 총액: ${NumberFormat('#,###').format(_overallTotal)} 원',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[700],
                ),
              ),
            ),
            SizedBox(height: 24),

            // 구매 목록 상세 표시 영역
            Text(
              '구매 목록 상세',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Expanded(
              // 남은 공간 전체 사용 (필수)
              child: Container(
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    _purchaseList.isEmpty
                        ? Center(
                          child: Text('구매 목록 데이터가 없습니다.'),
                        ) // 데이터 없을 때 메시지
                        : ListView.builder(
                          itemCount: _purchaseList.length,
                          itemBuilder: (context, index) {
                            final purchaseItem =
                                _purchaseList[index]; // Map 형태 데이터
                            // Map에서 필요한 정보 가져오기 (키 이름 케이스 반영)
                            final int purchaseId =
                                purchaseItem['purchaseId'] as int? ??
                                0; // int로 캐스팅, null이면 0
                            final String purchaseDate =
                                purchaseItem['purchaseDate']?.toString() ?? '';
                            final String customerName =
                                purchaseItem['customerName']?.toString() ?? '';
                            final String productsName =
                                purchaseItem['productsName']?.toString() ?? '';
                            final int purchasePrice =
                                purchaseItem['purchasePrice'] as int? ??
                                0; // int로 캐스팅, null이면 0
                            // 다른 필드들도 필요하면 가져와서 표시 가능 (storeName, productsColor, productsSize 등)

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                                horizontal: 4.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '주문 #${purchaseId} (${purchaseDate})',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '고객: ${customerName}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blueGrey[700],
                                    ),
                                  ),
                                  Text(
                                    '제품: ${productsName} (${purchaseItem['productsColor'] ?? ''}, ${purchaseItem['productsSize']?.toString() ?? ''})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blueGrey[700],
                                    ),
                                  ),
                                  Text(
                                    '금액: ${NumberFormat('#,###').format(purchasePrice)} 원',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ), // 숫자 포맷 적용
                                  Text(
                                    '대리점: ${purchaseItem['storeName'] ?? ''}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blueGrey[700],
                                    ),
                                  ), // 대리점 이름 추가
                                ],
                              ),
                            );
                          },
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 이 메서드는 _CompanyPurchaseListState 클래스 내에 단 한 번만 정의되어야 합니다.
  // 이름이 _getStoreNameByCodeS로 변경되었습니다.
  String _getStoreNameByCodeS(String? storeCode) {
    // <-- 메서드 이름 변경: _getStoreNameByCodeS
    if (storeCode == null ||
        storeCode.isEmpty ||
        storeCode == ALL_STORES_CODE) {
      return ALL_STORES_NAME; // '전체' 또는 유효하지 않은 코드는 '전체 대리점'으로 처리
    }
    // _stores 목록에서 해당 코드를 가진 항목을 찾아 이름 반환
    final selectedStore = _stores.firstWhereOrNull(
      (s) => s['storeCode'] == storeCode,
    ); // firstWhereOrNull 사용 (GetX)
    return selectedStore?['storeName']?.toString() ??
        '알 수 없음'; // 찾지 못했거나 이름이 null이면 '알 수 없음'
  }
}
