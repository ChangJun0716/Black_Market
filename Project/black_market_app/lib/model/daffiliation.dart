class Daffiliation {
  final String dstoreCode; // 대리점 코드
  final String duserId; // 회원 코드

  Daffiliation(
    {
    required this.dstoreCode,
    required this.duserId
    }
  );
  Daffiliation.fromMap(Map<String, dynamic> res)
  : dstoreCode = res['dstoreCode'],
  duserId = res['duserId'];
}
