class ApprovalStep {
  final int documentId; // CreateApprovalDocument의 corderID 또는 고유 식별자
  final int stepOrder; // 결재 단계 순서 (1, 2, 3...)
  final String approverId; // 결재자 사용자 ID
  final String status; // '대기', '승인', '반려'
  final String? comment; // 결재 의견
  final DateTime? actionDate; // 결재 수행 일시

  ApprovalStep({
    required this.documentId,
    required this.stepOrder,
    required this.approverId,
    required this.status,
    this.comment,
    this.actionDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'documentId': documentId,
      'stepOrder': stepOrder,
      'approverId': approverId,
      'status': status,
      'comment': comment,
      'actionDate': actionDate?.toIso8601String(),
    };
  }

  factory ApprovalStep.fromMap(Map<String, dynamic> map) {
    return ApprovalStep(
      documentId: map['documentId'],
      stepOrder: map['stepOrder'],
      approverId: map['approverId'],
      status: map['status'],
      comment: map['comment'],
      actionDate: map['actionDate'] != null ? DateTime.parse(map['actionDate']) : null,
    );
  }
}
