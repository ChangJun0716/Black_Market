class Affiliation {
  final String aJobGradeCode; // 직급 코드
  Affiliation({required this.aJobGradeCode});
  Affiliation.fromMap(Map<String, dynamic> res)
    : aJobGradeCode = res['aJobGradeCode'];
}