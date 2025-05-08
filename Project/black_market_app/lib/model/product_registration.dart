//제품 게시글 
import 'dart:convert';
import 'dart:typed_data';

import 'package:black_market_app/view/post/post_block.dart';


class ProductRegistration {
  final String paUserid; // 회원 pk 
  final String pProductCode; // 제품 코드
  final Uint8List introductionPhoto; // 대표 사진
  final String ptitle; // 제목
  final List<PostBlock> contentBlocks; // 본문 (텍스트 + 이미지 섞임)

  ProductRegistration({
    required this.paUserid,
    required this.pProductCode,
    required this.introductionPhoto,
    required this.ptitle,
    required this.contentBlocks,
  });

  Map<String, dynamic> toMap() => {
        'paUserid': paUserid,
        'pProductCode': pProductCode,
        'introductionPhoto': introductionPhoto,
        'ptitle': ptitle,
        'contentJson': jsonEncode(contentBlocks.map((e) => e.toMap()).toList()),
      };

  factory ProductRegistration.fromMap(Map<String, dynamic> res) {
    List<PostBlock> blocks = [];
    if (res['contentJson'] != null) {
      final List decoded = jsonDecode(res['contentJson']);
      blocks = decoded.map((e) => PostBlock.fromMap(e)).toList();
    }

    return ProductRegistration(
      paUserid: res['paUserid'],
      pProductCode: res['pProductCode'],
      introductionPhoto: res['introductionPhoto'],
      ptitle: res['ptitle'],
      contentBlocks: blocks,
    );
  }
}
