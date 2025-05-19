// 제품 상세
import 'dart:convert';
import 'package:black_market_app/global.dart';
import 'package:black_market_app/message/custom_snackbar.dart';
import 'package:black_market_app/utility/custom_button.dart';
import 'package:black_market_app/utility/custom_textfield.dart';
import 'package:black_market_app/view/customer/customer_select_store.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class CustomerProductDetail extends StatefulWidget {
  const CustomerProductDetail({super.key});

  @override
  State<CustomerProductDetail> createState() => _CustomerProductDetailState();
}

class _CustomerProductDetailState extends State<CustomerProductDetail> {
// ------------------------------- Property ------------------------------------ //
  final box = GetStorage();
  List data = []; // 선택한 제품과 이름이 같은 제품들의 List
  List<int> sizeList = []; // 제품 사이즈 List
  List<String> contentImageUrls = []; // url List
  late String productsName;
  late int productsCode;
  late String uid;
  String? selectedColor;
  late int selectedSize;
  late TextEditingController quantityCon;
  late DateTime now;
  late int selectedStore;
// ----------------------------------------------------------------------------- //
  @override
  void initState(){
    super.initState();
    final args = Get.arguments as Map;
    productsName = args['productsName'];
    productsCode = args['productsCode'];
    getJSONData();
    fetchContentImageUrls(productsCode);
    uid = box.read('uid') ?? '';
    quantityCon = TextEditingController();
    selectedStore = 9999999;
    now = DateTime.now();
  }
// ------------------------------------------------------------------------------ //
@override
void dispose() {
  quantityCon.dispose();
  super.dispose();
}
// ------------------------------------------------------------------------------ //
// ------------------------------- Functions ------------------------------------ //
// 1. 사용자가 선택한 제품의 상세보기 data 를 database 에서 가져오는 함수 (Image 제외!)
  getJSONData() async {
    var response = await http.get(
      Uri.parse(
        "http://$globalip:8000/changjun/select/selectedProduct?productsName=$productsName",
      ),
    );
    data.clear();
    sizeList.clear();
    data.addAll(json.decode(utf8.decode(response.bodyBytes))['results']);
    await addSizeList();
    // print(data);// --- 1
    // print(sizeList);// --- 2
    setState(() {});
  }
// ------------------------------------------------------------------------------ //
// 2. 1. 에서 불러온 data 들의 size 만 List 에 모으는 함수
addSizeList(){
  for (int i = 0; i < data.length; i++) {
    sizeList.add(data[i]['productsSize']);
    selectedSize = sizeList[0];
  }
}
// ------------------------------------------------------------------------------ //
// 3. 선택된 제품의 소개글 에서 Image 의 갯수에 따라 index 를 메긴 url 을 넘겨주는 함수
fetchContentImageUrls(int productsCode) async {
  var response = await http.get(Uri.parse(
      'http://$globalip:8000/changjun/select/products/contentImageUrls/$productsCode'));

  if (response.statusCode == 200) {
    var data = json.decode(utf8.decode(response.bodyBytes));
    List<String> imageUrls = List<String>.from(data['contentImages']);
    contentImageUrls = imageUrls.map((url) => "$url?t=${DateTime.now().microsecondsSinceEpoch}").toList();
    print("Fetching content image URLs for productCode: $productsCode");
    print("Received image URLs: $contentImageUrls");
    setState(() {});
  }
}
// ------------------------------------------------------------------------------ //
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('제품 상세'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: data.isEmpty
      ? Center(child: Text('데이터가 없습니다.'),)
      : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
// 제품 이미지
            Image.network("http://$globalip:8000/changjun/select/selectedProduct/image/$productsName?t=${DateTime.now().microsecondsSinceEpoch}",
            width: MediaQuery.of(context).size.width,
            height: 200,
            ),
// 제품 명
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('제품명: ${data[0]['productsName']}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold
              ),
              ),
            ),
