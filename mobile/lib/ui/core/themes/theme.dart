import 'package:flutter/material.dart';

import 'colors.dart';
import 'dimens.dart';

abstract final class AppTheme {
  static const _colorScheme = ColorScheme.light(
    primary: BrandColors.primary,
    onPrimary: BrandColors.white,
    primaryContainer: BrandColors.softPrimary,
    onPrimaryContainer: BrandColors.primaryInk,
    primaryFixedDim: BrandColors.primaryEdge,
    surface: BrandColors.white,
    onSurface: BrandColors.ink,
    onSurfaceVariant: BrandColors.muted,
    surfaceContainerLow: BrandColors.surface,
    outline: BrandColors.border,
    outlineVariant: BrandColors.line,
    error: BrandColors.danger,
    errorContainer: BrandColors.dangerSoft,
  );

  static OutlineInputBorder fieldBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(Dimens.radius),
    borderSide: BorderSide(color: color, width: Dimens.borderWidth),
  );

  static final light = ThemeData(
    useMaterial3: true,
    fontFamily: 'Nunito',
    colorScheme: _colorScheme,
    scaffoldBackgroundColor: _colorScheme.surface,
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? _colorScheme.surface
            : _colorScheme.surfaceContainerLow,
      ),
      constraints: const BoxConstraints(minHeight: Dimens.fieldMinHeight),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Dimens.spaceL,
        vertical: Dimens.spaceL,
      ),
      hintStyle: TextStyle(
        color: _colorScheme.onSurfaceVariant,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
      enabledBorder: fieldBorder(_colorScheme.outline),
      disabledBorder: fieldBorder(_colorScheme.outline),
      focusedBorder: fieldBorder(_colorScheme.primaryFixedDim),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _colorScheme.onPrimaryContainer,
        minimumSize: const Size.square(Dimens.minTapTarget),
        padding: const EdgeInsets.symmetric(horizontal: Dimens.spaceS),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimens.radiusS),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.78,
        ),
      ),
    ),
  );
}
