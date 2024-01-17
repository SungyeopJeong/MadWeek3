import 'package:week3/models/node.dart';

class Edge {
  Node start, end;
  Constellation? constellation;

  Edge(this.start, this.end, {this.constellation});

  @override
  bool operator ==(Object other) {
    if (other is! Edge) return false;
    return (start == other.start && end == other.end) ||
        (start == other.end && end == other.start);
  }

  @override
  int get hashCode => Object.hash(start, end);

  void replaceIfcontains(Node from, Node to) {
    if (start == from) {
      start = to;
    } else if (end == from) {
      end = to;
    }
  }

  bool contains(Node node) {
    return start == node || end == node;
  }

  Node? other(Node node) {
    if (contains(node)) {
      return start == node ? end : start;
    }
    return null;
  }
}
