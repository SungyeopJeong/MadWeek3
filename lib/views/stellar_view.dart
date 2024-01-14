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

  // 뷰를 이동시키기 위한 Controller
  final TransformationController _transformationController =
      TransformationController();

  // 뷰를 이동시킬 때 애니메이션을 적용하기 위한 선언
  late AnimationController _animationController;
  late Animation<Matrix4> _animation;

  // 뷰의 최소 / 최대 배율, 현재 배율 저장 변수
  double _minScale = 1.0;
  double _maxScale = 4.0;
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    // AnimationController 초기화
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _transformationController.addListener(_updateZoomSlider);

// InteractiveViewer의 초기 스케일을 기반으로 _currentScale 값을 설정합니다.
    _currentScale =
        (_transformationController.value.getMaxScaleOnAxis() - _minScale) /
            (_maxScale - _minScale);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_updateZoomSlider);
    // AnimationController 정리
    _animationController.dispose();
    super.dispose();
  }

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
                    minScale: _minScale,
                    maxScale: _maxScale,
                    transformationController: _transformationController,
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
                  _buildZoomSlider(),
                ],
              ),
            ),
          ),
          _buildNoteView(),
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
            // 이전 노드의 정보를 저장합니다.
            if (isEditing && selectedNode != null) {
              selectedNode!.post.title = titleController.text;
              selectedNode!.post.markdownContent = contentController.text;
            }

            // 새 노드를 선택합니다.
            if (selectedNode != node) {
              selectedNode?.showOrbit = false; // 이전 선택된 노드의 orbit을 해제합니다.
              selectedNode?.planetAnimation.reset();

              selectedNode = node; // 새로운 노드를 선택된 노드로 설정합니다.
              selectedNode!.showOrbit = true;
              selectedNode!.planetAnimation.repeat();

              // 새 노드의 정보로 텍스트 필드를 업데이트합니다.
              titleController.text = selectedNode!.post.title;
              contentController.text = selectedNode!.post.markdownContent;

              _focusOnNode(node); // 뷰포트 이동
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
              if (node != selectedNode) node.showOrbit = false;
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

  // 줌슬라이더 만드는 함수
  Widget _buildZoomSlider() {
    return Positioned(
      left: 32,
      top: (MediaQuery.of(context).size.height - 320) / 2,
      child: Container(
        width: 48,
        height: 320,
        decoration: BoxDecoration(
          color: Color(0xFFE5E5E1),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 0),
            ),
          ],
        ),
        padding: EdgeInsets.all(4),
        child: RotatedBox(
          quarterTurns: 3,
          child: _customSliderTheme(context, _customSlider(context)),
        ),
      ),
    );
  }

  // 현재 zoom 상태에 맞게 slider 값 바꾸기
  void _updateZoomSlider() {
    double scale = _transformationController.value.getMaxScaleOnAxis();
    setState(() {
      // 현재 스케일을 기반으로 슬라이더의 값을 계산합니다.
      // 계산된 값이 범위를 벗어나지 않도록 clamp 함수를 사용합니다.
      _currentScale =
          ((scale - _minScale) / (_maxScale - _minScale)).clamp(0.0, 1.0);
    });
  }

  //_customSlider의 모양 함수
  SliderTheme _customSliderTheme(BuildContext context, Widget slider) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4.0,
        thumbColor: Color(0xFF4D4D4D),
        inactiveTrackColor: Color(0xFFC5C5C5),
        activeTrackColor: Color(0xFF4D4D4D),
        overlayColor: Colors.transparent,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10.0),
        trackShape: RoundedRectSliderTrackShape(),
      ),
      child: slider,
    );
  }

  // 슬라이더를 위치시키고 상태를 업데이트
  Widget _customSlider(BuildContext context) {
    return Slider(
      value: _currentScale,
      min: 0,
      max: 1,
      onChanged: (newValue) {
        // 슬라이더의 새 값에 따라 스케일을 계산합니다.
        double newScale = newValue * (_maxScale - _minScale) + _minScale;

        // 화면의 중앙 좌표를 계산합니다.
        final screenCenterX = MediaQuery.of(context).size.width / 2;
        final screenCenterY = MediaQuery.of(context).size.height / 2;

        // 새로운 변환 행렬을 계산합니다.
        // 화면 중앙을 기준으로 스케일을 적용합니다.
        Matrix4 newMatrix = Matrix4.identity()
          ..translate(
            -screenCenterX * (newScale - 1),
            -screenCenterY * (newScale - 1),
          )
          ..scale(newScale);

        // 변환 컨트롤러의 값을 업데이트합니다.
        _transformationController.value = newMatrix;

        // 현재 스케일 상태를 업데이트합니다.
        setState(() {
          _currentScale = newValue;
        });
      },
    );
  }

  // 주어진 노드가 화면 가로 1/4 지점에 오도록 화면을 이동시키는 함수
  void _focusOnNode(Node node) {
    // 시작 행렬
    final Matrix4 startMatrix = _transformationController.value;
    // 최종 행렬
    final Matrix4 endMatrix = Matrix4.identity()
      ..scale(3.0)
      ..translate(
        -node.pos.dx + MediaQuery.of(context).size.width / 4 / 3,
        -node.pos.dy + MediaQuery.of(context).size.height / 2 / 3,
      );

    // Tween을 사용하여 시작과 끝 행렬 사이를 보간합니다.
    _animation = Matrix4Tween(
      begin: startMatrix,
      end: endMatrix,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // 리스너를 추가하여 변환 컨트롤러의 값을 업데이트합니다.
    _animation.addListener(() {
      _transformationController.value = _animation.value;
    });

    // 애니메이션을 시작합니다.
    _animationController.forward(from: 0.0);
  }

  //선택한 별이 있는지 확인하고 선택된게 있다면 해당 Node의 Post의 title과 markdownContent를 불러와서 화면에 보여주는 위젯
  Widget _buildNoteView() {
    if (!isStarSelected) {
      return SizedBox.shrink();
    }
    return Positioned(
        top: 32,
        right: 32,
        bottom: 32,
        child: Focus(
          autofocus: true,
          onKey: (FocusNode node, RawKeyEvent event) {
            // ESC 키가 눌렸는지 확인합니다.
            if (event is RawKeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.escape) {
              // 에딧모드라면 뷰모드로 전환합니다.
              if (isEditing) {
                setState(() {
                  _enterViewMode();
                });
                // 이벤트 처리를 중단합니다.
                return KeyEventResult.handled;
              }
              // 에딧모드가 아니라면 노트를 닫습니다.
              setState(() {
                selectedNode!.showOrbit = false;
                selectedNode = null;
              });
              // 이벤트 처리를 중단합니다.
              return KeyEventResult.handled;
            }
            // 다른 키 이벤트는 무시합니다.
            return KeyEventResult.ignored;
          },
          child: GestureDetector(
            onTap: () {
              if (isEditing) _enterViewMode();
            },
            behavior: HitTestBehavior.opaque,
            child: _buildNoteContainer(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderRow(),
                  _buildTitleSection(),
                  SizedBox(height: 16),
                  _buildContentSection(),
                ],
              ),
            ),
          ),
        ));
  }

  // 노트뷰에서 편집모드 -> 뷰모드로의 전환 함수
  void _enterViewMode() {
    setState(() {
      if (selectedNode != null) {
        selectedNode!.post.title = titleController.text;
        selectedNode!.post.markdownContent = contentController.text;
      }
      isEditing = false;
    });
  }

  // 노트뷰에서 편집모드 -> 뷰모드로의 전환 함수
  void _enterEditMode() {
    setState(() {
      if (selectedNode != null) {
        titleController.text = selectedNode!.post.title;
        contentController.text = selectedNode!.post.markdownContent;
      }
      isEditing = true;
    });
  }

  // 노트 뷰 컨테이너 위젯
  Widget _buildNoteContainer(Widget child) {
    return Container(
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
      child: child, // 내부 내용은 주어진 child 위젯으로 동적 할당
    );
  }

  // 노트뷰의 상단, 아이콘 배치 위젯
  Widget _buildHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (isEditing)
          IconButton(icon: Icon(Icons.edit), onPressed: _enterViewMode),
        if (!isEditing)
          IconButton(
              icon: Icon(Icons.my_library_books_rounded),
              onPressed: _enterEditMode),
        IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            setState(() {
              _enterViewMode();
              selectedNode!.showOrbit = false;
              selectedNode = null;
            });
          },
        )
      ],
    );
  }

  //note_view의 타이틀 섹션 위젯, 클릭하면 editmode로 전환
  Widget _buildTitleSection() {
    return isEditing
        ? _buildTitleTextField()
        : GestureDetector(
            onTap: _enterEditMode,
            child: Text(selectedNode!.post.title,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)));
  }

  //note_view의 컨텐츠 섹션 위젯, 클릭하면 editmode로 전환
  Widget _buildContentSection() {
    return Expanded(
      child: isEditing
          ? _buildContentTextField()
          : GestureDetector(
              onTap: _enterEditMode,
              child: MarkdownBody(
                softLineBreak: true,
                data: selectedNode!.post.markdownContent,
                styleSheet:
                    MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                  p: Theme.of(context)
                      .textTheme
                      .bodyLarge!
                      .copyWith(fontSize: 16), // 폰트 크기 16으로 설정
                ),
              )),
    );
  }

  Widget _buildTitleTextField() {
    return TextField(
      controller: titleController,
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      decoration:
          InputDecoration(hintText: 'Enter title', border: InputBorder.none),
    );
  }

  Widget _buildContentTextField() {
    return TextField(
      controller: contentController,
      style: TextStyle(fontSize: 16),
      maxLines: null,
      decoration:
          InputDecoration(hintText: 'Enter content', border: InputBorder.none),
    );
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
