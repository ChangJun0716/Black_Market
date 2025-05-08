import 'package:black_market_app/utility/custom_button.dart';
import 'package:black_market_app/view/company/company_check_inventory.dart';
import 'package:black_market_app/view/company/company_post_list.dart';
import 'package:black_market_app/view/company/company_product_list.dart';
import 'package:black_market_app/view/company/company_return_list.dart';
import 'package:black_market_app/view/company/order/company_order_list.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CompanyHome extends StatefulWidget {
  const CompanyHome({super.key});

  @override
  State<CompanyHome> createState() => _CompanyHomeState();
}

class _CompanyHomeState extends State<CompanyHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("관리자 페이지",
        style: TextStyle(
          color: Colors.white,
        ),
        ),
      ),
      body: Center(
        child: SizedBox(
          height: 600,
          width: 800,
          child: Card(
            color: Colors.white,
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("---------재고 관리---------",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 80,
                          width: 180,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CustomButton(
                              text:" 재고 확인 ", 
                              onPressed:(){
                                Get.to(CompanyCheckInventory());
                              }),
                          ),
                        ),
                        SizedBox(
                          height: 80,
                          width: 180,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CustomButton(
                              text: "재고 입출고", 
                              onPressed:(){
                                
                              }),
                          ),
                        ),
                    ],),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("---------제품 관리---------",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 80,
                          width: 180,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CustomButton(
                              text:" 제품 관리 ", 
                              onPressed:(){
                                Get.to(CompanyProductList());
                              }),
                          ),
                        ),
                        SizedBox(
                          height: 80,
                          width: 180,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CustomButton(
                              text: "제품 게시글 작성", 
                              onPressed:(){
                                Get.to(CompanyPostList());
                              }),
                          ),
                        ),
                    ],),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("---------회원 관리---------",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 80,
                          width: 180,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CustomButton(
                              text:" 반품 확인 ", 
                              onPressed:(){
                                Get.to(CompanyReturnList());
                              }),
                          ),
                        ),
                        SizedBox(
                          height: 80,
                          width: 180,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CustomButton(
                              text: " 구매 내역 ", 
                              onPressed:(){
                            
                              }),
                          ),
                        ),
                    ],),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("---------서류 관리---------",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 80,
                          width: 180,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CustomButton(
                              text:" 공지 작성 ", 
                              onPressed:(){
                            
                              }),
                          ),
                        ),
                        SizedBox(
                          height: 80,
                          width: 180,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CustomButton(
                              text: " 결재 내역 ", 
                              onPressed:(){
                                Get.to(CompanyOrderList());
                              }),
                          ),
                        ),
                    ],),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 130),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("대리점 직원 등록"),
                         SizedBox(
                            height: 80,
                            width: 180,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CustomButton(
                                text: " 회원 등록 ", 
                                onPressed:(){
                              
                                }),
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}