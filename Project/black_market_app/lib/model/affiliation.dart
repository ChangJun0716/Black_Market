class Affiliation {
  final String aJobGradeCode; // 직급 코드
  final String aUserid;
  Affiliation({required this.aJobGradeCode, required this.aUserid});
  Affiliation.fromMap(Map<String, dynamic> res)
    : aJobGradeCode = res['aJobGradeCode'],
      aUserid = res['aUserid'];
}
