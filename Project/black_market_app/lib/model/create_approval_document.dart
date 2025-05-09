class CreateApprovalDocument {//발주서 
  final String cUserid; // 유저 pk
  final String cajobGradeCode; // 소속 PK
  final String checkGradeCode;
  final String name; // 이름
  final String title; // 제목
  final String content; // 내용
  final DateTime date; // 날짜 없어서 추가했음
  final String approvalStatus; // 승인 상태
  final int approvalRequestExpense; // 결재 품의비
  final int corderID; //발주 신청된 발주서 그룹된거 


  CreateApprovalDocument({
    required this.cUserid,
    required this.cajobGradeCode,
    required this.checkGradeCode,
    required this.name,
    required this.title,
    required this.content,
    required this.date,
    required this.approvalStatus,
    required this.approvalRequestExpense,
    required this.corderID
  });

  CreateApprovalDocument.fromMap(Map<String, dynamic> res)
    : cUserid = res['cUserid'],
      cajobGradeCode = res['cajobGradeCode'],
      checkGradeCode =res['checkGradeCode'],
      name = res['name'],
      title = res['title'],
      content = res['content'],
      date = res['date'],
      approvalStatus = res['approvalStatus'],
      approvalRequestExpense = res['approvalRequestExpense'],
      corderID = res['corderID'];
}
