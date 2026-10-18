import 'package:flutter/painting.dart';

abstract final class Dimens {
  static const double spaceXs = 6;
  static const double spaceS = 8;
  static const double spaceM = 12;
  static const double spaceL = 16;
  static const double spaceXl = 20;
  static const double space2xl = 28;
  static const double space3xl = 32;

  /// Side margin of full-width pages.
  static const double gutter = 24;

  static const double minTapTarget = 44;
  static const double radius = 16;
  static const double radiusS = 12;
  static const double radiusL = 24;
  static const double borderWidth = 2;

  /// Depth of the solid edge under a primary button.
  static const double buttonEdge = 4;
  static const double buttonMinHeight = 50;
  static const double fieldMinHeight = 56;
  static const double iconS = 18;
  static const double spinner = 22;

  // Chat measurements copied from artifacts/master-mobile.html.
  static const double space2xs = 4;
  static const double spaceTiny = 5;
  static const double spaceSm = 10;
  static const double spaceChat = 14;
  static const double chatAvatar = 42;
  static const double messageAvatar = 30;
  static const double bubbleRadius = 18;
  static const double dayRadius = 10;
  static const double messageTimeGap = 7;
  static const double messageTimeInset = 3;
  static const double iconXs = 13;
  static const double sendVisual = 36;
  static const double photoTile = 104;
  static const double photoRadius = 13;
  static const double gallerySide = 72;
  static const double galleryHandle = 40;
  static const EdgeInsets chatInputPadding = EdgeInsets.fromLTRB(14, 11, 4, 10);
  static const EdgeInsets chatHeaderPadding = EdgeInsets.fromLTRB(
    14,
    8,
    14,
    12,
  );
  static const EdgeInsets chatThreadPadding = EdgeInsets.fromLTRB(
    20,
    19,
    20,
    22,
  );
  static const EdgeInsets chatIntroPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 12,
  );
  static const EdgeInsets chatBubblePadding = EdgeInsets.symmetric(
    horizontal: 15,
    vertical: 11,
  );
  static const EdgeInsets chatComposerPadding = EdgeInsets.fromLTRB(
    14,
    6,
    14,
    8,
  );
  static const EdgeInsets chatMemoryPadding = EdgeInsets.fromLTRB(
    16,
    10,
    16,
    7,
  );

  static const EdgeInsets authPadding = EdgeInsets.fromLTRB(
    space2xl,
    space3xl,
    space2xl,
    spaceXl,
  );
}
