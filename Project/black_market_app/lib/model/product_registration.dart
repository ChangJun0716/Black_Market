//제품
import 'dart:typed_data';

class ProductRegistration {
  final String paUserid; // 회원 pk
  final String paJobGradeCode; // 직급 코드
  final String pProductCode; // 제품 코드
  final Uint8List introductionPhoto; // 소개 사진
  final String productDescription; // 제품 설명
  ProductRegistration({
    required this.paUserid,
    required this.paJobGradeCode,
    required this.pProductCode,
    required this.introductionPhoto,
    required this.productDescription,
  });
  ProductRegistration.fromMap(Map<String, dynamic> res)
    : paUserid = res['paUserid'],
      paJobGradeCode = res['paJobGradeCode'],
      pProductCode = res['pProductCode'],
      introductionPhoto = res['introductionPhoto'],
      productDescription = res['productDescription'];
}
