import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:week3/models/node.dart';
import 'package:week3/viewmodels/note_view_model.dart';

class NoteView extends StatefulWidget {
  const NoteView({
    super.key,
    required this.star,
    required this.onClose,
  });
  final Star star;
  final void Function() onClose;

  @override
  State<NoteView> createState() => _NoteViewState();
}

class _NoteViewState extends State<NoteView> {
  //텍스트 수정을 위한 선언
  bool isNoteEditing = false;

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
    return Container(
      width: MediaQuery.of(context).size.width / 3 - 32,
      padding: const EdgeInsets.symmetric(
          horizontal: 32, vertical: 16), // 좌우 32, 위아래 16 패딩
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
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
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              _enterViewMode();
              widget.star.showOrbit = false;
              widget.onClose();
            });
          },
        ),
      ],
    );
  }

  //note_view의 타이틀 섹션 위젯, 클릭하면 editmode로 전환
  Widget _buildTitleSection() {
    return isNoteEditing
        ? _buildTitleTextField()
        : GestureDetector(
            onTap: _enterEditMode,
            child: Text(
              widget.star.post.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          );
  }

  //note_view의 컨텐츠 섹션 위젯, 클릭하면 editmode로 전환
  Widget _buildContentSection() {
    return Expanded(
      child: isNoteEditing
          ? _buildContentTextField()
          : GestureDetector(
              onTap: _enterEditMode,
              child: MarkdownBody(
                softLineBreak: true,
                data: widget.star.post.markdownContent,
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

  Widget _buildTitleTextField() {
    return TextField(
      controller: context.read<NoteViewModel>().titleController,
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      decoration: const InputDecoration(
        hintText: 'Enter title',
        border: InputBorder.none,
      ),
      onChanged: (value) {
        widget.star.post.title = value;
      },
    );
  }

  Widget _buildContentTextField() {
    return TextField(
      controller: context.read<NoteViewModel>().contentController,
      style: const TextStyle(fontSize: 16),
      maxLines: null, // 텍스트 필드가 여러 줄을 차지할 수 있도록 설정
      decoration: const InputDecoration(
        hintText: 'Enter content',
        border: InputBorder.none,
      ),
      onChanged: (value) {
        widget.star.post.markdownContent = value;
      },
    );
  }
}
