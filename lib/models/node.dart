import 'package:flutter/material.dart';

class Node {
  Offset pos;
  bool hover, isDeleting;

  Node(
    this.pos, {
    this.hover = false,
    this.isDeleting = false,
  });

  factory Node.from(Node node) {
    return Node(node.pos, hover: node.hover, isDeleting: node.isDeleting);
  }

  @override
  bool operator ==(Object other) {
    if (other is! Node) return false;
    return pos == other.pos;
  }

  @override
  int get hashCode => Object.hash(hover, pos);
}
