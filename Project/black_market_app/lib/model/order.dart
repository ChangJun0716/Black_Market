//발주
class Orders {
  final int? orderID; 
  final String orderQuantity; //발주수량
  final String? orderDate; // 발주날짜
  final String orderStatus; // 발주상태
  final int orderPrice; /// 발주 가격
  final String oajobGradCode; // 소속pk
  final String oaUserid; // 회원 pk
  final String oproductCode; // 제품코드
  final String omamufacturer; //제조사 코드

  Orders({
    this.orderID,
    required this.orderQuantity,
    this.orderDate,
    required this.orderStatus,
    required this.orderPrice,
    required this.oajobGradCode,
    required this.oaUserid,
    required this.oproductCode,
    required this.omamufacturer,
  });
  factory Orders.formMap(Map<String, dynamic> res) {
  return Orders(
    orderID: res['orderID'], // int OK
    orderQuantity: res['orderQuantity'].toString(),
    orderDate: res['orderDate']?.toString(),
    orderPrice: res['orderPrice'], // int OK
    orderStatus: res['orderStatus'].toString(),
    oajobGradCode: res['oajobGradCode'].toString(),
    oaUserid: res['oaUserid'].toString(),
    oproductCode: res['oproductCode'].toString(),
    omamufacturer: res['omamufacturer'].toString(),
  );
}

}