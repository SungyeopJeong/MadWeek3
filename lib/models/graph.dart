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
    edges.add(Edge(node1, node2));
  }

  void removeNode(Node node) {
    nodes.remove(node);
  }
}
