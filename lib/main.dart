import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:week3/enums/mode.dart';
import 'package:week3/models/edge.dart';
import 'package:week3/models/node.dart';
import 'package:week3/views.dart/stellar_view.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  List<Node> nodes = [];
  List<Edge> edges = [];
  Node? tempNode;
  Edge? tempEdge;
  Mode mode = Mode.none;

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: StellarView(),
        /*body: InteractiveViewer(
          child: CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              const SingleActivator(LogicalKeyboardKey.keyI): () {
                setState(() {
                  mode = Mode.add;
                });
              }
            },
            child: Focus(
              autofocus: true,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapDown: (details) {
                  if (mode == Mode.add) {
                    setState(() {
                      nodes.add(Node(details.localPosition));
                      mode = Mode.none;
                    });
                  }
                },
                child: MouseRegion(
                  onHover: (details) {
                    if (tempNode != null) {
                      setState(() {
                        tempEdge = Edge(
                          tempNode!,
                          Node(details.localPosition),
                        );
                      });
                    }
                  },
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Color(0xFF1A1133),
                          Color(0xFF1E1A2B),
                        ],
                      ),
                    ),
                    width: double.infinity,
                    height: double.infinity,
                    child: Stack(
                      children: [
                        CustomPaint(
                          size: MediaQuery.of(context).size,
                          painter: EdgePainter(
                            edges,
                            temp: tempEdge,
                          ),
                        ),
                        ...nodes.map((e) => star(e)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              mode = Mode.add;
            });
          },
          shape: const CircleBorder(),
          child: const Icon(Icons.insights),
        ),*/
      ),
    );
  }

  Widget star(Node star) {
    return Positioned(
      left: star.pos.dx - 20 / 2,
      top: star.pos.dy - 20 / 2,
      child: MouseRegion(
        onEnter: (_) {
          setState(() {
            star.hover = true;
          });
        },
        onExit: (_) {
          setState(() {
            star.hover = false;
          });
        },
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              star.pos += details.delta;
            });
          },
          onTap: () {
            if (tempNode != null) {
              setState(() {
                final edge = Edge(tempNode!, star);
                if (!edges.contains(edge)) {
                  edges.add(edge);
                }
                tempNode = null;
                tempEdge = null;
              });
            } else {
              setState(() {
                tempNode = star;
              });
            }
          },
          child: SizedBox(
            width: 20,
            height: 20,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Visibility(
                  visible: star.hover,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EdgePainter extends CustomPainter {
  final List<Edge> edges;
  final Edge? temp;

  const EdgePainter(this.edges, {this.temp});

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
    if (temp != null) drawLine(temp!);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
