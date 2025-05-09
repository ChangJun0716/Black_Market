//제품 게시글 작성
//제품 게시글 작성
import 'dart:typed_data';
import 'package:black_market_app/model/products.dart';
import 'package:black_market_app/model/product_registration.dart';
import 'package:black_market_app/view/company/post/post_block.dart';
import 'package:black_market_app/view/company/post/post_block_editor.dart';
import 'package:black_market_app/vm/database_handler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get_storage/get_storage.dart';

class CompanyCreatePost extends StatefulWidget {
  const CompanyCreatePost({super.key});

  @override
  State<CompanyCreatePost> createState() => _CompanyCreatePostState();
}

class _CompanyCreatePostState extends State<CompanyCreatePost> {
  late DatabaseHandler handler;
  List<String> productNames = [];
  List<Products> productList = [];
  String? selectedProductName;
  Products? selectedProduct;

  final _titleController = TextEditingController();
  Uint8List? _thumbnail;
  List<PostBlock> _blocks = [];

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    _loadProductNames();
  }

  Future<void> _loadProductNames() async {
    final names = await handler.getDistinctProductNames();
    setState(() {
      productNames = names;
    });
  }

  Future<void> _loadProductsByName(String name) async {
    final list = await handler.getProductsByName(name);
    setState(() {
      productList = list;
      selectedProduct = null;
    });
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

  Future<void> _savePost() async {
    final box = GetStorage();
    final userId = box.read('uid');

    if (_formKey.currentState!.validate() && selectedProduct != null && _thumbnail != null && _blocks.isNotEmpty) {
      final existing = await handler.getProductRegistrationByProductCode(selectedProduct!.productsCode.toString());
      if (existing != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('이미 해당 제품에 대한 게시글이 존재합니다.')));
        return;
      }

      final post = ProductRegistration(
        paUserid: userId,
        pProductCode: selectedProduct!.productsCode.toString(),
        introductionPhoto: _thumbnail!,
        ptitle: _titleController.text,
        contentBlocks: _blocks,
      );

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('저장 내용 확인'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User ID: ${post.paUserid}'),
                Text('Product Code: ${post.pProductCode}'),
                Text('Title: ${post.ptitle}'),
                Text('Block 수: ${post.contentBlocks.length}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await handler.insertProductRegistration(post);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('게시글이 저장되었습니다.')));
                Get.back();
              },
              child: Text('확인'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('모든 항목을 입력해주세요.')));
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
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 800,
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: DropdownButtonFormField<String>(
                      value: selectedProductName,
                      dropdownColor: Colors.white,
                      hint: const Text('상품명 선택'),
                      items: productNames.map((name) {
                        return DropdownMenuItem(
                          value: name,
                          child: Text(name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedProductName = value;
                          selectedProduct = null;
                        });
                        if (value != null) _loadProductsByName(value);
                      },
                      validator: (value) => value == null ? '상품명을 선택해주세요' : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (productList.isNotEmpty)
                    DropdownButtonFormField<Products>(
                      value: selectedProduct,
                      dropdownColor: Colors.white,
                      hint: const Text('세부 상품 선택'),
                      items: productList.map((product) {
                        return DropdownMenuItem(
                          value: product,
                          child: Text('${product.productsColor}, ${product.productsSize}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedProduct = value;
                        });
                      },
                      validator: (value) => value == null ? '제품을 선택해주세요' : null,
                    ),
                  const SizedBox(height: 20),
                  if (selectedProduct != null)
                    Card(
                      color: Colors.white10,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.memory(
                              selectedProduct!.productsImage,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('제품명: ${selectedProduct!.productsName}', style: TextStyle(color: Colors.white)),
                                  Text('색상: ${selectedProduct!.productsColor}', style: TextStyle(color: Colors.white)),
                                  Text('사이즈: ${selectedProduct!.productsSize}', style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
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
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: _pickThumbnail,
                        child: const Text('대표 이미지 선택'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_thumbnail != null)
                    Image.memory(_thumbnail!, height: 150),
                  const SizedBox(height: 16),
                  PostBlockEditor(
                    blocks: _blocks,
                    onChanged: (updated) {
                      setState(() {
                        _blocks = updated;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: _savePost,
                        child: const Text('저장하기'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
