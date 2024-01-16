import 'package:flutter/foundation.dart';
import 'package:week3/models/edge.dart';
import 'package:week3/models/node.dart';

class Graph extends ChangeNotifier {
  List<Node> nodes = [];
  List<Edge> edges = [];
  int _newId = 1;

  void addNode(Node node) {
    nodes.add(node..id = _newId++);
    notifyListeners(); // 상태 변경 알림
  }

  void addEdge(Node node1, Node node2) {
    final edge = Edge(node1, node2);
    if (!edges.contains(edge)) {
      edges.add(edge);
      notifyListeners(); // 상태 변경 알림
    }
  }

  void removeNode(Node node) {
    nodes.remove(node);
    notifyListeners(); // 상태 변경 알림
  }
}
