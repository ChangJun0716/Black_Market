import 'dart:typed_data';

class Products {
  final int? productsCode; // 제품번호
  final String productsColor; // 제품 컬러
  final String productsName; // 제품명
  final int productsPrice; // 가격
  final int productsSize; // 사이즈
  final Uint8List productsImage;

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
    productsCode: res['productsCode'],
    productsColor: res['productsColor'],
    productsName: res['productsName'],
    productsPrice: res['productsPrice'],
    productsSize: res['productsSize'],
    productsImage: Uint8List.fromList(res['productsImage']),
  );
}

}
