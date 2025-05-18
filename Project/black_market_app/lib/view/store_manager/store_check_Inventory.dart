import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import '../../global.dart';

class StoreCheckInventory extends StatefulWidget {
  const StoreCheckInventory({super.key});

  @override
  State<StoreCheckInventory> createState() => _StoreCheckInventoryState();
}

class _StoreCheckInventoryState extends State<StoreCheckInventory> {
  final GetStorage _box = GetStorage();

  final String? _storeCode = Get.arguments;
  String? _loggedInUserId;

  DateTime? _startDate;
  DateTime? _endDate;
  List<Map<String, dynamic>> inventoryList = [];
  int _totalQuantity = 0;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loggedInUserId = _box.read('uid');

    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 7));

    if (_loggedInUserId != null && _loggedInUserId!.isNotEmpty) {
      _fetchInventory(_startDate!, _endDate!, _loggedInUserId!);
    } else {
      Get.snackbar(
        '오류',
        '사용자 정보를 가져오지 못했습니다. 홈 화면으로 돌아가주세요.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _selectDate(
    BuildContext context, {
    required bool isStartDate,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          isStartDate
              ? (_startDate ?? DateTime.now())
              : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_startDate != null && _startDate!.isAfter(_endDate!)) {
            _startDate = _endDate;
          }
        }
      });
      if (_startDate != null && _endDate != null) {
        final DateTime adjustedEndDate = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
          23,
          59,
          59,
        );
        _fetchInventory(_startDate!, adjustedEndDate, _loggedInUserId!);
      }
    }
  }

  void _fetchInventory(
    DateTime startDate,
    DateTime endDate,
    String userId,
  ) async {
    setState(() {
      _isLoading = true;
      inventoryList.clear();
      _totalQuantity = 0;
    });

    try {
      final String formattedStartDate = DateFormat(
        'yyyy-MM-dd',
      ).format(startDate);
      final String formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate);

      final String apiUrl =
          "http://$globalip:8000/inhwan/store/inventory/?start_date=$formattedStartDate&end_date=$formattedEndDate&user_id=$userId";

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));

        if (responseData['result'] == 'OK' &&
            responseData.containsKey('results')) {
          List<dynamic> results = responseData['results'];
          List<Map<String, dynamic>> fetchedInventory =
              results.map((item) => item as Map<String, dynamic>).toList();

          int calculatedTotalQuantity = 0;
          for (var item in fetchedInventory) {
            calculatedTotalQuantity += (item['receivedQuantity'] as int? ?? 0);
          }

          setState(() {
            inventoryList = fetchedInventory;
            _totalQuantity = calculatedTotalQuantity;
            _isLoading = false;
          });
        } else {
          setState(() {
            inventoryList = [];
            _totalQuantity = 0;
            _isLoading = false;
          });
          Get.snackbar(
            '알림',
            responseData['message'] ?? '매장 재고 현황을 가져오는데 실패했습니다.',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
        }
      } else {
        setState(() {
          inventoryList = [];
          _totalQuantity = 0;
          _isLoading = false;
        });
        Get.snackbar(
          '오류',
          '매장 재고 현황을 가져오는데 실패했습니다: 상태 코드 ${response.statusCode}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      setState(() {
        inventoryList = [];
        _totalQuantity = 0;
        _isLoading = false;
      });
      Get.snackbar(
        '오류',
        '매장 재고 현황 로딩 중 오류 발생: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("매장 재고 확인"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _selectDate(context, isStartDate: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 15,
                      ),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                    child: Text(
                      _startDate == null
                          ? '시작일 선택'
                          : DateFormat('yyyy-MM-dd').format(_startDate!),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _selectDate(context, isStartDate: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 15,
                      ),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                    child: Text(
                      _endDate == null
                          ? '종료일 선택'
                          : DateFormat('yyyy-MM-dd').format(_endDate!),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                '총 입고 수량: ${_totalQuantity}개',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 8),
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
                            flex: 3,
                            child: Text(
                              '제품 이름',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
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
                            flex: 2,
                            child: Text(
                              '수량',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, thickness: 1, color: Colors.grey),
                    _isLoading
                        ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                        : inventoryList.isEmpty &&
                            _startDate != null &&
                            _endDate != null
                        ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: Text('해당 기간에 입고된 제품이 없습니다.')),
                        )
                        : Expanded(
                          child: ListView.builder(
                            itemCount: inventoryList.length,
                            itemBuilder: (context, index) {
                              final inventoryItem = inventoryList[index];
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
                                      flex: 3,
                                      child: Text(
                                        inventoryItem['productsName'] ?? '',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        inventoryItem['productsColor'] ?? '',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        inventoryItem['productsSize']
                                                ?.toString() ??
                                            '',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        inventoryItem['receivedQuantity']
                                                ?.toString() ??
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
