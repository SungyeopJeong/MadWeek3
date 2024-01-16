import 'package:flutter/material.dart';

class NoteViewModel extends ChangeNotifier {
  TextEditingController titleController = TextEditingController(),
      contentController = TextEditingController();

  // 팝업이 전체 화면으로 확장되었는지 여부를 나타내는 플래그입니다.
  bool _isPopupExpanded = false;

  // 팝업 확장 상태를 가져오는 getter
  bool get isPopupExpanded => _isPopupExpanded;

  // 팝업 확장 상태를 업데이트하는 메서드
  void updatePopupWidth(bool isExpanded) {
    _isPopupExpanded = isExpanded;
    notifyListeners(); // 상태 변경을 알려 UI를 업데이트
  }
}
