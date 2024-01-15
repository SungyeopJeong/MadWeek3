import 'package:flutter/material.dart';

class MyText {
  static const regularBase = TextStyle(
    letterSpacing: 0.15,
    leadingDistribution: TextLeadingDistribution.even,
  );

  static final labelRegular = regularBase.copyWith(
    fontSize: 12.0,
    height: 1.4,
  );
  static final labelBold = labelRegular.copyWith(fontWeight: FontWeight.bold);

  static final bodyRegular = regularBase.copyWith(
    fontSize: 14.0,
    height: 1.6,
  );
  static final bodyBold = bodyRegular.copyWith(fontWeight: FontWeight.bold);

  static final titleRegular = regularBase.copyWith(
    fontSize: 16.0,
    height: 1.6,
  );
  static final titleBold = titleRegular.copyWith(fontWeight: FontWeight.bold);

  static final headlineRegular = regularBase.copyWith(
    fontSize: 18.0,
    height: 1.6,
  );
  static final headlineBold =
      headlineRegular.copyWith(fontWeight: FontWeight.bold);

  static final displayRegular = regularBase.copyWith(
    fontSize: 20.0,
    height: 1.6,
  );
  static final displayBold =
      displayRegular.copyWith(fontWeight: FontWeight.bold);
}
