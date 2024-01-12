import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:week3/models/edge.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  List<Offset> list = [];
  List<bool> visible = [];
  List<EdgeIndexed> edges = [];
  Edge? temp;
  bool addable = false;
  int? start;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: InteractiveViewer(
          child: CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              const SingleActivator(LogicalKeyboardKey.keyI): () {
                setState(() {
                  addable = true;
                });
              }
            },
            child: Focus(
              autofocus: true,
              child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapDown: (details) {
                    if (addable) {
                      setState(() {
                        list.add(Offset(details.localPosition.dx,
                            details.localPosition.dy));
                        visible.add(false);
                        addable = false;
                      });
                    }
                  },
                  child: MouseRegion(
                    onHover: (details) {
                      if (start != null) {
                        setState(() {
                          temp = Edge(
                            start: list[start!],
                            end: details.localPosition,
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
                              edges: edges
                                  .map((e) => Edge(
                                        start: list[e.startIdx],
                                        end: list[e.endIdx],
                                      ))
                                  .toList(),
                              temp: temp,
                            ),
                          ),
                          ...list.indexed.map((e) => Positioned(
                              left: e.$2.dx - 20 / 2,
                              top: e.$2.dy - 20 / 2,
                              child: MouseRegion(
                                onEnter: (_) {
                                  setState(() {
                                    visible[e.$1] = true;
                                  });
                                },
                                onExit: (_) {
                                  setState(() {
                                    visible[e.$1] = false;
                                  });
                                },
                                child: GestureDetector(
                                  onPanUpdate: (details) {
                                    setState(() {
                                      list[e.$1] += details.delta;
                                    });
                                  },
                                  onTap: () {
                                    if (start != null) {
                                      setState(() {
                                        final edge = EdgeIndexed(
                                          startIdx: start!,
                                          endIdx: e.$1,
                                        );
                                        if (!edges.contains(edge)) {
                                          edges.add(edge);
                                        }
                                        start = null;
                                        temp = null;
                                      });
                                    } else {
                                      setState(() {
                                        start = e.$1;
                                      });
                                    }
                                  },
                                  onSecondaryTap: () {
                                    print("hmm");
                                  },
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Visibility(
                                          visible: visible[e.$1],
                                          child: Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.5),
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
                              )))
                        ],
                      ),
                    ),
                  )),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              addable = true;
            });
          },
          shape: const CircleBorder(),
          child: const Icon(Icons.insights),
        ),
      ),
    );
  }
}

class EdgePainter extends CustomPainter {
  final List<Edge> edges;
  final Edge? temp;

  const EdgePainter({required this.edges, this.temp});

  @override
  void paint(Canvas canvas, Size size) {
    void drawLine(Edge edge) {
      final p1 = edge.start;
      final p2 = edge.end;
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
