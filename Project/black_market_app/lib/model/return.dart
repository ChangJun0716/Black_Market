class Return {
  final int returnCode; // 반품코드
  final String ruserId; // 회원 아이디
  final String rProductCode; // 제품 코드
  final String returnReason; // 반품 사유
  final DateTime returnDate; // 반품 날짜
  final String returnCategory; // 반품 분류
  final String prosessionStateus; // 처리상태
  Return({
    required this.returnCode,
    required this.ruserId,
    required this.rProductCode,
    required this.returnReason,
    required this.returnDate,
    required this.returnCategory,
    required this.prosessionStateus,
  });
  Return.fromMap(Map<String, dynamic> res)
    : returnCode = res['returnCode'],
      ruserId = res['ruserId'],
      rProductCode = res['rProductCode'],
      returnReason = res['returnReason'],
      returnDate = res['returnDate'],
      returnCategory = res['returnCategory'],
      prosessionStateus = res['prosessionStateus'];
}
