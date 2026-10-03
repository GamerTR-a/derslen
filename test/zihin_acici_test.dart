import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yks_kocu/core/storage/storage_service.dart';
import 'package:yks_kocu/core/theme/app_theme.dart';
import 'package:yks_kocu/core/theme/tema_verisi.dart';
import 'package:yks_kocu/presentation/providers/profil_provider.dart';
import 'package:yks_kocu/presentation/screens/bahce/mini_oyunlar_screen.dart';
import 'package:yks_kocu/presentation/screens/bahce/oyunlar/dikkat_oyunlari.dart';
import 'package:yks_kocu/presentation/screens/bahce/oyunlar/hafiza_oyunlari.dart';
import 'package:yks_kocu/presentation/screens/bahce/oyunlar/mantik_oyunlari.dart';

Future<Widget> _sarmala(WidgetTester tester, Widget sayfa, AppTheme tema) async {
  SharedPreferences.setMockInitialValues({});
  final depo = SharedPrefsStorageService();
  await tester.runAsync(depo.init);
  return ProviderScope(
    overrides: [localStorageServiceProvider.overrideWithValue(depo)],
    child: MaterialApp(theme: temaVerisi(tema), home: sayfa),
  );
}

Future<void> _telefon(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360, 780) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  final oyunlar = <String, Widget Function()>{
    'Kart Eşleştirme': () => const KartEslestirme(),
    'Işık Sırası': () => const IsikSirasi(),
    'Kare Hafızası': () => const KareHafizasi(),
    '2-Geri': () => const IkiGeri(),
    'Schulte Tablosu': () => const SchulteTablosu(),
    'Farklı Rengi Bul': () => const FarkliRenk(),
    'Ok Yönü': () => const OkYonu(),
    'Örüntü Bul': () => const OruntuBul(),
    'Hangisi Büyük?': () => const HangisiBuyuk(),
    'Eş / Zıt Anlam': () => const EsZitAnlam(),
  };

  for (final (temaAdi, tema) in [('açık', AppTheme.light), ('koyu', AppTheme.dark)]) {
    testWidgets('Zihin Açıcı menüsü tüm oyunları listeler ($temaAdi)', (tester) async {
      await _telefon(tester);
      await tester.pumpWidget(await _sarmala(tester, const MiniOyunlarScreen(), tema));
      await tester.pump();
      expect(find.text('Tümü (13)'), findsOneWidget);
      await tester.ensureVisible(find.text('Dikkat'));
      await tester.pump();
      await tester.tap(find.text('Dikkat'));
      await tester.pump();
      expect(find.text('Schulte Tablosu'), findsOneWidget);
      expect(find.text('Kart Eşleştirme'), findsNothing);
    });

    for (final e in oyunlar.entries) {
      testWidgets('${e.key} oynanır ve hatasız biter ($temaAdi)', (tester) async {
        await _telefon(tester);
        await tester.pumpWidget(await _sarmala(tester, e.value(), tema));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text(e.key), findsOneWidget);

        // Rastgele dokunuşlar: oyun alanındaki ilk birkaç dokunulabilir öğe.
        for (var tur = 0; tur < 6; tur++) {
          final hedefler = find.descendant(of: find.byType(Scaffold), matching: find.byWidgetPredicate((w) => w is GestureDetector || w is ButtonStyleButton));
          final adet = hedefler.evaluate().length;
          if (adet > 0) {
            await tester.tap(hedefler.at(tur % adet), warnIfMissed: false);
          }
          await tester.pump(const Duration(milliseconds: 900));
        }
        // Süreli oyunların bitmesi için zamanı ilerlet.
        for (var i = 0; i < 100; i++) {
          await tester.pump(const Duration(seconds: 1));
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 10));
      });
    }
  }
}
