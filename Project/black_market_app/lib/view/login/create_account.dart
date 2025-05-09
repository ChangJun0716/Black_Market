import 'package:black_market_app/message/custom_dialogue.dart';
import 'package:black_market_app/message/custom_snackbar.dart';
import 'package:black_market_app/model/users.dart';
import 'package:black_market_app/utility/custom_button.dart';
import 'package:black_market_app/utility/custom_button_calender.dart';
import 'package:black_market_app/utility/custom_textfield.dart';
import 'package:black_market_app/view/login/login.dart';
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
        child: Container(
          width: 550,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // textField : ID
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CustomTextField(
                  label: '아이디를 입력 하세요',
                  controller: idCon,
                  readOnly: idCheck,
                ),
              ),
              // button : id 중복 체크
              CustomButton(
                text: '중복 확인',
                onPressed: () {
                  idDoubleCheck(idCon.text);
                },
              ),
              // textField : PW
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CustomTextField(label: '비밀번호를 입력 하세요',
                obscureText: true,
                 controller: pwCon),
              ),
              // textField : Name
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CustomTextField(label: '이름을 입력 하세요', controller: nameCon),
              ),
              // button : 생년월일 선택
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CustomButtonCalender(
                  label: '생년월일 선택',
                  onDateSelected: (p0) {
                    birthDate = p0.toString().substring(0, 10);
                  },
                ),
              ),
              // textField : Gender
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CustomTextField(label: '성별을 입력 하세요', controller: genderCon),
              ),
              // textField : Phone
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CustomTextField(label: '전화번호를 입력 하세요', controller: phoneCon),
              ),
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
      ),
    );
  }

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
          setState(() {
            idCheck = true;
          });
        },
      );
    } else {
      CustomSnackbar().showSnackbar(
        title: '아이디 중복',
        message: '이미 사용 중인 아이디입니다.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // --------------------------------------- //
  // 회원가입 버튼 action
  _createAccount() async {
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
    } else if (!idCheck) {
      CustomSnackbar().showSnackbar(
        title: '오류',
        message: '아이디 중복 확인을 해주세요.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } else {
      var userInfoInsert = Users(
        userid: idCon.text,
        password: pwCon.text,
        name: nameCon.text,
        phone: phoneCon.text,
        memberType: 1,
        birthDate: birthDate,
        gender: genderCon.text,
      );
      
      try {
        // 비동기적으로 회원가입 처리
        await handler.insertUserInfo(userInfoInsert);
        CustomSnackbar().showSnackbar(
          title: '가입 성공',
          message: '가입이 완료되었습니다.',
          backgroundColor: Colors.black,
          textColor: Colors.white,
        );
        // 회원가입 완료 후 홈 화면으로 이동
        Get.offAll(Login()); 
      } catch (e) {
        CustomSnackbar().showSnackbar(
          title: '오류',
          message: '회원가입 중 오류가 발생했습니다.',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }
}
