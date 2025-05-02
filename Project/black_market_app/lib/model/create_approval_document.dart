class CreateApprovalDocument {
  final String cUserid; // 유저 pk
  final String cajobGradeCode; // 소속 PK
  final String name; // 이름
  final String title; // 제목
  final String content; // 내용
  final DateTime date; // 날짜 없어서 추가했음
  final String rejectedReason; // 반려 사유
  final String approvalStatus; // 승인 상태
  final int approvalRequestExpense; // 결재 품의비

  CreateApprovalDocument({
    required this.cUserid,
    required this.cajobGradeCode,
    required this.name,
    required this.title,
    required this.content,
    required this.date,
    required this.rejectedReason,
    required this.approvalStatus,
    required this.approvalRequestExpense,
  });

  CreateApprovalDocument.fromMap(Map<String, dynamic> res)
    : cUserid = res['cUserid'],
      cajobGradeCode = res['cajobGradeCode'],
      name = res['name'],
      title = res['title'],
      content = res['content'],
      date = res['date'],
      rejectedReason = res['rejectedReason'],
      approvalStatus = res['approvalStatus'],
      approvalRequestExpense = res['approvalRequestExpense'];
}
