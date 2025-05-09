// company_create_account.dart
import 'package:black_market_app/model/users.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // GetX 임포트 (Snackbar, Navigator 등 사용)
import 'package:get_storage/get_storage.dart'; // GetStorage 사용 (선택 사항, 여기서는 직접 사용 안 함)
// DatabaseHandler 임포트 (경로에 맞게 수정 필요)
import 'package:black_market_app/vm/database_handler.dart';
// Custom 위젯 임포트 (경로에 맞게 수정 필요)
import 'package:black_market_app/utility/custom_textfield.dart';
import 'package:black_market_app/utility/custom_button.dart';
import 'package:black_market_app/message/custom_snackbar.dart'; // CustomSnackbar 사용

class CompanyCreateAccount extends StatefulWidget {
  const CompanyCreateAccount({super.key});

  @override
  State<CompanyCreateAccount> createState() => _CompanyCreateAccountState();
}

class _CompanyCreateAccountState extends State<CompanyCreateAccount> {
  late DatabaseHandler handler;

  // 입력 필드 컨트롤러
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthDateController =
      TextEditingController(); // 생년월일
  final TextEditingController _genderController = TextEditingController(); // 성별

  // 회원 유형 (memberType) - 이 페이지에서는 대리점 관리자 (3)로 고정
  final int _selectedMemberType = 3; // 대리점 관리자로 고정

  // 대리점 목록 및 선택 상태
  List<Map<String, dynamic>> _stores = []; // 데이터베이스에서 가져온 대리점 목록
  String? _selectedStoreCode; // 드롭다운에서 선택된 대리점 코드
  bool _isLoadingStores = true; // 대리점 목록 로딩 상태

  // 드롭다운 힌트 텍스트
  static const String SELECT_STORE_HINT = '소속 대리점을 선택하세요';

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler(); // 핸들러 인스턴스 생성

