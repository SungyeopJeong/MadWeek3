import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:week3/extensions/offset.dart';
import 'package:week3/models/Graph.dart';
import 'package:week3/models/node.dart';
import 'package:week3/models/edge.dart';
import 'package:week3/models/post.dart';

class GraphViewModel extends ChangeNotifier {
  final Graph _graph = Graph();

  List<Node> get nodes => _graph.nodes;
  List<Edge> get edges => _graph.edges;

  GraphViewModel() {
    loadFromJsonFile();
  }

  Star _jsonToStar(Map<String, dynamic> json) {
    final newStar = Star(pos: OffsetExt.fromJson(json['pos']))
      ..post = Post.fromJson(json['post'])
      ..planets = [];
    for (final planet in json['planets']) {
      newStar.addPlanet(
          Planet(star: newStar)..post = Post.fromJson(planet['post']));
    }
    return newStar;
  }

  void loadFromJsonFile() async {
    final sp = await SharedPreferences.getInstance();
    final string = sp.getString('data');
    if (string != null) {
      final map = jsonDecode(string);
      for (final node in map['data']) {
        if ((node as Map).containsKey('stars')) {
          /*final newConstellation =
              Constellation(pos: OffsetExt.fromJson(node['pos']))
                ..post = Post.fromJson(node['post'])
                ..stars = [];
          for (final star in node['stars']) {
            newConstellation.stars.add(_jsonToStar(star));
          }
          _graph.addNode(newConstellation, newPost: false);*/
        } else {
          _graph.addNode(_jsonToStar(node as Map<String, dynamic>),
              newPost: false);
        }
      }
    }
    notifyListeners();
  }

  void addNode(Node node, {bool newPost = true}) {
    _graph.addNode(node, newPost: newPost);
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
