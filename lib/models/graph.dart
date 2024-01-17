import 'package:flutter/foundation.dart';
import 'package:week3/models/edge.dart';
import 'package:week3/models/node.dart';
import 'package:week3/models/post.dart';

class Graph extends ChangeNotifier {
  List<Node> nodes = [];
  List<Edge> edges = [];
  int _newId = 1, _newConstellationId = 1;

  void addNode(Node node, {bool newPost = true}) {
    nodes.add(node
      ..id = (node is Constellation) ? _newConstellationId++ : _newId++
      ..post = newPost
          ? Post(
              title: (node is Constellation)
                  ? 'Constellation ${node.id}'
                  : 'Star ${node.id}',
            )
          : node.post);
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
    if (node is Star) {
      final index = node.constellation?.stars.indexOf(node);
      if (index != null) {
        node.constellation!.stars.removeAt(index);
        node.constellation!.starsPos.removeAt(index);
      }
    }
    notifyListeners(); // 상태 변경 알림
  }
}