    // 페이지 로드 시 대리점 목록 가져오기 시작
    _fetchStores();
  }

  @override
  void dispose() {
    // 컨트롤러 메모리 해제
    _idController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  // ------------ functions ---------------- //

  // 모든 대리점 목록을 가져오는 메서드
  Future<void> _fetchStores() async {
    // 반환 타입을 Future<void>로 명시
    try {
      // DatabaseHandler에서 모든 대리점 목록 가져오기
      final fetchedStores = await handler.getAllStores();

      setState(() {
        _stores = fetchedStores; // 대리점 목록 업데이트
        _isLoadingStores = false; // 로딩 완료
        // _selectedStoreCode는 초기값 null 상태
      });
      print('>>> 대리점 목록 로딩 완료: ${_stores.length} 개'); // 로깅
    } catch (e) {
      print('>>> 대리점 목록 가져오는 중 오류 발생: ${e.toString()}'); // 로깅
      setState(() {
        _isLoadingStores = false; // 로딩 완료 (오류 발생 시)
        _stores = []; // 오류 시 목록 초기화
      });
      Get.snackbar(
        '오류',
        '대리점 목록을 가져오는데 실패했습니다: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // 계정 생성 액션
  void _createAccount() async {
    // 입력 값 가져오기
    final userid = _idController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final birthDate = _birthDateController.text.trim();
    final gender = _genderController.text.trim(); // 성별 입력 방식에 따라 수정 필요

    // 필수 필드 검증 (대리점 선택 포함)
    if (userid.isEmpty ||
        password.isEmpty ||
        name.isEmpty ||
        phone.isEmpty ||
        birthDate.isEmpty ||
        gender.isEmpty) {
      Get.snackbar(
        '오류',
        '모든 필수 정보를 입력해주세요.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return; // 함수 종료
    }

    // 대리점 회원이므로 소속 대리점 선택 필수 검증
    if (_selectedStoreCode == null) {
      // 드롭다운에서 대리점이 선택되지 않은 경우
      Get.snackbar(
        '오류',
        '소속 대리점을 선택해야 합니다.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return; // 함수 종료
    }

    // 사용자 ID 중복 체크
    try {
      int idCount = await handler.idDoubleCheck(userid);
      if (idCount > 0) {
        Get.snackbar(
          '오류',
          '이미 사용 중인 아이디입니다.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return; // 함수 종료
      }
    } catch (e) {
      print('아이디 중복 체크 중 오류 발생: ${e.toString()}');
      Get.snackbar(
        '오류',
        '아이디 중복 체크 중 오류가 발생했습니다.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return; // 함수 종료
    }

    // 사용자 정보 Map 형태로 준비 (DB insert 메서드는 Map을 받도록 설계)
    // users 테이블 스키마에 맞춰 키 이름 사용: userid, password, name, phone, memberType, birthDate, gender
    final userData = {
      'userid': userid,
      'password': password,
      'name': name,
      'phone': phone,
      'memberType': _selectedMemberType, // 대리점 관리자 (3)로 고정
      'birthDate': birthDate,
      'gender': gender,
    };

    // 데이터베이스에 사용자 기록 삽입 (users 테이블)
    try {
      print('>>> 사용자 삽입 시도 (memberType 3): $userData'); // 로깅 추가
      // DatabaseHandler의 insertUserInfo 메서드를 호출
      int userInsertResult = await handler.insertUserInfo(
        Users.fromMap(userData),
      ); // Users 객체로 변환하여 삽입
      print('>>> 사용자 삽입 결과 (rowId): $userInsertResult'); // 로깅 추가

      if (userInsertResult > 0) {
        // 사용자 삽입 성공
        print('>>> 사용자 성공적으로 삽입됨. UserID: $userid'); // 로깅 추가

        // daffiliation 테이블에 연결 정보 삽입 (대리점 코드는 필수로 선택됨)
        print(
          '>>> daffiliation 삽입 시도: dstoreCode=$_selectedStoreCode, duserId=$userid',
        ); // 로깅 추가
        try {
          // DatabaseHandler의 insertDaffiliation 메서드를 호출
          int daffiliationInsertResult = await handler.insertDaffiliation(
            _selectedStoreCode!,
            userid,
          );
          print(
            '>>> daffiliation 삽입 결과 (rowId): $daffiliationInsertResult',
          ); // 로깅 추가

          if (daffiliationInsertResult > 0) {
            print('>>> daffiliation 성공적으로 삽입됨.'); // 로깅 추가
            // 사용자 및 daffiliation 삽입 모두 성공
            Get.snackbar(
              '등록 성공',
              '대리점 회원 계정 등록 및 대리점 연결 성공.',
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
            // 성공 시 입력 필드 초기화 및 상태 재설정
            _clearFields();
            // 필요하다면 다른 페이지로 이동
            // Get.back();
          } else {
            // daffiliation 삽입 실패 (무시 ConflictAlgorithm.ignore에 의해 실패 시 0 또는 -1 반환 가능)
            print('>>> daffiliation 삽입 실패 (이미 존재할 수 있음 또는 다른 원인).'); // 로깅 추가
            Get.snackbar(
              '등록 완료 (주의)',
              '사용자 등록은 성공했으나 대리점 연결에 실패했거나 이미 존재합니다.', // 사용자 등록은 성공했음을 알림
              backgroundColor: Colors.orange,
              colorText: Colors.white,
            );
            _clearFields(); // 사용자 등록은 성공했으므로 필드는 초기화
          }
        } catch (e) {
          // daffiliation 삽입 중 예외 발생
          print(
            '>>> daffiliation 삽입 중 예외 발생: ${e.toString()}',
          ); // 오류 메시지 포함 로깅 추가
          Get.snackbar(
            '등록 완료 (오류)',
            '사용자 등록은 성공했으나 대리점 연결 중 오류 발생: ${e.toString()}',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          _clearFields(); // 사용자 등록은 성공했으므로 필드는 초기화
        }
      } else {
        // 사용자 삽입 실패 (insertUserInfo 결과 <= 0)
        print('>>> 사용자 삽입 실패 (insertUserInfo 결과 <= 0).'); // 로깅 추가
        // 사용자 삽입 실패
        Get.snackbar(
          '등록 실패',
          '계정 등록에 실패했습니다.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      // 데이터베이스 작업 중 예외 발생 (users 삽입 시)
      print('>>> 사용자 삽입 중 예외 발생: ${e.toString()}'); // 오류 메시지 포함 로깅 추가
      // 데이터베이스 작업 중 예외 발생
      Get.snackbar(
        '오류',
        '계정 등록 중 오류가 발생했습니다: ${e.toString()}', // 오류 메시지 포함
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // 입력 필드 초기화 메서드
  void _clearFields() {
    _idController.clear();
    _passwordController.clear();
    _nameController.clear();
    _phoneController.clear();
    _birthDateController.clear();
    _genderController.clear();
    setState(() {
      _selectedStoreCode = null; // 선택된 대리점 초기화
      // _selectedMemberType은 3으로 고정이므로 초기화 불필요
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('대리점 회원 계정 생성 (본사)'), // 제목 변경
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        // 스크롤 가능하도록 SingleChildScrollView 추가
        padding: const EdgeInsets.all(16.0), // 전체 패딩
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // 가로로 늘이기
          children: [
            // TextField: 아이디
            Text(
              '아이디',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            CustomTextField(label: '아이디 입력 (중복 확인)', controller: _idController),
            SizedBox(height: 16),

            // TextField: 비밀번호
            Text(
              '비밀번호',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            CustomTextField(
              label: '비밀번호 입력',
              controller: _passwordController,
              obscureText: true,
            ),
            SizedBox(height: 16),

            // TextField: 이름
            Text(
              '이름',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            CustomTextField(label: '이름 입력', controller: _nameController),
            SizedBox(height: 16),

            // TextField: 연락처
            Text(
              '연락처',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            CustomTextField(
              label: '연락처 입력',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16),

            // TextField: 생년월일
            Text(
              '생년월일',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            CustomTextField(
              label: '생년월일 입력 (YYYY-MM-DD)',
              controller: _birthDateController,
              keyboardType: TextInputType.datetime,
            ), // 날짜 입력 타입
            SizedBox(height: 16),

            // TextField: 성별
            Text(
              '성별',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            CustomTextField(
              label: '성별 입력 (남/여)',
              controller: _genderController,
            ),
            SizedBox(height: 16),

            // 소속 대리점 선택 드롭다운 (필수)
            Text(
              '소속 대리점 선택',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            _isLoadingStores // 대리점 목록 로딩 중인 경우 로딩 인디케이터 표시
                ? Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 15,
                    ),
                  ),
                  hint: Text(SELECT_STORE_HINT), // 힌트 텍스트
                  value: _selectedStoreCode, // 현재 선택된 대리점 코드
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
                        _selectedStoreCode = newValue; // 선택된 대리점 코드 업데이트
                      });
                      print('>>> 선택된 대리점 코드: $_selectedStoreCode'); // 로깅
                    }
                  },
                  // 대리점 회원은 소속 대리점 선택이 필수이므로 유효성 검사 필요
                  validator:
                      (value) => value == null ? '소속 대리점을 선택해주세요.' : null,
                ),
            SizedBox(height: 24),
            // 계정 생성 버튼
            Center(
              // 버튼을 중앙에 배치
              child: CustomButton(
                // CustomButton 사용
                text: '계정 생성', // 버튼 텍스트
                onPressed: _createAccount, // 널이 아닌 함수 전달
                // CustomButton 스타일 조정은 위젯 내부에서 처리
              ),
            ),
            SizedBox(height: 16), // 하단 간격
          ],
        ),
      ),
    );
  }
}
