import 'dart:ui';

class MyColor {
  static const bg = Color(0xFFF3F0E9);

  static const surface = Color(0xFF4D4D4D);
  static const onSurface = Color(0xFFFFFFFF);

  static const planet = Color(0xFF8E8E8E);
  static final planetArea = planet.withOpacity(0.2);
  static const star = Color(0xFFE5C33E);
  static final starArea = star.withOpacity(0.2);
  static final starOrbit = star.withOpacity(0.05);
  static const blackhole = Color(0xFF000000);
  static Color get origin => starArea;

  static const line = Color(0xFF777777);
  static const dashedLine = Color(0xFFCCCCCC);

  static final shadow = const Color(0xFF000000).withOpacity(0.1);
}
