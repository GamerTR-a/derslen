import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yks_kocu/core/algorithms/analiz_motoru.dart';
import 'package:yks_kocu/core/algorithms/asistan_motoru.dart';
import 'package:yks_kocu/core/algorithms/ders_programi.dart';
import 'package:yks_kocu/core/constants/app_constants.dart';
import 'package:yks_kocu/core/constants/yks_data.dart';
import 'package:yks_kocu/core/storage/storage_provider.dart';
import 'package:yks_kocu/core/storage/storage_service.dart';
import 'package:yks_kocu/core/theme/app_theme.dart';
import 'package:yks_kocu/core/theme/tema_verisi.dart';
import 'package:yks_kocu/core/utils/tarih.dart';
import 'package:yks_kocu/data/models/net_kaydi.dart';
import 'package:yks_kocu/data/models/ogrenci_profil.dart';
import 'package:yks_kocu/presentation/widgets/asistan_sohbet_sheet.dart';

const _profil = OgrenciProfil(
  hedefBolum: 'sayisal',
  gunlukSaat: 3,
  ogrenmeMetod: OgrenmeMetod.dengeli,
  onboardingTamamlandi: true,
);

NetKaydi _kayit(String id, String ders, int d, int y, int b, String deneme, DateTime t) => NetKaydi(
      id: id,
      tarih: gunAnahtari(t),
      alan: SinavAlani.TYT,
      ders: ders,
      dogru: d,
      yanlis: y,
      bos: b,
      denemeAdi: deneme,
      createdAt: t,
    );

void main() {
  final simdi = DateTime.now();
  final netler = [
    _kayit('a1', 'Türkçe', 28, 6, 6, 'Deneme 1', simdi.subtract(const Duration(days: 10))),
    _kayit('a2', 'Matematik', 12, 8, 20, 'Deneme 1', simdi.subtract(const Duration(days: 10))),
    _kayit('b1', 'Türkçe', 31, 5, 4, 'Deneme 2', simdi.subtract(const Duration(days: 3))),
    _kayit('b2', 'Matematik', 9, 12, 19, 'Deneme 2', simdi.subtract(const Duration(days: 3))),
  ];

  group('Niyet tanıma', () {
    test('Türkçe büyük harf ve ekler doğru eşlenir', () {
      expect(niyetBul('SON DENEMEMİ ANALİZ ET'), AsistanNiyet.denemeAnalizi);
      expect(niyetBul('Netlerim neden düştü?'), AsistanNiyet.denemeAnalizi);
      expect(niyetBul('Programımı düzenler misin'), AsistanNiyet.programIyilestir);
      expect(niyetBul('bana bir ders programı hazırla'), AsistanNiyet.programIyilestir);
      expect(niyetBul('Hangi derse ağırlık vermeliyim'), AsistanNiyet.zayifDersler);
      expect(niyetBul('Bugün ne çalışacağım, programım nasıl?'), AsistanNiyet.programIncele);
      expect(niyetBul('Bu hafta ne kadar çalıştım'), AsistanNiyet.haftaOzeti);
      expect(niyetBul('Çok bunaldım'), AsistanNiyet.motivasyon);
      expect(niyetBul('merhaba'), AsistanNiyet.yardim);
    });
  });

  group('Deneme analizi', () {
    test('Kayıt yoksa deneme eklemeye yönlendirir', () {
      final y = denemeAnaliziYaniti(const []);
      expect(y.aksiyonlar.single.rota, '/netler');
    });

    test('Net değişimi, güçlü/zayıf ders ve yanlış kaybı çıkarılır', () {
      final y = denemeAnaliziYaniti(netler);
      // Deneme 2: Türkçe 29.75 + Matematik 6 = 35.75; Deneme 1: 26.5 + 10 = 36.5 → -0.75
      expect(y.metin, contains('Deneme 2'));
      expect(y.metin, contains('-0.8'));
      expect(y.maddeler.any((m) => m.startsWith('En güçlü dersin Türkçe')), isTrue);
      expect(y.maddeler.any((m) => m.contains('Matematik') && m.contains('öncelik')), isTrue);
      expect(y.aksiyonlar.any((a) => a.niyet == AsistanNiyet.programIyilestir), isTrue);
    });
  });

  group('Program önerisi', () {
    final ayar = DersProgramiAyar.varsayilan(_profil).copyWith(pazarDeneme: false);

    test('Plan uyumu düşükse süreleri azaltır, zayıf dersi önceliklendirir, deneme ekler', () {
      final girdi = AnalizGirdisi(
        profil: _profil,
        bugun: simdi,
        konular: tumKonular,
        netler: netler,
        planUyum: {
          for (var i = 0; i < 5; i++) gunAnahtari(simdi.subtract(Duration(days: i))): [4, 1, 100, 25],
        },
      );
      final o = programOnerisi(
        profil: _profil,
        ayar: ayar,
        analiz: donemAnalizi(girdi, 30),
        netler: netler,
        konular: tumKonular,
      );
      expect(o.degisti, isTrue);
      expect(o.yeniAyar.gunler[0].sureDk, lessThan(ayar.gunler[0].sureDk));
      expect(o.yeniAyar.gunler[0].sureDk % 15, 0);
      expect(o.yeniAyar.oncelikliDersler.first, 'Matematik');
      // Son 30 günde 2 deneme var; Pazar denemesi yalnızca 2'nin altında eklenir.
      expect(o.yeniAyar.pazarDeneme, isFalse);

      final yanit = programOnerisiYaniti(o);
      expect(yanit.aksiyonlar.first.programAyari, isNotNull);
    });

    test('Bulut bağlamı kimlik bilgisi içermez ve JSON olarak kodlanır', () {
      final girdi = AnalizGirdisi(profil: _profil, bugun: simdi, konular: tumKonular, netler: netler);
      final baglam = asistanBaglami(
        profil: _profil.copyWith(hedefUniversite: 'Gizli Üniversite'),
        analiz30: donemAnalizi(girdi, 30),
        netler: netler,
        konular: tumKonular,
        ayar: ayar,
        hafta: haftalikProgramOlustur(profil: _profil, konular: tumKonular, ayar: ayar, haftaBaslangic: haftaBaslangici(simdi)),
        bugun: const [],
      );
      final metin = jsonEncode(baglam);
      expect(metin, isNot(contains('Gizli Üniversite')));
      expect(metin, contains('Deneme 2'));
      expect((baglam['denemeler'] as List).length, 2);
    });
  });

  testWidgets('Sohbet paneli hızlı soruyla cihaz içi deneme analizini gösterir', (tester) async {
    tester.view.physicalSize = const Size(360, 780) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final depo = SharedPrefsStorageService();
    await tester.runAsync(() async {
      await depo.init();
      await depo.setMap('ogrenci_profil_data', _profil.toJson());
      await depo.setMap('net_kayitlari_listesi', {'items': [for (final n in netler) n.toJson()]});
    });

    await tester.pumpWidget(ProviderScope(
      overrides: [storageServiceProvider.overrideWithValue(depo)],
      child: MaterialApp(
        theme: temaVerisi(AppTheme.light),
        home: const Scaffold(body: AsistanSohbetSheet()),
      ),
    ));
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 50));
    }

    await tester.tap(find.text('Son denememi analiz et'));
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(
      find.byWidgetPredicate((w) => w is SelectableText && (w.data ?? '').contains('Deneme 2 (TYT)')),
      findsOneWidget,
    );
    expect(find.text('Programımı buna göre iyileştir'), findsOneWidget);
    expect(find.text('Cihaz içi analiz'), findsWidgets);
  });
}
