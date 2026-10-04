import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yks_kocu/core/algorithms/analiz_motoru.dart';
import 'package:yks_kocu/core/constants/app_constants.dart';
import 'package:yks_kocu/core/constants/yks_data.dart';
import 'package:yks_kocu/core/storage/storage_service.dart';
import 'package:yks_kocu/core/theme/app_theme.dart';
import 'package:yks_kocu/core/theme/tema_verisi.dart';
import 'package:yks_kocu/core/utils/tarih.dart';
import 'package:yks_kocu/data/models/net_kaydi.dart';
import 'package:yks_kocu/data/models/ogrenci_profil.dart';
import 'package:yks_kocu/presentation/providers/analiz_provider.dart';
import 'package:yks_kocu/presentation/providers/profil_provider.dart';
import 'package:yks_kocu/presentation/providers/test_provider.dart';
import 'package:yks_kocu/presentation/screens/analiz/analiz_screen.dart';
import 'package:yks_kocu/presentation/screens/program/ders_programi_screen.dart';
import 'package:yks_kocu/presentation/screens/program/program_duzenleme.dart';
import 'package:yks_kocu/presentation/screens/tabs/konu_takibi_tab.dart';
import 'package:yks_kocu/presentation/screens/test/test_olustur_screen.dart';

const _profil = OgrenciProfil(
  hedefBolum: 'sayisal',
  gunlukSaat: 3,
  ogrenmeMetod: OgrenmeMetod.dengeli,
  onboardingTamamlandi: true,
);

AnalizGirdisi _ornekGirdi() {
  final bugun = DateTime.now();
  String g(int i) => gunAnahtari(bugun.subtract(Duration(days: i)));
  return AnalizGirdisi(
    profil: _profil,
    bugun: bugun,
    konular: [for (final k in tumKonular) k.id.endsWith('-1') ? k.copyWith(tamamlandi: true) : k],
    calismaGunluk: {for (var i = 0; i < 40; i++) g(i): (i * 37) % 200},
    calismaDers: {
      g(0): {'Matematik': 60, 'Fizik': 30},
      g(1): {'Türkçe': 45},
    },
    planUyum: {g(0): [4, 3, 100, 75], g(1): [4, 1, 100, 25]},
    checkinLog: {g(0): [4, 3, 2], g(2): [2, 2, 4]},
    konuLog: {g(5): [3, 1], g(0): [7, 2]},
    testler: [TestKaydi(tarih: g(1), ders: 'Matematik', dogru: 6, yanlis: 3, bos: 1)],
    netler: [
      for (var i = 0; i < 5; i++)
        NetKaydi(
          id: 't$i',
          tarih: g(30 - i * 5),
          alan: SinavAlani.TYT,
          ders: 'Türkçe',
          dogru: 20 + i * 2,
          yanlis: 4,
          denemeAdi: 'Deneme $i',
          createdAt: bugun.subtract(Duration(days: 30 - i * 5)),
        ),
    ],
  );
}

Future<void> _telefonBoyutu(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360, 780) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Profil kayıtlı bir depo ile uygulama kapsayıcısı.
Future<SharedPrefsStorageService> _depo(WidgetTester tester, {String? sinif}) async {
  SharedPreferences.setMockInitialValues({});
  final depo = SharedPrefsStorageService();
  await tester.runAsync(() async {
    await depo.init();
    await depo.setMap('ogrenci_profil_data', _profil.copyWith(sinifSeviyesi: sinif).toJson());
  });
  return depo;
}

