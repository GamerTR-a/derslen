/// Günlük Check-in Modeli — Enerji, Odak, Stres (1-5)
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'gunluk_checkin.freezed.dart';
part 'gunluk_checkin.g.dart';

@freezed
abstract class GunlukCheckin with _$GunlukCheckin {
  const factory GunlukCheckin({
    required String tarih, // YYYY-MM-DD
    required int enerji, // 1-5
    required int odak, // 1-5
    required int stres, // 1-5
    required DateTime createdAt,
  }) = _GunlukCheckin;

  factory GunlukCheckin.fromJson(Map<String, dynamic> json) =>
      _$GunlukCheckinFromJson(json);

  const GunlukCheckin._();

  /// Enerji emoji
  String get enerjiEmoji {
    switch (enerji) {
      case 1:
        return '😴';
      case 2:
        return '😕';
      case 3:
        return '😐';
      case 4:
        return '😊';
      case 5:
        return '⚡';
      default:
        return '❓';
    }
  }

  /// Odak emoji
  String get odakEmoji {
    switch (odak) {
      case 1:
        return '🌫️';
      case 2:
        return '😕';
      case 3:
        return '😐';
      case 4:
        return '🎯';
      case 5:
        return '🔥';
      default:
        return '❓';
    }
  }

  /// Stres emoji
  String get stresEmoji {
    switch (stres) {
      case 1:
        return '😌';
      case 2:
        return '😌';
      case 3:
        return '😐';
      case 4:
        return '😰';
      case 5:
        return '🤯';
      default:
        return '❓';
    }
  }

  /// Enerji katsayısı (plan hesaplamasında kullanılır): 0.6 + enerji * 0.08
  double get enerjiKatsayi => 0.6 + enerji * 0.08;

  /// Stres katsayısı (plan hesaplamasında kullanılır): stres >= 4 ? 0.75 : 1.0
  double get stresKatsayi => stres >= 4 ? 0.75 : 1.0;

  /// Ortalama durum (1-5 arası)
  double get ortalama => (enerji + odak + (6 - stres)) / 3;

  /// Gün iyi mi? (enerji+odak yüksek, stres düşük)
  bool get gunIyiMi => enerji >= 4 && odak >= 4 && stres <= 2;

  /// Yüksek stres günü mü?
  bool get yuksekStresGunu => stres >= 4;

  /// Emoji ve değer çiftleri listesi
  List<(String, int, String)> get degerler => [
        ('Enerji', enerji, enerjiEmoji),
        ('Odak', odak, odakEmoji),
        ('Stres', stres, stresEmoji),
      ];
}