// 제품 가격
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 15, 20, 15),
                  child: Text("가격: ${data[0]['productsPrice']}원",
                  style: TextStyle(
                    fontWeight: FontWeight.bold
                  ),
                  ),
                ),
// 제품 사이즈 : dropdownButton
            DropdownButton<int>(
              value: selectedSize,
              icon: Icon(Icons.keyboard_arrow_down),
              items: sizeList.map((size){
                return DropdownMenuItem<int>(
                  value: size,
                  child: Text('$size')
                );
              }
            ).toList(),
              onChanged:(value) {
                selectedSize = value!;
                setState(() {});
              },
            ),
              ],
            ),
// // 제품 소개 이미지
SizedBox(
  height: 300,
  child: ListView.builder(
    itemCount: contentImageUrls.length,
    itemBuilder: (context, index) {
      return Image.network(
        'http://$globalip:8000/changjun/select/selectedProducts/contentBlock/$productsCode/$index',
        width: 200,
        height: 200,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.broken_image),
      );
    },
  ),
),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomButton(
                  text: '픽업 대리점 선택',
                  onPressed:
                      () => Get.to(CustomerSelectStore())!.then((value) {
                        value == null
                        ? selectedStore = 9999999
                        : selectedStore = value;
                        // print('넘겨 받은 code : $selectedStore');
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
// button : 장바구니 담기
                  child: CustomButton(
                    text: '장바구니 담기',
                    onPressed: () async {
                      if (selectedStore == 9999999 ||
                          quantityCon.text.trim().isEmpty) {
                        CustomSnackbar().showSnackbar(
                          title: '오류',
                          message: '선택하지 않은 항목이 있습니다.',
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                        );
                        return;
                      }
// 장바구니 담기 action
                      insertAction(int.parse(data[0]['productsPrice']), '장바구니');
                    },
                  ),
                ),
// button : 주문하기
                CustomButton(
                  text: '주문하기',
                  onPressed: () async {
                    if (selectedStore == 9999999 ||
                        quantityCon.text.trim().isEmpty) {
                      CustomSnackbar().showSnackbar(
                        title: '오류',
                        message: '선택하지 않은 항목이 있습니다.',
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                      );
                      return;
                    }
                    insertAction(int.parse(data[0]['productsPrice']), '주문완료');
                  },
                ),
              ],
            ),
          ],
        ),
      )
    );
  }// build
// ------------------------------------------------------------------- //
// multipart 는 큰 데이터를 사용 할 때 사용하며 퍼포먼스가 좋다!
// String 과 image 를 함께 보내기 때문에 MultipartRequest 를 사용한다!
insertAction(int productsPrice, String status)async{
  var request = http.MultipartRequest(
    "POST",      // get 방식 이라면 get 이 쓰인다.
    Uri.parse("http://$globalip:8000/changjun/insert/purchase")
  );
  request.fields['users_userid'] = uid;
  request.fields['purchasePrice'] = (productsPrice*int.parse(quantityCon.text)).toString();
  request.fields['PurchaseQuanity'] = quantityCon.text;
  request.fields['PurchaseDate'] = now.toString();
  request.fields['PurchaseDeliveryStatus'] = status;
  request.fields['products_productsCode'] = productsCode.toString();
  request.fields['store_storeCode'] = selectedStore.toString();
  var res = await request.send();
  if(res.statusCode == 200){
    _showDialog();
  } else{
    errorSnackBar();
  }
}
// ------------------------------------------------------------------- //
_showDialog(){
  Get.defaultDialog(
    title: "입력 결과",
    middleText: "입력이 완료 되었습니다.",
    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
    barrierDismissible: false,
    actions: [
      TextButton(
        onPressed: () {
          Get.back();
          Get.back();
        }, 
        child: Text('OK')
      ),
    ]
  );
}
// ------------------------------------------------------------------- //
errorSnackBar(){
  Get.snackbar(
    'Error', 
    '입력시 문제가 발생 했습니다.',
    duration: Duration(seconds: 2)
  );
}
// ------------------------------------------------------------------- //
}// class
