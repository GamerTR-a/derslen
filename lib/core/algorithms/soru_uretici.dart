/// Soru üreteci — sayısal konularda her seferinde farklı sayılarla yeni soru
/// üretir. Doğru cevap ve çözüm hesaplanarak yazıldığından üretilen soruların
/// cevabı her zaman tutarlıdır; hazır havuzdaki sorular bittiğinde bile konu
/// testleri ve denemeler soru bulur.
library;

import 'dart:math';

import '../../data/models/soru.dart';

/// Bir şablonun ürettiği ham soru.
class SoruTaslagi {
  final String metin;
  final String dogru;

  /// Çeldiriciler (en az dört farklı değer kalacak kadar aday verilir).
  final List<String> yanlis;
  final String cozum;

  const SoruTaslagi(this.metin, this.dogru, this.yanlis, this.cozum);
}

class SoruSablonu {
  final String id;
  final String ders;
  final String konu;
  final String alt;
  final SoruZorluk zorluk;

  /// Hizmet ettiği sınıf müfredatı konuları (bkz. sinif_mufredati.dart).
  final List<String> konuIdleri;
  final SoruTaslagi Function(Random r) taslak;

  const SoruSablonu(this.id, this.ders, this.konu, this.alt, this.zorluk, this.konuIdleri, this.taslak);

  /// Şablondan bir soru üretir. Aynı [tohum] aynı soruyu verir.
  Soru uret(int tohum) {
    final r = Random(tohum);
    for (var deneme = 0; deneme < 40; deneme++) {
      final t = taslak(r);
      final yanlis = <String>[];
      for (final y in t.yanlis) {
        if (y != t.dogru && !yanlis.contains(y)) yanlis.add(y);
      }
      if (yanlis.length < 4) continue;
      final secenekler = [t.dogru, ...yanlis.take(4)]..shuffle(r);
      const harfler = ['A', 'B', 'C', 'D', 'E'];
      return Soru(
        id: 'ur-$id-$tohum',
        ders: ders,
        konu: konu,
        altBaslik: alt,
        zorluk: zorluk,
        soruMetni: t.metin,
        secenekler: {for (var i = 0; i < 5; i++) harfler[i]: secenekler[i]},
        dogruSecenek: harfler[secenekler.indexOf(t.dogru)],
        cozumAciklama: t.cozum,
        kaynak: 'DersNet soru üreteci',
      );
    }
    throw StateError('Şablon $id yeterli çeldirici üretemedi');
  }
}

/// Üretilmiş (havuzda kayıtlı olmayan) soru mu?
bool uretilmisSoruMu(Soru s) => s.id.startsWith('ur-');

// ─── Şablon yazımında kullanılan yardımcılar ────────────────────────────

int rs(Random r, int alt, int ust) => alt + r.nextInt(ust - alt + 1);

T sec<T>(Random r, List<T> liste) => liste[r.nextInt(liste.length)];

int ebob(int a, int b) => b == 0 ? a.abs() : ebob(b, a % b);

/// Sadeleştirilmiş kesir metni ("3/4"); tam sayıysa yalnızca sayı.
String kesir(int pay, int payda) {
  if (payda < 0) {
    pay = -pay;
    payda = -payda;
  }
  final e = ebob(pay, payda);
  final p = pay ~/ e, q = payda ~/ e;
  return q == 1 ? '$p' : '$p/$q';
}

/// Tam sayı doğru cevap için çeldirici listesi: önce verilen (tipik hata)
/// adayları, ardından yakın değerler. Negatif adaylar [negatif] ile açılır.
List<String> sayiCeldirici(int dogru, List<int> adaylar, {bool negatif = false, String ek = ''}) {
  final l = <int>[];
  void ekle(int v) {
    if (v == dogru || l.contains(v)) return;
    if (!negatif && v < 0) return;
    l.add(v);
  }

  adaylar.forEach(ekle);
  for (final d in [1, -1, 2, -2, 3, 5, -3, 10, 4, 6, 7]) {
    ekle(dogru + d);
  }
  return [for (final v in l) '$v$ek'];
}

/// Ondalıklı (bir basamak) değer metni: 25 → "2,5" ([onKat] değerin 10 katıdır).
String ondalik(int onKat) {
  final isaret = onKat < 0 ? '-' : '';
  final m = onKat.abs();
  return m % 10 == 0 ? '$isaret${m ~/ 10}' : '$isaret${m ~/ 10},${m % 10}';
}
