import 'package:black_market_app/message/custom_dialogue.dart';
import 'package:black_market_app/message/custom_snackbar.dart';
import 'package:black_market_app/model/users.dart';
import 'package:black_market_app/utility/custom_button.dart';
import 'package:black_market_app/utility/custom_button_calender.dart';
import 'package:black_market_app/utility/custom_textfield.dart';
import 'package:black_market_app/vm/database_handler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateAccount extends StatefulWidget {
  const CreateAccount({super.key});

  @override
  State<CreateAccount> createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  late DatabaseHandler handler;
  late TextEditingController idCon;
  late TextEditingController pwCon;
  late TextEditingController nameCon;
  late TextEditingController genderCon;
  late TextEditingController phoneCon;
  late String birthDate;
  late bool idCheck;

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    idCon = TextEditingController();
    pwCon = TextEditingController();
    nameCon = TextEditingController();
    genderCon = TextEditingController();
    phoneCon = TextEditingController();
    birthDate = '';
    idCheck = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('회원 가입'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          children: [
            // textField : ID
            CustomTextField(
              label: '아이디를 입력 하세요',
              controller: idCon,
              readOnly: idCheck,
            ),
            // button : id 중복 체크
            CustomButton(
              text: '중복 확인',
              onPressed: () {
                idDoubleCheck(idCon.text);
              },
            ),
            // textField : PW
            CustomTextField(label: '비밀번호를 입력 하세요', controller: pwCon),
            // textField : Name
            CustomTextField(label: '이름를 입력 하세요', controller: nameCon),
            // button : 생년월일 선택
            CustomButtonCalender(
              label: '생년월일 선택',
              onDateSelected: (p0) {
                birthDate = p0.toString().substring(0, 10);
              },
            ),
            // textField : Gender
            CustomTextField(label: '성별를 입력 하세요', controller: genderCon),
            // textField : Phone
            CustomTextField(label: '전화번호를 입력 하세요', controller: phoneCon),
            // button : 회원가입
            CustomButton(
              text: '회원가입',
              onPressed: () {
                _createAccount();
              },
            ),
          ],
        ),
      ),
    );
  } // build

  // ------------ functions ---------------- //
  // 중복확인 버튼 action
  idDoubleCheck(String id) async {
    int count = await handler.idDoubleCheck(id);
    if (count == 0) {
      CustomDialogue().showDialogue(
        title: '확인 완료',
        middleText: '이 아이디를 사용 하시겠습니까?',
        cancelText: "취소",
        onCancel: () => Get.back(),
        confirmText: '사용하기',
        onConfirm: () {
          idCheck = true;
          Get.back();
        },
      );
    }
  }

  // --------------------------------------- //
  // 회원가입 버튼 action
  _createAccount() {
    if (idCon.text.trim().isEmpty ||
        pwCon.text.trim().isEmpty ||
        nameCon.text.trim().isEmpty ||
        phoneCon.text.trim().isEmpty ||
        genderCon.text.trim().isEmpty ||
        birthDate == '') {
      CustomSnackbar().showSnackbar(
        title: '오류',
        message: '입력하지 않은 정보가 있습니다.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      Get.back();
    } else {
      var userInfoInsert = Users(
        userid: idCon.text,
        password: pwCon.text,
        name: nameCon.text,
        phone: phoneCon.text,
        memberType: 1,
        birthDate: birthDate.substring(0, 10),
        gender: genderCon.text,
      );
      handler.insertUserInfo(userInfoInsert);
      CustomSnackbar().showSnackbar(
        title: '가입 성공',
        message: '가입이 완료 되었습니다.',
        backgroundColor: Colors.black,
        textColor: Colors.white,
      );
      Get.back();
      Get.back();
    }
  }

  // --------------------------------------- //
} // class
