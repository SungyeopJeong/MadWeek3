// ignore_for_file: prefer_const_constructors

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:week3/const/size.dart';
import 'package:week3/enums/mode.dart';
import 'package:week3/models/node.dart';
import 'package:week3/models/edge.dart';

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
      body: CallbackShortcuts(
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
                        nodes.add(
                          Node(details.localPosition)
                            ..planetAnimation = AnimationController(
                              vsync: this,
                              upperBound: 2 * pi,
                              duration: Duration(seconds: 10),
                            ),
                        );
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
        onPanUpdate: (details) {
          setState(() {
            //원래자리에 노드 모양 위젯 생성
            origin ??= Node(
              node.pos,
            )..planetAnimation = AnimationController(
                vsync: this,
                upperBound: 2 * pi,
                duration: Duration(seconds: 10),
              );

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
