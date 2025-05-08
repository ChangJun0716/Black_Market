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
      purchaseId: map['purchaseId'],
      productsName: map['productsName'],
      productsImage: map['productsImage'] as Uint8List,
      purchaseQuantity: map['purchaseQuantity'],
      purchasePrice: map['purchasePrice'],
      storeName: map['storeName'],
    );
  }
}
