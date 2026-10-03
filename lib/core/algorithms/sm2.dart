/// SM-2 Spaced Repetition Algorithm
/// Web projesindeki `src/lib/sm2.ts` dosyasından port edildi.
library;

import '../../data/models/kart_durum.dart';

/// SM-2 kalite değerleri (0-5)
enum Sm2Kalite {
  tekrarSifirla(0, 'Tekrar', 'Bilmedim, tekrar et'),
  cokZor(1, 'Çok Zor', 'Büyük zorlukla hatırladım'),
  zor(2, 'Zor', 'Zorlayarak hatırladım'),
  orta(3, 'Orta', 'Biraz zorlayarak hatırladım'),
  kolay(4, 'Kolay', 'Kolayca hatırladım'),
  cokKolay(5, 'Çok Kolay', 'Mükemmel, anında hatırladım');

  const Sm2Kalite(this.value, this.kisaAd, this.aciklama);
  final int value;
  final String kisaAd;
  final String aciklama;

  static Sm2Kalite fromInt(int value) {
    return Sm2Kalite.values.firstWhere(
      (e) => e.value == value,
      orElse: () => Sm2Kalite.orta,
    );
  }
}

/// SM-2 Güncelleme Algoritması
/// [durum] güncel kart durumu
/// [kalite] kullanıcının verdiği puan (0-5)
/// Güncellenmiş KartDurum döner
KartDurum sm2Guncelle(KartDurum durum, Sm2Kalite kalite) {
  var tekrarSayisi = durum.tekrarSayisi;
  var aralik = durum.aralik;
  var kolaylikFaktoru = durum.kolaylikFaktoru;

  if (kalite.value < 3) {
    // Yanlış veya zor — tekrar sayısını sıfırla
    tekrarSayisi = 0;
    aralik = 1;
  } else {
    // Doğru cevap
    if (tekrarSayisi == 0) {
      aralik = 1;
    } else if (tekrarSayisi == 1) {
      aralik = 6;
    } else {
      aralik = (aralik * kolaylikFaktoru).round();
    }
    tekrarSayisi += 1;
  }

  // Kolaylık faktörünü güncelle
  // EF' = EF + 0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)
  kolaylikFaktoru = kolaylikFaktoru +
      0.1 -
      (5 - kalite.value) * (0.08 + (5 - kalite.value) * 0.02);

  // Minimum 1.3
  if (kolaylikFaktoru < 1.3) kolaylikFaktoru = 1.3;

  // Maksimum tekrar aralığı
  if (aralik > 365) aralik = 365;

  // Sonraki tekrar tarihi
  final now = DateTime.now();
  final bugun = DateTime(now.year, now.month, now.day);
  final sonrakiTekrar = bugun.add(Duration(days: aralik));

  return KartDurum(
    id: durum.id,
    tekrarSayisi: tekrarSayisi,
    aralik: aralik,
    kolaylikFaktoru: double.parse(kolaylikFaktoru.toStringAsFixed(2)),
    sonrakiTekrar: sonrakiTekrar.toIso8601String().split('T')[0],
    createdAt: durum.createdAt,
    updatedAt: DateTime.now(),
  );
}

/// Kolaylık butonları için kullanılan 3 buton (Basit UI için)
enum Sm2BasitKalite {
  bilmedim(0, 'Bilmedim', 0, '😞'),
  zor(1, 'Zor', 3, '😐'),
  kolay(2, 'Kolay', 5, '😊');

  const Sm2BasitKalite(this.kaliteIndex, this.etiket, this.kaliteDegeri, this.emoji);
  final int kaliteIndex;
  final String etiket;
  final int kaliteDegeri;
  final String emoji;

  Sm2Kalite get sm2Kalite => Sm2Kalite.fromInt(kaliteDegeri);
}

/// Bugün tekrar edilecek kartları filtrele
List<KartDurum> bugunTekrarEdilecekler(List<KartDurum> durumlar) {
  final bugun = DateTime.now();
  final today = DateTime(bugun.year, bugun.month, bugun.day);
  return durumlar.where((d) {
    final sonraki = DateTime.parse(d.sonrakiTekrar);
    return !sonraki.isAfter(today);
  }).toList();
}

/// Kart due sayısını ders bazında hesapla
Map<String, int> dueSayilariDersBazinda(
  List<KartDurum> durumlar,
  List<dynamic> flashKartlar, // FlashKart listesi
) {
  final bugunKartlar = bugunTekrarEdilecekler(durumlar);
  final map = <String, int>{};
  for (final durum in bugunKartlar) {
    final kart = flashKartlar.cast<dynamic>().firstWhere(
      (k) => k.id == durum.id,
      orElse: () => null,
    );
    if (kart != null) {
      final ders = kart.ders as String;
      map[ders] = (map[ders] ?? 0) + 1;
    }
  }
  return map;
}