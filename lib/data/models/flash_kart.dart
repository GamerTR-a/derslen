/// Flash Kart Modeli — Ders kartı içeriği
library;

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/constants/app_constants.dart';

part 'flash_kart.freezed.dart';
part 'flash_kart.g.dart';

@freezed
abstract class FlashKart with _$FlashKart {
  const factory FlashKart({
    required String id,
    required String ders,
    required String unite,
    required String on,
    required String arka,
    String? ipucu,
  }) = _FlashKart;

  factory FlashKart.fromJson(Map<String, dynamic> json) =>
      _$FlashKartFromJson(json);

  const FlashKart._();

  /// Ders rengi
  Color get renk => dersRengi(ders);

  /// Ders etiketi
  String get dersEtiketi => dersEtiketleri[ders] ?? ders;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlashKart && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}