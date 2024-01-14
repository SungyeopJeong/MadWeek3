import 'package:flutter/material.dart';
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
}

class Star extends Node {
  Constellation? constellation;
  late List<Planet> planets;
  bool showStar, showArea, showOrbit, isDeleting;
  late AnimationController planetAnimation;

  int _newId = 1;

  Star({
    required super.pos,
    this.constellation,
    this.showStar = true,
    this.showArea = false,
    this.showOrbit = false,
    this.isDeleting = false,
  });

  void addPlanet(Planet planet) {
    planets.add(planet..id = _newId++);
  }
}

class Constellation extends Node {
  late List<Star> stars;

  Constellation({
    required super.pos,
  });
}
