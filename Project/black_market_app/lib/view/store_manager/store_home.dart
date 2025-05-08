// store_home.dart
import 'package:black_market_app/view/store_manager/return/store_return_list.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // GetX 임포트 (내비게이션 사용)
import 'package:get_storage/get_storage.dart'; // GetStorage 임포트

// CustomButton 위젯 임포트 (경로에 맞게 수정 필요)
import 'package:black_market_app/utility/custom_button.dart';

// 대리점 관리 페이지들 임포트 (경로에 맞게 수정 필요)
import 'store_check_inventory.dart'; // 매장 재고 확인
import 'store_product_condition.dart'; // 픽업 대기 목록
import 'store_scheduled_product.dart'; // 입고 예정 제품

// DatabaseHandler 임포트 (대리점 이름, storeCode 조회에 사용)
import 'package:black_market_app/vm/database_handler.dart';

class StoreHomePage extends StatefulWidget {
  // StatelessWidget에서 StatefulWidget으로 변경
  const StoreHomePage({Key? key}) : super(key: key);

  @override
  State<StoreHomePage> createState() => _StoreHomePageState();
}

class _StoreHomePageState extends State<StoreHomePage> {
  // GetStorage에서 읽어온 사용자 ID와 memberType
  String? _loggedInUserId;
  int? _loggedInUserMemberType;

  // 로그인된 대리점 코드 (사용자 ID로 조회)
  String? _loggedInStoreCode; // 초기값 null
  // 조회된 대리점 이름
  String? _loggedInStoreName; // 초기값 null

  // 데이터 로딩 상태
  bool _isLoadingStoreInfo = true; // 대리점 정보 로딩 상태

  // DatabaseHandler 인스턴스
  late DatabaseHandler _handler;
  final box = GetStorage(); // GetStorage 인스턴스

