import 'package:flutter_test/flutter_test.dart';
import 'package:yks_kocu/core/constants/soru_havuzu.dart';

void main() {
  test('Soru havuzu benzersiz, eksiksiz ve tutarlı', () {
    expect(soruHavuzu.length, greaterThanOrEqualTo(600));
    final idler = <String>{};
    final metinler = <String>{};
    for (final s in soruHavuzu) {
      expect(idler.add(s.id), isTrue, reason: 'Tekrarlanan soru kimliği: ${s.id}');
      expect(metinler.add(s.soruMetni.trim()), isTrue, reason: 'Aynı soru metni iki kez var: ${s.id}');
      expect(s.soruMetni.trim(), isNotEmpty, reason: s.id);
      expect(s.cozumAciklama.trim(), isNotEmpty, reason: s.id);
      expect(s.konu.trim(), isNotEmpty, reason: s.id);
      expect(s.altBaslik.trim(), isNotEmpty, reason: s.id);
      expect(s.secenekler.keys.toList(), ['A', 'B', 'C', 'D', 'E'], reason: s.id);
      expect(s.secenekler.containsKey(s.dogruSecenek), isTrue, reason: '${s.id} doğru şık geçersiz');
      final secenekMetinleri = s.secenekler.values.map((v) => v.trim()).toSet();
      expect(secenekMetinleri.length, 5, reason: '${s.id} sorusunda aynı şık iki kez var');
      expect(secenekMetinleri.contains(''), isFalse, reason: '${s.id} sorusunda boş şık var');
    }
  });

  test('Her derste yeterli soru var ve doğru şıklar dengeli dağılmış', () {
    final dersler = <String, int>{};
    final siklar = <String, int>{};
    for (final s in soruHavuzu) {
      dersler[s.ders] = (dersler[s.ders] ?? 0) + 1;
      siklar[s.dogruSecenek] = (siklar[s.dogruSecenek] ?? 0) + 1;
    }
    expect(dersler.length, 11);
    for (final e in dersler.entries) {
      expect(e.value, greaterThanOrEqualTo(35), reason: '${e.key} dersinde az soru var');
    }
    // Hiçbir şık, soruların üçte birinden fazlasında doğru cevap olmamalı.
    for (final e in siklar.entries) {
      expect(e.value, lessThan(soruHavuzu.length / 3), reason: '${e.key} şıkkı çok sık doğru cevap');
      expect(e.value, greaterThan(soruHavuzu.length / 10), reason: '${e.key} şıkkı çok seyrek doğru cevap');
    }
  });

  test('Filtre haritası her soruyu kapsar', () {
    for (final s in soruHavuzu) {
      expect(dersKonuAltBaslikHaritasi[s.ders]?[s.konu]?.contains(s.altBaslik), isTrue, reason: s.id);
    }
    expect(filtreliSorular().length, soruHavuzu.length);
    expect(filtreliSorular(ders: 'Matematik', zorluk: 'kolay'), isNotEmpty);
  });
}
