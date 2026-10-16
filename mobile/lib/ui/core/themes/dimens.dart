import 'package:flutter/painting.dart';

abstract final class Dimens {
  static const double spaceXs = 6;
  static const double spaceS = 8;
  static const double spaceM = 12;
  static const double spaceL = 16;
  static const double spaceXl = 20;
  static const double space2xl = 28;
  static const double space3xl = 32;

  static const double minTapTarget = 44;
  static const double radius = 16;
  static const double radiusS = 12;
  static const double borderWidth = 2;

  /// Depth of the solid edge under a primary button.
  static const double buttonEdge = 4;
  static const double buttonMinHeight = 50;
  static const double fieldMinHeight = 56;
  static const double iconS = 18;
  static const double spinner = 22;

  static const EdgeInsets authPadding = EdgeInsets.fromLTRB(
    space2xl,
    space3xl,
    space2xl,
    spaceXl,
  );
}
