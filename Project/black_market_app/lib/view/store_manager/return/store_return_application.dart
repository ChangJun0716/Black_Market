// store_return_application.dart
import 'package:flutter/material.dart';
import 'package:black_market_app/vm/database_handler.dart'; // DatabaseHandler 임포트
import 'package:intl/intl.dart'; // 날짜 형식을 위해 intl 패키지 필요 (pubspec.yaml에 추가해야 함)
import 'package:black_market_app/message/custom_snackbar.dart'; // CustomSnackbar 사용
import 'package:black_market_app/utility/custom_button.dart'; // CustomButton 사용
import 'package:black_market_app/utility/custom_textfield.dart'; // CustomTextField 사용
import 'package:get/get.dart'; // GetX 임포트 (Snackbar 사용)
import 'package:get_storage/get_storage.dart'; // GetStorage 임포트

class StoreReturnApplication extends StatefulWidget {
  const StoreReturnApplication({super.key});

  @override
  _StoreReturnApplicationState createState() => _StoreReturnApplicationState();
}

class _StoreReturnApplicationState extends State<StoreReturnApplication> {
  late DatabaseHandler handler;
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _orderNumberController =
      TextEditingController(); // 주문 번호 (purchaseId)
  final TextEditingController _returnDateController = TextEditingController();
  final TextEditingController _returnReasonController = TextEditingController();

  // 오늘 날짜를 YYYY-MM-DD 형식으로 가져오기
  String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  // 주문 번호로 조회된 회원 ID와 제품 코드를 저장할 변수
  String? _ruserId;
  String? _rProductCode;

  // GetStorage에서 읽어온 사용자 ID
  String? _loggedInUserId;

  // 로그인된 대리점 코드 (사용자 ID로 조회)
  String? _loggedInStoreCode; // 초기값 null
  bool _isLoadingStoreCode = true; // storeCode 로딩 상태

  // DatabaseHandler 인스턴스
  // late DatabaseHandler _handler; // 이미 handler가 정의되어 있음
  final box = GetStorage(); // GetStorage 인스턴스

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler(); // 핸들러 인스턴스 생성

    // GetStorage에서 로그인된 사용자 ID 읽어오기
    _loggedInUserId = box.read('uid');
    print(
      '>>> StoreReturnApplication: GetStorage에서 읽어온 uid=$_loggedInUserId',
    ); // 로깅

    // 사용자 ID가 유효한 경우 해당 사용자의 storeCode 가져오기 시작
    if (_loggedInUserId != null) {
      _fetchStoreCodeByUserId(_loggedInUserId!); // storeCode 가져온 후 로딩 완료 처리
    } else {
      print('>>> StoreReturnApplication: GetStorage에 유효한 사용자 ID가 없습니다.');
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

    // 페이지 로드 시 반품일자 TextField에 오늘 날짜 설정
    _returnDateController.text = todayDate;
  }

  @override
  void dispose() {
    // 컨트롤러 메모리 해제
    _customerNameController.dispose();
    _orderNumberController.dispose();
    _returnDateController.dispose();
    _returnReasonController.dispose();
    super.dispose();
  }

