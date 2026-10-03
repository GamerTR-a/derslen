/// Konu Modeli
library;

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/constants/app_constants.dart';

part 'konu.freezed.dart';
part 'konu.g.dart';

@freezed
abstract class Konu with _$Konu {
  const factory Konu({
    required String id,
    required String ders,
    required SinavAlani alan,
    required String baslik,
    @Default(false) bool tamamlandi,
    @Default(false) bool zayif,
  }) = _Konu;

  factory Konu.fromJson(Map<String, dynamic> json) => _$KonuFromJson(json);

  const Konu._();

  /// Ders rengi
  Color get renk => dersRengi(ders);

  /// Kullanıcının kendi eklediği konu mu (hazır YKS müfredatı dışı)?
  bool get ozel => id.startsWith('ozel-');

  /// Konu tam adı (ders + başlık)
  String get tamAd => '$ders - $baslik';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Konu && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}