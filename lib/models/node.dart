import 'package:flutter/material.dart';

class Node {
  Offset pos;
  bool hover;

  Node(
    this.pos, {
    this.hover = false,
  });

  @override
  bool operator ==(Object other) {
    if (other is! Node) return false;
    return pos == other.pos;
  }

  @override
  int get hashCode => Object.hash(hover, pos);
}