Future<void> _bekle(WidgetTester tester, [int tur = 10]) async {
  for (var i = 0; i < tur; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _sekme(WidgetTester tester, String ad) async {
  await tester.tap(find.widgetWithText(Tab, ad));
  await tester.pumpAndSettle();
}

void main() {
  for (final (ad, tema) in [('açık', AppTheme.light), ('koyu', AppTheme.dark)]) {
    testWidgets('Gelişim Analizi üç sekmede hatasız çizilir ($ad tema)', (tester) async {
      await _telefonBoyutu(tester);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          analizGirdisiProvider.overrideWith((ref) async => _ornekGirdi()),
          denemeGecmisiProvider.overrideWith(
            (ref) async => const [DenemeKaydi(tarih: '2026-10-01', baslik: '9. Sınıf Genel Deneme', sinif: 9, dogru: 30, yanlis: 8, bos: 7)],
          ),
        ],
        child: MaterialApp(theme: temaVerisi(tema), home: const AnalizScreen()),
      ));
      await tester.pumpAndSettle();

      // Özet: dört gösterge ve çalışma süresi.
      expect(find.text('Gelişim Analizi'), findsOneWidget);
      expect(find.text('Toplam çalışma'), findsOneWidget);
      expect(find.text('Plan uyumu'), findsOneWidget);
      expect(find.text('Konu tamamlama'), findsOneWidget);
      expect(find.text('Test doğruluğu'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Çalışma süresi'), 300, scrollable: find.byType(Scrollable).last);

      await _sekme(tester, 'Çalışma');
      expect(find.text('Derslere göre dağılım'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Enerji, odak ve stres'), 300, scrollable: find.byType(Scrollable).last);
      await tester.pumpAndSettle();

      await _sekme(tester, 'Başarı');
      expect(find.text('Konu ilerlemesi'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Uygulama içi denemeler'), 300, scrollable: find.byType(Scrollable).last);
      await tester.pumpAndSettle();
      expect(find.text('9. Sınıf Genel Deneme'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Ders bazında net tablosu'), 300, scrollable: find.byType(Scrollable).last);
      await tester.pumpAndSettle();

      // Dönem değiştirme (3 ay → haftalık toplamlar).
      await tester.tap(find.text('3 ay'));
      await tester.pumpAndSettle();
      await _sekme(tester, 'Özet');
      expect(find.text('Toplam çalışma'), findsOneWidget);
    });

    testWidgets('Ders Programım: Günlük, Haftalık ve Kişiselleştir sekmeleri ($ad tema)', (tester) async {
      await _telefonBoyutu(tester);
      final depo = await _depo(tester);
      await tester.pumpWidget(ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(depo), localStorageServiceProvider.overrideWithValue(depo)],
        child: MaterialApp(theme: temaVerisi(tema), home: const DersProgramiScreen()),
      ));
      await _bekle(tester);

      expect(find.text('Ders Programım'), findsOneWidget);
      expect(find.textContaining('Bu hafta'), findsWidgets);

      // Pazar'a geç: deneme sınavı bloğu programın başında olmalı.
      await tester.tap(find.text('Paz').first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Deneme Sınavı'), findsOneWidget);
      expect(find.text('Blok ekle'), findsOneWidget);

      await _sekme(tester, 'Haftalık');
      expect(find.text('Haftalık tablo'), findsOneWidget);
      expect(find.text('Bu haftanın ders dağılımı'), findsOneWidget);

      await _sekme(tester, 'Kişiselleştir');
      expect(find.text('1 · Programın nasıl hazırlansın?'), findsOneWidget);
      expect(find.text('Ders ders, konu konu seç'), findsOneWidget);
      final liste = find.byType(Scrollable).last;
      await tester.scrollUntilVisible(find.text('Pazar deneme sınavı'), 300, scrollable: liste);
      await tester.pump(const Duration(milliseconds: 100));

      // Bir gün kapatılınca kaydet çubuğu çıkar.
      await tester.drag(liste, const Offset(0, 400));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(Switch).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Kaydet ve programı güncelle'), findsOneWidget);
    });

    testWidgets('Programa elle blok eklenir ve konu seçim ekranı açılır ($ad tema)', (tester) async {
      await _telefonBoyutu(tester);
      final depo = await _depo(tester, sinif: '9. Sınıf');
      await tester.pumpWidget(ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(depo), localStorageServiceProvider.overrideWithValue(depo)],
        child: MaterialApp(theme: temaVerisi(tema), home: const DersProgramiScreen()),
      ));
      await _bekle(tester);

      await tester.tap(find.text('Paz').first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('9. Sınıf Genel Denemesi'), findsOneWidget);
      await tester.ensureVisible(find.text('Blok ekle'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Blok ekle'));
      await tester.pumpAndSettle();
      expect(find.textContaining('blok ekle'), findsOneWidget);
      expect(find.text('Programa ekle'), findsOneWidget);

      // Mola seçilince ders zorunlu olmaz; blok eklenir.
      await tester.tap(find.text('Mola'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('10 dk'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Programa ekle'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Programa ekle'));
      await _bekle(tester, 6);
      expect(find.textContaining('Uzun mola · 10 dk'), findsWidgets);

      // Konu seçim ekranı: dersler listelenir, seçim sayısı düğmede görünür.
      await tester.pumpWidget(ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(depo), localStorageServiceProvider.overrideWithValue(depo)],
        child: MaterialApp(theme: temaVerisi(tema), home: const KonuSecimSayfasi(seciliIdler: ['s9-mat-05', 's9-fiz-07'])),
      ));
      await _bekle(tester);
      expect(find.text('Konularını seç'), findsOneWidget);
      expect(find.text('2 konuyla programı hazırla'), findsOneWidget);
      expect(find.text('Matematik'), findsOneWidget);
      await tester.tap(find.text('Fizik'));
      await tester.pumpAndSettle();
      expect(find.text('Katı ve Sıvı Basıncı'), findsOneWidget);
      await tester.ensureVisible(find.text('Bernoulli İlkesi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bernoulli İlkesi'));
      await tester.pumpAndSettle();
      expect(find.text('3 konuyla programı hazırla'), findsOneWidget);
    });

    testWidgets('Test ve Deneme ekranı sınıfa göre açılır ($ad tema)', (tester) async {
      await _telefonBoyutu(tester);
      final depo = await _depo(tester, sinif: '10. Sınıf');
      late ProviderContainer c;
      await tester.runAsync(() async {
        c = ProviderContainer(overrides: [storageServiceProvider.overrideWithValue(depo), localStorageServiceProvider.overrideWithValue(depo)]);
        c.read(profilProvider);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      addTearDown(c.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(theme: temaVerisi(tema), home: const TestOlusturScreen()),
      ));
      await _bekle(tester, 4);

      expect(find.text('Test ve Deneme'), findsOneWidget);
      expect(c.read(testFiltreProvider).sinif, 10);
      expect(find.textContaining('10. sınıf müfredatından'), findsOneWidget);
      expect(find.text('Testi başlat'), findsOneWidget);

      await tester.tap(find.text('Deneme'));
      await tester.pumpAndSettle();
      expect(find.text('Genel deneme'), findsOneWidget);
      expect(find.text('Kısa deneme'), findsOneWidget);
      expect(find.text('Ders denemesi'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Son denemelerin'), 300, scrollable: find.byType(Scrollable).first);

      await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Yanlışlarım'));
      await tester.pumpAndSettle();
      expect(find.text('Yanlışlarımın tekrarı'), findsOneWidget);

      // Tüm havuza geçilince alt başlık filtresi de kullanılabilir.
      await tester.tap(find.text('Konu testi'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).at(1), const Offset(-400, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tüm havuz (YKS)'));
      await tester.pumpAndSettle();
      expect(c.read(testFiltreProvider).sinif, isNull);
      expect(find.textContaining('Tüm soru havuzundan'), findsOneWidget);
    });

    testWidgets('Konularım ekranı 9. sınıfta Maarif konularını ve konu testi düğmesini gösterir ($ad tema)', (tester) async {
      await _telefonBoyutu(tester);
      final depo = await _depo(tester, sinif: '9. Sınıf');
      await tester.pumpWidget(ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(depo), localStorageServiceProvider.overrideWithValue(depo)],
        child: MaterialApp(theme: temaVerisi(tema), home: const Scaffold(body: KonuTakibiTab())),
      ));
      await _bekle(tester);

      expect(find.text('Konularım'), findsOneWidget);
      expect(find.text('TYT'), findsNothing);
      expect(find.text('Üslü ve Köklü Gösterimler'), findsOneWidget);
      expect(find.byTooltip('Bu konudan test çöz'), findsWidgets);
      expect(find.textContaining('9. sınıf denemesi'), findsOneWidget);
    });
  }
}
