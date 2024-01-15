// ignore_for_file: prefer_const_constructors

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:week3/const/color.dart';
import 'package:week3/const/size.dart';
import 'package:week3/enums/mode.dart';
import 'package:week3/extensions/offset.dart';
import 'package:week3/models/graph.dart';
import 'package:week3/models/node.dart';
import 'package:week3/models/edge.dart';
import 'package:week3/models/post.dart';
import 'package:week3/viewmodels/note_view_model.dart';
import 'package:week3/views/note_view.dart';

class StellarView extends StatefulWidget {
  const StellarView({super.key});

  @override
  State<StellarView> createState() => _StellarViewState();
}

class _StellarViewState extends State<StellarView>
    with TickerProviderStateMixin {
  Graph graph = Graph();
  Node? origin;
  Planet? tempPlanet;
  Edge? originEdge;
  Mode mode = Mode.none;
  bool isBlackholeEnabled = false;
  bool isEditing = false;

  bool get isStarSelected => selectedNode != null; // 별이 선택되었는지 여부를 추적하는 변수
  Star? selectedNode; // 선택된 노드 추적

  // 뷰를 이동시키기 위한 Controller
  final TransformationController _transformationController =
      TransformationController();

  // 뷰를 이동시킬 때 애니메이션을 적용하기 위한 선언
  late AnimationController _animationController;
  late Animation<Matrix4> _animation;

  // 뷰의 최소 / 최대 배율, 현재 배율 저장 변수
  final double _minScale = 1.0;
  final double _maxScale = 4.0;
  double _currentScale = 1.0;

  final _exception = Exception('Unable to classify');

  bool isMenuVisible = false;
  late AnimationController _menuAnimationController;
  late Animation<Offset> _menuSlideAnimation;
  // 메뉴 호버링 상태를 추적하는 변수 추가
  bool _menuHovering = false;

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

    // 메뉴 애니메이션 컨트롤러 초기화
    _menuAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 250), // 메뉴가 나오는 데 걸리는 시간
    );
    // 메뉴 슬라이드 애니메이션 정의
    _menuSlideAnimation = Tween<Offset>(
      begin: Offset(-1, 0), // 메뉴가 왼쪽에서 시작
      end: Offset(0, 0), // 메뉴가 화면에 완전히 나옴
    ).animate(CurvedAnimation(
      parent: _menuAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _transformationController.removeListener(_updateZoomSlider);
    // AnimationController 정리
    _animationController.dispose();

    // 컨트롤러 정리
    _menuAnimationController.dispose();
    super.dispose();
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
              },
            },
            child: Focus(
              autofocus: true,
              child: Stack(
                children: [
                  InteractiveViewer(
                    minScale: _minScale,
                    maxScale: _maxScale,
                    transformationController: _transformationController,
                    child: _buildBody(),
                  ),
                  _buildBlackhole(),
                  _buildZoomSlider(),
                ],
              ),
            ),
          ),
          _buildHoverableMenu(),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildBody() {
    return GestureDetector(
      onTapDown: (details) {
        if (mode == Mode.add) {
          setState(() {
            Star newStar = Star(pos: details.localPosition)
              ..post = Post(
                title: "Title Here",
                markdownContent: "Content Here",
              );

            graph.addNode(newStar
              ..planets = []
              ..planetAnimation = AnimationController(vsync: this));

            _focusOnNode(newStar);
            selectedNode = newStar;

            selectedNode!.showOrbit = true;
            selectedNode!.planetAnimation.repeat(period: Duration(seconds: 10));

            mode = Mode.none;
            _showNoteViewDialogIfNeeded();
          });
        } else if (selectedNode != null) {
          setState(() {
            selectedNode?.showOrbit = false;
            selectedNode?.planetAnimation.reset();
            selectedNode = null;
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
        cursor:
            mode == Mode.add ? SystemMouseCursors.precise : MouseCursor.defer,
        child: Container(
          color: MyColor.bg,
          width: double.maxFinite,
          height: double.maxFinite,
          child: Stack(
            children: [
              CustomPaint(
                size: Size(double.maxFinite, double.maxFinite),
                painter: EdgePainter(
                  graph.edges,
                  originEdge: originEdge,
                ),
              ),
              ..._buildNodes(graph.nodes),
              if (origin != null) _buildOrigin(origin!),
            ],
          ),
        ),
      ),
    );
  }

  // 디렉토리 표시될 사이드바
  // 메뉴버튼 호버링으로 열고 사이드바 바깥 영역으로 마우스를 이동시켜 닫기
  Widget _buildHoverableMenu() {
    return Stack(
      children: [
        Positioned(
          left: 32,
          top: 32,
          child: MouseRegion(
            onEnter: (event) => _menuAnimationController.forward(),
            child: FloatingActionButton(
              onPressed: () {
                // 버튼 클릭 이벤트: 사이드바를 토글
                isMenuVisible = !isMenuVisible;
                isMenuVisible
                    ? _menuAnimationController.forward()
                    : _menuAnimationController.reverse();
              },
              child: Icon(Icons.menu),
            ),
          ),
        ),
        Positioned(
          top: 32,
          bottom: 32,
          left: 0,
          child: SlideTransition(
            position: _menuSlideAnimation,
            child: Align(
              alignment: Alignment.centerLeft,
              child: MouseRegion(
                onEnter: (event) => setState(() => _menuHovering = true),
                onExit: (event) => setState(() {
                  if (_menuHovering) {
                    _menuAnimationController.reverse();
                    _menuHovering = false;
                    isMenuVisible = false;
                  }
                }),
                child: Container(
                  width: 240, // 고정 너비
                  decoration: BoxDecoration(
                    color: Colors.grey[850], // 사이드바의 배경색
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12), // 오른쪽 상단 모서리 둥글게
                      bottomRight: Radius.circular(12), // 오른쪽 하단 모서리 둥글게
                    ),
                  ),
                  child: _buildNodeList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 사이드바에서 보여줄 노드 리스트 만들기
  Widget _buildNodeList() {
    List<Node> nodes = graph.nodes;

    return ListView.builder(
      itemCount: nodes.length,
      itemBuilder: (context, index) {
        Node node = nodes[index];
        return ListTile(
          title: Text(
            node.post.title,
            style: TextStyle(color: Colors.white),
          ),
          onTap: () {
            // 탭한 노드를 selectedNode에 할당
            setState(() {
              selectedNode = node as Star;
              selectedNode!.showOrbit = true;
              selectedNode!.planetAnimation
                  .repeat(period: Duration(seconds: 10));
            });

            // 해당 노드에 포커스
            _focusOnNode(node);
            _showNoteViewDialogIfNeeded();
          },
        );
      },
    );
  }

  Widget _buildFAB() {
    return GestureDetector(
      onTap: () {
        setState(() {
          mode = Mode.add;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: MyColor.surface,
          shape: BoxShape.circle,
        ),
        width: 60,
        height: 60,
        child: Icon(
          Icons.insights,
          color: MyColor.onSurface,
        ),
      ),
    );
  }

  List<Widget> _buildNodes(List<Node> nodes) {
    return nodes.skipWhile((node) => node is Planet).map((node) {
      switch (node) {
        case Star():
          return _buildStar(node);
        case Constellation():
          return _buildConstellation(node);
        default:
          throw _exception;
      }
    }).toList();
  }

  Widget _buildDeletingNode(Node node, Widget Function(Offset) childBuilder) {
    return TweenAnimationBuilder(
      tween: Tween(
        begin: node.pos,
        end: Offset(0, MediaQuery.of(context).size.height),
      ),
      duration: Duration(milliseconds: 250),
      onEnd: () {
        setState(() {
          graph.removeNode(node);
        });
      },
      builder: (_, val, __) => childBuilder(val),
    );
  }

  Widget _buildHelper(double size, List<Widget> children) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: children,
      ),
    );
  }

  Widget _buildColoredCircle(
    double size,
    Color color, {
    BoxBorder? border,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        border: border,
        shape: BoxShape.circle,
      ),
      width: size,
      height: size,
    );
  }

  Widget _buildPlanetCenter(Planet planet) {
    return Visibility(
      visible: planet.showPlanet,
      child: _buildColoredCircle(
        planetSize,
        planet == tempPlanet ? MyColor.star : MyColor.planet,
      ),
    );
  }

  Widget _buildPlanetArea(Planet planet) {
    return Visibility(
      visible: planet.showArea,
      child: _buildColoredCircle(
        planetAreaSize,
        planet == tempPlanet ? MyColor.starArea : MyColor.planetArea,
      ),
    );
  }

  Widget _buildEmptyPlanet(Planet planet) {
    return _buildHelper(
      planetAreaSize,
      [
        _buildPlanetArea(planet),
        _buildPlanetCenter(planet),
      ],
    );
  }

  Widget _buildPlanet(Planet planet) {
    if (planet.isDeleting) {
      return _buildDeletingNode(
        planet,
        (val) => Positioned(
          left: val.dx - planetSize / 2,
          top: val.dy - planetSize / 2,
          child: _buildPlanetCenter(planet),
        ),
      );
    }
    return MouseRegion(
      onEnter: (_) {
        if (!isEditing) {
          setState(() {
            planet.showArea = true;
          });
        }
      },
      onExit: (_) {
        if (!isEditing) {
          setState(() {
            planet.showArea = false;
          });
        }
      },
      child: _buildEmptyPlanet(planet),
    );
  }

  Widget _buildStarCenter(Star star) {
    return Visibility(
      visible: star.showStar,
      child: _buildColoredCircle(
        starSize,
        MyColor.star.withOpacity(star == origin ? 0.2 : 1),
      ),
    );
  }

  Widget _buildStarArea(Star star) {
    return Visibility(
      visible: star.showOrbit ? true : star.showArea,
      child: _buildColoredCircle(starAreaSize, MyColor.starArea),
    );
  }

  Widget _buildStarOrbit(Star star) {
    return Visibility(
      visible: star.showOrbit,
      child: _buildHelper(
        starTotalSize,
        [
          _buildColoredCircle(
            starOrbitSize,
            MyColor.starOrbit,
            border: Border.all(color: MyColor.star),
          ),
          AnimatedBuilder(
            animation: star.planetAnimation,
            builder: (_, __) {
              final alpha = star.planetAnimation.value * 2 * pi;
              const radius = starOrbitSize / 2;
              for (final planetWithIndex in star.planets.indexed) {
                final index = planetWithIndex.$1;
                final planet = planetWithIndex.$2;
                final angle = index * 2 * pi / star.planets.length + alpha;
                final x = radius * cos(angle);
                final y = radius * sin(angle);
                planet.pos = star.pos + Offset(x, y);
              }
              return Stack(
                children: star.planets
                    .map(
                      (planet) => Positioned(
                        left: starTotalSize / 2 +
                            planet.pos.dx -
                            star.pos.dx -
                            planetAreaSize / 2,
                        top: starTotalSize / 2 +
                            planet.pos.dy -
                            star.pos.dy -
                            planetAreaSize / 2,
                        child: _buildPlanet(planet),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStar(Star star) {
    return _buildHelper(
      starTotalSize,
      [
        _buildStarOrbit(star),
        _buildStarArea(star),
        _buildStarCenter(star),
      ],
    );
  }

  void _setOnPanStart(Node node) {
    isEditing = true;
    switch (node) {
      case Planet():
        throw UnimplementedError();
      case Star():
        origin = Star(pos: node.pos)
          ..id = 0
          ..planets = []
          ..planetAnimation = AnimationController(vsync: this);
        originEdge = Edge(origin!, node);
      default:
        throw _exception;
    }
  }

  void _setOnPanEnd(Node node) {
    isEditing = false;
    switch (node) {
      case Planet():
        throw UnimplementedError();
      case Star():
        for (final other in graph.nodes + [origin!]) {
          if (other == node) continue;
          if (other == origin && mode != Mode.add) continue;
          if (other.pos.closeTo(node.pos, starOrbitSize)) {
            (other as Star).showOrbit = false;

            if (other.planets.remove(tempPlanet)) {
              other.addPlanet(Planet(star: other));
              tempPlanet = null;
            }
            if (other.planetAnimation.isAnimating) {
              other.planetAnimation.reset();
            }
            break;
          }
        }

        originEdge = null;
        origin = null;
      default:
        throw _exception;
    }
  }

  void _caseProcess(Node node) {
    switch (node) {
      case Planet():
        throw UnimplementedError();
      case Star():
        for (final other in graph.nodes + [origin!]) {
          if (other == node) continue;
          if (other == origin && mode != Mode.add) continue;
          if (other.pos.closeTo(node.pos, starOrbitSize)) {
            (other as Star).showOrbit = true;
            if (tempPlanet == null) {
              tempPlanet = Planet(star: other, showArea: true)..id = 0;
              other.planets.add(tempPlanet!);
              originEdge!.end = tempPlanet!;
            }
            if (!other.planetAnimation.isAnimating) {
              other.planetAnimation.repeat(period: Duration(seconds: 10));
            }
          } else {
            (other as Star).showOrbit = false;

            if (other.planets.remove(tempPlanet)) {
              tempPlanet = null;
              originEdge!.end = node;
            }
            if (other.planetAnimation.isAnimating) {
              other.planetAnimation.reset();
            }
          }
        }
      default:
        throw _exception;
    }
  }

  Widget _buildStar(Star star) {
    if (star.isDeleting) {
      return _buildDeletingNode(
        star,
        (val) => Positioned(
          left: val.dx - starSize / 2,
          top: val.dy - starSize / 2,
          child: _buildStarCenter(star),
        ),
      );
    }
    return Positioned(
      left: star.pos.dx - starTotalSize / 2,
      top: star.pos.dy - starTotalSize / 2,
      child: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _setOnPanStart(star);
          });
        },
        onPanUpdate: (details) {
          if (star.showArea) {
            // star following cursor if area shown(interactive)
            setState(() {
              star.pos += details.delta;

              _caseProcess(star);
            });
          }
        },
        onPanEnd: (_) {
          setState(() {
            _setOnPanEnd(star);
            star.isDeleting = isBlackholeEnabled;
          });
        },
        onTap: () {
          //setState(() {
          // 새 노드를 선택합니다.
          // if (selectedNode != star) {
          //   selectedNode?.showOrbit = false; // 이전 선택된 노드의 orbit을 해제합니다.
          //   selectedNode?.planetAnimation.reset();

          //   selectedNode = star; // 새로운 노드를 선택된 노드로 설정합니다.
          //   selectedNode!.showOrbit = true;
          //   selectedNode!.planetAnimation
          //       .repeat(period: Duration(seconds: 10));

          //   // 새 노드의 정보로 텍스트 필드를 업데이트합니다.
          //   context.read<NoteViewModel>().titleController.text =
          //       selectedNode!.post.title;
          //   context.read<NoteViewModel>().contentController.text =
          //       selectedNode!.post.markdownContent;

          //   _focusOnNode(star); // 뷰포트 이동
          // }
          //});
          setState(() {
            selectedNode = star;
            selectedNode!.showOrbit = true;
            selectedNode!.planetAnimation.repeat(period: Duration(seconds: 10));

            _focusOnNode(star);

            // 새 노드의 정보로 텍스트 필드를 업데이트합니다.
            context.read<NoteViewModel>().titleController.text =
                selectedNode!.post.title;
            context.read<NoteViewModel>().contentController.text =
                selectedNode!.post.markdownContent;

            _showNoteViewDialogIfNeeded();
          });
        },
        child: MouseRegion(
          onHover: (details) {
            setState(() {
              // show area if mouse in area
              star.showArea = details.localPosition.closeTo(
                OffsetExt.center(starTotalSize),
                starAreaSize,
              );
            });
          },
          child: _buildEmptyStar(star),
        ),
      ),
    );
    /*GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            //원래자리에 노드 모양 위젯 생성
            origin ??= Node(node.pos)
              ..planetAnimation = AnimationController(
                vsync: this,
                upperBound: 2 * pi,
                duration: Duration(seconds: 10),
              );
            origin!.showStar = false;
            originEdge = Edge(origin!, node);
            node.showStar = true;

            void updateState(Node? other) {
              if (other == node || other == null) return;
              final distanceSquared = (other.pos - node.pos).distanceSquared;
              double radiusSquared(double diameter) => diameter * diameter / 4;
              if (distanceSquared <= radiusSquared(areaSize)) {
                final edge = Edge(origin!, other);
                if (!edges.any((element) => element == edge)) {
                  origin!.showStar = true;
                  originEdge = edge;
                  node.showStar = false;
                }
                return;
              }
              if (distanceSquared <= radiusSquared(orbitSize)) {
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
              updateState(other);
            }
            if (mode == Mode.add) {
              updateState(origin);
            }
          });
        },
        onPanEnd: (details) {
          setState(() {
            for (final node in nodes) {
              node.showOrbit = false;
            }

            if (origin?.showStar ?? false) {
              node.pos = origin!.pos;
              node.showStar = true;
              originEdge!.node1 = node;
              if (!edges.contains(originEdge)) {
                edges.add(originEdge!);
              }
            }

            origin = null; // `origin`을 `null`로 설정
            originEdge = null;
          });
        },
      )*/
  }

  void _showNoteViewDialogIfNeeded() {
    if (isStarSelected) {
      showGeneralDialog(
        context: context,
        barrierColor: Colors.transparent, // 배경색을 투명하게 설정
        barrierDismissible: true, // 배경을 탭하면 팝업 닫기
        barrierLabel:
            MaterialLocalizations.of(context).modalBarrierDismissLabel,
        transitionDuration: Duration(milliseconds: 200),
        pageBuilder: (BuildContext buildContext, Animation<double> animation,
            Animation<double> secondaryAnimation) {
          return WillPopScope(
            onWillPop: () async {
              Navigator.of(context).pop(); // 팝업을 닫을 때 호출됩니다.
              setState(() {
                selectedNode!.showOrbit = false;
                selectedNode = null;
              });
              return true;
            },
            child: Material(
              color: Colors.transparent,
              child: Align(
                alignment: Alignment.centerRight, // 오른쪽 정렬
                child: Container(
                  width: MediaQuery.of(context).size.width / 3, // 너비는 화면의 1/3
                  margin: EdgeInsets.only(
                      right: 32, top: 32, bottom: 32), // 오른쪽에서 32만큼 여백
                  child: NoteView(
                    star: selectedNode!,
                    onClose: () {
                      Navigator.of(context).pop(); // 팝업을 닫을 때 호출됩니다.
                      setState(() {
                        selectedNode!.showOrbit = false;
                        selectedNode = null;
                      });
                    },
                  ),
                ),
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildOrigin(Node node) {
    switch (node) {
      case Planet():
        return _buildEmptyPlanet(node);
      case Star():
        return Positioned(
          left: node.pos.dx - starTotalSize / 2,
          top: node.pos.dy - starTotalSize / 2,
          child: _buildEmptyStar(node),
        );
      default:
        throw _exception;
    }
  }

  Widget _buildConstellation(Constellation constellation) {
    return Placeholder();
  }

  Widget _buildBlackhole() {
    final blackholeSize =
        isBlackholeEnabled ? blackholeMaxSize : blackholeMinSize;
    return Positioned(
      left: -blackholeAreaSize / 2,
      bottom: -blackholeAreaSize / 2,
      child: MouseRegion(
        onEnter: (_) {
          setState(() {
            isBlackholeEnabled = true;
          });
        },
        onExit: (_) {
          setState(() {
            isBlackholeEnabled = false;
          });
        },
        child: Container(
          width: blackholeAreaSize,
          height: blackholeAreaSize,
          alignment: Alignment.center,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 100),
            decoration: BoxDecoration(
              color: MyColor.blackhole,
              shape: BoxShape.circle,
            ),
            width: blackholeSize,
            height: blackholeSize,
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

  // 슬라이더를 위치시키고 상태를 업데이트      << 얘를 바꿔야 슬라이드바 줌 문제 해결됨
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

  // 주어진 노드가 화면 가로 1/3 지점에 오도록 화면을 이동시키는 함수
  void _focusOnNode(Node node) {
    // 시작 행렬
    final Matrix4 startMatrix = _transformationController.value;
    // 최종 행렬
    final Matrix4 endMatrix = Matrix4.identity()
      ..scale(3.0)
      ..translate(
        -node.pos.dx + MediaQuery.of(context).size.width / 3 / 3,
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
}

class EdgePainter extends CustomPainter {
  final List<Edge> edges;
  final Edge? originEdge;

  EdgePainter(this.edges, {this.originEdge});

  @override
  void paint(Canvas canvas, Size size) {
    void drawLine(Edge edge) {
      final p1 = edge.start.pos;
      final p2 = edge.end.pos;
      final paint = Paint()
        ..color = MyColor.line
        ..strokeWidth = 1;
      canvas.drawLine(p1, p2, paint);
    }

    void drawDashedLine(Edge edge) {
      final p1 = edge.start.pos;
      final p2 = edge.end.pos;
      final paint = Paint()
        ..color = MyColor.dashedLine
        ..strokeWidth = 2;

      final unit = (p2 - p1) / (p2 - p1).distance;
      final dash = unit * 10;
      final gap = unit * 8;

      for (var p = p1;
          (p + dash - p1).distanceSquared <= (p2 - p1).distanceSquared;
          p += dash + gap) {
        canvas.drawLine(p, p + dash, paint);
      }
    }

    for (final edge in edges) {
      drawLine(edge);
    }
    if (originEdge != null) drawDashedLine(originEdge!);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
