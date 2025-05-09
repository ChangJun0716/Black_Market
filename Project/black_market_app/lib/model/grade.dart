class Grade {
final String jobGradeCode; // 직급 코드
  final String gradeName; // 직급 명
  // 소속 날짜
  Grade({
    required this.jobGradeCode,
    required this.gradeName,
    
  });
  Grade.fromMap(Map<String, dynamic> res)
    : jobGradeCode = res['jobGradeCode'],
      gradeName = res['gradeName'];
}