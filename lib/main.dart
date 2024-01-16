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
      child: MaterialApp(
        home: SplitScreen(),
      ),
    );
  }
}

class SplitScreen extends StatefulWidget {
  const SplitScreen({Key? key}) : super(key: key);

  @override
  _SplitScreenState createState() => _SplitScreenState();
}

class _SplitScreenState extends State<SplitScreen> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  bool isNodeListVisible = false;

  void toggleNodeList() {
    setState(() {
      isNodeListVisible = !isNodeListVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 메인 컨텐츠: SplitView
          Row(
            children: [
              // // 왼쪽에 NodeList를 표시하는 부분
              // isNodeListVisible
              //     ? Expanded(
              //         child: DirectoryView(), // NodeList를 빌드하는 함수나 위젯을 여기에 배치
              //       )
              //     : Container(),
              // 오른쪽에 StellarView를 포함하는 Navigator
              Expanded(
                child: Navigator(
                  key: navigatorKey,
                  onGenerateRoute: (settings) {
                    return MaterialPageRoute(
                        builder: (context) => StellarView());
                  },
                ),
              ),
            ],
          ),
          // 오른쪽 상단에 FAB 배치
          Positioned(
            top: 32,
            right: 32,
            child: FloatingActionButton(
              onPressed: toggleNodeList,
              child: Icon(isNodeListVisible ? Icons.close : Icons.menu),
            ),
          ),
        ],
      ),
    );
  }
}
