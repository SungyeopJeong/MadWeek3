import 'package:flutter/material.dart';

class Node {
  Offset pos;
  bool showArea, showOrbit, isDeleting;

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
