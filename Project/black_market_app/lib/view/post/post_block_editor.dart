import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'post_block.dart';

class PostBlockEditor extends StatefulWidget {
  final List<PostBlock> blocks;
  final ValueChanged<List<PostBlock>> onChanged;

  const PostBlockEditor({
    super.key,
    required this.blocks,
    required this.onChanged,
  });

  @override
  State<PostBlockEditor> createState() => _PostBlockEditorState();
}

class _PostBlockEditorState extends State<PostBlockEditor> {
  final _textController = TextEditingController();

  void _addTextBlock() {
    if (_textController.text.trim().isNotEmpty) {
      widget.blocks.add(PostBlock(type: 'text', text: _textController.text));
      _textController.clear();
      widget.onChanged(widget.blocks);
      setState(() {});
    }
  }

  Future<void> _addImageBlock() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      widget.blocks.add(PostBlock(type: 'image', image: bytes));
      widget.onChanged(widget.blocks);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("제품 소개", style: TextStyle(color: Colors.white, fontSize: 16)),
        TextField(
          controller: _textController,
          decoration: const InputDecoration(
            hintText: '텍스트 입력',
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: _addTextBlock,
              child: const Text('텍스트 추가'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _addImageBlock,
              child: const Text('이미지 추가'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...widget.blocks.map((block) {
          if (block.type == 'text' && block.text != null) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(block.text!, style: const TextStyle(color: Colors.white)),
            );
          } else if (block.type == 'image' && block.image != null) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Image.memory(block.image!, height: 150),
            );
          }
          return const SizedBox.shrink();
        }).toList()
      ],
    );
  }
}
