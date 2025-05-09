class Affiliation {
  final String aJobGradeCode; // 직급 코드
  final String aUserid; //유저 아이디
  final String joinDate;

  Affiliation({
    required this.aJobGradeCode, 
    required this.aUserid,
    required this.joinDate
    });
    

  Affiliation.fromMap(Map<String, dynamic> res)
    : aJobGradeCode = res['aJobGradeCode'],
      aUserid = res['aUserid'],
      joinDate = res['joinDate;']
      ;
}
