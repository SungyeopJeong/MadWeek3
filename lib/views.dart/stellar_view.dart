// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:week3/const/size.dart';
import 'package:week3/enums/mode.dart';
import 'package:week3/models/node.dart';

class StellarView extends StatefulWidget {
  const StellarView({super.key});

  @override
  State<StellarView> createState() => _StellarViewState();
}

class _StellarViewState extends State<StellarView> {
  List<Node> nodes = [];
  Node? temp;
  Node? original;
  Mode mode = Mode.none;
  double scale = 1.0;
  Offset mouse = Offset.zero;
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
              temp = Node(mouse, showArea: true);
            });
          }
        },
        child: Focus(
          autofocus: true,
          child: Stack(
            children: [
              InteractiveViewer(
                onInteractionUpdate: (details) {
                  setState(() {
                    scale = details.scale;
                  });
                },
                child: GestureDetector(
                  onTapDown: (details) {
                    if (temp != null) {
                      setState(() {
                        nodes.add(Node(details.localPosition));
                        temp = null;
                      });
                    }
                  },
                  onSecondaryTap: () {
                    // 마우스 오른쪽 클릭 이벤트 처리
                    setState(() {
                      temp = null; // 별 생성 모드 취소
                    });
                  },
                  child: MouseRegion(
                    onHover: (details) {
                      //여기서 temp가 현재 마우스의 위치를 따라가도록 함
                      setState(() {
                        mouse = details.localPosition;
                        temp?.pos = details.localPosition;
                      });
                    },
                    child: Container(
                      color: Color(0xFFF3F0E9),
                      width: double.maxFinite,
                      height: double.maxFinite,
                      child: Stack(
                        children: [
                          ...nodes.map((star) => node(context, star)),
                          if (temp != null) emptyNode(temp!),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              blackhole(),
            ],
          ),
        ),
      ),
      floatingActionButton: GestureDetector(
        onTapUp: (details) {
          setState(() {
            temp = Node(details.globalPosition, showArea: true);
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

  Widget node(BuildContext context, Node node) {
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
              children: [starArea(node), star()],
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
          if (original == null) {
            // 클릭한 별의 원래 자리에 투명한 노드를 추가
            original = Node(node.pos);
            nodes.add(original!);
          }

          setState(() {
            for (final node in nodes) {
              node.showOrbit = true;
            }
            node.pos += details.delta;
          });
        },
        onPanEnd: (details) {
          setState(() {
            for (final node in nodes) {
              node.showOrbit = false;
            }
            if (original != null) {
              // 클릭한 별의 원래 자리에 추가한 투명한 노드를 삭제
              nodes.remove(original);
              original = null;
            }
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
            children: [orbit(node), starArea(node), star()],
          ),
        ),
      ),
    );
  }

  Widget emptyNode(Node node) {
    return Positioned(
      left: node.pos.dx - areaSize / 2,
      top: node.pos.dy - areaSize / 2,
      child: starArea(node),
    );
  }

  Widget orbit(Node star) {
    return Visibility(
      visible: star.showOrbit,
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFFE5C33E).withOpacity(0.1),
          border: Border.all(color: Color(0xFFE5C33E)),
          shape: BoxShape.circle,
        ),
        width: orbitSize,
        height: orbitSize,
      ),
    );
  }

  Widget starArea(Node star) {
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

  Widget star() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFE5C33E),
        shape: BoxShape.circle,
      ),
      width: starSize,
      height: starSize,
    );
  }

  Widget blackhole() {
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
