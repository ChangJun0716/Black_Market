import 'package:black_market_app/global.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'store_return_application.dart';

class StoreReturnList extends StatefulWidget {
  const StoreReturnList({super.key});

  @override
  State<StoreReturnList> createState() => _StoreReturnListState();
}

class _StoreReturnListState extends State<StoreReturnList> {
  final Map<String, dynamic>? _arguments = Get.arguments;

  String? _loggedInUserId;
  String? _loggedInStoreCode;

  DateTime? _selectedDate;
  List<Map<String, dynamic>> returnList = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _loggedInUserId = _arguments?['userId'] as String?;
    _loggedInStoreCode = _arguments?['storeCode'] as String?;

    if (_loggedInUserId != null && _loggedInUserId!.isNotEmpty) {
      _selectedDate = DateTime.now();
      _fetchReturns(_selectedDate!, _loggedInUserId!);
    } else {
      Get.snackbar(
        '오류',
        '사용자 정보를 가져오지 못했습니다. 홈 화면으로 돌아가주세요.',
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
      _fetchReturns(_selectedDate!, _loggedInUserId!);
    }
  }

  void _fetchReturns(DateTime date, String userId) async {
    setState(() {
      _isLoading = true;
      returnList.clear();
    });

    try {
      final String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final String apiUrl =
          "http://$globalip:8000/inhwan/store/returns/?date=$formattedDate&user_id=$userId";

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));

        if (responseData['result'] == 'OK' &&
            responseData.containsKey('results')) {
          List<dynamic> results = responseData['results'];

          List<Map<String, dynamic>> fetchedReturns =
              results.map((item) => item as Map<String, dynamic>).toList();

          setState(() {
            returnList = fetchedReturns;
            _isLoading = false;
          });
        } else {
          setState(() {
            returnList = [];
            _isLoading = false;
          });
          Get.snackbar(
            '알림',
            responseData['message'] ?? '매장 반품 목록을 가져오는데 실패했습니다.',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
        }
      } else {
        setState(() {
          returnList = [];
          _isLoading = false;
        });
        Get.snackbar(
          '오류',
          '매장 반품 목록을 가져오는데 실패했습니다: 상태 코드 ${response.statusCode}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      setState(() {
        returnList = [];
        _isLoading = false;
      });
      Get.snackbar(
        '오류',
        '매장 반품 목록 로딩 중 오류 발생: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("매장 반품 목록"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _selectDate(context),
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
                      _selectedDate == null
                          ? '날짜 선택'
                          : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed:
                        (_loggedInUserId != null &&
                                _loggedInUserId!.isNotEmpty &&
                                _loggedInStoreCode != null &&
                                _loggedInStoreCode!.isNotEmpty)
                            ? () {
                              Get.to(
                                () => StoreReturnApplication(),
                                arguments: {
                                  'userId': _loggedInUserId,
                                  'storeCode': _loggedInStoreCode,
                                },
                              );
                            }
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 15,
                      ),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                    child: const Text('반품 신청'),
                  ),
                ),
              ],
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
                              '반품 코드',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '반품 날짜',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '처리 상태',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              '반품 사유',
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
                        : returnList.isEmpty && _selectedDate != null
                        ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: Text('해당 날짜에 반품 기록이 없습니다.')),
                        )
                        : Expanded(
                          child: ListView.builder(
                            itemCount: returnList.length,
                            itemBuilder: (context, index) {
                              final returnItem = returnList[index];
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
                                        returnItem['returnCode']?.toString() ??
                                            '',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        returnItem['returnDate'] ?? '',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        returnItem['processionStatus'] ?? '',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        returnItem['returnReason'] ?? '',
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
