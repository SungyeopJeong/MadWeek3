import 'package:flutter/material.dart';
import 'package:week3/models/post.dart';

class Node {
  Offset pos;
  bool showArea, showOrbit, isDeleting;
  late Post post;
  late AnimationController planetAnimation;

  Node(
    this.pos, {
    this.showArea = false,
    this.showOrbit = false,
    this.isDeleting = false,
  });

  factory Node.from(Node node) {
    return Node(
      node.pos,
      showArea: node.showArea,
      showOrbit: node.showOrbit,
      isDeleting: node.isDeleting,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! Node) return false;
    return pos == other.pos;
  }

  @override
  int get hashCode => Object.hash(pos, showArea, showOrbit, isDeleting);
}
