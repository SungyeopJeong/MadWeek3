import 'package:flutter/material.dart';

class Edge {
  final Offset start, end;

  Edge({required this.start, required this.end});

  @override
  bool operator ==(Object other) {
    if (other is! Edge) return false;
    return start == other.start && end == other.end;
  }

  @override
  int get hashCode => Object.hash(start, end);
}
