//출고페이지 - 2팀 팀원 : 김수아 개발 
//목적 : 
//있는 재고 안에서만 재고를 출고 할 수 있다.
//개발일지
//2025_05_18
//sqlite로 구현 헀던 핸드러를 빼고 mysql 파이썬 서버로 바꾸기 
//파이썬으로 받으면서 sql문을 try로 감쌌다 아님 화면 들어가다가 튕김 
//global ip로 설정 바꿈 
import 'dart:convert';

import 'package:black_market_app/global.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;


class CompanyProductDelivery extends StatefulWidget {
  const CompanyProductDelivery({super.key});

  @override
  State<CompanyProductDelivery> createState() => _CompanyProductDeliveryState();
}

class _CompanyProductDeliveryState extends State<CompanyProductDelivery> {
  late Map<String, dynamic> selectedItem;
  //출고 수량
  final TextEditingController quantityController = TextEditingController();
  final box = GetStorage();
  //아아디
  late String userId;
  int currentStock = 0;
  //대리점 리스트
  List<Map<String, dynamic>> storeList = [];
  //선택 대리점
  Map<String, dynamic>? selectedStore;
  //주문자 정보
  List<Map<String, dynamic>> pendingOrders = [];
  //드롭다운에 쓸꺼 
  int? selectedOrderId;
  String? selectedCustomer;
  int? selectedQuantity;

  @override
  void initState() {
    super.initState();
    selectedItem = Map<String, dynamic>.from(Get.arguments);
    userId = box.read('uid') ?? '';
    loadStores();
    _loadStock();
  }
  //대리점 검색
  loadStores() async {
    try {
      final response = await http.get(Uri.parse('http://$globalip:8000/kimsua/select/store'));
      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          storeList = List<Map<String, dynamic>>.from(decoded['result']);
        });
      }
    } catch (e) {
      print("Error: $e");
    }
  }
  //선택 대리점의 주문완료건 검색해줌
  loadPendingOrders(int storeCode) async {
    try {
      final response = await http.post(
        Uri.parse("http://$globalip:8000/kimsua/select/Purchase/store"),
        body: {
          'store_storeCode': storeCode.toString(),
          'products_productsCode': selectedItem['productsCode'].toString(),
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        final result = decoded['result'];

        if (result is List) {
          setState(() {
            pendingOrders = List<Map<String, dynamic>>.from(result);
            selectedOrderId = pendingOrders.isNotEmpty ? pendingOrders.first['purchaseId'] : null;
            selectedCustomer = pendingOrders.isNotEmpty ? pendingOrders.first['users_userid'] : null;
            selectedQuantity = pendingOrders.isNotEmpty ? pendingOrders.first['PurchaseQuanity'] : null;
          });
        }
      } else {
        print("서버 응답 실패: ${response.statusCode}");
      }
    } catch (e, stack) {
      debugPrint("❌ 주문 목록 로딩 오류: $e");
      debugPrint("📌 StackTrace: $stack");
    }
  }
  //재고 검색 
  _loadStock() async {
    try {
      final response = await http.post(
        Uri.parse("http://$globalip:8000/kimsua/select/currentStock"),
        body: {'productsCode': selectedItem['productsCode'].toString()},
      );

      if (response.statusCode == 200) {
        final jsonRes = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          currentStock = int.tryParse(jsonRes['result'].toString()) ?? 0;
        });
      }
    } catch (e) {
      print(e);
    }
  }
  //넣기
  submitDispatch() async {
    final qty = int.tryParse(quantityController.text);;
    if (qty == null || qty <= 0 || selectedStore == null || selectedOrderId == null || selectedQuantity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('수량, 대리점, 주문 ID를 모두 정확히 입력해주세요.')),
      );
      return;
    }
    if (qty > currentStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('출고 수량이 재고($currentStock)를 초과했습니다.')),
      );
      return;
    }
    if (qty > selectedQuantity!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('출고 수량이 주문 수량(${selectedQuantity!})을 초과했습니다.')),
      );
      return;
    }
     try {
        var request = http.MultipartRequest(
          "POST",
          Uri.parse("http://$globalip:8000/kimsua/insert/products/dispatch"),
        );
        request.fields['dispatchedQuantity'] = quantityController.text.trim();
        request.fields['dispatchDate'] = DateTime.now().toString();
        request.fields['users_userid'] = userId;
        request.fields['Purchase_purchaseId'] =  selectedOrderId.toString();
        request.fields['Purchase_users_userid'] =  selectedCustomer.toString();
        request.fields['Purchase_store_storeCode'] = selectedStore!['storeCode'].toString();
        request.fields['Purchase_products_productsCode'] = selectedItem['productsCode'].toString();

        var res = await request.send();
        if (res.statusCode == 200) {
          updatestate();
         ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('출고 처리가 완료되었습니다.')),
      
    );
    Get.back();
        } else {
          errorSnackBar();
        }
      } catch (e) {
        print(e);
        errorSnackBar();
      }
    
  }
   errorSnackBar() {
    Get.snackbar(
      'Error',
      '출고시 문제가 발생했습니다.',
      duration: Duration(seconds: 2),
    );
  }
  @override
  void dispose() {
    quantityController.dispose();
    super.dispose();
  }
  updatestate()async{
    await http.post(
        Uri.parse("http://$globalip:8000/kimsua/update/Purchase/state"),
        body: {'purchaseId': selectedOrderId.toString()},
      );
   
  }
//----------------------Ui 시작 --------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("출고 페이지"),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: Colors.grey[900],
              child: ListTile(
                title: Text(
                  '${selectedItem['productsName']} (ID: ${selectedItem['productsCode']})',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '컬러: ${selectedItem['productsColor']} / 사이즈: ${selectedItem['productsSize']} / 재고: $currentStock',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Map<String, dynamic>>(
              style: const TextStyle(color: Colors.pink),
              value: selectedStore,
              hint: const Text('대리점 선택'),
              items: storeList.map((store) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: store,
                  child: Text('${store['storeName']} (${store['storeCode']})'),
                );
              }).toList(),
              onChanged: (Map<String, dynamic>? newValue) {
                setState(() {
                  selectedStore = newValue;
                  selectedOrderId = null;
                  selectedCustomer = null;
                  selectedQuantity = null;
                  pendingOrders.clear();
                });
                if (newValue != null) {
                  loadPendingOrders(newValue['storeCode']);
                }
              },
              validator: (value) => value == null ? '대리점을 선택해 주세요' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: selectedOrderId,
              items: pendingOrders.map((order) => DropdownMenuItem<int>(
                value: order['purchaseId'],
                child: Text('ID: ${order['purchaseId']} / 수량: ${order['PurchaseQuanity']} / 고객: ${order['users_userid']}'),
              )).toList(),
              onChanged: (value) async {
                setState(() {
                  selectedOrderId = value;
                  final match = pendingOrders.firstWhere((e) => e['purchaseId'] == value);
                  selectedCustomer = match['users_userid'];
                  selectedQuantity = match['PurchaseQuanity'];
                });
              },
              decoration: const InputDecoration(
                labelText: '주문 선택',
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(),
              ),
              dropdownColor: Colors.black,
              style: const TextStyle(color: Colors.white),
            ),
            if (selectedQuantity != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  '주문 수량: ${selectedQuantity ?? '-'} / 고객 ID: ${selectedCustomer ?? '-'}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '출고 수량 입력',
                hintStyle: TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: submitDispatch,
                child: const Text('출고하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
