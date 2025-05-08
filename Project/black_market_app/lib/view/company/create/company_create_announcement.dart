// company_create_announcement.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // GetX 임포트 (Snackbar 등 사용)
import 'package:intl/intl.dart'; // 날짜 포맷을 위해 intl 패키지 사용
import 'package:image_picker/image_picker.dart'; // 사진 첨부를 위해 image_picker 패키지 사용
import 'dart:io'; // File 객체 사용을 위해 임포트
import 'dart:typed_data'; // Uint8List (BLOB) 타입 사용을 위해 임포트

// DatabaseHandler 임포트
import 'package:black_market_app/vm/database_handler.dart';
// 커스텀 위젯 임포트
import 'package:black_market_app/utility/custom_button.dart';
import 'package:black_market_app/utility/custom_textfield.dart';
// CustomButtonCalender는 공지사항 작성일 자동 설정이므로 필요 없을 수 있습니다.

class CompanyCreateAnnouncement extends StatefulWidget {
  const CompanyCreateAnnouncement({super.key});

  @override
  State<CompanyCreateAnnouncement> createState() =>
      _CompanyCreateAnnouncementState();
}

class _CompanyCreateAnnouncementState extends State<CompanyCreateAnnouncement> {
  late DatabaseHandler handler;

  // 입력 필드 컨트롤러
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  // 자동 설정될 정보
  // TODO: 실제 로그인된 본사 사용자의 ID와 직급 코드를 가져오는 로직 구현 필요
  String _cuserid = 'YOUR_LOGGED_IN_USER_ID'; // <<< 중요: 실제 사용자 ID로 바꿔주세요!
  String _cajobGradeCode = 'YOUR_JOB_GRADE_CODE'; // <<< 중요: 실제 직급 코드로 바꿔주세요!
  String _date = DateFormat('yyyy-MM-dd').format(DateTime.now()); // 현재 날짜 자동 설정

