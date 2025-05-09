import 'dart:typed_data';
class PurchaseDetail {
  final String productName;
  final String productColor;
  final int productSize;
  final Uint8List productImage;
  final String ptitle;
  final int purchasePrice;
  final int purchaseQuantity;
  final String purchaseDeliveryStatus;
  final String storeName;

  PurchaseDetail({
    required this.productName,
    required this.productColor,
    required this.productSize,
    required this.productImage,
    required this.ptitle,
    required this.purchasePrice,
    required this.purchaseQuantity,
    required this.purchaseDeliveryStatus,
    required this.storeName,
  });

factory PurchaseDetail.fromMap(Map<String, dynamic> map) {
  return PurchaseDetail(
    productName: map['productsName'] as String,
    productColor: map['productsColor'] as String,
    productSize: map['productsSize'] as int,
    productImage: map['productsImage'] as Uint8List,
    ptitle: map['ptitle'] as String? ?? '',
    purchasePrice: map['purchasePrice'] as int,
    purchaseQuantity: map['purchaseQuanity'] as int,
    purchaseDeliveryStatus: map['purchaseDeliveryStatus'] as String,
    storeName: map['storeName'] as String,
  );
}
}
