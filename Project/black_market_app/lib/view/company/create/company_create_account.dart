// CompanyCreateAccount.dart
import 'package:black_market_app/message/custom_dialogue.dart';
import 'package:black_market_app/message/custom_snackbar.dart';
import 'package:black_market_app/model/users.dart'; // Users 모델 사용
import 'package:black_market_app/utility/custom_button.dart'; // CustomButton 사용
import 'package:black_market_app/utility/custom_button_calender.dart'; // CustomButtonCalender 사용
import 'package:black_market_app/utility/custom_textfield.dart'; // CustomTextField 사용
import 'package:black_market_app/vm/database_handler.dart'; // DatabaseHandler 사용
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // GetX 임포트
import 'company_create_store.dart'; // CompanyCreateStore 페이지 임포트

class CompanyCreateAccount extends StatefulWidget {
  // 이름 그대로 사용
  const CompanyCreateAccount({super.key});

  @override
  State<CompanyCreateAccount> createState() => _CompanyCreateAccountState(); // State 이름 그대로 사용
}

class _CompanyCreateAccountState extends State<CompanyCreateAccount> {
  // State 이름 그대로 사용
  late DatabaseHandler handler;
  late TextEditingController idCon;
  late TextEditingController pwCon;
  late TextEditingController nameCon;
  late TextEditingController genderCon;
  late TextEditingController phoneCon;
  late String birthDate; // 'YYYY-MM-DD' 형식 문자열로 저장
  late bool idCheck; // 사용자 ID 중복 확인 상태

