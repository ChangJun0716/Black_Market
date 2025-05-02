class CreateApprovalDocument {
  final String cuserId; // 회원 PK
  final String cajobGradeCode; // 소속 PK
  final String name; // 이름
  final String title; // 제목
  final String content; // 내용
  final String rejectedReason; // 반려 사유
  final String approvalStatus; // 승인 상태
  final int approvalRequestExpense; // 결재 품의비

  CreateApprovalDocument(
    {
    required this.cuserId,
    required this.cajobGradeCode,
    required this.name,
    required this.title,
    required this.content,
    required this.rejectedReason,
    required this.approvalStatus,
    required this.approvalRequestExpense
    }
  );

  CreateApprovalDocument.fromMap(Map<String, dynamic>res)
  : cuserId = res['cuserId'],
  cajobGradeCode = res['cajobGradeCode'],
  name = res['name'],
  title = res['title'],
  content = res['content'],
  rejectedReason = res['rejectedReason'],
  approvalStatus = res['approvalStatus'],
  approvalRequestExpense = res['approvalRequestExpense'];
}
