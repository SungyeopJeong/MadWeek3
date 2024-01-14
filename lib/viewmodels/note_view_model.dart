import 'package:flutter/material.dart';

class NoteViewModel extends ChangeNotifier {
  TextEditingController titleController = TextEditingController(),
      contentController = TextEditingController();
}
