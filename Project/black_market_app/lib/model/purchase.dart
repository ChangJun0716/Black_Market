class Purchase {
  final String purchaseId; //주문번호
  final DateTime purchaseDate; // 구매일
  final int purchaseQuanity; // 수량
  final int purchaseCardId; // 장바구니 //
  final String pStoreCode; //대리점코드
  final String purchaseDeliveryStatus; //배송 상태
  final String oproductCode; //제품코드
  final int purchasePrice; // 구매가격
  //Constructor
  Purchase({
    required this.purchaseId,
    required this.purchaseDate,
    required this.purchaseQuanity,
    required this.purchaseCardId,
    required this.pStoreCode,
    required this.purchaseDeliveryStatus,
    required this.oproductCode,
    required this.purchasePrice,
  });
  factory Purchase.formMap(Map<String, dynamic> res) {
    return Purchase(
      purchaseId: res['PurchaseId'],
      purchaseDate: res['PurchaseDate'],
      purchaseQuanity: res['PurchaseQuanity'],
      purchaseCardId: res['PurchaseCardId'],
      pStoreCode: res['pStoreCode'],
      purchaseDeliveryStatus: res['purchaseDeliveryStatus'],
      oproductCode: res['oproductcode'],
      purchasePrice: res['purchasePrice'],
    );
  }
}
