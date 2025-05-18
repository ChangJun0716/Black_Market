import 'package:black_market_app/view/store_manager/return/store_return_list.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../global.dart';
import '../login/login.dart';
import 'store_scheduled_product.dart';
import 'store_product_condition.dart';
import 'store_check_inventory.dart';

class StoreHome extends StatefulWidget {
  const StoreHome({super.key});

  @override
  State<StoreHome> createState() => _StoreHomeState();
}

class _StoreHomeState extends State<StoreHome> {
  final GetStorage _box = GetStorage();

  String? _loggedInUserId;
  int? _loggedInUserType;
  String? _loggedInStoreCode;
  String _loggedInStoreName = "매장 정보 로딩 중...";

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  void _loadUserInfo() async {
    _loggedInUserId = _box.read('uid');
    _loggedInUserType = _box.read('memberType');

    if (_loggedInUserId != null && _loggedInUserId!.isNotEmpty) {
      _fetchStoreInfo(_loggedInUserId!);
    } else {
      setState(() {
        _loggedInStoreName = "사용자 정보 오류";
      });
      Get.snackbar(
        '오류',
        '사용자 로그인 정보를 찾을 수 없습니다. 다시 로그인해주세요.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _fetchStoreInfo(String userId) async {
    setState(() {
      _loggedInStoreName = "매장 정보 로딩 중...";
    });
    try {
      final String apiUrl = "http://$globalip:8000/inhwan/users/$userId/store";
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        final storeInfo = responseData['storeInfo'];
        final String fetchedStoreCode = storeInfo['storeCode'];
        final String fetchedStoreName = storeInfo['storeName'];

        setState(() {
          _loggedInStoreCode = fetchedStoreCode;
          _loggedInStoreName = fetchedStoreName;
          _box.write('loggedInStoreCode', _loggedInStoreCode);
        });
      } else {
        setState(() {
          _loggedInStoreCode = null;
          _loggedInStoreName = "정보 로딩 실패";
        });
        Get.snackbar(
          '오류',
          '대리점 정보를 가져오는데 실패했습니다: 상태 코드 ${response.statusCode}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      setState(() {
        _loggedInStoreCode = null;
        _loggedInStoreName = "로딩 중 오류 발생";
      });
      Get.snackbar(
        '오류',
        '대리점 정보 로딩 중 오류 발생: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_loggedInStoreName),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              _box.remove('uid');
              _box.remove('memberType');
              _box.remove('loggedInStoreCode');
              Get.offAll(() => Login());
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                '$_loggedInStoreName 관리 페이지',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: _buildMenuButton(
                            text: '입고 예정\n제품 확인',
                            onPressed:
                                _loggedInStoreCode != null
                                    ? () {
                                      Get.to(
                                        () => StoreScheduledProduct(),
                                        arguments: _loggedInStoreCode,
                                      );
                                    }
                                    : null,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: _buildMenuButton(
                            text: '매장 재고\n현황',
                            onPressed:
                                _loggedInStoreCode != null
                                    ? () {
                                      Get.to(
                                        () => StoreCheckInventory(),
                                        arguments: _loggedInStoreCode,
                                      );
                                    }
                                    : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: _buildMenuButton(
                            text: '픽업 대기\n목록',
                            onPressed:
                                _loggedInStoreCode != null
                                    ? () {
                                      Get.to(
                                        () => StoreProductCondition(),
                                        arguments: _loggedInStoreCode,
                                      );
                                    }
                                    : null,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: _buildMenuButton(
                            text: '매장 반품\n목록',
                            onPressed:
                                _loggedInStoreCode != null
                                    ? () {
                                      Get.to(
                                        () => StoreReturnList(),
                                        arguments: {
                                          'storeCode': _loggedInStoreCode,
                                          'userId': _loggedInUserId,
                                        },
                                      );
                                    }
                                    : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton({required String text, VoidCallback? onPressed}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: EdgeInsets.symmetric(vertical: 20),
      ),
      onPressed: onPressed,
      child: Text(text, textAlign: TextAlign.center),
    );
  }
}
