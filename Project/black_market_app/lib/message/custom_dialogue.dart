import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomDialogue {
  void showDialogue({
    required String title,
    required String middleText,
    String? confirmText,
    VoidCallback? onConfirm,
    String? cancelText,
    VoidCallback? onCancel,

  }) {
    List<Widget> actions = [];

    if (cancelText != null && onCancel != null) {
      actions.add(
        TextButton(
          onPressed: () {
            Get.back(); 
            onCancel();
          },
          child: Text(cancelText),
        ),
      );
    }

    if (confirmText != null && onConfirm != null) {
      actions.add(
        TextButton(
          onPressed: () {
            Get.back(); 
            onConfirm();
          },
          child: Text(confirmText),
        ),
      );
    }

    Get.defaultDialog(
      title: title,
      middleText: middleText,
      barrierDismissible: false,
      actions: actions,
    );
  }
}
// ----- if only cancel button ----- //
/* 
CustomDialogue().showDialogue(
  title: '알림',
  middleText: '저장되었습니다.',
  confirmText: '확인',
  onConfirm: () {
    print('확인 클릭됨');
  },
);
*/
// ----- if use two buttons ----- //
/* 
CustomDialogue().showDialogue(
  title: '삭제하시겠습니까?',
  middleText: '삭제하면 복구할 수 없습니다.',
  confirmText: '삭제',
  onConfirm: () {
    print('삭제 실행');
  },
  cancelText: '취소',
  onCancel: () {
    print('취소됨');
  },
);
*/