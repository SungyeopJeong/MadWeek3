import 'package:week3/models/node.dart';

class Edge {
  Node start, end;

  Edge(this.start, this.end);

  @override
  bool operator ==(Object other) {
    if (other is! Edge) return false;
    return (start == other.start && end == other.end) ||
        (start == other.end && end == other.start);
  }

  @override
  int get hashCode => Object.hash(start, end);
}
