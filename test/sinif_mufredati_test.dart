import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:yks_kocu/core/algorithms/soru_uretici.dart';
import 'package:yks_kocu/core/constants/flashkart_data.dart';
import 'package:yks_kocu/core/constants/sinif_mufredati.dart';
import 'package:yks_kocu/core/constants/soru_havuzu.dart';

void main() {
  group('Sınıf müfredatı (9-11, Maarif Modeli)', () {
    test('sınıf metninden sınıf numarası çıkarılır', () {
      expect(sinifNo('9. Sınıf'), 9);
      expect(sinifNo('11. Sınıf'), 11);
      expect(sinifNo('Mezun'), isNull);
      expect(sinifNo(null), isNull);
      expect(araSinif('10. Sınıf'), 10);
      expect(araSinif('12. Sınıf'), isNull);
      expect(araSinif('Üniversite'), isNull);
    });

    test('konu kimlikleri ve ders içi başlıklar benzersizdir', () {
      final idler = <String>{};
      final basliklar = <String>{};
      for (final k in sinifMufredati) {
        expect(idler.add(k.id), isTrue, reason: 'Tekrarlanan konu kimliği: ${k.id}');
        expect(basliklar.add('${k.ders}>${k.baslik}'), isTrue, reason: 'Aynı derste aynı başlık: ${k.id}');
        expect(k.id.startsWith('s${k.sinif}-'), isTrue, reason: k.id);
        expect(mufredatliSiniflar.contains(k.sinif), isTrue, reason: k.id);
      }
      for (final s in mufredatliSiniflar) {
        expect(sinifDersleri(s).length, greaterThanOrEqualTo(7), reason: '$s. sınıf');
        expect(sinifKonulari(s).length, greaterThanOrEqualTo(60), reason: '$s. sınıf');
      }
    });

    test('havuz ve kart bağlantıları gerçekten var olan başlıkları gösterir', () {
      final soruAnahtarlari = <String>{};
      for (final s in soruHavuzu) {
        soruAnahtarlari
          ..add('${s.ders}>${s.konu}')
          ..add('${s.ders}>${s.konu}>${s.altBaslik}');
      }
      final kartAnahtarlari = {for (final k in flashKartlar) '${k.ders}>${k.unite}'};
      for (final k in sinifMufredati) {
        for (final h in k.havuz) {
          expect(soruAnahtarlari.contains(h), isTrue, reason: '${k.id}: havuzda “$h” yok');
        }
        for (final c in k.kart) {
          expect(kartAnahtarlari.contains(c), isTrue, reason: '${k.id}: kartlarda “$c” yok');
        }
      }
    });

    test('her konuda konu testi ve kart tekrarı için yeterli içerik var', () {
      for (final k in sinifMufredati) {
        final hazir = konuHazirSorulari(k.id).length;
        final sablon = konuSablonlari(k.id).length;
        final yeterli = hazir >= 4 || (sablon >= 1 && hazir + 3 * sablon >= 5);
        expect(yeterli, isTrue, reason: '${k.id} ${k.baslik}: $hazir hazır soru, $sablon şablon');
        final kart = flashKartlar.where((f) => k.kartEslesir(f.id, f.ders, f.unite)).length;
        expect(kart, greaterThanOrEqualTo(2), reason: '${k.id} ${k.baslik}: $kart kart');
      }
    });

    test('her sınıfın her dersinde deneme kurmaya yetecek soru var', () {
      for (final s in mufredatliSiniflar) {
        for (final d in sinifDersleri(s)) {
          final hazir = sinifHazirSorulari(s, ders: d).length;
          final sablon = sinifSablonlari(s, ders: d).length;
          expect(hazir + sablon * 5, greaterThanOrEqualTo(25), reason: '$s. sınıf $d: $hazir soru, $sablon şablon');
        }
      }
    });
  });

  group('Soru üreteci', () {
    test('şablon kimlikleri benzersiz ve bağlandıkları konular geçerli', () {
      final idler = <String>{};
      for (final s in soruSablonlari) {
        expect(idler.add(s.id), isTrue, reason: 'Tekrarlanan şablon: ${s.id}');
        expect(s.konuIdleri, isNotEmpty, reason: s.id);
        for (final id in s.konuIdleri) {
          expect(sinifKonusuBul(id), isNotNull, reason: '${s.id} → $id');
        }
      }
      expect(soruSablonlari.length, greaterThanOrEqualTo(100));
    });

    test('her şablon her tohumda geçerli ve tutarlı soru üretir', () {
      for (final s in soruSablonlari) {
        final metinler = <String>{};
        for (var tohum = 0; tohum < 300; tohum++) {
          final soru = s.uret(tohum);
          expect(soru.secenekler.keys.toList(), ['A', 'B', 'C', 'D', 'E'], reason: '${s.id} #$tohum');
          final sik = soru.secenekler.values.map((v) => v.trim()).toSet();
          expect(sik.length, 5, reason: '${s.id} #$tohum aynı şık iki kez: ${soru.secenekler}');
          expect(sik.contains(''), isFalse, reason: '${s.id} #$tohum');
          expect(soru.secenekler.containsKey(soru.dogruSecenek), isTrue, reason: '${s.id} #$tohum');
          expect(soru.soruMetni.trim(), isNotEmpty, reason: s.id);
          expect(soru.cozumAciklama.trim(), isNotEmpty, reason: s.id);
          expect(soru.soruMetni.contains('null') || soru.cozumAciklama.contains('NaN'), isFalse, reason: '${s.id} #$tohum');
          expect(uretilmisSoruMu(soru), isTrue);
          metinler.add(soru.soruMetni);
          // Aynı tohum aynı soruyu vermeli (yanlış kartlarının tutarlılığı).
          if (tohum < 3) expect(s.uret(tohum).soruMetni, soru.soruMetni);
        }
        expect(metinler.length, greaterThanOrEqualTo(4), reason: '${s.id} yeterince çeşit üretmiyor');
      }
    });

    test('doğru cevaplar şıklara dengeli dağılır', () {
      final sayac = <String, int>{};
      for (final s in soruSablonlari) {
        for (var tohum = 0; tohum < 60; tohum++) {
          final d = s.uret(tohum).dogruSecenek;
          sayac[d] = (sayac[d] ?? 0) + 1;
        }
      }
      final toplam = sayac.values.fold<int>(0, (a, b) => a + b);
      for (final e in sayac.entries) {
        expect(e.value / toplam, inInclusiveRange(0.14, 0.26), reason: '${e.key} şıkkı');
      }
    });

    test('soruSec hazır soru yetmediğinde şablonlarla tamamlar', () {
      final r = Random(7);
      final konu = sinifKonusuBul('s9-mat-05')!;
      final secki = soruSec(konuHazirSorulari(konu.id), konuSablonlari(konu.id), 20, rastgele: r);
      expect(secki.length, 20);
      expect(secki.map((s) => s.soruMetni).toSet().length, 20);
      expect(secki.where(uretilmisSoruMu), isNotEmpty);

      // Şablonu olmayan konuda yalnızca hazır sorular gelir.
      final sozel = soruSec(konuHazirSorulari('s9-tar-03'), konuSablonlari('s9-tar-03'), 20, rastgele: r);
      expect(sozel.length, konuHazirSorulari('s9-tar-03').length);
      expect(sozel.any(uretilmisSoruMu), isFalse);
    });
  });
}
