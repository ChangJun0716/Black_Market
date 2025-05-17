import 'dart:convert';

import 'package:black_market_app/message/custom_dialogue.dart';
import 'package:black_market_app/message/custom_snackbar.dart';
import 'package:black_market_app/utility/custom_button.dart';
import 'package:black_market_app/utility/custom_button_calender.dart';
import 'package:black_market_app/utility/custom_textfield.dart';
import 'package:black_market_app/vm/database_handler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../global.dart';

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
  List data = []; // id 중복 체크 함수의 결과를 담을 list

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
                  if (idCon.text.trim().isEmpty){
                  }else{
                    idDoubleCheck(idCon.text);
                  }
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

// ------------------------------ functions --------------------------------- //
// 1. 중복확인 버튼 action
  idDoubleCheck(String id) async {
    await selectUseridDoubleCheck(id);
    int count = data[0]['count'];
    // print(count); --- 2
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
// -------------------------------------------------------------------------- //
// 2. 사용자가 입력한 아이디 값을 데이터베이스에서 검색하여 일치하는 아이디가 있는지 중복 여부를 확인하는 함수
// count = 0 : 중복 없음 / count = 1 중복 있음
  selectUseridDoubleCheck(String userid)async{
  var response = await http.get(Uri.parse("http://${globalip}:8000/changjun/selectUseridDoubleCheck?userid=$userid"));
  data.clear();
  data.addAll(json.decode(utf8.decode(response.bodyBytes))['results']);
  // print(data); --- 1
  }
// -------------------------------------------------------------------------- //
// 3. 회원가입 버튼 action
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
      insertUserAccount();
    }
  }
// -------------------------------------------------------------------------- //
// 4. 사용자가 입력한 정보를 database 에 insert 하는 함수
insertUserAccount()async{
  var request = http.MultipartRequest(
    'POST', 
    Uri.parse("http://${globalip}:8000/changjun/insertUserAccount")
  );
  request.fields['userid'] = idCon.text;
  request.fields['password'] = pwCon.text;
  request.fields['name'] = nameCon.text;
  request.fields['phone'] = phoneCon.text;
  request.fields['birthDate'] = birthDate;
  request.fields['gender'] = genderCon.text;
  request.fields['memberType'] = 1.toString();
  var res = await request.send();
  if(res.statusCode == 200){
    CustomDialogue().showDialogue(title: '회원 가입 성공', middleText: '회원가입에 성공 하셨습니다.',
    confirmText: "확인",
    onConfirm: () => Get.back(),
    );
  } else {
    CustomSnackbar().showSnackbar(title: '오류', message: '회원 가입에 실패 하였습니다.', backgroundColor: Colors.red, textColor: Colors.white);
  }
}
// -------------------------------------------------------------------------- //
}// class
