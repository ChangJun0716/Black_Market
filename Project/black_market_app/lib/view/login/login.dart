import 'package:black_market_app/message/custom_snackbar.dart';
import 'package:black_market_app/utility/custom_button.dart';
import 'package:black_market_app/utility/custom_textbutton.dart';
import 'package:black_market_app/utility/custom_textfield.dart';
import 'package:black_market_app/view/login/create_account.dart';
import 'package:black_market_app/vm/database_handler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  late DatabaseHandler handler;
  late TextEditingController idCon;
  late TextEditingController pwCon;
  final box = GetStorage();

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    idCon = TextEditingController();
    pwCon = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          children: [
            // textField : id
            CustomTextField(label: '아이디를 입력 하세요', controller: idCon),
            // textField : pw
            CustomTextField(label: '비밀번호를 입력 하세요', controller: pwCon),
            // button : login
            CustomButton(
              text: '로그인',
              onPressed: () {
                loginCheck(idCon.text, pwCon.text);
              },
            ),
            // button : 회원가입
            CustomTextButton(
              text: '회원 가입',
              onPressed: () {
                Get.to(CreateAccount());
              },
            ),
          ],
        ),
      ),
    );
  } // build

  // ----- functions ----- //
  // 로그인 버튼 action
  loginCheck(String id, String pw) async {
    int count = await handler.loginUsers(idCon.text, pwCon.text);
    if (count == 1) {
      // id,pw 일치하는 값이 있을 때
      CustomSnackbar().showSnackbar(
        title: '로그인 성공',
        message: '환영합니다.',
        backgroundColor: Colors.black,
        textColor: Colors.white,
      );
      int memberType = await handler.userMemberType(id); // 회원 아이디로 분류코드 식별
      if (memberType == 1) {
        saveStorage(memberType);
        // 사용자 페이지
      } else if (memberType == 2) {
        saveStorage(memberType);
        // 본사 페이지
      } else {
        saveStorage(memberType);
        // 대리점 페이지
      }
    } else {
      // id,pw 일치하는 값이 없을 때
      CustomSnackbar().showSnackbar(
        title: '오류',
        message: 'ID 혹은 PW 가 일치하지 않습니다.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // --------------------------------------- //
  // 로그인 성공 시 GetStorage 로 data 삽입
  saveStorage(int memberType) {
    box.write('uid', idCon.text);
    box.write('memberType', memberType);
  }

  // --------------------------------------- //
} // class
