// store_return_application.dart
import 'package:flutter/material.dart';
import 'package:black_market_app/vm/database_handler.dart'; // DatabaseHandler 임포트
import 'package:intl/intl.dart'; // 날짜 형식을 위해 intl 패키지 필요 (pubspec.yaml에 추가해야 함)
import 'package:black_market_app/message/custom_snackbar.dart'; // CustomSnackbar 사용
import 'package:black_market_app/utility/custom_button.dart'; // CustomButton 사용
import 'package:black_market_app/utility/custom_textfield.dart'; // CustomTextField 사용
import 'package:get/get.dart'; // GetX 임포트

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

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler(); // 핸들러 인스턴스 생성
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
      // DatabaseHandler의 쿼리가 'pUserId'와 'oproductCode'를 반환함을 반영합니다.
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
      print('주문 정보 조회 중 오류 발생: $e');
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

    // 반품 정보를 Map 형태로 준비 (DB insert 메서드는 Map을 받도록 설계)
    // DatabaseHandler의 insertReturnRecord 메서드가 processionStatus 케이스를 사용함을 반영합니다.
    final returnData = {
      // 'returnCode': DB 자동 생성 가정 (INTEGER PRIMARY KEY). 만약 수동 할당이라면 여기에 추가.
      'ruserId': _ruserId, // 조회된 회원 ID
      'rProductCode': _rProductCode, // 조회된 제품 코드
      'returnReason': returnReason,
      'returnDate': returnDate, // YYYY-MM-DD 형식 문자열
      'returnCategory': '고객 방문 반품', // 기본값 설정
      'processionStatus': '접수 대기', // 초기 처리 상태 설정 (processionStatus 케이스 반영)
    };

    // 데이터베이스에 반품 기록 삽입
    try {
      int result = await handler.insertReturnRecord(returnData);
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
      print('반품 신청 저장 중 오류 발생: $e');
      Get.snackbar(
        '오류',
        '반품 신청 저장 중 오류가 발생했습니다: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('반품 신청')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          // 화면 넘침 방지를 위해 SingleChildScrollView 사용
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // 필드들을 왼쪽 정렬
            children: [
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
                    // 표준 ElevatedButton 사용 (CustomButton 아님)
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
              if (_ruserId == null &&
                  _orderNumberController.text.isNotEmpty &&
                  int.tryParse(_orderNumberController.text.trim()) != null)
                Padding(
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
            ],
          ),
        ),
      ),
    );
  }
}
