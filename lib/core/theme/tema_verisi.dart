/// AppTheme renk setinden Material ThemeData üretir; açık ve koyu tema
/// aynı kurallarla kurulur, sadece renk ve yazı tipleri değişir.
library;

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'app_theme.dart';

ThemeData temaVerisi(AppTheme c) {
  final brightness = c.gece ? Brightness.dark : Brightness.light;
  final govdeFont = c.gece ? 'Manrope' : 'PlusJakartaSans';
  final yuvarlak = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));

  final scheme = ColorScheme.fromSeed(
    seedColor: c.primary,
    brightness: brightness,
  ).copyWith(
    primary: c.primary,
    onPrimary: c.onPrimary,
    secondary: c.accent,
    onSecondary: c.onPrimary,
    surface: c.surface,
    onSurface: c.textPrimary,
    onSurfaceVariant: c.textSecondary,
    error: c.danger,
    onError: c.onPrimary,
    outline: c.border,
    outlineVariant: c.border,
    secondaryContainer: c.primarySoft,
    onSecondaryContainer: c.textPrimary,
    primaryContainer: c.primarySoft,
    onPrimaryContainer: c.textPrimary,
    surfaceContainerHighest: c.background,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: govdeFont,
    scaffoldBackgroundColor: c.background,
    extensions: [c],
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      headlineLarge: c.baslik(30),
      headlineMedium: c.baslik(26),
      headlineSmall: c.baslik(22),
      titleLarge: c.baslik(20),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: c.textPrimary),
      titleTextStyle: c.baslik(21),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      titleTextStyle: c.baslik(21),
      contentTextStyle: TextStyle(fontFamily: govdeFont, color: c.textSecondary, fontSize: 14.5, height: 1.45),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: c.border,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    cardTheme: CardThemeData(
      color: c.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: c.gece ? BorderSide(color: c.border) : BorderSide.none,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        disabledBackgroundColor: c.border,
        shape: yuvarlak,
        minimumSize: const Size(48, 48),
        textStyle: TextStyle(fontFamily: govdeFont, fontWeight: FontWeight.w800, fontSize: 15),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        elevation: 0,
        shape: yuvarlak,
        minimumSize: const Size(48, 48),
        textStyle: TextStyle(fontFamily: govdeFont, fontWeight: FontWeight.w800, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.primary,
        side: BorderSide(color: c.border, width: 1.5),
        shape: yuvarlak,
        minimumSize: const Size(48, 48),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: c.primary, minimumSize: const Size(48, 44)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: c.primary,
      foregroundColor: c.onPrimary,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: c.surface,
      selectedColor: c.primary,
      side: BorderSide(color: c.border),
      labelStyle: TextStyle(fontFamily: govdeFont, color: c.textSecondary, fontWeight: FontWeight.w700),
      secondaryLabelStyle: TextStyle(fontFamily: govdeFont, color: c.onPrimary, fontWeight: FontWeight.w800),
      checkmarkColor: c.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.gece ? const Color(0xFF161C35) : c.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: c.primarySoft,
      height: 70,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontFamily: govdeFont,
            fontSize: 11.5,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w700,
            color: s.contains(WidgetState.selected) ? (c.gece ? c.primaryLight : c.primary) : c.textMuted,
          )),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? (c.gece ? c.primaryLight : c.primary) : c.textMuted,
          )),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.gece ? c.primaryLight : c.feature,
      contentTextStyle: TextStyle(fontFamily: govdeFont, color: c.gece ? c.onPrimary : c.onFeature, fontWeight: FontWeight.w600),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.gece ? c.background : c.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.primary, width: 2)),
      labelStyle: TextStyle(color: c.textSecondary),
      hintStyle: TextStyle(color: c.textMuted),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary, linearTrackColor: c.border, circularTrackColor: c.border),
    sliderTheme: base.sliderTheme.copyWith(activeTrackColor: c.primary, thumbColor: c.primary, inactiveTrackColor: c.border),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.onPrimary : null),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.primary : null),
    ),
    dividerTheme: DividerThemeData(color: c.border, thickness: 1),
    tabBarTheme: TabBarThemeData(labelColor: c.textPrimary, unselectedLabelColor: c.textMuted, indicatorColor: c.accent),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
