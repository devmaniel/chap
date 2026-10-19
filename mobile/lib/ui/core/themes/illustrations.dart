import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../../domain/models/post/post.dart';

/// Picture colors copied from the master mockup: portrait tones, profile
/// covers and sample photo scenes. Content art, not UI chrome, so these sit
/// outside the color scheme.
abstract final class Illustrations {
  static const _tones = {
    'mina': Color(0xFFEDCFB9),
    'kai': Color(0xFFD8D4ED),
    'sol': Color(0xFFDEEBFF),
    'lumi': Color(0xFFECD9D9),
  };

  static const _fallbackTone = Color(0xFFFFE3D1);

  static Color tone(String characterId) => _tones[characterId] ?? _fallbackTone;

  /// Profile banner; a character without one gets their tone.
  static Gradient cover(String characterId) => switch (characterId) {
    'mina' => _css(135, const [
      Color(0xFFFFD9B0),
      Color(0xFFFF9F7A),
      Color(0xFFF0708A),
    ]),
    'lumi' => _css(135, const [
      Color(0xFFF6D4FF),
      Color(0xFFB9A4F5),
      Color(0xFF7F8CF0),
    ]),
    'sol' => _css(135, const [
      Color(0xFFC9F1FF),
      Color(0xFF7CC8F5),
      Color(0xFF4F8FE0),
    ]),
    _ => _css(135, List.filled(3, tone(characterId))),
  };

  /// Warm backdrop behind the friend on a voice call.
  static const callStage = RadialGradient(
    center: Alignment(-0.7, -1),
    radius: 1.2,
    colors: [Color(0xFFFFF6EC), Color(0xFFFFE6CC), Color(0xFFFFD6AD)],
    stops: [0, 0.5, 1],
  );

  /// Dark backdrop while a call rings, like an iPhone outgoing call.
  static const callDial = RadialGradient(
    center: Alignment(0, -0.8),
    radius: 1.5,
    colors: [Color(0xFF5A4636), Color(0xFF2A2420), Color(0xFF141210)],
    stops: [0, 0.55, 1],
  );

  /// Dark floor under the call controls.
  static const callBar = LinearGradient(
    colors: [Color(0xFF0F1418), Color(0xFF1A252C), Color(0xFF2E4450)],
    stops: [0, 0.7, 1],
  );

  static Gradient scene(PhotoScene scene) => switch (scene) {
    PhotoScene.sunset => _css(160, const [
      Color(0xFFFFE08A),
      Color(0xFFFF9A62),
      Color(0xFFE2557A),
    ], middle: 0.5),
    PhotoScene.sea => _css(180, const [
      Color(0xFFBFEAFF),
      Color(0xFF58B7EA),
      Color(0xFF1F6FB8),
    ]),
    PhotoScene.mint => _css(150, const [
      Color(0xFFE6FFF2),
      Color(0xFF9DE3C4),
      Color(0xFF4FB79A),
    ]),
    PhotoScene.peach => _css(140, const [
      Color(0xFFFFF1E0),
      Color(0xFFFFC8A2),
      Color(0xFFF59A8A),
    ]),
    PhotoScene.dusk => _css(170, const [
      Color(0xFFFFB3C7),
      Color(0xFFA77DE0),
      Color(0xFF3F3A8F),
    ], middle: 0.5),
    PhotoScene.forest => _css(160, const [
      Color(0xFFD9F5A8),
      Color(0xFF6FC46B),
      Color(0xFF2F7A52),
    ]),
  };

  /// CSS `linear-gradient(<deg>, a, b <middle>, c)`: 0deg points up and 90deg
  /// right, which is Flutter's unrotated direction.
  static Gradient _css(
    double degrees,
    List<Color> colors, {
    double middle = 0.55,
  }) => LinearGradient(
    colors: colors,
    stops: [0, middle, 1],
    transform: GradientRotation((degrees - 90) * math.pi / 180),
  );
}

/// The photo viewer is full-bleed black whatever the theme, so it keeps its
/// own ink, copied from the master mockup.
abstract final class ViewerColors {
  static const background = Color(0xFF000000);
  static const ink = Color(0xFFFFFFFF);
  static const muted = Color(0xB3FFFFFF);
  static const line = Color(0x33FFFFFF);
  static const dot = Color(0x59FFFFFF);
  static const like = Color(0xFFFF6B6B);
}
