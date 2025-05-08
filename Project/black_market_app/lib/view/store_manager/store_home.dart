// store_home.dart
import 'package:black_market_app/view/store_manager/return/store_return_list.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // GetX 임포트 (내비게이션 사용)

// CustomButton 위젯 임포트 (경로에 맞게 수정 필요)
import 'package:black_market_app/utility/custom_button.dart';

// 대리점 관리 페이지들 임포트 (경로에 맞게 수정 필요)
import 'store_check_inventory.dart'; // 매장 재고 확인
import 'store_product_condition.dart'; // 픽업 대기 목록
import 'store_scheduled_product.dart'; // 입고 예정 제품

class StoreHomePage extends StatelessWidget {
  const StoreHomePage({Key? key}) : super(key: key); // Key 추가

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('대리점 메인 페이지'), // 앱 바 제목
        backgroundColor: Colors.black, // 배경색 설정 (어두운 테마 유지)
        foregroundColor: Colors.white, // 글자색 설정
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
                          Get.to(() => StoreCheckInventory());
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
                          Get.to(() => StoreProductCondition());
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
                          Get.to(() => StoreScheduledProduct());
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
                          Get.to(() => StoreReturnList());
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
