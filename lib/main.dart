import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:week3/viewmodels/note_view_model.dart';
import 'package:week3/views/stellar_view.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NoteViewModel()),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: StellarView(),
        ),
      ),
    );
  }
}