  @override
  void initState() {
    super.initState();
    _handler = DatabaseHandler(); // 핸들러 인스턴스 생성

    // GetStorage에서 로그인 정보 읽어오기
    _loggedInUserId = box.read('uid');
    _loggedInUserMemberType = box.read('memberType');
    print(
      '>>> StoreHomePage: GetStorage에서 읽어온 uid=$_loggedInUserId, memberType=$_loggedInUserMemberType',
    ); // 로깅

    // 사용자 ID가 유효하고 memberType이 대리점 관리자인 경우 storeCode 및 대리점 이름 가져오기 시작
    if (_loggedInUserId != null &&
        _loggedInUserMemberType != null &&
        _loggedInUserMemberType! >= 3) {
      // memberType 3 이상인 대리점 관리자만 해당
      _fetchStoreInfoByUserId(_loggedInUserId!);
    } else {
      // 로그인 정보가 없거나 memberType이 대리점 관리자가 아닌 경우 처리
      print('>>> StoreHomePage: GetStorage에 유효한 대리점 관리자 정보가 없습니다.');
      _isLoadingStoreInfo = false; // 로딩 완료 처리 (실패)
      _loggedInStoreCode = null; // storeCode 상태 초기화
      _loggedInStoreName = '로그인 정보 오류'; // 오류 메시지 표시
      // 사용자에게 알림 또는 로그인 페이지로 강제 이동 고려
      Get.snackbar(
        '오류',
        '대리점 정보를 가져올 수 없습니다. 다시 로그인해주세요.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  void dispose() {
    // Dispose controllers etc. (이 페이지에는 없음)
    super.dispose();
  }

  // 사용자 ID로 대리점 코드와 이름 가져오는 메서드
  Future<void> _fetchStoreInfoByUserId(String userId) async {
    print('>>> StoreHomePage: 사용자 ID ($userId)로 대리점 코드/이름 가져오기 시도'); // 로깅
    try {
      // DatabaseHandler의 getStoreCodeByUserId 메서드를 사용하여 storeCode 가져오기
      final String? storeCode = await _handler.getStoreCodeByUserId(userId);
      print('>>> StoreHomePage: 검색된 storeCode = $storeCode'); // 로깅

      if (storeCode != null) {
        // storeCode로 대리점 이름 가져오기
        final String? storeName = await _handler.getStoreNameByStoreCode(
          storeCode,
        ); // 새로 추가한 메서드 사용
        print('>>> StoreHomePage: 검색된 storeName = $storeName'); // 로깅

        setState(() {
          _loggedInStoreCode = storeCode; // storeCode 상태 업데이트
          _loggedInStoreName =
              storeName ?? '알 수 없는 대리점'; // 이름 상태 업데이트 (null이면 기본값)
          _isLoadingStoreInfo = false; // 로딩 완료
          print(
            '>>> StoreHomePage: 대리점 정보 로딩 완료 - 코드: $_loggedInStoreCode, 이름: $_loggedInStoreName',
          ); // 로깅
        });
      } else {
        // storeCode를 찾을 수 없는 경우 (daffiliation 테이블에 정보 없음)
        print(
          '>>> StoreHomePage: 사용자 ID ($userId)에 연결된 대리점 코드를 찾을 수 없습니다.',
        ); // 로깅
        setState(() {
          _loggedInStoreCode = null; // storeCode 상태 초기화
          _loggedInStoreName = '소속 대리점 정보 없음'; // 오류 메시지 표시
          _isLoadingStoreInfo = false; // 로딩 완료
        });
        Get.snackbar(
          '오류',
          '소속 대리점 정보를 찾을 수 없습니다. 관리자에게 문의하세요.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('>>> StoreHomePage: 대리점 정보 가져오는 중 오류 발생: ${e.toString()}'); // 로깅
      setState(() {
        _loggedInStoreCode = null; // 오류 시 storeCode 초기화
        _loggedInStoreName = '오류 발생'; // 오류 메시지 표시
        _isLoadingStoreInfo = false; // 로딩 완료
      });
      Get.snackbar(
        '오류',
        '대리점 정보를 가져오는데 실패했습니다: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 대리점 정보 로딩 중이거나 로딩 실패 시 로딩 인디케이터 또는 오류 메시지 표시
    if (_isLoadingStoreInfo) {
      return Scaffold(
        appBar: AppBar(title: Text('대리점 정보 로딩 중...')),
        body: Center(child: CircularProgressIndicator()),
      );
    } else if (_loggedInStoreCode == null) {
      // storeCode 로딩 실패 (사용자 ID 없거나, storeCode 못 찾은 경우 등)
      return Scaffold(
        appBar: AppBar(
          title: Text(_loggedInStoreName ?? '대리점 메인 페이지 오류'),
        ), // 로딩 실패 시 설정된 오류 메시지를 제목으로 사용
        body: Center(
          child: Text(
            _loggedInStoreName ?? '대리점 정보를 가져오는데 실패했습니다.',
            style: TextStyle(color: Colors.red),
          ),
        ), // 동일한 오류 메시지 표시
      );
    }

    return Scaffold(
      // 앱 바 제목에 대리점 이름 표시
      appBar: AppBar(
        title: Text(
          _loggedInStoreName ?? '대리점 메인 페이지',
        ), // 앱 바 제목 (_loggedInStoreName이 로딩되면 표시됨)
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        // 화면 중앙에 내용을 배치
        child: SingleChildScrollView(
          // 내용이 많아지면 스크롤 가능하도록 추가
          padding: const EdgeInsets.all(
            20.0,
          ), // SingleChildScrollView 자체에 전체 패딩 추가
          child: Container(
            // 네모난 상자 형태로 버튼들을 감싸는 Container
            padding: const EdgeInsets.all(
              20.0,
            ), // Container 내부 패딩 (버튼 그룹과 테두리 사이 여백)
            decoration: BoxDecoration(
              // Container 테두리 및 배경 설정
              border: Border.all(color: Colors.grey, width: 1.0), // 회색 테두리 추가
              borderRadius: BorderRadius.circular(8.0), // 모서리 둥글게 처리
              color: Colors.white, // 배경색 설정 (원하는 색상으로 변경 가능)
            ),
            child: Column(
              // 2개의 Row를 담을 컬럼 (수직 배치)
              mainAxisSize: MainAxisSize.min, // 컬럼 크기를 자식들 (Row)의 최소 크기로 제한
              mainAxisAlignment:
                  MainAxisAlignment.center, // 컬럼 내 Row들을 수직 중앙 정렬
              crossAxisAlignment:
                  CrossAxisAlignment
                      .stretch, // 컬럼 내 Row들을 수평으로 늘이기 (Container 너비에 맞춰짐)
              children: [
                // 첫 번째 Row (1행)
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly, // Row 내 버튼들을 균등하게 정렬
                  children: [
                    // 첫 번째 버튼: 매장 재고 확인
                    Expanded(
                      // Row 공간을 차지하도록 Expanded 사용
                      child: CustomButton(
                        text: '매장 재고 확인',
                        onPressed: () {
                          // _loggedInStoreCode가 유효할 때만 이동 (하위 페이지에서 GetStorage 읽도록 수정)
                          if (_loggedInStoreCode != null) {
                            Get.to(() => StoreCheckInventory()); // 인자 전달 제거
                          } else {
                            Get.snackbar(
                              '오류',
                              '대리점 정보가 로딩되지 않았습니다.',
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 15), // 버튼 사이 수평 간격
                    // 두 번째 버튼: 픽업 대기 목록
                    Expanded(
                      // Row 공간을 차지하도록 Expanded 사용
                      child: CustomButton(
                        text: '픽업 대기 목록',
                        onPressed: () {
                          // _loggedInStoreCode가 유효할 때만 이동 (하위 페이지에서 GetStorage 읽도록 수정)
                          if (_loggedInStoreCode != null) {
                            Get.to(() => StoreProductCondition()); // 인자 전달 제거
                          } else {
                            Get.snackbar(
                              '오류',
                              '대리점 정보가 로딩되지 않았습니다.',
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15), // 첫 번째 Row와 두 번째 Row 사이의 수직 간격
                // 두 번째 Row (2행)
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly, // Row 내 버튼들을 균등하게 정렬
                  children: [
                    // 세 번째 버튼: 입고 예정 제품
                    Expanded(
                      // Row 공간을 차지하도록 Expanded 사용
                      child: CustomButton(
                        text: '입고 예정 제품',
                        onPressed: () {
                          // _loggedInStoreCode가 유효할 때만 이동 (하위 페이지에서 GetStorage 읽도록 수정)
                          if (_loggedInStoreCode != null) {
                            Get.to(() => StoreScheduledProduct()); // 인자 전달 제거
                          } else {
                            Get.snackbar(
                              '오류',
                              '대리점 정보가 로딩되지 않았습니다.',
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 15), // 버튼 사이 수평 간격
                    // 네 번째 버튼: 매장 반품 목록
                    Expanded(
                      // Row 공간을 차지하도록 Expanded 사용
                      child: CustomButton(
                        text: '매장 반품 목록',
                        onPressed: () {
                          // _loggedInStoreCode가 유효할 때만 이동 (하위 페이지에서 GetStorage 읽도록 수정)
                          if (_loggedInStoreCode != null) {
                            Get.to(() => StoreReturnList()); // 인자 전달 제거
                          } else {
                            Get.snackbar(
                              '오류',
                              '대리점 정보가 로딩되지 않았습니다.',
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
