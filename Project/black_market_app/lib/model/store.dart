class Store {
  final String storeCode; // 대리점 코드
  final String storeName; // 대리점 명
  final String address; // 주소
  final double longitude; // 경도
  final double latitude; // 위도

  Store(
    {
    required this.storeCode,
    required this.storeName,
    required this.address,
    required this.longitude,
    required this.latitude
    }
  );

  Store.fromMap(Map<String, dynamic> res)
  : storeCode = res['storeCode'],
  storeName = res['storeName'],
  address = res['address'],
  longitude = res['longitude'],
  latitude = res['latitude'];
}
