import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import '../../global.dart';

class PickupOrderState {
  final Map<String, dynamic> orderData;
  String currentStatus;
  late final String originalStatus;

  PickupOrderState({required this.orderData, required this.currentStatus})
    : originalStatus = currentStatus;
}

class StoreProductCondition extends StatefulWidget {
  const StoreProductCondition({super.key});

  @override
  State<StoreProductCondition> createState() => _StoreProductConditionState();
}

class _StoreProductConditionState extends State<StoreProductCondition> {
  final TextEditingController _searchController = TextEditingController();
  List<PickupOrderState> allPickupOrders = [];
  List<PickupOrderState> filteredPickupOrders = [];

  final String? _loggedInStoreCode = Get.arguments;

  final List<String> _deliveryStatuses = [
    'Ready for Pickup',
    'Picked Up',
    'Cancelled',
  ];

  bool _isLoading = false; // 데이터 로딩 상태만 관리

  @override
  void initState() {
    super.initState();
    if (_loggedInStoreCode != null && _loggedInStoreCode!.isNotEmpty) {
      _fetchPickupOrders();
    } else {
      Get.snackbar(
        '오류',
        '대리점 정보를 가져오지 못했습니다. 홈 화면으로 돌아가주세요.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }

    _searchController.addListener(_filterOrders);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterOrders);
    _searchController.dispose();
    super.dispose();
  }

  void _fetchPickupOrders() async {
    if (_loggedInStoreCode == null) {
      setState(() {
        allPickupOrders = [];
        filteredPickupOrders = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      allPickupOrders.clear();
      filteredPickupOrders.clear();
    });

    try {
      final String apiUrl =
          "http://$globalip:8000/inhwan/store/pickup-ready-orders/?store_code=$_loggedInStoreCode";

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));

        if (responseData['result'] == 'OK' &&
            responseData.containsKey('results')) {
          List<dynamic> results = responseData['results'];

          List<PickupOrderState> fetchedOrders =
              results.map((item) {
                final currentStatus =
                    item['purchaseDeliveryStatus'] as String? ?? '';
                return PickupOrderState(
                  orderData: item as Map<String, dynamic>,
                  currentStatus: currentStatus,
                );
              }).toList();

          setState(() {
            allPickupOrders = fetchedOrders;
            filteredPickupOrders = List.from(allPickupOrders);
            _isLoading = false;
          });
        } else {
          setState(() {
            allPickupOrders = [];
            filteredPickupOrders = [];
            _isLoading = false;
          });
          Get.snackbar(
            '알림',
            responseData['message'] ?? '픽업 대기 목록을 가져오는데 실패했습니다.',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
        }
      } else {
        setState(() {
          allPickupOrders = [];
          filteredPickupOrders = [];
          _isLoading = false;
        });
        Get.snackbar(
          '오류',
          '픽업 대기 목록을 가져오는데 실패했습니다: 상태 코드 ${response.statusCode}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      setState(() {
        allPickupOrders = [];
        filteredPickupOrders = [];
        _isLoading = false;
      });
      Get.snackbar(
        '오류',
        '픽업 대기 목록 로딩 중 오류 발생: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _filterOrders() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredPickupOrders = List.from(allPickupOrders);
      } else {
        filteredPickupOrders =
            allPickupOrders.where((orderState) {
              return orderState.orderData.values.any((value) {
                if (value != null) {
                  return value.toString().toLowerCase().contains(query);
                }
                return false;
              });
            }).toList();
      }
    });
  }

  void _updateOrderStatus(PickupOrderState orderState) async {
    if (orderState.currentStatus == orderState.originalStatus) {
      Get.snackbar(
        '알림',
        '상태 변경 사항이 없습니다.',
        backgroundColor: Colors.blueAccent,
        colorText: Colors.white,
      );
      return;
    }

    final int? purchaseId = orderState.orderData['purchaseId'] as int?;

    if (purchaseId == null) {
      Get.snackbar(
        '오류',
        '주문 ID 정보를 찾을 수 없습니다.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final String apiUrl =
        "http://$globalip:8000/inhwan/purchase/$purchaseId/update-status/";

    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {'new_status': orderState.currentStatus},
      );

      Get.back();

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));

        if (responseData['result'] == 'OK') {
          orderState.originalStatus = orderState.currentStatus;
          setState(() {});
          Get.snackbar(
            '성공',
            responseData['message'] ?? '주문 상태가 성공적으로 업데이트되었습니다.',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          Get.snackbar(
            '업데이트 실패',
            responseData['message'] ?? '주문 상태 업데이트에 실패했습니다.',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
        }
      } else {
        Get.snackbar(
          '업데이트 오류',
          '주문 상태 업데이트에 실패했습니다: 상태 코드 ${response.statusCode}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      Get.snackbar(
        '업데이트 오류',
        '주문 상태 업데이트 중 오류 발생: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("픽업 대기 목록"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '검색 (제품 이름, 고객 이름 등)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
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
                              '상태',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '업데이트',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, thickness: 1, color: Colors.grey),
                    _isLoading // 데이터 로딩 중일 때 로딩 인디케이터 표시
                        ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                        : filteredPickupOrders
                            .isEmpty // 로딩 완료 후 필터링된 목록이 비어있으면 메시지 표시
                        ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: Text('픽업 대기 주문이 없습니다.')),
                        )
                        : Expanded(
                          child: ListView.builder(
                            itemCount: filteredPickupOrders.length,
                            itemBuilder: (context, index) {
                              final pickupOrderState =
                                  filteredPickupOrders[index];
                              final orderData = pickupOrderState.orderData;
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
                                        orderData['purchaseId']?.toString() ??
                                            '',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        orderData['oproductCode']?.toString() ??
                                            '',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        orderData['purchaseQuanity']
                                                ?.toString() ??
                                            '',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        value: pickupOrderState.currentStatus,
                                        items:
                                            _deliveryStatuses.map((
                                              String status,
                                            ) {
                                              return DropdownMenuItem<String>(
                                                value: status,
                                                child: Text(
                                                  status,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                        onChanged: (String? newValue) {
                                          if (newValue != null) {
                                            setState(() {
                                              pickupOrderState.currentStatus =
                                                  newValue;
                                            });
                                          }
                                        },
                                        underline: SizedBox(),
                                        dropdownColor: Colors.white,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Center(
                                        child: ElevatedButton(
                                          onPressed:
                                              pickupOrderState.currentStatus !=
                                                      pickupOrderState
                                                          .originalStatus
                                                  ? () => _updateOrderStatus(
                                                    pickupOrderState,
                                                  )
                                                  : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.black,
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            textStyle: TextStyle(fontSize: 12),
                                          ),
                                          child: const Text('업데이트'),
                                        ),
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
