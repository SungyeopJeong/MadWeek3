import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:week3/const/color.dart';
import 'package:week3/models/edge.dart';
import 'package:week3/models/node.dart';
import 'package:week3/viewmodels/graph_view_model.dart';
import 'package:week3/viewmodels/note_view_model.dart';

class NoteView extends StatefulWidget {
  const NoteView({
    super.key,
    required this.node,
    required this.onClose,
  });
  final Node node;
  final void Function() onClose;

  @override
  State<NoteView> createState() => _NoteViewState();
}

class _NoteViewState extends State<NoteView> {
  //텍스트 수정을 위한 선언
  bool isExpanded = false; // true -> 전체화면, false -> 1/3
  bool isNoteEditing = false;
  late NoteViewModel noteViewModel; // 클래스 멤버 변수로 선언

  @override
  void initState() {
    super.initState();

    // initState에서 NoteViewModel의 참조를 저장합니다.
    // Provider.of를 사용하여 context에 안전하게 접근
    noteViewModel = Provider.of<NoteViewModel>(context, listen: false);
    noteViewModel.titleController.text = widget.node.post.title;
    noteViewModel.contentController.text = widget.node.post.markdownContent;
  }

  @override
  void dispose() {
    super.dispose();
    isExpanded = false;
  }

  void _togglePopupSize() {
    // 현재 상태를 반전시킵니다.
    setState(() {
      isExpanded = !isExpanded;
    });
    // StellarView에 현재 팝업의 상태를 전달합니다.
    Provider.of<NoteViewModel>(context, listen: false)
        .updatePopupWidth(isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isNoteEditing) _enterViewMode();
      },
      behavior: HitTestBehavior.opaque,
      child: _buildNoteContainer(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderRow(),
            const SizedBox(height: 8),
            _buildTitleSection(),
            const SizedBox(height: 16),
            _buildContentSection(),
          ],
        ),
      ),
    );
  }

  void _enterViewMode() {
    setState(() {
      isNoteEditing = false;
    });
  }

  // 노트뷰에서 편집모드 -> 뷰모드로의 전환 함수
  void _enterEditMode() {
    setState(() {
      isNoteEditing = true;
    });
  }

  // 노트 뷰 컨테이너 위젯
  Widget _buildNoteContainer(Widget child) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    double sidepadding =
        isExpanded ? screenWidth / 4 : 32; // 확장되었을 때 0, 아닐 때 1/4
    // 팝업의 너비를 상태에 따라 결정합니다.
    // final popupWidth = isExpanded ? screenWidth : screenWidth / 3 - 32;
    // final popupHeight = isExpanded ? screenHeight : screenHeight - 32;
    return Container(
      width: screenWidth,
      height: screenHeight,

      padding: EdgeInsets.symmetric(
          horizontal: sidepadding, vertical: 16), // 좌우 32, 위아래 16 패딩
      decoration: BoxDecoration(
        color: MyColor.onSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: MyColor.shadow,
            blurRadius: 10,
          ),
        ],
      ),
      child: child, // 내부 내용은 주어진 child 위젯으로 동적 할당
    );
  }

  // 노트뷰의 상단, 아이콘 배치 위젯
  Widget _buildHeaderRow() {
    return Row(
      children: [
        IconButton(
          icon: Icon(isExpanded ? Icons.close_fullscreen : Icons.open_in_full),
          onPressed: _togglePopupSize,
        ),
        SizedBox(width: 2), // 간격 조절
        if (isNoteEditing)
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _enterViewMode,
          )
        else
          IconButton(
            icon: const Icon(Icons.my_library_books_rounded),
            onPressed: _enterEditMode,
          ),
        SizedBox(width: 2), // 간격 조절
        IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.red),
          onPressed: _showDeleteConfirmation,
        ),
        Expanded(
          // 나머지 공간을 채우기 위해 Expanded 위젯 사용
          child: Container(),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              _enterViewMode();
              if (widget.node is Star) {
                (widget.node as Star).showOrbit = false;
              }
              widget.onClose();
            });
          },
        ),
      ],
    );
  }

  // 삭제 확인 대화상자를 표시하는 함수
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('정말 삭제하시겠습니까?'),
          content: const Text('이 작업을 수행하면 되돌릴 수 없습니다.'),
          actions: <Widget>[
            TextButton(
              child: const Text('삭제하기'),
              onPressed: () {
                Navigator.of(context).pop(); // 대화상자 닫기
                context.read<GraphViewModel>().removeNode(widget.node);
                if (widget.node is Star) {
                  final edges = context.read<GraphViewModel>().edges;
                  final addEdges = [];
                  for (final edge1 in edges) {
                    for (final edge2 in edges) {
                      if (edge1 == edge2) continue;
                      if (edge1.contains(widget.node) &&
                          edge2.contains(widget.node)) {
                        addEdges.add(Edge(edge1.other(widget.node)!,
                            edge2.other(widget.node)!));
                      }
                    }
                  }
                  for (Edge edge in addEdges) {
                    context
                        .read<GraphViewModel>()
                        .addEdge(edge.start, edge.end);
                  }
                  context
                      .read<GraphViewModel>()
                      .edges
                      .removeWhere((edge) => edge.contains(widget.node));
                }
                widget.onClose();
              },
            ),
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  //note_view의 타이틀 섹션 위젯, 클릭하면 editmode로 전환
  Widget _buildTitleSection() {
    final noteViewModel = context.watch<NoteViewModel>(); // ViewModel 가져오기
    return isNoteEditing
        ? TextField(
            controller: noteViewModel.titleController,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              hintText: 'Enter title',
              border: InputBorder.none,
            ),
            onChanged: (value) {
              widget.node.post.title = value;
            },
          )
        : GestureDetector(
            onTap: _enterEditMode,
            child: Text(
              noteViewModel.titleController.text, // ViewModel의 컨트롤러에서 제목 가져오기
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          );
  }

  //note_view의 컨텐츠 섹션 위젯, 클릭하면 editmode로 전환
  Widget _buildContentSection() {
    final noteViewModel = context.watch<NoteViewModel>(); // ViewModel 가져오기

    return Expanded(
      child: isNoteEditing
          ? TextField(
              controller: noteViewModel.contentController,
              style: const TextStyle(fontSize: 16),
              minLines: 10,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Enter content',
                border: InputBorder.none,
              ),
              onChanged: (value) {
                widget.node.post.markdownContent = value;
              },
            )
          : GestureDetector(
              onTap: _enterEditMode,
              child: MarkdownBody(
                softLineBreak: true,
                data: widget.node.post.markdownContent,
                styleSheet: MarkdownStyleSheet.fromTheme(
                  Theme.of(context),
                ).copyWith(
                  p: Theme.of(context)
                      .textTheme
                      .bodyLarge!
                      .copyWith(fontSize: 16), // 폰트 크기 16으로 설정
                ),
              ),
            ),
    );
  }
}
