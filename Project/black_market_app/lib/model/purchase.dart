class Purchase {
  final int? purchaseId; //주문번호
  final String purchaseDate; // 구매일
  final int purchaseQuanity; // 수량
  final int? purchaseCardId; // 장바구니 //
  final String pUserId; // 고객 아이디
  final String pStoreCode; //대리점코드
  final String purchaseDeliveryStatus; //배송 상태
  final String oproductCode; //제품코드
  final int purchasePrice; // 구매가격
  //Constructor
  Purchase({
    this.purchaseId,
    required this.purchaseDate,
    required this.purchaseQuanity,
    this.purchaseCardId,
    required this.pUserId,
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
      pUserId: res['pUserId'],
      pStoreCode: res['pStoreCode'],
      purchaseDeliveryStatus: res['purchaseDeliveryStatus'],
      oproductCode: res['oproductcode'],
      purchasePrice: res['purchasePrice'],
    );
  }
}
