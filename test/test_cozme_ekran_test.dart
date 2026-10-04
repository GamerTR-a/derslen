import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yks_kocu/core/constants/app_constants.dart';
import 'package:yks_kocu/core/storage/storage_service.dart';
import 'package:yks_kocu/core/theme/app_theme.dart';
import 'package:yks_kocu/core/theme/tema_verisi.dart';
import 'package:yks_kocu/presentation/providers/flashkart_provider.dart';
import 'package:yks_kocu/presentation/providers/profil_provider.dart';
import 'package:yks_kocu/presentation/providers/test_provider.dart';
import 'package:yks_kocu/presentation/screens/tabs/calis_tab.dart';
import 'package:yks_kocu/presentation/screens/test/test_coz_screen.dart';
import 'package:yks_kocu/presentation/screens/test/test_sonuc_screen.dart';

Future<ProviderContainer> _kapsayici(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360, 780) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final depo = SharedPrefsStorageService();
  late ProviderContainer c;
  await tester.runAsync(() async {
    await depo.init();
    c = ProviderContainer(overrides: [
      storageServiceProvider.overrideWithValue(depo),
      localStorageServiceProvider.overrideWithValue(depo),
    ]);
    await c
        .read(profilProvider.notifier)
        .kaydetProfil(hedefBolum: 'sayisal', gunlukSaat: 3, ogrenmeMetod: OgrenmeMetod.dengeli, sinifSeviyesi: '9. Sınıf');
    await c.read(flashkartProvider.notifier).loadStates();
    await c.read(yanlisSorularProvider.notifier).hazir;
  });
  addTearDown(c.dispose);
  return c;
}

void main() {
  for (final (ad, tema) in [('açık', AppTheme.light), ('koyu', AppTheme.dark)]) {
    testWidgets('Deneme çözülür, bitirilir ve sonuç ekranı ders kırılımını gösterir ($ad tema)', (tester) async {
      final c = await _kapsayici(tester);
      c.read(aktifTestProvider.notifier).denemeOlustur(sinif: 9, kisa: true, rastgele: Random(1));
      final soruSayisi = c.read(aktifTestProvider).sorular.length;

      final router = GoRouter(
        initialLocation: '/test-coz',
        routes: [
          GoRoute(path: '/test-coz', builder: (_, _) => const TestCozScreen()),
          GoRoute(path: '/test-sonuc', builder: (_, _) => const TestSonucScreen()),
          GoRoute(path: '/ana', builder: (_, _) => const Scaffold(body: Text('ana'))),
          GoRoute(path: '/test-olustur', builder: (_, _) => const Scaffold(body: Text('olustur'))),
        ],
      );
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp.router(theme: temaVerisi(tema), routerConfig: router),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('9. Sınıf Kısa Deneme'), findsOneWidget);
      expect(find.text('Soru 1 / $soruSayisi'), findsOneWidget);
      // Süreli deneme: kalan süre geri sayar.
      expect(c.read(aktifTestProvider).kalanSaniye, soruSayisi * denemeSoruSuresi);
      await tester.pump(const Duration(seconds: 3));
      expect(c.read(aktifTestProvider).kalanSaniye, soruSayisi * denemeSoruSuresi - 3);

      // İlk soruyu doğru işaretle, ikinciye geç.
      final dogru = c.read(aktifTestProvider).sorular.first.dogruSecenek;
      await tester.tap(find.text(dogru).first);
      await tester.pump();
      expect(c.read(aktifTestProvider).cevaplar[0], dogru);
      await tester.tap(find.byTooltip('Sonraki soru'));
      await tester.pump();
      expect(find.text('Soru 2 / $soruSayisi'), findsOneWidget);

      await tester.tap(find.text('Bitir'));
      await tester.pumpAndSettle();
      expect(find.text('Test bitirilsin mi?'), findsOneWidget);
      await tester.tap(find.text('Testi bitir'));
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();

      expect(find.text('Deneme sonucu'), findsOneWidget);
      expect(find.text('1.0 net'), findsOneWidget);
      expect(find.text('Derslere göre sonuç'), findsOneWidget);
      expect(c.read(aktifTestProvider).tamamlandi, isTrue);
      await tester.scrollUntilVisible(find.text('Cevaplar ve çözümler'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('Yalnız hatalar'), findsOneWidget);
    });

    testWidgets('Çalış sekmesi seans yokken hatasız çizilir ($ad tema)', (tester) async {
      final c = await _kapsayici(tester);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(theme: temaVerisi(tema), home: const CalisTab()),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Odaklanmaya başla'), findsOneWidget);
      expect(find.textContaining('Uygulamadan çıksan'), findsNothing);
    });
  }
}
