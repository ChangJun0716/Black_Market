import 'package:flutter/material.dart';

class CustomButtonCalender extends StatefulWidget {
  final DateTime? initialDate;
  final void Function(DateTime) onDateSelected;
  final String label;

  const CustomButtonCalender({
    super.key,
    this.initialDate,
    required this.onDateSelected,
    required this.label,
  });

  @override
  State<CustomButtonCalender> createState() => _CustomButtonCalenderState();
}

class _CustomButtonCalenderState extends State<CustomButtonCalender> {
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
  }

  Future<void> pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? result = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (result != null) {
      setState(() {
        selectedDate = result;
      });
      widget.onDateSelected(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String displayText =
        selectedDate == null
            ? widget.label
            : '선택한 날짜 : ${selectedDate!.toLocal().toString().split(' ')[0]}';

    return ElevatedButton(onPressed: pickDate, child: Text(displayText));
  }
}
