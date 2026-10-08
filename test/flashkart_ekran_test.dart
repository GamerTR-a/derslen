import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yks_kocu/core/constants/app_constants.dart';
import 'package:yks_kocu/core/storage/storage_service.dart';
import 'package:yks_kocu/core/theme/app_theme.dart';
import 'package:yks_kocu/core/theme/tema_verisi.dart';
import 'package:yks_kocu/presentation/providers/flashkart_provider.dart';
import 'package:yks_kocu/presentation/providers/profil_provider.dart';
import 'package:yks_kocu/presentation/screens/tabs/flashkart_tab.dart';

Future<ProviderContainer> _kapsayici(WidgetTester tester, Size boyut) async {
  tester.view.physicalSize = boyut * 3;
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
  });
  addTearDown(c.dispose);
  return c;
}

void main() {
  // Alt gezinme çubuğu düşüldükten sonra sekmeye kalan alan: küçük ve orta telefon.
  for (final boyut in [const Size(360, 520), const Size(360, 620), const Size(411, 760)]) {
    for (final (ad, tema) in [('açık', AppTheme.light), ('koyu', AppTheme.dark)]) {
      testWidgets('Kartın ön yüzü okunacak kadar büyük (${boyut.width.toInt()}x${boyut.height.toInt()}, $ad tema)', (tester) async {
        final c = await _kapsayici(tester, boyut);
        await tester.pumpWidget(UncontrolledProviderScope(
          container: c,
          child: MaterialApp(theme: temaVerisi(tema), home: const FlashkartTab()),
        ));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);

        final kart = c.read(bugunCalisilacakKartlarProvider).first;
        final onYuz = find.byKey(ValueKey('on_${kart.id}'));
        expect(onYuz, findsOneWidget);
        expect(find.text(kart.on), findsOneWidget);
        expect(tester.getSize(onYuz).height, greaterThanOrEqualTo(250));
        expect(find.text('Kart ekle'), findsOneWidget);

        // Cevap ve puanlama düğmeleri kaydırılarak her ekranda erişilebilir.
        await tester.ensureVisible(find.text('Cevabı göster'));
        await tester.pump();
        await tester.tap(find.text('Cevabı göster'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.text(kart.arka), findsOneWidget);
        expect(find.text('Kolaydı'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
