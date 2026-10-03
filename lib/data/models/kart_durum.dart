/// Flash Kart Durumu — SM-2 Algoritması için
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'kart_durum.freezed.dart';
part 'kart_durum.g.dart';

@freezed
abstract class KartDurum with _$KartDurum {
  const factory KartDurum({
    required String id, // kart_id (örn: edb-001)
    @Default(0) int tekrarSayisi,
    @Default(1) int aralik, // gün cinsinden
    @Default(2.5) double kolaylikFaktoru,
    required String sonrakiTekrar, // YYYY-MM-DD
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _KartDurum;

  factory KartDurum.fromJson(Map<String, dynamic> json) =>
      _$KartDurumFromJson(json);

  const KartDurum._();

  /// Bugün tekrar edilecek mi?
  bool get bugunTekrarEdilecek {
    final bugun = DateTime.now();
    final sonraki = DateTime.parse(sonrakiTekrar);
    return !sonraki.isAfter(DateTime(bugun.year, bugun.month, bugun.day));
  }

  /// Kaç gün sonra tekrar?
  int get gunSonra {
    final bugun = DateTime.now();
    final sonraki = DateTime.parse(sonrakiTekrar);
    final fark = sonraki.difference(DateTime(bugun.year, bugun.month, bugun.day)).inDays;
    return fark.clamp(0, 365);
  }

  /// Tekrar durumu etiketi
  String get durumEtiketi {
    if (bugunTekrarEdilecek) return 'Bugün';
    if (gunSonra == 1) return 'Yarın';
    if (gunSonra <= 7) return '$gunSonra gün sonra';
    return '$gunSonra gün sonra';
  }

  /// Zorluk seviyesi (kolaylık faktörüne göre)
  String get zorlukSeviyesi {
    if (kolaylikFaktoru >= 2.5) return 'Kolay';
    if (kolaylikFaktoru >= 2.0) return 'Orta';
    return 'Zor';
  }

  /// Yeni kart için varsayılan durum
  factory KartDurum.yeniKart(String kartId) {
    final now = DateTime.now();
    final bugun = DateTime(now.year, now.month, now.day);
    return KartDurum(
      id: kartId,
      tekrarSayisi: 0,
      aralik: 1,
      kolaylikFaktoru: 2.5,
      sonrakiTekrar: bugun.toIso8601String().split('T')[0],
      createdAt: now,
      updatedAt: now,
    );
  }
}