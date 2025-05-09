//재조사 입력 페이지
import 'package:black_market_app/model/manufacturers.dart';
import 'package:black_market_app/vm/database_handler.dart';
import 'package:flutter/material.dart';

class CompanyCreateManufacturer extends StatefulWidget {
  const CompanyCreateManufacturer({super.key});

  @override
  State<CompanyCreateManufacturer> createState() => _CompanyCreateManufacturerState();
}

class _CompanyCreateManufacturerState extends State<CompanyCreateManufacturer> {
  final TextEditingController _nameController = TextEditingController();
  late DatabaseHandler handler;

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
  }

  void _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제조사명을 입력해주세요.')),
      );
      return;
    }

    final manufacturer = Manufacturers(manufacturerName: name);
    await handler.insertManufacturer(manufacturer);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('제조사가 등록되었습니다.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('제조사 등록')),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: '제조사명',
                labelStyle: TextStyle(color: Colors.white),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('등록하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
