import 'dart:ui';

double ccw(Offset a, Offset b, Offset c) {
  return (b.dx - a.dx) * (c.dy - a.dy) - (c.dx - a.dx) * (b.dy - a.dy);
}

bool isIn(Offset position, List<Offset>? corners) {
  if (corners == null) return false;
  if (ccw(corners.first, corners.last, position) > 0) return false;
  if (ccw(corners.first, corners[1], position) < 0) return false;
  var l = 1, r = corners.length - 1;
  while (l + 1 < r) {
    final m = (l + r) ~/ 2;
    if (ccw(corners[0], corners[m], position) > 0) {
      l = m;
    } else {
      r = m;
    }
  }
  return ccw(corners[l], position, corners[l + 1]) < 0;
}
