// 제품 상세
import 'package:black_market_app/message/custom_dialogue.dart';
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

  @override
  void initState() {
    super.initState();
    initStorage();
    uid = '';
    handler = DatabaseHandler();
    productsName = Get.arguments ?? '__';
    quantityCon = TextEditingController();
    now = DateTime.now();
    selectedStore = 0;
    
  }

  // ------- functions ------- //
  initStorage() async {
    uid = await box.read('uid');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('제품 상세')),
      body: FutureBuilder(
        future: handler.querySelectedProducts(productsName),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final products = snapshot.data!;
            final representative = products.first; // 대표 데이터
            final colors =
                products.map((p) => p.productsColor).toSet().toList();
            final sizes = products.map((p) => p.productsSize).toSet().toList();
            selectedColor ??= colors.first;
            selectedSize ??= sizes.first;

            return Center(
              child: Column(
                children: [
                  // image : product
                  Image.memory(representative.productsImage),
                  // name : product
                  Text(representative.productsName),
                  // price : product
                  Text("가격 : ${representative.productsPrice} 원"),
                  Row(
                    children: [
                      // dropdown button : color
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
                        onChanged: (value) {
                          selectedColor = value;
                          setState(() {});
                        },
                      ),
                      // dropdown button : size
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
                        onChanged: (value) {
                          selectedSize = value;
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  // textfield : 수량 작성
                  CustomTextField(label: '수량을 입력 하세요', controller: quantityCon),
                  // button : 대리점 선택 페이지로 이동
                  CustomButton(
                    text: '픽업 대리점 선택',
                    onPressed: () => Get.to(CustomerSelectStore()),
                  ),
                  CustomButton(text: '장바구니 담기', onPressed: () {
                    if (
                      selectedStore == 0 ||
                      quantityCon.text.trim().isEmpty
                    ) {
                      CustomSnackbar().showSnackbar(title: '오류', message: '선택하지 않은 항목이 있습니다.', backgroundColor: Colors.red, textColor: Colors.white);
                    }else {
                      addShopingCart(representative.productsPrice);
                    }
                  },)
                ],
              ),
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }// build
  // ----- functions ----- //
  addShopingCart(int price)async{
    var insertPurchase  = Purchase(
      purchaseId: purchaseId, // AI 하는건지
      purchaseDate: now.toString(), 
      purchaseQuanity: int.parse(quantityCon.text), 
      purchaseCardId: purchaseCardId, // AI 하는건지
      pStoreCode: selectedStore.toString(), 
      purchaseDeliveryStatus: '장바구니', 
      oproductCode: uid, 
      purchasePrice: int.parse(quantityCon.text)*price
    );
    
      CustomDialogue().showDialogue(
        title: '장바구니 담기', 
        middleText: '선택하신 제품을 장바구니에 담으시겠습니까?',
        cancelText: '취소',
        onCancel: () => Get.back(),
        confirmText: '담기',
        onConfirm: () async{
          int result = await handler.addShopingCart(insertPurchase);
          if (result == 0) {
            CustomSnackbar().showSnackbar(title: '오류', message: '장바구니 등록에 실패 하였습니다.', backgroundColor: Colors.red, textColor: Colors.white);
          }
          Get.back();
          Get.back();
        },
      );
  }
}// class
