import 'package:flutter/material.dart';

import '../models/store_category.dart';

/// Две темы приложения:
///  * светлая (по умолчанию) — мягкая, тёплая, с разноцветными категориями пастельных оттенков;
///  * тёмная — лаконичная: чёрный, графит и фиолетовый/пурпурный акцент.

// ---- Светлая ----
const _rose = Color(0xFFD9467A); // основной акцент — приглушённая роза
const _lightBg = Color(0xFFFFF8FA);

// ---- Тёмная ----
const darkPurple = Color(0xFFA259FF);
const darkMagenta = Color(0xFFD946EF);
const _black = Color(0xFF0D0D0F);
const _graphite = Color(0xFF1A1A1E);
const _graphite2 = Color(0xFF242429);

ThemeData buildTheme(Brightness b) => b == Brightness.dark ? _dark() : _light();

ThemeData _light() {
  final scheme = ColorScheme.fromSeed(
    seedColor: _rose,
    brightness: Brightness.light,
    primary: _rose,
    secondary: const Color(0xFF8E7CC3), // лаванда
    tertiary: const Color(0xFF4DB6AC), // мята
    surface: _lightBg,
  );
  return _base(scheme).copyWith(
    scaffoldBackgroundColor: _lightBg,
    cardTheme: CardThemeData(
      elevation: 1,
      shadowColor: _rose.withValues(alpha: 0.15),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    ),
  );
}

ThemeData _dark() {
  final scheme = ColorScheme.fromSeed(
    seedColor: darkPurple,
    brightness: Brightness.dark,
  ).copyWith(
    primary: darkPurple,
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFF3B1F66),
    onPrimaryContainer: const Color(0xFFEBDCFF),
    secondary: darkMagenta,
    secondaryContainer: const Color(0xFF2E1A33),
    onSecondaryContainer: const Color(0xFFF5D0FE),
    tertiary: const Color(0xFF9CA3AF),
    surface: _black,
    onSurface: const Color(0xFFEDEDF0),
    onSurfaceVariant: const Color(0xFF9A9AA3),
    surfaceContainerLowest: _black,
    surfaceContainerLow: _graphite,
    surfaceContainer: _graphite,
    surfaceContainerHigh: _graphite2,
    surfaceContainerHighest: _graphite2,
    outline: const Color(0xFF55555E),
    outlineVariant: const Color(0xFF2E2E34),
  );
  return _base(scheme).copyWith(
    scaffoldBackgroundColor: _black,
    cardTheme: CardThemeData(
      elevation: 0,
      color: _graphite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF2A2A30)),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    ),
  );
}

ThemeData _base(ColorScheme scheme) => ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: scheme.brightness,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        scrolledUnderElevation: 2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: scheme.brightness == Brightness.dark ? 1 : 0.7),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
      chipTheme: ChipThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
    );

/// Цвет категории с учётом темы: в светлой — разноцветные мягкие оттенки,
/// в тёмной — только фиолетово-пурпурно-серая гамма.
extension CategoryTint on StoreCategory {
  Color tint(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.light) return _lightTints[this] ?? color;
    return _darkTints[this] ?? darkPurple;
  }
}

const _lightTints = <StoreCategory, Color>{
  StoreCategory.grocery: Color(0xFF5BAE7E), // шалфей
  StoreCategory.hardware: Color(0xFFE59A5C), // абрикос
  StoreCategory.household: Color(0xFF5B9BD5), // небесный
  StoreCategory.pharmacy: Color(0xFFE5737F), // коралл
  StoreCategory.pets: Color(0xFFB08968), // карамель
  StoreCategory.kids: Color(0xFFE07BB0), // пион
  StoreCategory.electronics: Color(0xFF8E7CC3), // лаванда
  StoreCategory.garden: Color(0xFF8DB86B), // олива
  StoreCategory.other: Color(0xFF8A94A6), // серо-голубой
};

const _darkTints = <StoreCategory, Color>{
  StoreCategory.grocery: Color(0xFFA259FF),
  StoreCategory.hardware: Color(0xFFD946EF),
  StoreCategory.household: Color(0xFF8B5CF6),
  StoreCategory.pharmacy: Color(0xFFE879F9),
  StoreCategory.pets: Color(0xFF9CA3AF),
  StoreCategory.kids: Color(0xFFC084FC),
  StoreCategory.electronics: Color(0xFF7C3AED),
  StoreCategory.garden: Color(0xFFB794F6),
  StoreCategory.other: Color(0xFF9CA3AF),
};
