import 'dart:convert';
import 'dart:typed_data';

class ProductRegistration {
  final String paUserid;
  final String pProductCode;
  final Uint8List introductionPhoto;
  final String ptitle;
  final List<Uint8List> contentBlocks;

  ProductRegistration({
    required this.paUserid,
    required this.pProductCode,
    required this.introductionPhoto,
    required this.ptitle,
    required this.contentBlocks,
  });

  factory ProductRegistration.fromMap(Map<String, dynamic> map) {
    return ProductRegistration(
      paUserid: map['paUserid'],
      pProductCode: map['pProductCode'],
      introductionPhoto: base64Decode(map['introductionPhoto']),
      ptitle: map['ptitle'],
      contentBlocks: (jsonDecode(map['contentBlocks']) as List)
          .map((e) => base64Decode(e as String))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'paUserid': paUserid,
      'pProductCode': pProductCode,
      'introductionPhoto': base64Encode(introductionPhoto),
      'ptitle': ptitle,
      'contentBlocks': jsonEncode(contentBlocks.map((e) => base64Encode(e)).toList()),
    };
  }
}
