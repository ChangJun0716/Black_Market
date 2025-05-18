import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import '../../global.dart';

class StoreScheduledProduct extends StatefulWidget {
  const StoreScheduledProduct({super.key});

  @override
  State<StoreScheduledProduct> createState() => _StoreScheduledProductState();
}

class _StoreScheduledProductState extends State<StoreScheduledProduct> {
  final String? _storeCode = Get.arguments;

  DateTime? _selectedDate;
  List<Map<String, dynamic>> scheduledProducts = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (_storeCode != null && _storeCode!.isNotEmpty) {
      _selectedDate = DateTime.now();
      _fetchScheduledProducts(_selectedDate!, _storeCode!);
    } else {
      Get.snackbar(
        '오류',
        '대리점 정보를 가져오지 못했습니다. 홈 화면으로 돌아가주세요.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchScheduledProducts(_selectedDate!, _storeCode!);
    }
  }

  void _fetchScheduledProducts(DateTime date, String storeCode) async {
    setState(() {
      _isLoading = true;
      scheduledProducts.clear();
    });

    try {
      final String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final String apiUrl =
          "http://$globalip:8000/inhwan/store/scheduled-products/?date=$formattedDate&store_code=$storeCode";

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));

        if (responseData['result'] == 'OK' &&
            responseData.containsKey('results')) {
          List<dynamic> results = responseData['results'];
          List<Map<String, dynamic>> fetchedProducts =
              results.map((item) => item as Map<String, dynamic>).toList();

          setState(() {
            scheduledProducts = fetchedProducts;
            _isLoading = false;
          });
        } else {
          setState(() {
            scheduledProducts = [];
            _isLoading = false;
          });
          Get.snackbar(
            '알림',
            responseData['message'] ?? '입고 예정 제품 목록을 가져오는데 실패했습니다.',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
        }
      } else {
        setState(() {
          scheduledProducts = [];
          _isLoading = false;
        });
        Get.snackbar(
          '오류',
          '입고 예정 제품을 가져오는데 실패했습니다: 상태 코드 ${response.statusCode}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      setState(() {
        scheduledProducts = [];
        _isLoading = false;
      });
      Get.snackbar(
        '오류',
        '입고 예정 제품 로딩 중 오류 발생: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("입고 예정 제품"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () => _selectDate(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                textStyle: TextStyle(fontSize: 18),
              ),
              child: Text(
                _selectedDate == null
                    ? '날짜 선택'
                    : DateFormat('yyyy-MM-dd').format(_selectedDate!),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4.0,
                        horizontal: 8.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              '주문 번호',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '물건 ID',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              '색상',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              '사이즈',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              '수량',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '배송 상태',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey,
                    ), // 구분선 색상 추가
                    _isLoading // 로딩 상태에 따라 로딩 인디케이터 또는 목록 표시
                        ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ), // 중앙 정렬
                        )
                        : scheduledProducts.isEmpty &&
                            _selectedDate !=
                                null // 날짜 선택 후 데이터가 없을 때 메시지 표시
                        ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(
                            child: Text('해당 날짜에 입고 예정인 제품이 없습니다.'),
                          ), // 중앙 정렬
                        )
                        : Expanded(
                          child: ListView.builder(
                            itemCount: scheduledProducts.length,
                            itemBuilder: (context, index) {
                              final productData = scheduledProducts[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                  horizontal: 8.0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        productData['purchaseId']?.toString() ??
                                            '', // int일 수 있으므로 toString
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        productData['oproductCode']
                                                ?.toString() ??
                                            '', // int일 수 있으므로 toString
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        productData['productsColor'] ?? '',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        productData['productsSize']
                                                ?.toString() ??
                                            '', // int일 수 있으므로 toString
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        productData['purchaseQuanity']
                                                ?.toString() ??
                                            '', // int일 수 있으므로 toString
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        productData['purchaseDeliveryStatus'] ??
                                            '',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
