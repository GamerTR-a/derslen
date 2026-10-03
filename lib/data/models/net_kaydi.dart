/// Net Kaydı Modeli — Deneme sonuçları
library;

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/constants/app_constants.dart';

part 'net_kaydi.freezed.dart';
part 'net_kaydi.g.dart';

@freezed
abstract class NetKaydi with _$NetKaydi {
  const factory NetKaydi({
    required String id,
    required String tarih, // YYYY-MM-DD
    required SinavAlani alan,
    required String ders,
    @Default(0) int dogru,
    @Default(0) int yanlis,
    @Default(0) int bos,
    String? denemeAdi,
    required DateTime createdAt,
  }) = _NetKaydi;

  factory NetKaydi.fromJson(Map<String, dynamic> json) => _$NetKaydiFromJson(json);

  const NetKaydi._();

  /// Net hesaplama — ÖSYM'nin 2018'den beri geçerli kuralı gereği hem TYT
  /// hem AYT'de 4 yanlış 1 doğruyu götürür (yanlış başına 0.25 net kaybı).
  double get net {
    final dogruNet = dogru - yanlis * 0.25;
    return double.parse(dogruNet.toStringAsFixed(2));
  }

  /// Toplam soru sayısı
  int get toplamSoru => dogru + yanlis + bos;

  /// Soru İndeksi — Soruların yüzde kaçı doğru?
  double get soruIndeksi {
    if (toplamSoru == 0) return 0;
    return (dogru / toplamSoru * 100).roundToDouble();
  }

  /// Ders rengi
  Color get renk => dersRengi(ders);
}