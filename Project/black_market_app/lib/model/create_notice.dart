import 'dart:typed_data';

class CreateNotice {
  final String cuserid; // 회원 코드
  final String cajobGradeCode; // 직급 코드
  final String title; // 제목
  final String content; // 내용
  final String date; // 날짜
  final Uint8List photo; // 사진
  
  CreateNotice(
    {
    required this.cuserid,
    required this.cajobGradeCode,
    required this.title,
    required this.content,
    required this.date,
    required this.photo
    }
  );
  CreateNotice.fromMap(Map<String, dynamic> res)
  : cuserid = res['cuserid'],
  cajobGradeCode = res['cajobGradeCode'],
  title = res['title'],
  content = res['content'],
  date = res['date'],
  photo = res['photo'];
}
