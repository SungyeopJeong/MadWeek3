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

  // 사이드뷰 디렉토리 구현을 위한 메소드들

  // 별자리 리스트 반환
  List<Constellation> get constellations =>
      nodes.whereType<Constellation>().toList();

  // 독립적인 별들 리스트 반환
  List<Star> get standaloneStars {
    List<Star> allStars = nodes.whereType<Star>().toList();

    // 별자리에 속하지 않은 별들만 필터링
    return allStars.where((star) => star.constellation == null).toList();
  }

  // 별자리에 속한 별들 리스트 반환
  List<Star> starsInConstellation(Constellation constellation) {
    return constellation.stars;
  }

  // 별에 속한 행성들의 리스트를 반환하는 메소드
  List<Planet> planetsInStar(Star star) {
    return star.planets;
  }
}
