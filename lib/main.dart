import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:week3/const/color.dart';
import 'package:week3/models/graph.dart';
import 'package:week3/models/node.dart';
import 'package:week3/viewmodels/note_view_model.dart';
import 'package:week3/viewmodels/graph_view_model.dart';
import 'package:week3/views/note_view.dart';
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
        ChangeNotifierProvider(create: (_) => GraphViewModel()),
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

  // 스플릿 뷰의 너비 상태를 추가합니다.
  double nodeListWidth = 0;

  Graph graph = Graph(); // 그래프 객체

  void toggleNodeList() {
    setState(() {
      nodeListWidth = isNodeListVisible ? 0 : 300;
      isNodeListVisible = !isNodeListVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildSideView(), // 사이드 뷰를 별도의 함수로 분리하여 호출
          _buildMainNavigator(),
          if (!isNodeListVisible) _buildFAB(),
        ],
      ),
    );
  }

  // 사이드 뷰를 구성하는 별도의 함수
  Widget _buildSideView() {
    return AnimatedPositioned(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: isNodeListVisible ? 0 : -200, // 사이드 뷰가 보이거나 숨겨질 때의 위치
      top: 0,
      bottom: 0,
      width: 200, // 사이드 뷰의 너비
      child: Material(
        color: Colors.grey[850],
        elevation: 4.0, // 사이드 뷰에 그림자 효과를 주기 위해 Material 위젯을 사용
        child: Column(
          children: [
            // 상단의 닫기 버튼을 감싸는 SafeArea
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8.0), // 여기에 패딩을 추가합니다.
                  child: IconButton(
                    icon: Icon(Icons.keyboard_double_arrow_left,
                        color: Colors.white),
                    onPressed: toggleNodeList,
                  ),
                ),
              ),
            ),
            // 나머지 공간을 차지하는 노드 리스트
            Expanded(
              child: _buildNodeList(),
            ),
          ],
        ),
      ),
    );
  }

  // 메인 내비게이터를 구성하는 별도의 함수
  Widget _buildMainNavigator() {
    return AnimatedPositioned(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: isNodeListVisible ? 200 : 0,
      right: 0,
      top: 0,
      bottom: 0,
      child: Navigator(
        key: navigatorKey,
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => StellarView(),
          );
        },
      ),
    );
  }

  // FAB를 구성하는 별도의 함수
  Widget _buildFAB() {
    return AnimatedPositioned(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: 16,
      left: 16,
      child: GestureDetector(
        // InkWell or GestureDetector for the tap
        onTap: toggleNodeList,
        child: Container(
          width: 48.0, // FAB의 기본 크기와 동일
          height: 48.0,
          decoration: BoxDecoration(
            color: MyColor.surface,
            boxShadow: [
              BoxShadow(
                color: MyColor.shadow, // 색상의 투명도 조절
                spreadRadius: 0,
                blurRadius: 4,
                offset: Offset(0, 0), // 그림자 위치 조절
              ),
            ],
            borderRadius: BorderRadius.circular(12), // 라운드 조절
          ),
          child: Icon(Icons.menu, color: MyColor.onSurface),
        ),
      ),
    );
  }

  // 노드 리스트를 빌드하는 함수
  Widget _buildNodeList() {
    return Consumer<GraphViewModel>(
      builder: (context, graphViewModel, child) {
        return ListView.builder(
          itemCount: graphViewModel.nodes.length,
          itemBuilder: (context, index) {
            Node node = graphViewModel.nodes[index];
            return ListTile(
              title: Text(
                node.post.title,
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                // 노드 상세 정보 표시
              },
            );
          },
        );
      },
    );
  }
}
