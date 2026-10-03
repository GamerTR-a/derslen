import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yks_kocu/core/constants/app_constants.dart';
import 'package:yks_kocu/core/storage/storage_service.dart';
import 'package:yks_kocu/core/theme/app_theme.dart';
import 'package:yks_kocu/core/theme/tema_verisi.dart';
import 'package:yks_kocu/presentation/providers/konu_provider.dart';
import 'package:yks_kocu/presentation/providers/mufredat_provider.dart';
import 'package:yks_kocu/presentation/providers/profil_provider.dart';
import 'package:yks_kocu/presentation/screens/mufredat/mufredat_screen.dart';
import 'package:yks_kocu/presentation/screens/onboarding_flow/onboarding_screen.dart';
import 'package:yks_kocu/presentation/screens/tabs/konu_takibi_tab.dart';
import 'package:yks_kocu/presentation/widgets/deneme_ekle_dialog.dart';

Future<ProviderContainer> _kapsayici(WidgetTester tester, String alan) async {
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
    await c.read(profilProvider.notifier).kaydetProfil(hedefBolum: alan, gunlukSaat: 3, ogrenmeMetod: OgrenmeMetod.dengeli);
    await c.read(konuProvider.notifier).hazir;
    if (alan == 'serbest') await c.read(mufredatProvider.notifier).dersEkle('Anatomi', ['Kemikler', 'Kaslar']);
  });
  addTearDown(c.dispose);
  return c;
}

Widget _uyg(ProviderContainer c, Widget ev, AppTheme tema) =>
    UncontrolledProviderScope(container: c, child: MaterialApp(theme: temaVerisi(tema), home: ev));

void main() {
  for (final (ad, tema) in [('açık', AppTheme.light), ('koyu', AppTheme.dark)]) {
    testWidgets('Müfredatım ekranı serbest modda dersleri gösterir ($ad)', (tester) async {
      final c = await _kapsayici(tester, 'serbest');
      await tester.pumpWidget(_uyg(c, const MufredatScreen(), tema));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Anatomi'), findsOneWidget);
      expect(find.text('Hedef sınav ekle'), findsOneWidget);
      expect(find.text('Hazır YKS dersleri'), findsNothing);
      await tester.tap(find.text('Anatomi'));
      await tester.pumpAndSettle();
      expect(find.text('Kemikler'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Müfredatım ekranı YKS alanında hazır dersleri listeler ($ad)', (tester) async {
      final c = await _kapsayici(tester, 'sayisal');
      await tester.pumpWidget(_uyg(c, const MufredatScreen(), tema));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Hazır YKS dersleri'), findsOneWidget);
      expect(find.text('TYT Türkçe'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Konu takibi ve sınav sonucu penceresi serbest modda çalışır ($ad)', (tester) async {
      final c = await _kapsayici(tester, 'serbest');
      await tester.pumpWidget(_uyg(c, const Scaffold(body: KonuTakibiTab()), tema));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Kemikler'), findsOneWidget);
      expect(find.text('TYT'), findsNothing);

      await tester.pumpWidget(_uyg(c, const Scaffold(body: DenemeEkleDialog()), tema));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Sınav Sonucu Ekle'), findsOneWidget);
      expect(find.text('Anatomi'), findsOneWidget);
      expect(find.text('Puan'), findsOneWidget);
    });
  }

  testWidgets('Onboarding: serbest seçilince ders eklemeden ilerlenemez', (tester) async {
    final c = await _kapsayici(tester, 'sayisal');
    await tester.pumpWidget(_uyg(c, const OnboardingScreen(), AppTheme.light));
    await tester.pump();
    await tester.ensureVisible(find.text('Üniversite / Serbest'));
    await tester.tap(find.text('Üniversite / Serbest'));
    await tester.pump();
    expect(find.text('Derslerin'), findsOneWidget);
    await tester.tap(find.text('Devam Et'));
    await tester.pump();
    expect(find.text('Devam etmek için en az bir ders ekle.'), findsOneWidget);
    await tester.ensureVisible(find.widgetWithText(TextField, 'Örn: Anatomi, Lineer Cebir'));
    await tester.enterText(find.widgetWithText(TextField, 'Örn: Anatomi, Lineer Cebir'), 'Fizyoloji, Histoloji');
    await tester.tap(find.text('Devam Et'));
    await tester.pump();
    expect(find.text('Sınıfın ve Rutinin'), findsOneWidget);
  });
}
