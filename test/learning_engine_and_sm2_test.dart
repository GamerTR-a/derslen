import 'package:flutter_test/flutter_test.dart';
import 'package:yks_kocu/core/algorithms/learning_engine.dart';
import 'package:yks_kocu/core/algorithms/sm2.dart';
import 'package:yks_kocu/core/constants/app_constants.dart';
import 'package:yks_kocu/core/constants/soru_havuzu.dart';
import 'package:yks_kocu/core/constants/yks_data.dart';
import 'package:yks_kocu/data/models/ogrenci_profil.dart';
import 'package:yks_kocu/data/models/gunluk_checkin.dart';
import 'package:yks_kocu/data/models/kart_durum.dart';

void main() {
  group('🧠 YKS Koçu Algoritma ve Soru Havuzu Testleri', () {
    test('1. SM-2 Akıllı Tekrar Algoritması Hesaplaması', () {
      final baslangic = KartDurum(
        id: 'k1',
        tekrarSayisi: 0,
        aralik: 1,
        kolaylikFaktoru: 2.5,
        sonrakiTekrar: '2026-09-02',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Kolay (5/5 kalite puanı) yanıt verilince interval artmalı
      final sonucKolay = sm2Guncelle(baslangic, Sm2Kalite.cokKolay);

      expect(sonucKolay.tekrarSayisi, equals(1));
      expect(sonucKolay.aralik, equals(1));
      expect(sonucKolay.kolaylikFaktoru, greaterThan(2.5));

      // Bilmedim (0/5 kalite puanı) yanıt verilince tekrar sayısı 0 olmalı
      final sonucZor = sm2Guncelle(sonucKolay, Sm2Kalite.tekrarSifirla);

      expect(sonucZor.tekrarSayisi, equals(0));
      expect(sonucZor.aralik, equals(1));
    });

    test('2. AI Öğrenme Motoru Günlük Plan Üretimi', () {
      final profil = OgrenciProfil(
        hedefBolum: 'sayisal',
        gunlukSaat: 4,
        ogrenmeMetod: OgrenmeMetod.dengeli,
        onboardingTamamlandi: true,
      );

      final checkin = GunlukCheckin(
        enerji: 4,
        odak: 5,
        stres: 2,
        tarih: DateTime.now().toIso8601String(),
        createdAt: DateTime.now(),
      );

      final plan = gunlukPlanOlustur(
        profil,
        tumKonular,
        checkin,
      );

      expect(plan.length, greaterThan(0));
      final toplamDk = plan.fold<int>(0, (sum, b) => sum + b.sure);
      expect(toplamDk, greaterThanOrEqualTo(120));
    });

    test('3. Soru havuzu bütünlük ve filtreleme testi', () {
      expect(soruHavuzu.length, greaterThanOrEqualTo(150));
      final idler = <String>{};
      for (final soru in soruHavuzu) {
        expect(idler.add(soru.id), isTrue, reason: 'Tekrarlanan soru kimliği: ${soru.id}');
        expect(soru.soruMetni.trim(), isNotEmpty);
        expect(soru.cozumAciklama.trim(), isNotEmpty);
        expect(soru.secenekler.keys.toList(), equals(['A', 'B', 'C', 'D', 'E']));
        expect(soru.secenekler.values.toSet().length, 5, reason: '${soru.id} şıkları birbirinden farklı olmalı');
        expect(soru.secenekler.containsKey(soru.dogruSecenek), isTrue, reason: soru.id);
      }
      for (final ders in ['Türkçe', 'Matematik', 'Geometri', 'Fizik', 'Kimya', 'Biyoloji', 'Tarih', 'Coğrafya', 'Felsefe', 'Din Kültürü', 'Türk Dili ve Edebiyatı']) {
        expect(filtreliSorular(ders: ders).length, greaterThanOrEqualTo(10), reason: ders);
      }
      expect(filtreliSorular(ders: 'Matematik', zorluk: 'kolay').every((s) => s.ders == 'Matematik' && s.zorluk.name == 'kolay'), isTrue);
    });
  });
}
