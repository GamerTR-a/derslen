/// Plan Blok Modeli — Günlük çalışma blokları
library;

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/constants/app_constants.dart';

part 'plan_blok.freezed.dart';
part 'plan_blok.g.dart';

@freezed
abstract class PlanBlok with _$PlanBlok {
  const factory PlanBlok({
    required String id,
    required String konu,
    String? ders,
    required int sure, // dakika
    @Default(PlanBlokTip.calisma) PlanBlokTip tip,
    @Default(false) bool tamamlandi,
    String? renk,
    String? saat, // HH:MM format
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _PlanBlok;

  factory PlanBlok.fromJson(Map<String, dynamic> json) => _$PlanBlokFromJson(json);

  const PlanBlok._();

  /// Blok tipi etiketi
  String get tipEtiketi {
    switch (tip) {
      case PlanBlokTip.calisma:
        return 'Çalışma';
      case PlanBlokTip.tekrar:
        return 'Tekrar';
      case PlanBlokTip.soru:
        return 'Soru Çözme';
      case PlanBlokTip.mola:
        return 'Mola';
      case PlanBlokTip.egzersiz:
        return 'Egzersiz';
    }
  }

  /// Blok tipi ikonu
  String get tipIkon {
    switch (tip) {
      case PlanBlokTip.calisma:
        return '📚';
      case PlanBlokTip.tekrar:
        return '🔁';
      case PlanBlokTip.soru:
        return '✏️';
      case PlanBlokTip.mola:
        return '☕';
      case PlanBlokTip.egzersiz:
        return '🧘';
    }
  }

  /// Blok tipi ikonu (Material Icons) — profesyonel/sade liste görünümü için
  IconData get tipIconData {
    switch (tip) {
      case PlanBlokTip.calisma:
        return Icons.menu_book_rounded;
      case PlanBlokTip.tekrar:
        return Icons.replay_rounded;
      case PlanBlokTip.soru:
        return Icons.edit_note_rounded;
      case PlanBlokTip.mola:
        return Icons.coffee_rounded;
      case PlanBlokTip.egzersiz:
        return Icons.self_improvement_rounded;
    }
  }

  /// Blok rengi (ders rengi veya varsayılan)
  Color get blokRenk {
    if (renk != null && renk!.isNotEmpty) {
      final hex = renk!.replaceFirst('#', '');
      final deger = int.tryParse(hex.length <= 6 ? 'FF${hex.padLeft(6, '0')}' : hex, radix: 16);
      if (deger != null) return Color(deger);
    }
    if (ders != null && ders!.isNotEmpty) {
      return dersRengi(ders!);
    }
    switch (tip) {
      case PlanBlokTip.calisma:
        return const Color(0xFF6366F1);
      case PlanBlokTip.tekrar:
        return const Color(0xFF8B5CF6);
      case PlanBlokTip.soru:
        return const Color(0xFFF59E0B);
      case PlanBlokTip.mola:
        return const Color(0xFF10B981);
      case PlanBlokTip.egzersiz:
        return const Color(0xFF14B8A6);
    }
  }

  /// Saat formatı (HH:MM)
  String get saatFormatli {
    if (saat != null && saat!.isNotEmpty) return saat!;
    return '--:--';
  }

  /// Süre formatlı (25 dk, 1 saat 30 dk vb.)
  String get sureFormatli {
    if (sure < 60) return '$sure dk';
    final saat = sure ~/ 60;
    final dakika = sure % 60;
    if (dakika == 0) return '$saat saat';
    return '$saat saat $dakika dk';
  }

  /// Mola mı?
  bool get isMola => tip == PlanBlokTip.mola;

  /// Egzersiz mi?
  bool get isEgzersiz => tip == PlanBlokTip.egzersiz;

  /// Çalışma bloğu mu? (mola/egzersiz hariç)
  bool get isCalismaBloku =>
      tip == PlanBlokTip.calisma ||
      tip == PlanBlokTip.tekrar ||
      tip == PlanBlokTip.soru;
}