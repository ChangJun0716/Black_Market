class Dispatch {
  final String dUserid; // 회원 pk
  final String daJobGradeCode; // 직급 코드
  final String dProductCode; // 제품 코드
  final DateTime dispatchDate; // 출고 날짜
  final int dispatchedQuantity; // 출고 수량
  final String dstoreCode; //대리점 코드
  Dispatch({
    required this.dUserid,
    required this.daJobGradeCode,
    required this.dProductCode,
    required this.dispatchDate,
    required this.dispatchedQuantity,
    required this.dstoreCode
  });
  Dispatch.fromMap(Map<String, dynamic> res)
    : dUserid = res['dUserid'],
      daJobGradeCode = res['daJobGradeCode'],
      dProductCode = res['dProductCode'],
      dispatchDate = res['dispatchDate'],
      dispatchedQuantity = res['dispatchedQuantity'],
      dstoreCode = res['dstoreCode'];
}
