// 장바구니
import 'dart:convert';
import 'package:black_market_app/global.dart';
import 'package:black_market_app/message/custom_dialogue.dart';
import 'package:black_market_app/vm/database_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class CustomerShoppingCartList extends StatefulWidget {
  const CustomerShoppingCartList({super.key});

  @override
  State<CustomerShoppingCartList> createState() =>
      _CustomerShoppingCartListState();
}

class _CustomerShoppingCartListState extends State<CustomerShoppingCartList> {
// ------------------------------- Property ------------------------------------ //
  late DatabaseHandler handler;
  final box = GetStorage();
  late String uid;
  bool isReady = false;
  List data = [];
// ------------------------------------------------------------------------------ //
  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    initStorage();
    getJSONData();
  }
// ------------------------------- Functions ------------------------------------ //
// 1. 사용자가 제품 상세보기 페이지에서 장바구니에 담은 list 의 data 를 불러온다.
getJSONData()async{
var response = await http.get(Uri.parse("http://$globalip:8000/changjun/select/shoppingCart/?userid=$uid"));
  data.clear();
  data.addAll(json.decode(utf8.decode(response.bodyBytes))['results']);
  setState(() {});
}
// ------------------------------------------------------------------------------ //
// 2. 로그인 시 write 된 box 의 data 중 userId 를 읽어오는 함수
  initStorage() {
    uid = box.read('uid');
    isReady = true;
    setState(() {});
  }
// ------------------------------------------------------------------------------ //

  Future<void> deleteCartItem(int purchaseId) async {
    await handler.deletePurchaseItem(purchaseId); // DB에서 삭제
    setState(() {});
  }

  // ------------------------- //
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('장바구니'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: data.isEmpty
      ? Text('데이터가 없습니다.', textAlign: TextAlign.center)
      : ListView.builder( 
              itemCount: data.length,
              itemBuilder: (context, index) {
                return Slidable(
                  endActionPane: ActionPane(
                    motion: const DrawerMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (context) {
                          Get.dialog(
                            AlertDialog(
                              title: const Text('삭제 확인'),
                              content: const Text('정말로 장바구니에서 삭제하시겠습니까?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(), // 취소
                                  child: const Text('취소'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await deleteAction(data[index]['purchaseId']);
                                    Get.back(); // 다이얼로그 닫기
                                  },
                                  child: const Text(
                                    '삭제',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                        label: '삭제',
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: () {
                      creditDialogue(
                        data[index]['productsName'],
                        data[index]['PurchaseQuanity'],
                        data[index]['purchasePrice'],
                        data[index]['storeName'],
                        data[index]['purchaseId'],
                      );
                    },
                    child: Card(
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.network("http://$globalip:8000/changjun/select/shoppingCart/image/${data[index]['productsCode']}?t=${DateTime.now().microsecondsSinceEpoch}",
                            width: 80,
                            height: 80,
                            )
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '제품명 : ${data[index]['productsName']}',
                              ),
                              Text(
                                '수량    : ${data[index]['PurchaseQuanity']} 개',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
    );
  } // build

// ------------------------------------------------------------------- //
deleteAction(int seq){
  getJSONDataDelete(seq);
  getJSONData();
  setState(() {});
}
// ------------------------------------------------------------------- //
getJSONDataDelete(int seq)async{
  var response = await http.delete(Uri.parse("http://$globalip:8000/changjun/delete/purchase/$seq"));
  var result = json.decode(utf8.decode(response.bodyBytes))['result'];
  if (result != "OK"){
    errorSnackBar();
  }
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
  creditDialogue(
    String productName,
    int quantity,
    int price,
    String storeName,
    int purchaseId,
  ) {
    CustomDialogue().showDialogue(
      title: '구매 진행',
      middleText: '''
      선택하신 상품은 $productName 이며
      $quantity 개, 가격은 $price 원 입니다.
      픽업 장소 : $storeName 으로 주문 하시겠습니까? 
      ''',
      cancelText: '취소',
      onCancel: () => Get.back(),
      confirmText: '구매요청',
      onConfirm: () async {
        await updatePurchaseStatus(purchaseId);
        Get.back();
      },
    );
  }
// ------------------------------------------------------------------- //
updatePurchaseStatus(int purchaseId) async {
  final url = Uri.parse('http://$globalip:8000/changjun/update/Purchase');

  try {
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: {
        'purchaseId': purchaseId.toString(),
      },
    );

    if (response.statusCode == 200) {
      await getJSONData(); // 업데이트 성공 후 데이터 다시 로드
      _showDialog();
    } else {
      print('Failed: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('Error occurred: $e');
  }
}
// ------------------------------------------------------------------- //
_showDialog(){
  Get.defaultDialog(
    title: "수정 결과",
    middleText: "수정이 완료 되었습니다.",
    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
    barrierDismissible: false,
    actions: [
      TextButton(
        onPressed: () {
          Get.back();
        }, 
        child: Text('OK')
      ),
    ]
  );
}
  // ----------------------------------- //
} // class
