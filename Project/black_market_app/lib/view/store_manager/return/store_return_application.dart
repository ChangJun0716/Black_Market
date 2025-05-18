import 'package:black_market_app/global.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class StoreReturnApplication extends StatefulWidget {
  const StoreReturnApplication({super.key});

  @override
  State<StoreReturnApplication> createState() => _StoreReturnApplicationState();
}

class _StoreReturnApplicationState extends State<StoreReturnApplication> {
  final Map<String, dynamic>? _arguments = Get.arguments;

  String? _loggedInUserId;
  String? _loggedInStoreCode;

  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _orderNumberController = TextEditingController();
  final TextEditingController _returnDateController = TextEditingController();
  final TextEditingController _returnReasonController = TextEditingController();

  String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  Map<String, dynamic>? _purchaseDetails;

  bool _isLoadingLookup = false;
  bool _isLoadingApplication = false;

  @override
  void initState() {
    super.initState();

    _loggedInUserId = _arguments?['userId'] as String?;
    _loggedInStoreCode = _arguments?['storeCode'] as String?;

    _returnDateController.text = todayDate;

    if (_loggedInUserId == null ||
        _loggedInUserId!.isEmpty ||
        _loggedInStoreCode == null ||
        _loggedInStoreCode!.isEmpty) {
      Get.snackbar(
        '오류',
        '사용자 또는 대리점 정보를 가져오지 못했습니다. 홈 화면으로 돌아가주세요.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _orderNumberController.dispose();
    _returnDateController.dispose();
    _returnReasonController.dispose();
    super.dispose();
  }

  void _lookupPurchaseDetails(String purchaseIdText) async {
    if (_loggedInStoreCode == null || _loggedInStoreCode!.isEmpty) {
      Get.snackbar(
        '오류',
        '대리점 정보가 유효하지 않습니다. 반품 신청이 불가합니다.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (purchaseIdText.trim().isEmpty) {
      setState(() {
        _purchaseDetails = null;
        _customerNameController.clear();
      });
      Get.snackbar(
        '알림',
        '조회할 주문 번호를 입력해주세요.',
        backgroundColor: Colors.blueAccent,
        colorText: Colors.white,
      );
      return;
    }

    int? purchaseId = int.tryParse(purchaseIdText.trim());

    if (purchaseId == null) {
      setState(() {
        _purchaseDetails = null;
        _customerNameController.clear();
      });
      Get.snackbar(
        '오류',
        '유효한 숫자 형식의 주문 번호를 입력해주세요.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoadingLookup = true;
      _purchaseDetails = null;
      _customerNameController.clear();
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

          Map<String, dynamic>? foundOrder = results.firstWhereOrNull(
            (item) => (item['purchaseId'] as int?) == purchaseId,
          );

          if (foundOrder != null) {
            setState(() {
              _purchaseDetails = foundOrder;
              _customerNameController.text =
                  _purchaseDetails!['customerName'] as String? ?? '';
              _isLoadingLookup = false;
            });
            Get.snackbar(
              '조회 성공',
              '주문 정보를 찾았습니다.',
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
          } else {
            setState(() {
              _purchaseDetails = null;
              _customerNameController.clear();
              _isLoadingLookup = false;
            });
            Get.snackbar(
              '알림',
              '입력된 주문 번호에 해당하는 정보를 찾을 수 없습니다.',
              backgroundColor: Colors.orange,
              colorText: Colors.white,
            );
          }
        } else {
          setState(() {
            _purchaseDetails = null;
            _customerNameController.clear();
            _isLoadingLookup = false;
          });
          Get.snackbar(
            '오류',
            responseData['message'] ?? '주문 정보 조회에 실패했습니다. 백엔드 응답 오류.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } else {
        setState(() {
          _purchaseDetails = null;
          _customerNameController.clear();
          _isLoadingLookup = false;
        });
        Get.snackbar(
          '오류',
          '주문 정보 조회에 실패했습니다: 상태 코드 ${response.statusCode}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      setState(() {
        _purchaseDetails = null;
        _customerNameController.clear();
        _isLoadingLookup = false;
      });
      Get.snackbar(
        '오류',
        '주문 정보 조회 중 오류 발생: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // 반품 신청 버튼 클릭 시 백엔드 API 호출 (Get.dialog 제거, _isLoadingApplication만 사용)
  void _submitReturnApplication() async {
    // 필수 입력/조회 값 유효성 검사 (이전과 동일)
    if (_loggedInUserId == null || _loggedInUserId!.isEmpty) {
      Get.snackbar(
        '오류',
        '사용자 정보가 유효하지 않습니다. 반품 신청이 불가합니다.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    if (_loggedInStoreCode == null || _loggedInStoreCode!.isEmpty) {
      Get.snackbar(
        '오류',
        '대리점 정보가 유효하지 않습니다. 반품 신청이 불가합니다.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    if (_purchaseDetails == null) {
      Get.snackbar(
        '알림',
        '주문 번호를 조회하여 정보를 확인해주세요.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    if (_returnReasonController.text.trim().isEmpty) {
      Get.snackbar(
        '알림',
        '반품 사유를 입력해주세요.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    // 필요한 다른 필드들도 유효성 검사 추가...

    // 반품 신청에 필요한 데이터 추출 (이전과 동일)
    final int? purchaseId = _purchaseDetails!['purchaseId'] as int?;
    final String? purchaseUserId = _purchaseDetails!['pUserId'] as String?;
    final int? purchaseProductCode = _purchaseDetails!['oproductCode'] as int?;

    if (purchaseId == null ||
        purchaseUserId == null ||
        purchaseProductCode == null) {
      Get.snackbar(
        '오류',
        '조회된 주문 정보가 불완전합니다. 반품 신청이 불가합니다.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // 반품 신청에 필요한 Form Data 구성 (이전과 동일)
    Map<String, String> formData = {
      'returnCategory': '기타',
      'returnDate': _returnDateController.text,
      'prosessionStatus': '신청 완료', // 스키마 오타 주의
      'returnReason': _returnReasonController.text.trim(),
      'resolution': '',
      'recordDate': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      'ruserId': _loggedInUserId!,
      'purchaseId': purchaseId.toString(),
      'purchaseUserId': purchaseUserId,
      'purchaseStoreCode': _loggedInStoreCode!,
      'purchaseProductCode': purchaseProductCode.toString(),
    };

    // 버튼 상태를 로딩 중으로 변경 (UI 업데이트)
    setState(() {
      _isLoadingApplication = true; // 로딩 시작
    });

    try {
      // 반품 신청 API 호출 (POST)
      final String apiUrl = "http://$globalip:8000/inhwan/returns/";
      final response = await http.post(
        Uri.parse(apiUrl),
        body: formData, // Form Data 전송
      );

      // 응답 처리
      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));

        if (responseData['result'] == 'OK') {
          // 반품 신청 성공
          Get.snackbar(
            '성공',
            responseData['message'] ?? '반품 신청이 성공적으로 접수되었습니다.',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          // TODO: 필요하다면 반품 목록 페이지로 돌아가거나 입력 필드 초기화 등의 후속 작업 수행
          // Get.back(); // 반품 목록 페이지로 돌아가기
        } else {
          // 백엔드 응답 형식은 맞으나 result가 'OK'가 아님 (반품 신청 실패 메시지)
          Get.snackbar(
            '신청 실패',
            responseData['message'] ?? '반품 신청에 실패했습니다.',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
        }
      } else {
        // HTTP 상태 코드 200이 아닌 경우 오류 처리
        Get.snackbar(
          '신청 오류',
          '반품 신청 중 오류가 발생했습니다: 상태 코드 ${response.statusCode}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      // 예외 처리 메시지 표시
      Get.snackbar(
        '신청 오류',
        '반품 신청 중 오류 발생: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      // API 호출 시도 후 성공/실패/예외와 관계없이 로딩 상태 해제
      setState(() {
        _isLoadingApplication = false; // 로딩 완료
      });
      // Get.dialog로 띄운 다이얼로그가 없으므로 여기서 Get.back() 호출 필요 없음
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("반품 신청"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _customerNameController,
                decoration: InputDecoration(
                  labelText: '고객 이름',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
              ),
              SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _orderNumberController,
                      decoration: InputDecoration(
                        labelText: '주문 번호',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed:
                        _isLoadingLookup
                            ? null
                            : () => _lookupPurchaseDetails(
                              _orderNumberController.text,
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                    child:
                        _isLoadingLookup
                            ? CircularProgressIndicator(color: Colors.white)
                            : const Text('조회'),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                controller: _returnDateController,
                decoration: InputDecoration(
                  labelText: '반품일자',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _returnReasonController,
                decoration: InputDecoration(
                  labelText: '반품 사유',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed:
                    _isLoadingApplication || _purchaseDetails == null
                        ? null
                        : _submitReturnApplication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  textStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child:
                    _isLoadingApplication
                        ? CircularProgressIndicator(color: Colors.white)
                        : const Text('반품 신청'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