  // CompanyCreateStore에서 받아올 대리점 정보 상태 변수
  Map<String, dynamic>?
  _registeredStoreInfo; // 등록된 대리점 정보 (storeCode, storeName)

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler(); // 핸들러 인스턴스 생성
    idCon = TextEditingController();
    pwCon = TextEditingController();
    nameCon = TextEditingController();
    genderCon = TextEditingController();
    phoneCon = TextEditingController();
    birthDate = ''; // 초기값은 빈 문자열
    idCheck = false; // 사용자 ID 중복 확인 초기 상태
    _registeredStoreInfo = null; // 등록된 대리점 정보 초기값
  }

  @override
  void dispose() {
    // 컨트롤러 메모리 해제
    idCon.dispose();
    pwCon.dispose();
    nameCon.dispose();
    genderCon.dispose();
    phoneCon.dispose();
    super.dispose();
  }

  // ------------ functions ---------------- //
  // 사용자 ID 중복 확인 액션
  void idDoubleCheck(String id) async {
    // 입력된 ID 유효성 검사 (비어 있는지 등)
    if (id.trim().isEmpty) {
      CustomSnackbar().showSnackbar(
        title: '오류',
        message: '아이디를 입력해주세요.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return; // 함수 종료
    }

    // 이미 중복 확인을 완료했으면 다시 확인하지 않음
    if (idCheck) {
      CustomSnackbar().showSnackbar(
        title: '확인 완료',
        message: '이미 중복 확인된 아이디입니다.',
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return; // 함수 종료
    }

    try {
      int count = await handler.idDoubleCheck(id);
      if (count == 0) {
        // 중복 없음
        CustomDialogue().showDialogue(
          title: '확인 완료',
          middleText: '이 아이디를 사용 하시겠습니까?',
          cancelText: "취소",
          onCancel: () => Get.back(), // Get.back() 사용
          confirmText: '사용하기',
          onConfirm: () {
            setState(() {
              idCheck = true; // ID 사용 가능 상태로 변경
            });
            Get.back(); // Get.back() 사용
            CustomSnackbar().showSnackbar(
              title: '성공',
              message: '사용 가능한 아이디입니다.',
              backgroundColor: Colors.green,
              textColor: Colors.white,
            );
          },
        );
      } else {
        // 중복 있음
        CustomSnackbar().showSnackbar(
          title: '오류',
          message: '이미 사용 중인 아이디입니다.',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        setState(() {
          idCheck = false; // 중복 확인 상태 초기화
          idCon.clear(); // 아이디 필드 초기화 (선택 사항)
        });
      }
    } catch (e) {
      // 데이터베이스 작업 중 예외 발생
      print('ID 중복 확인 중 오류 발생: $e');
      CustomSnackbar().showSnackbar(
        title: '오류',
        message: 'ID 중복 확인 중 오류가 발생했습니다.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // --------------------------------------- //
  // 사용자 계정 + 대리점 소속 등록 액션
  void _createUserAndAffiliate() async {
    // 메서드 이름 변경 (사용자 계정 및 소속 등록)
    // 입력 값 유효성 검사 (필수 필드 확인)
    if (idCon.text.trim().isEmpty ||
        pwCon.text.trim().isEmpty ||
        nameCon.text.trim().isEmpty ||
        phoneCon.text.trim().isEmpty ||
        genderCon.text.trim().isEmpty ||
        birthDate
            .isEmpty // 빈 문자열인지 확인
            ) {
      CustomSnackbar().showSnackbar(
        title: '오류',
        message: '모든 필수 정보를 입력해주세요.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return; // 함수 종료
    }

    // ID 중복 확인이 완료되었는지 확인
    if (!idCheck) {
      CustomSnackbar().showSnackbar(
        title: '오류',
        message: '아이디 중복 확인을 먼저 해주세요.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return; // 함수 종료
    }

    // 등록할 대리점 정보가 있는지 확인
    if (_registeredStoreInfo == null) {
      CustomSnackbar().showSnackbar(
        title: '오류',
        message: '소속 대리점을 등록 또는 선택 해주세요.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return; // 함수 종료
    }

    // Users 객체 생성 (memberType은 요구사항에 따라 설정)
    var newUser = Users(
      // 변수명 변경
      userid: idCon.text,
      password: pwCon.text,
      name: nameCon.text,
      phone: phoneCon.text,
      memberType: 3, // 예시: 대리점장 memberType. 실제 값 확인 및 설정 필요.
      birthDate: birthDate, // YYYY-MM-DD 형식 문자열
      gender: genderCon.text,
    );

    // 등록된 대리점 코드 가져오기
    final String storeCode = _registeredStoreInfo!['storeCode']; // null 아님 보장

    try {
      // 1. users 테이블에 사용자 정보 삽입
      int userInsertResult = await handler.insertUserInfo(newUser); // 변수명 변경

      if (userInsertResult > 0) {
        // 사용자 정보 삽입 성공 시 daffiliation 테이블에 소속 정보 삽입
        // 2. daffiliation 테이블에 대리점-사용자 소속 정보 삽입
        int daffiliationInsertResult = await handler.insertDaffiliation(
          storeCode, // CompanyCreateStore에서 받아온 대리점 코드
          newUser.userid, // 새로 생성된 사용자 ID
        );

        if (daffiliationInsertResult > 0) {
          // 두 테이블 모두 삽입 성공
          CustomSnackbar().showSnackbar(
            title: '등록 성공',
            message:
                '${newUser.name} 사용자 계정 및 ${_registeredStoreInfo!['storeName']} 소속 등록이 완료되었습니다.', // 메시지 수정
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );
          // 성공 시 입력 필드 초기화 및 상태 재설정
          idCon.clear();
          pwCon.clear();
          nameCon.clear();
          genderCon.clear();
          phoneCon.clear();
          setState(() {
            birthDate = ''; // 생년월일 초기화 (CustomButtonCalender 초기화 로직 필요)
            idCheck = false; // ID 중복 확인 상태 초기화
            _registeredStoreInfo = null; // 등록된 대리점 정보 초기화
          });
          // TODO: CustomButtonCalender 텍스트도 초기화하는 로직 추가 필요

          // 필요하다면 다음 단계 페이지로 이동하거나 그냥 둘 수 있습니다.
          // Get.back(); // 이전 페이지로 돌아가지 않도록 주석 처리
        } else {
          // daffiliation 삽입 실패 (users 삽입은 성공했으나 소속 등록 실패)
          // TODO: users 테이블에 삽입된 정보 롤백 고려 (복잡해질 수 있음)
          CustomSnackbar().showSnackbar(
            title: '등록 실패',
            message: '사용자 계정 등록은 완료되었으나, 소속 대리점 등록에 실패했습니다.',
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      } else {
        // users 테이블 삽입 실패
        CustomSnackbar().showSnackbar(
          title: '등록 실패',
          message: '사용자 계정 등록에 실패했습니다.',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      // 데이터베이스 작업 중 예외 발생
      print('사용자/소속 등록 중 오류 발생: $e');
      CustomSnackbar().showSnackbar(
        title: '오류',
        message: '사용자/소속 등록 중 오류가 발생했습니다: ${e.toString()}',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // 새 대리점 등록 페이지로 이동하고 결과를 받아오는 메서드
  void _navigateToCreateStorePage() async {
    // CompanyCreateStore 페이지로 이동하고 결과를 기다림 (Get.to 사용)
    final result = await Get.to(() => CompanyCreateStore());

    // result가 null이 아니고 Map 형태이면 상태 업데이트
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _registeredStoreInfo = result; // 받아온 대리점 정보 저장
        // 대리점 정보가 선택/등록되면 ID 중복 확인 상태를 초기화하여
        // 새 계정을 다시 등록할 수 있도록 합니다. (선택 사항)
        // idCheck = false; // ID 중복 확인 상태는 유지하는 것이 좋을 수도 있습니다.
        // idCon.clear(); // 아이디 필드는 유지
        // 다른 필드도 초기화할 수 있습니다.
      });
      CustomSnackbar().showSnackbar(
        // 사용자에게 대리점 선택/등록 완료 알림
        title: '대리점 선택 완료',
        message: '${_registeredStoreInfo!['storeName']} 대리점이 선택되었습니다.',
        backgroundColor: Colors.blueAccent,
        textColor: Colors.white,
      );
    } else {
      // 대리점 등록/선택이 취소되었을 때 (결과가 null이거나 Map이 아닐 때)
      // 현재 선택된 대리점 정보를 그대로 유지합니다.
      CustomSnackbar().showSnackbar(
        // 사용자에게 대리점 선택 취소 알림
        title: '알림',
        message: '대리점 선택이 취소되었습니다.',
        backgroundColor: Colors.grey,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('사용자 계정 등록'), // 제목 (대리점장 사용자 등록 의미)
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        // 스크롤 가능하도록 SingleChildScrollView 추가
        padding: const EdgeInsets.all(16.0), // 패딩 추가
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // 가로로 늘이기
          children: [
            // 새 대리점 등록 페이지 이동 버튼
            // 대리점 정보가 이미 등록/선택되었으면 버튼 텍스트 변경 또는 비활성화 고려 가능
            Align(
              alignment: Alignment.centerRight, // 오른쪽 정렬
              child: ElevatedButton.icon(
                // 아이콘 포함 버튼
                onPressed: _navigateToCreateStorePage, // 널이 아닌 함수 전달
                icon: Icon(Icons.store_mall_directory),
                // 이미 선택된 대리점이 있다면 텍스트 변경
                label: Text(
                  _registeredStoreInfo == null ? '소속 대리점 등록/선택' : '소속 대리점 변경',
                ), // 텍스트 수정
              ),
            ),
            SizedBox(height: 16), // 간격 추가
            // 선택된 대리점 정보 표시
            if (_registeredStoreInfo != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  '선택된 대리점: ${_registeredStoreInfo!['storeName']} (${_registeredStoreInfo!['storeCode']})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            if (_registeredStoreInfo == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  '소속 대리점 정보를 등록 또는 선택해주세요.', // 텍스트 수정
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            SizedBox(height: 16), // 간격 추가
            // textField : ID
            CustomTextField(
              label: '아이디를 입력 하세요',
              controller: idCon,
              readOnly: idCheck, // 중복 확인 완료 후 수정 불가
            ),
            SizedBox(height: 8), // 간격 추가
            // button : ID 중복 체크
            Align(
              // 버튼 정렬
              alignment: Alignment.centerRight, // 오른쪽 정렬 예시
              // CustomButton의 onPressed에 항상 널이 아닌 함수 전달
              child: CustomButton(
                text: 'ID 중복 확인', // 텍스트 명확히
                onPressed: () {
                  // 항상 널이 아닌 함수
                  // 함수 내부에서 idCheck 상태를 확인하여 액션 수행
                  if (!idCheck) {
                    idDoubleCheck(idCon.text);
                  } else {
                    // 이미 확인 완료된 상태일 때의 액션 (선택 사항)
                    CustomSnackbar().showSnackbar(
                      title: '확인 완료',
                      message: '이미 중복 확인된 아이디입니다.',
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
            // textField : PW
            CustomTextField(label: '비밀번호를 입력 하세요', controller: pwCon),
            SizedBox(height: 16), // 간격 추가
            // textField : Name
            CustomTextField(label: '이름를 입력 하세요', controller: nameCon),
            SizedBox(height: 16), // 간격 추가
            // button : 생년월일 선택
            // CustomButtonCalender 사용 시 선택된 날짜 표시 및 초기화 로직 필요
            CustomButtonCalender(
              label:
                  birthDate.isEmpty
                      ? '생년월일 선택'
                      : '생년월일: $birthDate', // 선택된 날짜 표시
              onDateSelected: (DateTime date) {
                // p0 대신 DateTime date 사용 (가독성)
                setState(() {
                  birthDate = date.toString().substring(
                    0,
                    10,
                  ); // 'YYYY-MM-DD' 형식
                });
              },
            ),
            SizedBox(height: 16), // 간격 추가
            // textField : Gender
            CustomTextField(label: '성별를 입력 하세요', controller: genderCon),
            SizedBox(height: 16), // 간격 추가
            // textField : Phone
            CustomTextField(label: '전화번호를 입력 하세요', controller: phoneCon),
            SizedBox(height: 24), // 간격 추가
            // button : 사용자 계정 + 대리점 소속 등록
            CustomButton(
              text: '사용자 계정 및 대리점 소속 등록', // 버튼 텍스트 변경
              onPressed: _createUserAndAffiliate, // 널이 아닌 함수 전달
            ),
            SizedBox(height: 16), // 하단 간격

            // TODO: CustomButtonCalender 선택 해제/초기화 기능 추가 필요
            // 현재는 birthDate 상태만 초기화되고 버튼 텍스트는 업데이트되지만,
            // 커스텀 위젯 내부 초기화 로직은 별도 구현 필요할 수 있습니다.
          ],
        ),
      ),
    );
  } // build
}
