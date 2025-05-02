//입고
class StockReceipts{
 final  int stockReceiptsQuantityReceived; //입고수량 //
  final DateTime stockReceiptsReceipDate;// 입고날짜
  final  String sproductCode; // 제품코드
  final String smamufacturerName; /// 제조사명

  StockReceipts(
    {
      required this.stockReceiptsQuantityReceived,
      required this.stockReceiptsReceipDate,
      required this.sproductCode,
      required this.smamufacturerName,
    }
  );
factory StockReceipts.formMap(Map<String,dynamic> res){
  return StockReceipts(
    stockReceiptsQuantityReceived : res['stockReceiptsQuantityReceived'],
    stockReceiptsReceipDate:res['stockReceiptsReceipDate'],
    sproductCode: res['sproductCode'],
    smamufacturerName: res['smamufacturerName']
    );
}
}