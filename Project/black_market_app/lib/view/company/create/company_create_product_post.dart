// 제품 게시글 작성 
import 'dart:convert';
import 'dart:typed_data';
import 'package:black_market_app/global.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:black_market_app/model/products.dart';

class CompanyCreatePost extends StatefulWidget {
  const CompanyCreatePost({super.key});

  @override
  State<CompanyCreatePost> createState() => _CompanyCreatePostState();
}

class _CompanyCreatePostState extends State<CompanyCreatePost> {
  final _titleController = TextEditingController();
  Uint8List? _thumbnail;
  List<XFile> _additionalImages = [];
  final _formKey = GlobalKey<FormState>();

  List<Products> _products = [];
  Products? _selectedProduct;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final response = await http.get(Uri.parse('http://${globalip}:8000/kimsua/select/products'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        setState(() {
          _products = jsonList.map((e) => Products.fromMap(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickThumbnail() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _thumbnail = bytes;
      });
    }
  }

  Future<void> _pickMultipleImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();

    if (images != null && images.length + _additionalImages.length <= 4) {
      setState(() {
        _additionalImages.addAll(images);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('최대 4장까지만 선택할 수 있습니다.')),
      );
    }
  }

  Future<void> _uploadPostToServer() async {
    final box = GetStorage();
    final userId = box.read('uid');

    if (_formKey.currentState!.validate() && _thumbnail != null && _additionalImages.isNotEmpty && _selectedProduct != null) {
      final uri = Uri.parse('http://${globalip}:8000/kimsua/insert/product');
      final request = http.MultipartRequest('POST', uri);

      request.fields['ptitle'] = _titleController.text;
      request.fields['products_productsCode'] = _selectedProduct!.productsCode.toString();
      request.fields['users_userid'] = userId.toString();
      request.files.add(http.MultipartFile.fromBytes('introductionPhoto', _thumbnail!, filename: 'thumbnail.jpg'));

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
                    DropdownButtonFormField<Products>(
                      value: _selectedProduct,
                      hint: const Text('제품 선택'),
                      items: _products.map((product) {
                        return DropdownMenuItem(
                          value: product,
                          child: Text('${product.productsName} (${product.productsCode})'),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedProduct = value),
                      validator: (value) => value == null ? '제품을 선택해주세요' : null,
                    ),
                    const SizedBox(height: 16),
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
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _pickThumbnail,
                          child: const Text('대표 이미지 선택'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _pickMultipleImages,
                          child: const Text('소개 이미지 선택 (최대 4장)'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
