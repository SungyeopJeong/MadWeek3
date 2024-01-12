import 'package:flutter/material.dart';

class Edge {
  Offset start, end;

  Edge({required this.start, required this.end});

  @override
  bool operator ==(Object other) {
    if (other is! Edge) return false;
    return start == other.start && end == other.end;
  }

  @override
  int get hashCode => Object.hash(start, end);
}

class EdgeIndexed {
  final int startIdx, endIdx;

  EdgeIndexed({required this.startIdx, required this.endIdx});

  @override
  bool operator ==(Object other) {
    if (other is! EdgeIndexed) return false;
    return startIdx == other.startIdx && endIdx == other.endIdx;
  }

  @override
  int get hashCode => Object.hash(startIdx, endIdx);
}