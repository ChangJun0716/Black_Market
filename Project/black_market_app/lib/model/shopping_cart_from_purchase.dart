import 'dart:typed_data';

class ShoppingCart {
  final int purchaseId;
  final String productsName;
  final Uint8List productsImage;
  final int purchaseQuantity;
  final int purchasePrice;
  final String storeName; // 추가된 필드

  ShoppingCart({
    required this.purchaseId,
    required this.productsName,
    required this.productsImage,
    required this.purchaseQuantity,
    required this.purchasePrice,
    required this.storeName,
  });

  factory ShoppingCart.fromMap(Map<String, dynamic> map) {
    return ShoppingCart(
      purchaseId: map['purchaseId'] ?? 0, // null이면 0 대입
      productsName: map['productsName'] ?? '',
      productsImage: map['productsImage'], // Uint8List라면 null이 아님을 보장
      purchaseQuantity: map['purchaseQuanity'] ?? 0,
      purchasePrice: map['purchasePrice'] ?? 0,
      storeName: map['storeName'] ?? '',
    );
  }
}
