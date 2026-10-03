import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yks_kocu/core/algorithms/analiz_motoru.dart';
import 'package:yks_kocu/core/constants/app_constants.dart';
import 'package:yks_kocu/core/constants/yks_data.dart';
import 'package:yks_kocu/core/storage/storage_provider.dart';
import 'package:yks_kocu/core/storage/storage_service.dart';
import 'package:yks_kocu/core/theme/app_theme.dart';
import 'package:yks_kocu/core/theme/tema_verisi.dart';
import 'package:yks_kocu/core/utils/tarih.dart';
import 'package:yks_kocu/data/models/net_kaydi.dart';
import 'package:yks_kocu/data/models/ogrenci_profil.dart';
import 'package:yks_kocu/presentation/providers/analiz_provider.dart';
import 'package:yks_kocu/presentation/screens/analiz/analiz_screen.dart';
import 'package:yks_kocu/presentation/screens/program/ders_programi_screen.dart';

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

void main() {
  for (final (ad, tema) in [('açık', AppTheme.light), ('koyu', AppTheme.dark)]) {
    testWidgets('Gelişim Analizi ekranı telefonda hatasız çizilir ($ad tema)', (tester) async {
      await _telefonBoyutu(tester);
      await tester.pumpWidget(ProviderScope(
        overrides: [analizGirdisiProvider.overrideWith((ref) async => _ornekGirdi())],
        child: MaterialApp(theme: temaVerisi(tema), home: const AnalizScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Gelişim Analizi'), findsOneWidget);
      expect(find.text('Toplam çalışma'), findsOneWidget);

      // Aşağı kaydırarak tüm kartları çizdir.
      for (var i = 0; i < 12; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -500));
        await tester.pumpAndSettle();
      }
      expect(find.text('Çalışma takvimi'), findsOneWidget);

      // Dönem değiştirme (3 ay → haftalık toplamlar).
      await tester.drag(find.byType(ListView).first, const Offset(0, 20000));
      await tester.pumpAndSettle();
      await tester.tap(find.text('3 ay'));
      await tester.pumpAndSettle();
    });

    testWidgets('Ders Programım ekranı programı üretip gösterir ($ad tema)', (tester) async {
      await _telefonBoyutu(tester);
      SharedPreferences.setMockInitialValues({});
      final depo = SharedPrefsStorageService();
      await tester.runAsync(() async {
        await depo.init();
        await depo.setMap('ogrenci_profil_data', _profil.toJson());
      });

      await tester.pumpWidget(ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(depo)],
        child: MaterialApp(theme: temaVerisi(tema), home: const DersProgramiScreen()),
      ));
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('Ders Programım'), findsOneWidget);
      expect(find.textContaining('Bu hafta'), findsWidgets);

      // Pazar'a geç: deneme sınavı bloğu programın başında olmalı.
      await tester.tap(find.text('Paz').first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Deneme Sınavı'), findsOneWidget);

      final liste = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('Haftalık tablo'), 300, scrollable: liste);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.scrollUntilVisible(find.text('Pazar deneme sınavı'), 300, scrollable: liste);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Program ayarları'), findsOneWidget);
    });
  }
}
