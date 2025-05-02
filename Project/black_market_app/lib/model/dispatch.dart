class Dispatch {
  final String daJobGradeCode; // 직급 코드
  final String dProductCode; // 제품 코드
  final DateTime dispatchDate; // 출고 날짜
  final int dispatchedQuantity; // 출고 수량
  Dispatch({
    required this.daJobGradeCode,
    required this.dProductCode,
    required this.dispatchDate,
    required this.dispatchedQuantity,
  });
  Dispatch.fromMap(Map<String, dynamic> res)
    : daJobGradeCode = res['daJobGradeCode'],
      dProductCode = res['dProductCode'],
      dispatchDate = res['dispatchDate'],
      dispatchedQuantity = res['dispatchedQuantity'];
}