  // 사진 첨부 관련 상태
  File? _photoFile; // 첨부된 사진 파일
  Uint8List? _photoBytes; // BLOB 저장을 위한 사진 바이트 데이터

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler(); // 핸들러 인스턴스 생성
  }

  @override
  void dispose() {
    // 컨트롤러 메모리 해제
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // ------------ functions ---------------- //

  // 사진 첨부 기능
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    // 갤러리에서 이미지 선택
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      // 선택된 파일을 File 객체로 변환
      final File file = File(pickedFile.path);
      // 파일을 바이트 데이터 (Uint8List)로 읽기
      final Uint8List bytes = await file.readAsBytes();

      setState(() {
        _photoFile = file; // UI 표시용 (필요하다면)
        _photoBytes = bytes; // DB 저장을 위한 바이트 데이터
      });
      Get.snackbar(
        '사진 첨부',
        '사진이 성공적으로 첨부되었습니다.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        '사진 첨부',
        '사진 선택이 취소되었습니다.',
        backgroundColor: Colors.grey,
        colorText: Colors.white,
      );
    }
  }

  // 공지사항 등록 액션
  void _createAnnouncement() async {
    // 입력 값 가져오기
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // 필수 필드 검증 (제목과 내용은 필수라고 가정)
    if (title.isEmpty || content.isEmpty) {
      Get.snackbar(
        '오류',
        '제목과 내용을 입력해주세요.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return; // 함수 종료
    }

    // 공지사항 정보를 Map 형태로 준비 (DB insert 메서드는 Map을 받도록 설계)
    // createNotice 테이블 스키마에 맞춰 키 이름 사용: cuserid, cajobGradeCode, title, content, date, photo
    final noticeData = {
      'cuserid': _cuserid, // 로그인된 사용자 ID (자동 설정)
      'cajobGradeCode': _cajobGradeCode, // 로그인된 사용자 직급 코드 (자동 설정)
      'title': title, // 입력된 제목
      'content': content, // 입력된 내용
      'date': _date, // 현재 날짜 (자동 설정)
      'photo': _photoBytes, // 첨부된 사진 바이트 데이터 (없으면 null)
    };

    // 데이터베이스에 공지사항 기록 삽입
    try {
      print('>>> 공지사항 삽입 시도: $noticeData'); // 로깅 추가
      int result = await handler.insertNotice(noticeData);
      print('>>> 공지사항 삽입 결과 (rowId): $result'); // 로깅 추가

      if (result > 0) {
        // 삽입 성공 (반환된 row ID가 0보다 크면 성공)
        print('>>> 공지사항 성공적으로 삽입됨.'); // 로깅 추가
        // 삽입 성공
        Get.snackbar(
          '등록 성공',
          '공지사항이 성공적으로 등록되었습니다.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        // 성공 시 입력 필드 초기화 및 상태 재설정
        _titleController.clear();
        _contentController.clear();
        setState(() {
          _photoFile = null; // 사진 상태 초기화
          _photoBytes = null; // 사진 바이트 초기화
          // _date는 현재 날짜로 유지하거나 필요에 따라 다시 설정
        });

        // 필요하다면 공지사항 목록 페이지 등으로 이동
        // Get.back();
      } else {
        // 삽입 실패 (insertNotice 결과 <= 0)
        print('>>> 공지사항 삽입 실패 (insertNotice 결과 <= 0).'); // 로깅 추가
        // 삽입 실패
        Get.snackbar(
          '등록 실패',
          '공지사항 등록에 실패했습니다.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      // 데이터베이스 작업 중 예외 발생 (삽입 시)
      print('>>> 데이터베이스 작업 중 예외 발생: ${e.toString()}'); // 오류 메시지 포함 로깅 추가
      // 데이터베이스 작업 중 예외 발생
      Get.snackbar(
        '오류',
        '공지사항 등록 중 오류가 발생했습니다: ${e.toString()}', // 오류 메시지 포함
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(context) {
    // GetX 사용을 위해 context 대신 build(context) 사용
    return Scaffold(
      appBar: AppBar(
        title: Text('공지사항 작성'), // 제목
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        // 스크롤 가능하도록 SingleChildScrollView 추가
        padding: const EdgeInsets.all(16.0), // 패딩 추가
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // 가로로 늘이기
          children: [
            // 작성자 정보 (자동 설정되며 표시만 함)
            Text(
              '작성자 ID: $_cuserid',
              style: TextStyle(fontSize: 14, color: Colors.blueGrey),
            ),
            SizedBox(height: 4),
            Text(
              '작성자 직급 코드: $_cajobGradeCode',
              style: TextStyle(fontSize: 14, color: Colors.blueGrey),
            ),
            SizedBox(height: 4),
            Text(
              '작성일: $_date',
              style: TextStyle(fontSize: 14, color: Colors.blueGrey),
            ),
            SizedBox(height: 16),

            // TextField: 제목
            Text(
              '제목',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            CustomTextField(
              // CustomTextField 사용
              label: '제목을 입력하세요',
              controller: _titleController,
            ),
            SizedBox(height: 16),

            // TextField: 내용
            Text(
              '내용',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            CustomTextField(
              // CustomTextField 사용
              label: '내용을 입력하세요',
              controller: _contentController,
            ),
            SizedBox(height: 16),

            // 사진 첨부 버튼 및 미리보기
            Text(
              '사진 첨부 (선택 사항)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ElevatedButton.icon(
              // 표준 ElevatedButton 사용
              onPressed: _pickImage, // 사진 첨부 함수 연결
              icon: Icon(Icons.attach_file),
              label: Text(
                _photoFile == null
                    ? '사진 선택'
                    : '사진 다시 선택 (${_photoFile!.path.split('/').last})',
              ), // 파일 이름 표시
            ),
            if (_photoFile != null) // 사진 미리보기 (파일 경로 또는 바이트 사용)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                // Image.file(_photoFile!, height: 150), // File 객체로 미리보기
                child: Image.memory(_photoBytes!, height: 150), // 바이트 데이터로 미리보기
              ),
            SizedBox(height: 24),
            // 공지사항 등록 버튼
            Center(
              // 버튼을 중앙에 배치
              child: CustomButton(
                // CustomButton 사용
                text: '공지사항 등록',
                onPressed: _createAnnouncement, // 공지사항 등록 함수 연결
                // CustomButton 스타일 조정은 위젯 내부에서 처리
              ),
            ),
            SizedBox(height: 16), // 하단 간격
          ],
        ),
      ),
    );
  }
}
