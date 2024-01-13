// ignore_for_file: prefer_cR   onst_constructors

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // Markdown 패키지 임포트
import 'package:week3/const/size.dart';
import 'package:week3/enums/mode.dart';
import 'package:week3/models/node.dart';
import 'package:week3/models/edge.dart';
import 'package:week3/models/post.dart';

class StellarView extends StatefulWidget {
  const StellarView({super.key});

  @override
  State<StellarView> createState() => _StellarViewState();
}

class _StellarViewState extends State<StellarView>
    with TickerProviderStateMixin {
  List<Node> nodes = [];
  List<Edge> edges = [];
  Node? origin;
  Mode mode = Mode.none;
  bool blackholeEnabled = false;
  bool get isStarSelected => selectedNode != null; // 별이 선택되었는지 여부를 추적하는 변수
  Node? selectedNode; // 선택된 노드 추적

  //텍스트 수정을 위한 선언
  bool isEditing = false;
  TextEditingController titleController = TextEditingController();
  TextEditingController contentController = TextEditingController();

  bool isIn(Offset leftTop, Offset rightBottom, Offset target, bool isCircle) {
    if (isCircle) {
      final center = (leftTop + rightBottom) / 2;
      final radius = leftTop.dx - center.dx;
      return (target - center).distanceSquared <= radius * radius;
    }
    return leftTop <= target && target <= rightBottom;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              const SingleActivator(LogicalKeyboardKey.keyI): () {
                setState(() {
                  mode = Mode.add;
                });
              }
            },
            child: Focus(
              autofocus: true,
              child: Stack(
                children: [
                  InteractiveViewer(
                    child: GestureDetector(
                      onTapDown: (details) {
                        if (mode == Mode.add) {
                          setState(() {
                            Node newNode = _createNode(
                              details.localPosition,
                              id: nodes
                                  .length, // 'id' is based on the length of 'nodes' list
                            )..post = Post(
                                title: "Title Here",
                                markdownContent:
                                    "Content Here"); // Create an associated empty Post

                            nodes.add(newNode);
                            mode = Mode.none;
                          });
                        }
                      },
                      onSecondaryTap: () {
                        // 마우스 오른쪽 클릭 이벤트 처리
                        setState(() {
                          mode = Mode.none; // 별 생성 모드 취소
                        });
                      },
                      child: MouseRegion(
                        cursor: mode == Mode.add
                            ? SystemMouseCursors.precise
                            : MouseCursor.defer,
                        child: Container(
                          color: Color(0xFFF3F0E9),
                          width: double.maxFinite,
                          height: double.maxFinite,
                          child: Stack(
                            children: [
                              ...nodes.map((star) => _buildNode(context, star)),
                              if (origin != null)
                                _buildOriginNode(origin!), // `origin` 위젯 추가
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _buildBlackhole(),
                ],
              ),
            ),
          ),
          _buildTextView(), // 여기에 넣고 싶음.
        ],
      ),
      floatingActionButton: GestureDetector(
        onTapUp: (details) {
          setState(() {
            mode = Mode.add;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFF4D4D4D),
            shape: BoxShape.circle,
          ),
          width: 60,
          height: 60,
          child: Icon(
            Icons.insights,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Node _createNode(Offset position, {int id = -1}) {
    return Node(
      position,
      //d: id,
    )..planetAnimation = AnimationController(
        vsync: this,
        upperBound: 2 * pi,
        duration: Duration(seconds: 10),
      );
  }

  Widget _buildNode(BuildContext context, Node node) {
    if (node.isDeleting) {
      return TweenAnimationBuilder(
        tween: Tween(
          begin: node.pos,
          end: Offset(0, MediaQuery.of(context).size.height),
        ),
        duration: Duration(milliseconds: 250),
        onEnd: () {
          setState(() {
            nodes.remove(node);
          });
        },
        builder: (_, val, __) => Positioned(
          left: val.dx - areaSize / 2,
          top: val.dy - areaSize / 2,
          child: SizedBox(
            width: areaSize,
            height: areaSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildArea(node),
                _buildStar(),
              ],
            ),
          ),
        ),
      );
    }
    return Positioned(
      left: node.pos.dx - orbitSize / 2,
      top: node.pos.dy - orbitSize / 2,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (selectedNode != node) {
              // 새로운 노드를 선택한 경우, 이전 선택된 노드의 orbit을 해제
              if (selectedNode != null) {
                selectedNode!.showOrbit = false;
                selectedNode!.planetAnimation.reset();
              }
              selectedNode = node;
              selectedNode!.showOrbit = true;
              selectedNode!.planetAnimation.repeat();
            }
          });
        },
        onPanUpdate: (details) {
          setState(() {
            origin ??= _createNode(node.pos, id: -1);

            void updateOrbit(Node? other) {
              if (other == node || other == null) return;
              if ((other.pos - node.pos).distanceSquared <=
                  orbitSize * orbitSize / 4) {
                other.showOrbit = true;
                if (!other.planetAnimation.isAnimating) {
                  other.planetAnimation.repeat();
                }
              } else {
                other.showOrbit = false;
                if (other.planetAnimation.isAnimating) {
                  other.planetAnimation.reset();
                }
              }
            }

            for (final other in nodes) {
              updateOrbit(other);
            }
            if (mode == Mode.add) {
              updateOrbit(origin);
            }

            node.pos += details.delta;
          });
        },
        onPanEnd: (details) {
          setState(() {
            for (final node in nodes) {
              node.showOrbit = false;
            }

            origin = null; // `origin`을 `null`로 설정

            if (blackholeEnabled) {
              node.isDeleting = true;
            }
          });
        },
        child: SizedBox(
          width: orbitSize,
          height: orbitSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _buildOrbit(node),
              _buildArea(node),
              _buildStar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOriginNode(Node node) {
    return Positioned(
      left: node.pos.dx - orbitSize / 2,
      top: node.pos.dy - orbitSize / 2,
      child: SizedBox(
        width: orbitSize,
        height: orbitSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _buildOrbit(node),
            Opacity(
              opacity: 0.2,
              child: _buildStar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrbit(Node star) {
    return Visibility(
      visible: star.showOrbit,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Color(0xFFE5C33E).withOpacity(0.05),
              border: Border.all(color: Color(0xFFE5C33E)),
              shape: BoxShape.circle,
            ),
            width: orbitSize,
            height: orbitSize,
          ),
          /*TweenAnimationBuilder(
            tween: Tween(
              begin: 0,
              end: 2 * pi,
            ),
            duration: Duration(seconds: 10),
            builder: (_, val, __) => Positioned(
              left: (orbitSize * (cos(val) + 1) - planetSize) / 2,
              top: (orbitSize * (sin(val) + 1) - planetSize) / 2,
              child: _buildPlanet(),
            ),*/
          AnimatedBuilder(
            animation: star.planetAnimation,
            builder: (_, __) => Positioned(
              left: (orbitSize * (cos(star.planetAnimation.value) + 1) -
                      planetSize) /
                  2,
              top: (orbitSize * (sin(star.planetAnimation.value) + 1) -
                      planetSize) /
                  2,
              child: _buildPlanet(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildArea(Node star) {
    return Visibility(
      visible: star.showArea,
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFFE5C33E).withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        width: areaSize,
        height: areaSize,
      ),
    );
  }

  Widget _buildStar() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFE5C33E),
        shape: BoxShape.circle,
      ),
      width: starSize,
      height: starSize,
    );
  }

  Widget _buildPlanet() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFE5C33E),
        shape: BoxShape.circle,
      ),
      width: planetSize,
      height: planetSize,
    );
  }

  Widget _buildBlackhole() {
    return Positioned(
      left: -blackholeAreaSize / 2,
      bottom: -blackholeAreaSize / 2,
      child: MouseRegion(
        onEnter: (_) {
          setState(() {
            blackholeEnabled = true;
          });
        },
        onExit: (_) {
          setState(() {
            blackholeEnabled = false;
          });
        },
        child: Container(
          width: blackholeAreaSize,
          height: blackholeAreaSize,
          alignment: Alignment.center,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 100),
            decoration: BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
            width: blackholeEnabled ? blackholeMaxSize : blackholeMinSize,
            height: blackholeEnabled ? blackholeMaxSize : blackholeMinSize,
          ),
        ),
      ),
    );
  }

  /*
    선택한 별이 있는지 확인하고 선택된게 있다면 해당 Node의 Post의 title과 markdownContent를 불러와서 화면에 보여주는 위젯
  */
  Widget _buildTextView() {
    if (!isStarSelected) {
      return SizedBox
          .shrink(); // If no star is selected, return an empty widget.
    }
    return Positioned(
        top: 32,
        right: 32,
        bottom: 32,
        child: GestureDetector(
          onTap: () {
            // 텍스트 필드 외부를 클릭했을 때 편집 모드 종료
            if (isEditing) {
              setState(() {
                selectedNode!.post.title = titleController.text;
                selectedNode!.post.markdownContent = contentController.text;
                isEditing = false;
              });
            }
          },
          behavior: HitTestBehavior.opaque, // 전체 영역이 클릭 가능하도록 설정
          child: Container(
            width: 400, // 창의 너비를 400으로 고정
            padding: EdgeInsets.symmetric(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isEditing)
                      IconButton(
                        icon: Icon(Icons.visibility),
                        onPressed: () {
                          setState(() {
                            selectedNode!.post.title = titleController.text;
                            selectedNode!.post.markdownContent =
                                contentController.text;
                            isEditing = false;
                          });
                        },
                      ),
                    if (!isEditing)
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          setState(() {
                            titleController.text = selectedNode!.post.title;
                            contentController.text =
                                selectedNode!.post.markdownContent;
                            isEditing = true;
                          });
                        },
                      ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          selectedNode!.post.title =
                              titleController.text; // 화면 취소로 닫아도 작성하던 정보는 저장.
                          selectedNode!.post.markdownContent =
                              contentController.text;
                          isEditing = false; // 화면을 닫으면 편집모드 종료
                          selectedNode!.showOrbit = false;
                          selectedNode = null;
                        });
                      },
                    ),
                  ],
                ),
                if (!isEditing)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isEditing = true; // 텍스트 영역 클릭 시 편집 모드 활성화
                      });
                    },
                    child: Text(selectedNode!.post.title,
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                if (isEditing)
                  TextField(
                    controller: titleController,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: 'Enter title',
                      border: InputBorder.none,
                    ),
                  ),
                SizedBox(
                    height:
                        16), // For some spacing between the title and content
                Expanded(
                  child: isEditing
                      ? TextField(
                          controller: contentController,
                          style: TextStyle(fontSize: 16),
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: 'Enter content',
                            border: InputBorder.none,
                          ),
                        )
                      : GestureDetector(
                          onTap: () {
                            setState(() {
                              isEditing = true; // 텍스트 영역 클릭 시 편집 모드 활성화
                            });
                          },
                          child: MarkdownBody(
                            softLineBreak: true,
                            data: selectedNode!.post.markdownContent,
                            styleSheet:
                                MarkdownStyleSheet.fromTheme(Theme.of(context))
                                    .copyWith(
                              p: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(fontSize: 16), // 폰트 크기 16으로 설정
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ));
  }
}

class EdgePainter extends CustomPainter {
  final List<Edge> edges;
  final Edge? addMark;

  EdgePainter(this.edges, {this.addMark});

  @override
  void paint(Canvas canvas, Size size) {
    void drawLine(Edge edge) {
      final p1 = edge.node1.pos;
      final p2 = edge.node2.pos;
      final paint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1;
      canvas.drawLine(p1, p2, paint);
    }

    for (final edge in edges) {
      drawLine(edge);
    }
    if (addMark != null) drawLine(addMark!);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
