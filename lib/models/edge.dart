import 'package:week3/models/node.dart';

class Edge {
  Node node1, node2;

  Edge(this.node1, this.node2);

  @override
  bool operator ==(Object other) {
    if (other is! Edge) return false;
    return (node1 == other.node1 && node2 == other.node2) ||
        (node1 == other.node2 && node2 == other.node1);
  }

  @override
  int get hashCode => Object.hash(node1, node2);
}