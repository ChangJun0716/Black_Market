import 'package:flutter/material.dart';
import 'package:get/get.dart';

// snackBar 의 경우 색상을 다르게 사용하는 경우가 있어 색상을 직접 선택 하도록 제작하였습니다.
class CustomSnackbar {
  showSnackbar({
    required String title,
    required String message,
    required Color backgroundColor,
    required Color textColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    Get.snackbar(
      title,
      message,
      backgroundColor: backgroundColor,
      colorText: textColor,
      snackPosition: SnackPosition.TOP,
      duration: duration,
    );
  }
}
