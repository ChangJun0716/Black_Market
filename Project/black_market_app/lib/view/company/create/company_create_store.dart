// company_create_store.dart
import 'package:black_market_app/message/custom_snackbar.dart';
import 'package:black_market_app/utility/custom_button.dart';
import 'package:black_market_app/utility/custom_textfield.dart';
import 'package:black_market_app/vm/database_handler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // GetX 임포트

class CompanyCreateStore extends StatefulWidget {
  // 이름 그대로 사용
  const CompanyCreateStore({super.key});

  @override
  State<CompanyCreateStore> createState() => _CompanyCreateStoreState(); // State 이름 그대로 사용
}

class _CompanyCreateStoreState extends State<CompanyCreateStore> {
  // State 이름 그대로 사용
  late DatabaseHandler handler;
  final TextEditingController _storeCodeCon = TextEditingController();
  final TextEditingController _storeNameCon = TextEditingController();
  final TextEditingController _addressCon = TextEditingController();
  final TextEditingController _longitudeCon = TextEditingController(); // 경도
  final TextEditingController _latitudeCon = TextEditingController(); // 위도

  late bool storeCodeCheck; // 대리점 코드 중복 확인 상태

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler(); // 핸들러 인스턴스 생성
    storeCodeCheck = false; // 대리점 코드 중복 확인 초기 상태
  }

  @override
  void dispose() {
    // 컨트롤러 메모리 해제
    _storeCodeCon.dispose();
    _storeNameCon.dispose();
    _addressCon.dispose();
    _longitudeCon.dispose();
    _latitudeCon.dispose();
    super.dispose();
  }

  // ------------ functions ---------------- //
  // 대리점 코드 중복 확인 액션
  void storeCodeDoubleCheck(String code) async {
    // 입력된 코드 유효성 검사 (비어 있는지 등)
    if (code.trim().isEmpty) {
      CustomSnackbar().showSnackbar(
        title: '오류',
        message: '대리점 코드를 입력해주세요.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return; // 함수 종료
    }

    // 이미 중복 확인을 완료했으면 다시 확인하지 않음
    if (storeCodeCheck) {
      CustomSnackbar().showSnackbar(
        title: '확인 완료',
        message: '이미 중복 확인된 대리점 코드입니다.',
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return; // 함수 종료
    }

    try {
      int count = await handler.storeCodeDoubleCheck(code);
      if (count == 0) {
        // 중복 없음
        CustomSnackbar().showSnackbar(
          title: '확인 완료',
          message: '사용 가능한 대리점 코드입니다.',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        setState(() {
          storeCodeCheck = true; // 코드 사용 가능 상태로 변경
        });
      } else {
        // 중복 있음
        CustomSnackbar().showSnackbar(
          title: '오류',
          message: '이미 사용 중인 대리점 코드입니다.',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        setState(() {
          storeCodeCheck = false; // 중복 확인 상태 초기화
          _storeCodeCon.clear(); // 코드 필드 초기화 (선택 사항)
        });
      }
    } catch (e) {
      // 데이터베이스 작업 중 예외 발생
      print('대리점 코드 중복 확인 중 오류 발생: $e');
      CustomSnackbar().showSnackbar(
        title: '오류',
        message: '대리점 코드 중복 확인 중 오류가 발생했습니다.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // 대리점 정보 저장 액션
  void _saveStoreInfo() async {
    // 입력 값 가져오기
    final storeCode = _storeCodeCon.text.trim();
    final storeName = _storeNameCon.text.trim();
    final address = _addressCon.text.trim();
    final longitudeText = _longitudeCon.text.trim();
    final latitudeText = _latitudeCon.text.trim();

    // 유효성 검사 (필수 필드 및 코드 중복 확인 여부)
    if (storeCode.isEmpty ||
        storeName.isEmpty ||
        address.isEmpty ||
        longitudeText.isEmpty ||
        latitudeText.isEmpty) {
      CustomSnackbar().showSnackbar(
        title: '오류',
        message: '모든 필수 정보를 입력해주세요.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    // 대리점 코드 중복 확인이 완료되었는지 확인
    if (!storeCodeCheck) {
      CustomSnackbar().showSnackbar(
        title: '오류',
        message: '대리점 코드 중복 확인을 먼저 해주세요.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return; // 함수 종료
    }

    // 위도/경도 숫자인지 확인 및 Double로 변환
    double? longitude = double.tryParse(longitudeText);
    double? latitude = double.tryParse(latitudeText);

    if (longitude == null || latitude == null) {
      CustomSnackbar().showSnackbar(
        title: '오류',
        message: '위도와 경도를 올바른 숫자로 입력해주세요.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    // 저장할 대리점 정보를 Map 형태로 준비
    final storeData = {
      'storeCode': storeCode,
      'storeName': storeName,
      'address': address,
      'longitude': longitude, // Double 타입으로 저장
      'latitude': latitude, // Double 타입으로 저장
    };

    // 데이터베이스에 대리점 정보 삽입
    try {
      int result = await handler.insertStoreInfo(storeData);
      if (result > 0) {
        // 삽입 성공
        CustomSnackbar().showSnackbar(
          title: '등록 성공',
          message: '${storeName} 대리점 정보 등록이 완료되었습니다.',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        // 성공 시 입력 필드 초기화 및 상태 재설정 (필요 없으면 제거 가능)
        // _storeCodeCon.clear();
        // _storeNameCon.clear();
        // _addressCon.clear();
        // _longitudeCon.clear();
        // _latitudeCon.clear();
        // setState(() {
        //    storeCodeCheck = false;
        // });

        // 이전 페이지 (CompanyCreateAccount)로 돌아가면서 결과 반환 (Get.back 사용)
        Get.back(
          result: {'storeCode': storeCode, 'storeName': storeName},
        ); // 결과 (Map) 반환하며 페이지 닫기
      } else {
        // 삽입 실패 (예: primary key 충돌 등 - 다만 중복 확인 로직으로 대부분 방지됨)
        CustomSnackbar().showSnackbar(
          title: '등록 실패',
          message: '대리점 정보 등록에 실패했습니다.',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      // 데이터베이스 삽입 중 예외 발생
      print('대리점 정보 저장 중 오류 발생: $e');
      CustomSnackbar().showSnackbar(
        title: '오류',
        message: '대리점 정보 저장 중 오류가 발생했습니다: ${e.toString()}',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('대리점 정보 등록'), // 제목 설정
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        // 스크롤 가능하도록 SingleChildScrollView 추가
        padding: const EdgeInsets.all(16.0), // 패딩 추가
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // 가로로 늘이기
          children: [
            // textField : 대리점 코드
            CustomTextField(
              label: '대리점 코드를 입력 하세요',
              controller: _storeCodeCon,
              readOnly: storeCodeCheck, // 중복 확인 완료 후 수정 불가
            ),
            SizedBox(height: 8), // 간격 추가
            // button : 대리점 코드 중복 체크
            Align(
              // 버튼 정렬
              alignment: Alignment.centerRight, // 오른쪽 정렬 예시
              // CustomButton의 onPressed에 항상 널이 아닌 함수 전달
              child: CustomButton(
                text: '코드 중복 확인', // 텍스트
                onPressed: () {
                  // 항상 널이 아닌 함수
                  // 함수 내부에서 storeCodeCheck 상태를 확인하여 액션 수행
                  if (!storeCodeCheck) {
                    storeCodeDoubleCheck(_storeCodeCon.text);
                  } else {
                    // 이미 확인 완료된 상태일 때의 액션 (선택 사항)
                    CustomSnackbar().showSnackbar(
                      title: '확인 완료',
                      message: '이미 중복 확인된 대리점 코드입니다.',
                      backgroundColor: Colors.orange,
                      textColor: Colors.white,
                    );
                  }
                },
                // CustomButton 위젯 자체에 활성화/비활성화를 제어하는 로직이 없다면
                // 버튼을 비활성화 상태처럼 보이게 하려면 CustomButton 위젯을 수정하거나
                // 여기에 조건부 스타일링을 추가해야 합니다.
              ),
            ),
            SizedBox(height: 16), // 간격 추가
            // textField : 대리점 이름
            CustomTextField(label: '대리점 이름을 입력 하세요', controller: _storeNameCon),
            SizedBox(height: 16), // 간격 추가
            // textField : 주소
            CustomTextField(label: '주소를 입력 하세요', controller: _addressCon),
            SizedBox(height: 16), // 간격 추가
            // textField : 경도
            CustomTextField(
              label: '경도를 입력 하세요 (예: 127.0)',
              controller: _longitudeCon,
              keyboardType: TextInputType.numberWithOptions(
                decimal: true,
              ), // 숫자 입력 (소수점 허용)
            ),
            SizedBox(height: 16), // 간격 추가
            // textField : 위도
            CustomTextField(
              label: '위도를 입력 하세요 (예: 37.5)',
              controller: _latitudeCon,
              keyboardType: TextInputType.numberWithOptions(
                decimal: true,
              ), // 숫자 입력 (소수점 허용)
            ),
            SizedBox(height: 24), // 간격 추가
            // button : 대리점 정보 저장
            CustomButton(
              text: '대리점 정보 저장',
              onPressed: _saveStoreInfo, // 널이 아닌 함수 전달
            ),
            SizedBox(height: 16), // 하단 간격
          ],
        ),
      ),
    );
  }
}
