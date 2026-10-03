import 'package:flutter/material.dart';
import 'app_theme.dart';

extension AppColorsX on BuildContext {
  AppTheme get colors => Theme.of(this).extension<AppTheme>() ?? AppTheme.light;

  /// Temaya göre başlık yazı tipi (Fraunces / DM Serif Display).
  TextStyle baslik(double size, {Color? color}) => colors.baslik(size, color: color);
}
