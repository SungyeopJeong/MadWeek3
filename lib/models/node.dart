import 'package:flutter/material.dart';
import 'package:week3/extensions/offset.dart';
import 'package:week3/models/post.dart';

class Node {
  late int id;
  Offset pos;
  late Post post;

  Node({
    required this.pos,
  });

  @override
  bool operator ==(Object other) {
    if (other is! Node) return false;
    return id == other.id;
  }

  @override
  int get hashCode => Object.hash(id, pos);
}

class Planet extends Node {
  Star star;
  bool showPlanet, showArea, isDeleting, isOrigin;

  Planet({
    super.pos = Offset.zero,
    required this.star,
    this.showPlanet = true,
    this.showArea = false,
    this.isDeleting = false,
    this.isOrigin = false,
  });

  Map<String, dynamic> toJson() => {
        'pos': pos.toJson(),
        'post': post.toJson(),
      };
}

class Star extends Node {
  Constellation? constellation;
  late List<Planet> planets;
  bool showStar, showArea, showOrbit, isDeleting;
  Offset? pushedPos;
  AnimationController? planetAnimation;

  int _newId = 1;

  bool get canBePlanet => planets.isEmpty;

  Star({
    required super.pos,
    this.constellation,
    this.showStar = true,
    this.showArea = false,
    this.showOrbit = false,
    this.isDeleting = false,
  });

  void addPlanet(Planet planet, {bool newPost = true}) {
    planets.add(planet
      ..id = _newId++
      ..post = newPost ? Post(title: 'Planet ${planet.id}') : planet.post);
  }

  Map<String, dynamic> toJson() => {
        'pos': pos.toJson(),
        'post': post.toJson(),
        'planets': planets.map((e) => e.toJson()).toList(),
      };
}

class Constellation extends Node {
  late List<Star> stars;
  List<Offset> starsPos = [];
  bool isIn = false;

  Constellation({
    super.pos = Offset.zero,
  });

  Map<String, dynamic> toJson() => {
        'pos': pos.toJson(),
        'post': post.toJson(),
        'stars': stars.map((e) => e.toJson()).toList(),
      };
}
