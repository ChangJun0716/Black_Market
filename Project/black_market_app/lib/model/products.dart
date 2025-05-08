import 'dart:typed_data';

class Products {
  final int? productsCode; // 제품번호 - int로 수정
  final String productsColor; // 제품 컬러
  final String productsName; // 제품명
  final int productsPrice; // 가격
  final int productsSize; // 사이즈
  final Uint8List productsImage; // 사진
  Products({
    this.productsCode,
    required this.productsColor,
    required this.productsName,
    required this.productsPrice,
    required this.productsSize,
    required this.productsImage,
  });
  factory Products.fromMap(Map<String, dynamic> res) {
    return Products(
      productsCode:
          res['productsCode'] is int
              ? res['productsCode']
              : int.tryParse(res['productsCode'].toString()),
      productsColor: res['productsColor'],
      productsName: res['productsName'],
      productsPrice: res['productsPrice'],
      productsSize: res['productsSize'],
      productsImage: res['productsImage'],
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'productsCode': productsCode,
      'productsColor': productsColor,
      'productsName': productsName,
      'productsPrice': productsPrice,
      'productsSize': productsSize,
      'productsImage': productsImage,
    };
  }
}
