class ReturnInvestigation {
  final String raUserid; // 회원 pk
  final String raJobGradeCode; // 반품 원인 규명 기록
  final int rreturnCode; // 반품 코드
  final String rmanufacturerName; // 제조사명
  final DateTime recordDate; // 기록 날짜
  final String resolutionDetails; // 처리 상황
  ReturnInvestigation({
    required this.raUserid,
    required this.raJobGradeCode,
    required this.rreturnCode,
    required this.rmanufacturerName,
    required this.recordDate,
    required this.resolutionDetails,
  });
  ReturnInvestigation.fromMap(Map<String, dynamic> res)
    : raUserid = res['raUserid'],
      raJobGradeCode = res['raJobGradeC'],
      rreturnCode = res['rreturnCode'],
      rmanufacturerName = res['rmanufacturerName'],
      recordDate = res['recordDate'],
      resolutionDetails = res['resolutionDetails'];
}
