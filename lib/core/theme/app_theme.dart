/// Tema-duyarlı renk ve yazı seti — açık tema "Sabah Bahçesi", koyu tema
/// "Gece Kütüphanesi". Kullanım: `context.colors.primary` (bkz. theme_extensions.dart)
library;

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme extends ThemeExtension<AppTheme> {
  final Color background;
  final Color surface;
  final Color card;
  final Color border;
  final Color primary;
  final Color primaryLight;
  final Color accent;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  /// primary / success / warning / danger dolgularının üzerindeki yazı rengi.
  final Color onPrimary;
  final Color primarySoft;
  final Color accentSoft;

  /// Öne çıkan kartların (ilham sözü vb.) zemini ve üzerindeki yazı.
  final Color feature;
  final Color onFeature;
  final Color star;
  final Color water;
  final Color sky;
  final Color soil;
  final String baslikFont;
  final bool gece;

  const AppTheme({
    required this.background,
    required this.surface,
    required this.card,
    required this.border,
    required this.primary,
    required this.primaryLight,
    required this.accent,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.onPrimary,
    required this.primarySoft,
    required this.accentSoft,
    required this.feature,
    required this.onFeature,
    required this.star,
    required this.water,
    required this.sky,
    required this.soil,
    required this.baslikFont,
    required this.gece,
  });

  static const AppTheme light = AppTheme(
    background: AppColors.sabahZemin,
    surface: AppColors.sabahYuzey,
    card: AppColors.sabahYuzey,
    border: AppColors.sabahCizgi,
    primary: AppColors.sabahAdacayi,
    primaryLight: AppColors.sabahYaprak,
    accent: AppColors.sabahAmber,
    success: AppColors.sabahAdacayi,
    warning: AppColors.sabahAmber,
    danger: AppColors.sabahKiremit,
    info: AppColors.sabahMavi,
    textPrimary: AppColors.sabahMurekkep,
    textSecondary: AppColors.sabahMurekkep2,
    textMuted: AppColors.sabahSoluk,
    onPrimary: Colors.white,
    primarySoft: AppColors.sabahFiliz,
    accentSoft: AppColors.sabahAmberSoft,
    feature: AppColors.sabahOrman,
    onFeature: AppColors.sabahZemin,
    star: AppColors.sabahYildiz,
    water: AppColors.sabahSu,
    sky: AppColors.sabahGok,
    soil: AppColors.sabahToprak,
    baslikFont: 'Fraunces',
    gece: false,
  );

  static const AppTheme dark = AppTheme(
    background: AppColors.geceZemin,
    surface: AppColors.geceYuzey,
    card: AppColors.geceYuzey,
    border: AppColors.geceCizgi,
    primary: AppColors.geceLavanta,
    primaryLight: AppColors.geceLavantaAcik,
    accent: AppColors.geceLamba,
    success: AppColors.geceNane,
    warning: AppColors.geceLamba,
    danger: AppColors.gecePembe,
    info: AppColors.geceBuz,
    textPrimary: AppColors.geceKrem,
    textSecondary: AppColors.geceKrem2,
    textMuted: AppColors.geceSoluk,
    onPrimary: AppColors.geceZemin,
    primarySoft: AppColors.geceLavantaSoft,
    accentSoft: AppColors.geceLambaSoft,
    feature: AppColors.geceYuzey2,
    onFeature: AppColors.geceKrem,
    star: AppColors.geceLamba,
    water: AppColors.geceLavanta,
    sky: AppColors.geceGok,
    soil: AppColors.geceTas,
    baslikFont: 'DMSerifDisplay',
    gece: true,
  );

  /// Başlık yazı stili. DM Serif Display tek ağırlıklı olduğu için gece
  /// temasında kalınlık yapay olarak kalınlaştırılmaz.
  TextStyle baslik(double size, {Color? color}) => TextStyle(
        fontFamily: baslikFont,
        fontSize: gece ? size * 1.06 : size,
        fontWeight: gece ? FontWeight.w400 : FontWeight.w700,
        color: color ?? textPrimary,
        letterSpacing: gece ? 0 : -0.4,
        height: 1.15,
      );

  @override
  AppTheme copyWith({
    Color? background,
    Color? surface,
    Color? card,
    Color? border,
    Color? primary,
    Color? primaryLight,
    Color? accent,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
  }) {
    return AppTheme(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      border: border ?? this.border,
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      accent: accent ?? this.accent,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      onPrimary: onPrimary,
      primarySoft: primarySoft,
      accentSoft: accentSoft,
      feature: feature,
      onFeature: onFeature,
      star: star,
      water: water,
      sky: sky,
      soil: soil,
      baslikFont: baslikFont,
      gece: gece,
    );
  }

  @override
  AppTheme lerp(ThemeExtension<AppTheme>? other, double t) {
    if (other is! AppTheme) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppTheme(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      card: l(card, other.card),
      border: l(border, other.border),
      primary: l(primary, other.primary),
      primaryLight: l(primaryLight, other.primaryLight),
      accent: l(accent, other.accent),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      danger: l(danger, other.danger),
      info: l(info, other.info),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      onPrimary: l(onPrimary, other.onPrimary),
      primarySoft: l(primarySoft, other.primarySoft),
      accentSoft: l(accentSoft, other.accentSoft),
      feature: l(feature, other.feature),
      onFeature: l(onFeature, other.onFeature),
      star: l(star, other.star),
      water: l(water, other.water),
      sky: l(sky, other.sky),
      soil: l(soil, other.soil),
      baslikFont: t < 0.5 ? baslikFont : other.baslikFont,
      gece: t < 0.5 ? gece : other.gece,
    );
  }
}
