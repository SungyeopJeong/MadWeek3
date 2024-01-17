import 'dart:ui';

extension OffsetExt on Offset {
  bool closeTo(Offset target, double diameter) {
    return (this - target).distanceSquared <= diameter * diameter / 4;
  }

  static Offset center(double diameter) {
    return Offset(diameter / 2, diameter / 2);
  }

  Map<String, dynamic> toJson() => {
        'x': dx,
        'y': dy,
      };

  static Offset fromJson(Map<String, dynamic> json) => Offset(json['x'], json['y']);
}
