// 제품 등록
import 'dart:typed_data';
import 'package:black_market_app/utility/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:black_market_app/model/products.dart';
import 'package:black_market_app/vm/database_handler.dart';

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
  late DatabaseHandler handler;

  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate() && _imageBytes != null) {
      final product = Products(
        productsColor: _colorController.text,
        productsName: _nameController.text,
        productsPrice: int.parse(_priceController.text),
        productsOPrice: int.parse(_opriceController.text),
        productsSize: int.parse(_sizeController.text),
        productsImage: _imageBytes!,
      );

      try {
        await handler.insertProduct(product);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("제품이 등록되었습니다.")),
        );

        _colorController.clear();
        _nameController.clear();
        _priceController.clear();
        _sizeController.clear();
        setState(() {
          _imageBytes = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(" 등록 실패: ${e.toString()}")),
        );
      }
    } else if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("이미지를 선택해주세요.")),
      );
    }
  }

  @override
  void dispose() {
    _colorController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _sizeController.dispose();
    _opriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("제품 등록하기",
          style: TextStyle(color: Colors.white),
        ),
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
              child: ListView(
                children: [
                  _buildTextField(_colorController, '제품 컬러', TextInputType.text),
                  _buildTextField(_nameController, '제품명', TextInputType.text),
                  _buildTextField(_priceController, '판매 가격', TextInputType.number),
                  _buildTextField(_opriceController, '구매 가격', TextInputType.number),
                  _buildTextField(_sizeController, '사이즈', TextInputType.number),
                  SizedBox(height: 12),
                  CustomButton(
                    onPressed: _pickImage,
                    text: '이미지 선택',
                  ),
                  if (_imageBytes != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _imageBytes!,
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

  Widget _buildTextField(
      TextEditingController controller, String label, TextInputType type) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? '값을 입력하세요' : null,
      ),
    );
  }
}
