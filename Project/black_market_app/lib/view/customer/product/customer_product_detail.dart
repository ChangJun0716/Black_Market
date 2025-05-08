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
  late int selectedStore;
  bool isReady = false;

  @override
  void initState() {
    super.initState();
    if (Get.arguments == null) {
    CustomSnackbar().showSnackbar(
      title: '에러',
      message: '제품명이 전달되지 않았습니다.',
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
    Get.back();
    return;
  }
    productsName = Get.arguments ?? '__';
    uid = '';
    handler = DatabaseHandler();
    quantityCon = TextEditingController();
    now = DateTime.now();
    selectedStore = 0;
    initStorage();
  }

  // ------- functions ------- //
  initStorage() async {
    uid = await box.read('uid');
    isReady = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('제품 상세')),
      body:
          isReady
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

                  final colors =
                      items
                          .map((e) => e['productsColor'] as String)
                          .toSet()
                          .toList();
                  final sizes =
                      items
                          .map((e) => e['productsSize'] as int)
                          .toSet()
                          .toList();

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
                        if (selected['productsImage'] != null)
                          Image.memory(selected['productsImage']),
                        Text(selected['productsName']),
                        Text("가격: ${selected['productsPrice']}원"),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            DropdownButton<String>(
                              value: selectedColor,
                              items:
                                  colors
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (val) => setState(() => selectedColor = val),
                            ),
                            SizedBox(width: 10),
                            DropdownButton<int>(
                              value: selectedSize,
                              items:
                                  sizes
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e.toString()),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (val) => setState(() => selectedSize = val),
                            ),
                          ],
                        ),
                        if (selected['introductionPhoto'] != null)
                          Image.memory(selected['introductionPhoto']),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomButton(
                              text: '픽업 대리점 선택',
                              onPressed:
                                  () => Get.to(CustomerSelectStore())!.then((
                                    value,
                                  ) {
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
                        CustomButton(
                          text: '장바구니 담기',
                          onPressed: () async {
                            if (selectedStore == 0 ||
                                quantityCon.text.trim().isEmpty) {
                              CustomSnackbar().showSnackbar(
                                title: '오류',
                                message: '선택하지 않은 항목이 있습니다.',
                                backgroundColor: Colors.red,
                                textColor: Colors.white,
                              );
                            } else {
                              await handler.addShopingCart(
                                Purchase(
                                  purchaseDate: now.toString(),
                                  purchaseQuanity: int.parse(quantityCon.text),
                                  pUserId: uid,
                                  pStoreCode: selectedStore.toString(),
                                  purchaseDeliveryStatus: '장바구니',
                                  oproductCode: selected['oproductCode'],
                                  purchasePrice:
                                      selected['purchasePrice'] *
                                      int.parse(quantityCon.text),
                                ),
                              );
                            }
                          },
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
