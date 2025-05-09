class Dispatch {
  final String dUserid; // 회원 pk
  final int dProductCode; // 제품 코드
  final DateTime dispatchDate; // 출고 날짜
  final int dispatchedQuantity; // 출고 수량
  final String dstoreCode; //대리점 코드
  final int dipurchaseId; // 주문 코드 
  Dispatch({
    required this.dUserid,
    required this.dProductCode,
    required this.dispatchDate,
    required this.dispatchedQuantity,
    required this.dstoreCode,
    required this.dipurchaseId
  });
 Dispatch.fromMap(Map<String, dynamic> res)
  : dUserid = res['dUserid'],
    dProductCode = res['dProductCode'],
    dispatchDate = DateTime.parse(res['dispatchDate']), 
    dispatchedQuantity = res['dispatchedQuantity'],
    dstoreCode = res['dstoreCode'],
    dipurchaseId = res['dipurchaseId']
    ;

}
