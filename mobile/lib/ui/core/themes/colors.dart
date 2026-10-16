import 'package:flutter/painting.dart';

/// Raw palette, copied from the master mockup tokens. Widgets read
/// `Theme.of(context).colorScheme`, never these.
abstract final class BrandColors {
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF3C3C3C);
  static const muted = Color(0xFF6B6B6B);
  static const line = Color(0xFFE5E5E5);
  static const border = Color(0xFF8F8F8F);
  static const surface = Color(0xFFF7F7F7);
  static const primary = Color(0xFF1CB0F6);
  static const primaryEdge = Color(0xFF1899D6);
  static const softPrimary = Color(0xFFDDF4FF);
  static const primaryInk = Color(0xFF1A6FA0);
  static const primaryLine = Color(0xFF84D8FF);
  static const sun = Color(0xFFFFC800);
  static const sunSoft = Color(0xFFFFF4CC);
  static const sunInk = Color(0xFF7A5A00);
  static const danger = Color(0xFFB42A2A);
  static const dangerSoft = Color(0xFFFFDFE0);
}
