//제품 게시글 작성 - 2팀 팀원 : 김수아 개발 
//목적 : 
//제품에 대한 게시글을 작성 할 수 있다  
//개발 일지 :
//2025_05_17 
//대대적으로 원래 쓰던 방식을 다 갈아 엎음 
//소개사진을 리스트에 담아 리스트 형식으로 mysql에 넣는 형식으로 바꿈 
//모든 소스 globlaip 적용 완료 

import 'dart:convert';
import 'dart:typed_data';
import 'package:black_market_app/global.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class CompanyCreatePost extends StatefulWidget {
  const CompanyCreatePost({super.key});

  @override
  State<CompanyCreatePost> createState() => _CompanyCreatePostState();
}

class _CompanyCreatePostState extends State<CompanyCreatePost> {
  //제품 제목 
  final _titleController = TextEditingController();
  //사진 
  XFile? imageFile;
  final ImagePicker picker = ImagePicker();
  //사진 여러개 
  List<XFile> _additionalImages = [];
  final _formKey = GlobalKey<FormState>();
  //등록된 제품 받아오는 리스트
  List<dynamic> data = [];
  Map<String, dynamic>? _selectedProduct;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // 제품 이름으로 그룹바이해서 대표 코드 들고옴 
  _loadProducts() async {
    try {
      final response = await http.get(Uri.parse('http://$globalip:8000/kimsua/select/products/post'));
      if (response.statusCode == 200) {
        data.clear();
        data.addAll(json.decode(utf8.decode(response.bodyBytes))['result']);
        _isLoading = false;
        setState(() {});
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error loading products: $e");
      setState(() => _isLoading = false);
    }
  }

  //대표 사진 선택 
  getImageFromGallery(ImageSource imageSource)async{
    final XFile? pickedFile = await picker.pickImage(source: imageSource);
    imageFile = XFile(pickedFile!.path); 
    setState(() {});
  }

  //여러장 선택
  // 더 여러장 등록 할 수 있는데 같은 조 팀장님인 창준님이 3장까지만 하죠? 하셔서 억울하게 5장 됨
  _pickMultipleImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images != null && images.length + _additionalImages.length <= 5) {
      setState(() {
        _additionalImages.addAll(images);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('최대 5장까지만 선택할 수 있습니다.')),
      );
    }
  }

  //게시글 업로드
  _uploadPostToServer() async {
    final box = GetStorage();
    final userId = box.read('uid');

    if (_formKey.currentState!.validate() && imageFile != null && _additionalImages.isNotEmpty && _selectedProduct != null) {
      final uri = Uri.parse('http://${globalip}:8000/kimsua/insert/products/post');
      final request = http.MultipartRequest('POST', uri);

      request.fields['ptitle'] = _titleController.text;
      request.fields['products_productsCode'] = _selectedProduct!['productsCode'].toString();
      request.fields['users_userid'] = userId.toString();
      request.files.add(await http.MultipartFile.fromPath('introductionPhoto', imageFile!.path));

      // 리스트 사진을 받은 갯수 만큼 5장으로 제한 줘서 그냥 5장도 가능함 
      for (var i = 0; i < _additionalImages.length; i++) {
        final bytes = await _additionalImages[i].readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('contentBlocks', bytes, filename: 'block_$i.jpg'));
      }

      try {
        final response = await request.send();
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('게시글이 저장되었습니다.')));
          Get.back();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('업로드 실패')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('에러 발생: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('게시글 작성', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제품 드롭다운
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: _selectedProduct,
                      hint: const Text('제품 선택'),
                      items: data.map<DropdownMenuItem<Map<String, dynamic>>>((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text('${item['productsName']} (${item['productsCode']})',
                          style: TextStyle(color: Colors.pink)),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedProduct = value),
                      validator: (value) => value == null ? '제품을 선택해주세요' : null,
                    ),
                    const SizedBox(height: 16),
                    // 제목 입력란
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: '제목',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) => value == null || value.isEmpty ? '제목을 입력해주세요' : null,
                    ),
                    const SizedBox(height: 16),
                    // 이미지 선택 버튼
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => getImageFromGallery(ImageSource.gallery),
                          child: const Text('대표 이미지 선택'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _pickMultipleImages,
                          child: const Text('소개 이미지 선택 (최대 5장)'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 이미지 미리보기
                    if (_additionalImages.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        children: _additionalImages.map((xfile) => FutureBuilder<Uint8List>(
                          future: xfile.readAsBytes(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                              return Image.memory(snapshot.data!, width: 100, height: 100, fit: BoxFit.cover);
                            }
                            return const SizedBox(width: 100, height: 100);
                          },
                        )).toList(),
                      ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: _uploadPostToServer,
                        child: const Text('저장하기'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}