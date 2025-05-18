// 제품 등록 - 2팀 팀원 : 김수아 개발 
//목적 : 
//판매할 상품을 등록한다  
//개발 일지 :
//2025_05_17 
//delate로 개발 했던 소스 mysql python 소스로 바꾸기 
import 'dart:io';
import 'package:black_market_app/global.dart';
import 'package:black_market_app/utility/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; 

class CompanyCreateProduct extends StatefulWidget {
  const CompanyCreateProduct({super.key});

  @override
  State<CompanyCreateProduct> createState() => _CompanyCreateProductState();
}

class _CompanyCreateProductState extends State<CompanyCreateProduct> {
  final _formKey = GlobalKey<FormState>();
  final _colorController = TextEditingController();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _sizeController = TextEditingController();
  final _opriceController = TextEditingController();
  XFile? imageFile;
  final ImagePicker picker = ImagePicker();

  getImageFromGallery(ImageSource imageSource)async{
  final XFile? pickedFile = await picker.pickImage(source: imageSource);
  imageFile = XFile(pickedFile!.path); 
  setState(() {});
}
  //물건 넣는 거 
   _submit() async {
    if (_formKey.currentState!.validate() && imageFile != null) {
      try {
        var request = http.MultipartRequest(
          "POST",
          Uri.parse("http://$globalip:8000/kimsua/insert/products"),
        );
        request.fields['productsName'] = _nameController.text.trim();
        request.fields['productsColor'] = _colorController.text.trim();
        request.fields['productsSize'] = _sizeController.text.trim();
        request.fields['productsOPrice'] = _opriceController.text.trim();
        request.fields['productsPrice'] = _priceController.text.trim();
        request.files.add(await http.MultipartFile.fromPath('productsImage', imageFile!.path));

        var res = await request.send();
        if (res.statusCode == 200) {
          _showDialog();
        } else {
          errorSnackBar();
        }
      } catch (e) {
        errorSnackBar();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("이미지를 선택해주세요.")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("제품 등록하기", style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Container(
          color: Colors.white,
          height: 600,
          width: 400,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child:ListView(
                    children: [
                  _buildTextField(_colorController, '제품 컬러', TextInputType.text),
                  _buildTextField(_nameController, '제품명', TextInputType.text),
                  _buildTextField(_priceController, '판매 가격', TextInputType.number),
                  _buildTextField(_opriceController, '구매 가격', TextInputType.number),
                  _buildTextField(_sizeController, '사이즈', TextInputType.number),
                  SizedBox(height: 12),
                  CustomButton(
                    onPressed: () => getImageFromGallery(ImageSource.gallery),
                    text: '이미지 선택',
                  ),
                  if (imageFile != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(imageFile!.path),
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  SizedBox(height: 20),
                  CustomButton(
                    onPressed: _submit,
                    text: "제품 등록",
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, TextInputType type) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (value) => value == null || value.isEmpty ? '값을 입력하세요' : null,
      ),
    );
  }

  _showDialog() {
    Get.defaultDialog(
      title: "입력 결과",
      middleText: "입력이 완료 되었습니다.",
      barrierDismissible: false,
      actions: [
        TextButton(
          onPressed: () {
            Get.back();
            Get.back();
          },
          child: Text('OK'),
        ),
      ],
    );
  }

  errorSnackBar() {
    Get.snackbar(
      'Error',
      '입력시 문제가 발생했습니다.',
      duration: Duration(seconds: 2),
    );
  }
}
