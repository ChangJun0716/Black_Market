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
      productName: map['productsName'],
      productColor: map['productsColor'],
      productSize: map['productsSize'],
      productImage: map['productsImage'],
      ptitle: map['ptitle'],
      purchasePrice: map['purchasePrice'],
      purchaseQuantity: map['purchaseQuanity'],
      purchaseDeliveryStatus: map['purchaseDeliveryStatus'],
      storeName: map['storeName'],
    );
  }
}
