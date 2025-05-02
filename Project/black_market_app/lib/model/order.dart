//발주
class Order {
  final String orderQuantity; //발주수량
  final DateTime orderDate; // 발주날짜
  final String orderStatus; // 발주상태
  final int orderPrice;

  /// 발주 가격
  final String oajobGradCode; // 소속pk
  final String oaUserid; // 회원 pk
  final String oproductCode; // 제품코드
  final String omamufacturer; //제조사 코드

  Order({
    required this.orderQuantity,
    required this.orderDate,
    required this.orderStatus,
    required this.orderPrice,
    required this.oajobGradCode,
    required this.oaUserid,
    required this.oproductCode,
    required this.omamufacturer,
  });
  factory Order.formMap(Map<String, dynamic> res) {
    return Order(
      orderQuantity: res['orderQuantity'],
      orderDate: res['oderDate'],
      orderPrice: res['orderPrice'],
      orderStatus: res['orderStatus'],
      oajobGradCode: res['oajobGradCode'],
      oaUserid: res['oaUserid'],
      oproductCode: res['oproductCode'],
      omamufacturer: res['omamufacturer'],
    );
  }
}
