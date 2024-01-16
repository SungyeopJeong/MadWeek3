import 'package:flutter/material.dart';
import 'package:week3/models/Graph.dart';
import 'package:week3/models/node.dart';
import 'package:week3/models/edge.dart';

class GraphViewModel extends ChangeNotifier {
  final Graph _graph = Graph();

  List<Node> get nodes => _graph.nodes;
  List<Edge> get edges => _graph.edges;

  void addNode(Node node) {
    _graph.addNode(node);
    notifyListeners(); // 상태 변경 알림
  }

  void removeNode(Node node) {
    _graph.removeNode(node);
    notifyListeners(); // 상태 변경 알림
  }

  void addEdge(Node other, Node node) {
    _graph.addEdge(other, node);
    notifyListeners(); // 상태 변경 알림
  }
}
