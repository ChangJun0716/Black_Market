class Users {
  final String userid; // 회원 아이디
  final String password; // 회원 비밀번호
  final String name; // 이름
  final String phone; // 전화번호
  final int memberType; // 분류
  final String birthDate; // 생년월일
  final String gender; // 성별

  Users({
    required this.userid,
    required this.password,
    required this.name,
    required this.phone,
    required this.memberType,
    required this.birthDate,
    required this.gender,
  });
  Users.fromMap(Map<String, dynamic> res)
    : userid = res['id'],
      password = res['password'],
      name = res['name'],
      phone = res['phone'],
      memberType = res['memberType'],
      birthDate = res['birthDate'],
      gender = res['gender'];
}
