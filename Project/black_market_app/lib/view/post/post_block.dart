import 'dart:convert';
import 'dart:typed_data';

class PostBlock {
  final String type; // 'text' 또는 'image'
  final String? text;
  final Uint8List? image;

  PostBlock({
    required this.type,
    this.text,
    this.image,
  });

  Map<String, dynamic> toMap() => {
        'type': type,
        'text': text,
        'image': image != null ? base64Encode(image!) : null,
      };

  factory PostBlock.fromMap(Map<String, dynamic> map) => PostBlock(
        type: map['type'],
        text: map['text'],
        image: map['image'] != null ? base64Decode(map['image']) : null,
      );
}

