import 'package:week3/models/edge.dart';
import 'package:week3/models/node.dart';

class Graph {
  List<Node> nodes = [];
  List<Edge> edges = [];
  int _newId = 1;

  void addNode(Node node) {
    nodes.add(node..id = _newId++);
  }

  void addEdge(Node node1, Node node2) {
    final edge = Edge(node1, node2);
    if (!edges.contains(edge)) {
      edges.add(edge);
    }
  }

  void removeNode(Node node) {
    nodes.remove(node);
  }
}