  // 사용자 ID로 대리점 코드를 가져오는 메서드 (로딩 상태만 업데이트)
  // 이 페이지에서는 storeCode가 직접적인 데이터 필터링에 사용되지 않으므로,
  // storeCode가 필요한 로직이 있다면 이 메서드를 활용합니다.
  Future<void> _fetchStoreCodeByUserId(String userId) async {
    print('>>> StoreReturnApplication: 사용자 ID ($userId)로 대리점 코드 가져오기 시도'); // 로깅
    try {
      // DatabaseHandler의 getStoreCodeByUserId 메서드를 사용하여 storeCode 가져오기
      final String? storeCode = await handler.getStoreCodeByUserId(userId);
      print('>>> StoreReturnApplication: 검색된 storeCode = $storeCode'); // 로깅

      setState(() {
        _loggedInStoreCode = storeCode; // storeCode 상태 업데이트
        _isLoadingStoreCode = false; // storeCode 로딩 완료
      });

      if (storeCode == null) {
        // storeCode를 찾을 수 없는 경우 (daffiliation 테이블에 정보 없음)
        print(
          '>>> StoreReturnApplication: 사용자 ID ($userId)에 연결된 대리점 코드를 찾을 수 없습니다.',
        ); // 로깅
        Get.snackbar(
          '알림',
          '소속 대리점 정보를 찾을 수 없습니다. 반품 신청 시 필요할 수 있습니다.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print(
        '>>> StoreReturnApplication: 대리점 코드 가져오는 중 오류 발생: ${e.toString()}',
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

  // ------------ functions ---------------- //

  // 주문 번호 입력 후 회원 ID와 제품 코드 조회
  void _lookupPurchaseDetails(String purchaseIdText) async {
    // 입력된 주문 번호 유효성 검사 및 int 변환 시도
    if (purchaseIdText.trim().isEmpty) {
      setState(() {
        _ruserId = null;
        _rProductCode = null;
      });
      print('주문 번호를 입력해주세요.');
      // Get.snackbar( ... ); // GetX 스낵바 알림 가능
      return;
    }

    int? purchaseId = int.tryParse(purchaseIdText.trim());

    if (purchaseId == null) {
      setState(() {
        _ruserId = null;
        _rProductCode = null;
      });
      print('유효하지 않은 주문 번호 형식입니다. 숫자를 입력해주세요.');
      Get.snackbar(
        '오류',
        '유효하지 않은 주문 번호 형식입니다.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return; // 함수 종료
    }

    try {
      // DatabaseHandler를 통해 주문 정보 조회 (purchaseId는 int)
      final purchaseDetails = await handler.getPurchaseDetailsByPurchaseId(
        purchaseId,
      );

      setState(() {
        if (purchaseDetails != null) {
          _ruserId = purchaseDetails['pUserId']?.toString(); // pUserId 케이스 반영
          _rProductCode =
              purchaseDetails['oproductCode']
                  ?.toString(); // oproductCode 케이스 반영
          print('조회된 회원 ID: $_ruserId, 제품 코드: $_rProductCode');
          Get.snackbar(
            '조회 성공',
            '주문 정보가 확인되었습니다.',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          _ruserId = null;
          _rProductCode = null;
          print('해당 주문 번호의 구매 정보가 없습니다.');
          Get.snackbar(
            '알림',
            '해당 주문 번호의 구매 정보가 없습니다.',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
        }
      });
    } catch (e) {
      // 데이터베이스 조회 중 예외 발생
      print('주문 정보 조회 중 오류 발생: ${e.toString()}');
      setState(() {
        _ruserId = null;
        _rProductCode = null;
      });
      Get.snackbar(
        '오류',
        '주문 정보 조회 중 오류가 발생했습니다: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // 반품 신청 정보를 데이터베이스에 저장하는 메서드
  void _submitReturnApplication() async {
    // 입력 값 가져오기
    final customerName = _customerNameController.text.trim();
    // final orderNumber = _orderNumberController.text.trim(); // 주문 번호는 이미 _lookupPurchaseDetails에서 처리
    final returnDate = _returnDateController.text.trim(); // YYYY-MM-DD 형식 문자열
    final returnReason = _returnReasonController.text.trim();

    // 필수 필드 검증
    if (customerName.isEmpty || returnReason.isEmpty) {
      print('고객명과 반품 사유를 입력해주세요.');
      Get.snackbar(
        '오류',
        '고객명과 반품 사유를 입력해주세요.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // 주문 번호 조회 결과가 있는지 확인
    if (_ruserId == null || _rProductCode == null) {
      print('유효한 주문 번호를 입력하고 정보를 확인해주세요.');
      Get.snackbar(
        '오류',
        '유효한 주문 번호를 입력하고 정보를 확인해주세요.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return; // 함수 종료
    }

    // storeCode가 필요한 로직이라면 유효성 체크 추가
    // 현재 반품 기록 테이블(return) 스키마에는 storeCode 컬럼이 없어 사용하지 않지만,
    // 만약 추가해야 한다면 여기서 _loggedInStoreCode를 확인하고 사용합니다.
    // if (_loggedInStoreCode == null) {
    //      Get.snackbar('오류', '대리점 정보가 없어 반품 신청할 수 없습니다.', backgroundColor: Colors.red, colorText: Colors.white);
    //      return;
    // }

    // 반품 정보를 Map 형태로 준비 (DB insert 메서드는 Map을 받도록 설계)
    final returnData = {
      // 'returnCode': DB 자동 생성 가정 (INTEGER PRIMARY KEY). 만약 수동 할당이라면 여기에 추가.
      'ruserId': _ruserId, // 조회된 회원 ID
      'rProductCode': _rProductCode, // 조회된 제품 코드
      'returnReason': returnReason,
      'returnDate': returnDate, // YYYY-MM-DD 형식 문자열
      'returnCategory': '고객 방문 반품', // 기본값 설정
      'processionStatus': '접수 대기', // 초기 처리 상태 설정
      // 'pStoreCode': _loggedInStoreCode, // 반품 기록에 storeCode를 추가한다면 여기에 포함
    };

    // 데이터베이스에 반품 기록 삽입
    try {
      print('>>> 반품 신청 삽입 시도: $returnData'); // 로깅 추가
      int result = await handler.insertReturnRecord(returnData);
      print('>>> 반품 신청 삽입 결과 (rowId): $result'); // 로깅 추가

      if (result > 0) {
        // TODO: 성공 알림 및 페이지 이동 또는 필드 초기화
        print(
          '반품 신청이 성공적으로 접수되었습니다. Result: $result',
        ); // SQLite insert는 row id 반환
        Get.snackbar(
          '가입 성공',
          '반품 신청이 성공적으로 접수되었습니다.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        // 성공 시 입력 필드 초기화 및 상태 재설정
        _customerNameController.clear();
        _orderNumberController.clear();
        _returnReasonController.clear();
        setState(() {
          _ruserId = null;
          _rProductCode = null;
        });

        // 필요하다면 반품 목록 페이지로 돌아갈 수 있습니다. (Get.back 사용)
        // Get.back();
      } else {
        // 삽입 실패
        print('반품 신청 접수 실패');
        Get.snackbar(
          '등록 실패',
          '반품 신청 접수 실패.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      // 데이터베이스 삽입 중 예외 발생
      print('반품 신청 저장 중 오류 발생: ${e.toString()}'); // 오류 메시지 포함 로깅 추가
      Get.snackbar(
        '오류',
        '반품 신청 저장 중 오류가 발생했습니다: ${e.toString()}', // 오류 메시지 포함
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
        appBar: AppBar(title: Text('반품 신청 정보 로딩 중...')),
        body: Center(child: CircularProgressIndicator()),
      );
    } else if (_loggedInUserId == null || _loggedInStoreCode == null) {
      // 사용자 ID 없거나 storeCode 로딩 실패
      return Scaffold(
        appBar: AppBar(title: Text('반품 신청 오류')),
        body: Center(
          child: Text(
            '대리점 정보를 가져오는데 실패했습니다. 로그인 정보를 확인해주세요.',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('반품 신청')), // 제목 (필요하다면 대리점 이름 추가)
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          // 화면 넘침 방지를 위해 SingleChildScrollView 사용
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // 필드들을 왼쪽 정렬
            children: [
              // 현재 대리점 정보 표시 (선택 사항)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  '현재 대리점 코드: ${_loggedInStoreCode}',
                  style: TextStyle(fontSize: 14, color: Colors.blueGrey),
                ),
              ),

              Text(
                '고객명',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              CustomTextField(
                // CustomTextField 사용
                label: '고객명을 입력하세요', // hintText 대신 label 사용
                controller: _customerNameController,
              ),
              SizedBox(height: 16),

              Text(
                '주문 번호',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Row(
                // 주문 번호 입력 필드와 조회 버튼을 가로로 배치
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomTextField(
                      // CustomTextField 사용
                      label: '주문 번호를 입력하세요', // hintText 대신 label 사용
                      controller: _orderNumberController,
                      keyboardType: TextInputType.number, // 주문 번호는 숫자로 가정
                      // 입력 완료 시 또는 변경 시 조회 (선택 사항)
                      // onSubmitted: (value) => _lookupPurchaseDetails(value), // TextField에서 바로 조회
                      // onChanged: (value) => _lookupPurchaseDetails(value), // 실시간 조회 (주의: 빈 값 처리 필요)
                    ),
                  ),
                  SizedBox(width: 8), // 간격
                  ElevatedButton(
                    // 표준 ElevatedButton 사용
                    onPressed: () {
                      // 널이 아닌 함수 전달
                      _lookupPurchaseDetails(
                        _orderNumberController.text,
                      ); // 조회 버튼 클릭 시 조회 함수 호출
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 20,
                      ), // 패딩 조정
                    ),
                    child: Text('조회'),
                  ),
                ],
              ),
              // 조회 결과 (회원 ID, 제품 코드) 표시 (선택 사항)
              if (_ruserId != null && _rProductCode != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '확인된 회원 ID: $_ruserId',
                        style: TextStyle(fontSize: 14, color: Colors.blueGrey),
                      ),
                      Text(
                        '확인된 제품 코드: $_rProductCode',
                        style: TextStyle(fontSize: 14, color: Colors.blueGrey),
                      ),
                    ],
                  ),
                ),
              // 유효하지 않은 주문 번호 입력 후 조회 시 메시지 표시 (조회 결과가 null일 때)
              if (_ruserId == null &&
                  _orderNumberController.text.isNotEmpty &&
                  int.tryParse(_orderNumberController.text.trim()) != null &&
                  !_isLoadingStoreCode)
                Padding(
                  // storeCode 로딩 완료 후에만 메시지 표시
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    '해당 주문 번호에 대한 정보가 없습니다.',
                    style: TextStyle(fontSize: 14, color: Colors.orange),
                  ),
                ),

              SizedBox(height: 16), // 간격 추가

              Text(
                '반품일자',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              CustomTextField(
                // CustomTextField 사용
                label: '반품일자', // hintText 대신 label 사용
                controller: _returnDateController,
                readOnly: true, // 사용자가 직접 수정하지 못하도록 읽기 전용 설정
              ),
              SizedBox(height: 16),

              Text(
                '반품 사유',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              CustomTextField(
                // CustomTextField 사용
                label: '반품 사유를 입력하세요', // hintText 대신 label 사용
                controller: _returnReasonController,
              ),
              SizedBox(height: 24),

              Center(
                // 버튼을 중앙에 배치
                child: CustomButton(
                  // CustomButton 사용
                  text: '반품 신청하기',
                  onPressed: _submitReturnApplication, // 널이 아닌 함수 전달
                  // CustomButton 스타일 조정은 위젯 내부에서 처리
                ),
              ),
              SizedBox(height: 16), // 하단 간격
            ],
          ),
        ),
      ),
    );
  }
}
