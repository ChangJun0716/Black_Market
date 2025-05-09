// 제품 상세
import 'package:black_market_app/message/custom_snackbar.dart';
import 'package:black_market_app/model/purchase.dart';
import 'package:black_market_app/utility/custom_button.dart';
import 'package:black_market_app/utility/custom_textfield.dart';
import 'package:black_market_app/view/customer/customer_select_store.dart';
import 'package:black_market_app/vm/database_handler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class CustomerProductDetail extends StatefulWidget {
  const CustomerProductDetail({super.key});

  @override
  State<CustomerProductDetail> createState() => _CustomerProductDetailState();
}

class _CustomerProductDetailState extends State<CustomerProductDetail> {
  final box = GetStorage();
  late String uid;
  late DatabaseHandler handler;
  late String productsName;
  String? selectedColor;
  int? selectedSize;
  late TextEditingController quantityCon;
  late DateTime now;
  late String selectedStore;
  bool isReady = false;

  @override
  void initState() {
    super.initState();
    final ptitle = Get.arguments;

    if (ptitle == null) {
      CustomSnackbar().showSnackbar(
        title: '에러',
        message: '제품명이 전달되지 않았습니다.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      Get.back();
      return;
    }

    handler = DatabaseHandler();
    quantityCon = TextEditingController();
    now = DateTime.now();
    selectedStore = '';
    uid = box.read('uid') ?? '';

    handler.findProductNameByTitle(ptitle).then((name) {
      if (name == null) {
        CustomSnackbar().showSnackbar(
          title: '에러',
          message: '해당 제품을 찾을 수 없습니다.',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        Get.back();
      } else {
        productsName = name;
        setState(() {
          isReady = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('제품 상세'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: isReady
          ? FutureBuilder<List<Map<String, dynamic>>>(
              future: handler.queryProductDetails(productsName),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('에러 발생: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('제품 정보를 찾을 수 없습니다.'));
                }

                final items = snapshot.data!;
                final representative = items.first;

                final colors = items.map((e) => e['productsColor'] as String).toSet().toList();
                final sizes = items.map((e) => e['productsSize'] as int).toSet().toList();

                selectedColor ??= colors.first;
                selectedSize ??= sizes.first;

                final selected = items.firstWhere(
                  (e) =>
                      e['productsColor'] == selectedColor &&
                      e['productsSize'] == selectedSize,
                  orElse: () => representative,
                );

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      if (representative['productsImage'] != null)
                        Image.memory(representative['productsImage']),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('제품명: ${selected['productsName']}'),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text("가격: ${selected['productsPrice']}원"),
                      ),
                      DropdownButton<int>(
                        value: selectedSize,
                        items: sizes
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e.toString()),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() => selectedSize = val),
                      ),
                      if (representative['introductionPhoto'] != null)
                        Image.memory(representative['introductionPhoto']),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomButton(
                            text: '픽업 대리점 선택',
                            onPressed: () => Get.to(CustomerSelectStore())!.then((value) {
                              selectedStore = value;
                              setState(() {});
                            }),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 200,
                              height: 50,
                              child: CustomTextField(
                                label: '수량을 입력하세요',
                                controller: quantityCon,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
                            child: CustomButton(
                              text: '장바구니 담기',
                              onPressed: () async {
                                if (selectedStore == '' || quantityCon.text.trim().isEmpty) {
                                  CustomSnackbar().showSnackbar(
                                    title: '오류',
                                    message: '선택하지 않은 항목이 있습니다.',
                                    backgroundColor: Colors.red,
                                    textColor: Colors.white,
                                  );
                                  return;
                                }

                                final inputQty = int.tryParse(quantityCon.text) ?? 0;
                                final productCode = selected['productsCode'].toString();

                                await handler.addShopingCart(
                                  Purchase(
                                    purchaseDate: now.toString(),
                                    purchaseQuanity: inputQty,
                                    purchaseCardId: 1,
                                    pUserId: uid,
                                    pStoreCode: selectedStore,
                                    purchaseDeliveryStatus: '장바구니',
                                    oproductCode: productCode,
                                    purchasePrice: selected['productsPrice'] * inputQty,
                                  ),
                                );
                                Get.back();
                                CustomSnackbar().showSnackbar(
                                  title: '장바구니 담기 성공',
                                  message: '해당 상품이 장바구니에 추가되었습니다.',
                                  backgroundColor: Colors.black,
                                  textColor: Colors.white,
                                );
                              },
                            ),
                          ),
                          CustomButton(
                            text: '주문하기',
                            onPressed: () async {
                              if (selectedStore == '' || quantityCon.text.trim().isEmpty) {
                                CustomSnackbar().showSnackbar(
                                  title: '오류',
                                  message: '선택하지 않은 항목이 있습니다.',
                                  backgroundColor: Colors.red,
                                  textColor: Colors.white,
                                );
                                return;
                              }

                              final inputQty = int.tryParse(quantityCon.text) ?? 0;
                              final productCode = selected['productsCode'].toString();

                              await handler.addShopingCart(
                                Purchase(
                                  purchaseDate: now.toString(),
                                  purchaseQuanity: inputQty,
                                  purchaseCardId: 1,
                                  pUserId: uid,
                                  pStoreCode: selectedStore,
                                  purchaseDeliveryStatus: '주문완료',
                                  oproductCode: productCode,
                                  purchasePrice: selected['productsPrice'] * inputQty,
                                ),
                              );
                              Get.back();
                              CustomSnackbar().showSnackbar(
                                title: '주문 완료',
                                message: '상품이 성공적으로 주문되었습니다.',
                                backgroundColor: Colors.black,
                                textColor: Colors.white,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            )
          : Center(child: CircularProgressIndicator()),
    );
  }
}
