class Manufacturers {
  final String manufacturerName; // 제조사 명
  Manufacturers({required this.manufacturerName});
  Manufacturers.fromMap(Map<String, dynamic> res)
    : manufacturerName = res['manufacturerName'];
}