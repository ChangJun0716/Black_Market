import 'dart:typed_data';

class GroupedProduct {
  final String pProductCode;
  final String ptitle;
  final Uint8List introductionPhoto;
  final String productsName;
  final int productsPrice;
  final String productsColor;

  GroupedProduct({
    required this.pProductCode,
    required this.ptitle,
    required this.introductionPhoto,
    required this.productsName,
    required this.productsPrice,
    required this.productsColor,
  });

  factory GroupedProduct.fromMap(Map<String, dynamic> map) {
    return GroupedProduct(
      pProductCode: map['pProductCode'].toString(),
      ptitle: map['ptitle'].toString(),
      introductionPhoto: map['introductionPhoto'],
      productsName: map['productsName'].toString(),
      productsPrice: map['productsPrice'] as int,
      productsColor: map['productsColor'].toString(),
    );
  }
}
