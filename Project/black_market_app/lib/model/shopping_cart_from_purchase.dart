import 'dart:typed_data';

class shoppingCart {
  final String productsName;
  final Uint8List productsImage;
  final int purchaseQuantity;

  shoppingCart({
    required this.productsName,
    required this.productsImage,
    required this.purchaseQuantity,
  });

  factory shoppingCart.fromMap(Map<String, dynamic> map) {
    return shoppingCart(
      productsName: map['productsName'],
      productsImage: map['productsImage'],
      purchaseQuantity: map['purchaseQuantity'],
    );
  }
}
