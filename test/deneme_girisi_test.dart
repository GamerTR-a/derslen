import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yks_kocu/core/algorithms/analiz_motoru.dart';
import 'package:yks_kocu/core/constants/app_constants.dart';
import 'package:yks_kocu/core/storage/storage_provider.dart';
import 'package:yks_kocu/core/storage/storage_service.dart';
import 'package:yks_kocu/core/theme/app_theme.dart';
import 'package:yks_kocu/core/theme/tema_verisi.dart';
import 'package:yks_kocu/presentation/providers/net_provider.dart';
import 'package:yks_kocu/presentation/widgets/deneme_ekle_dialog.dart';

void main() {
  testWidgets('Tüm dersler tek formda girilir ve tek deneme olarak kaydedilir', (tester) async {
    tester.view.physicalSize = const Size(360, 780) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final depo = SharedPrefsStorageService();
    await tester.runAsync(depo.init);
    final kapsayici = ProviderContainer(overrides: [storageServiceProvider.overrideWithValue(depo)]);
    addTearDown(kapsayici.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: kapsayici,
      child: MaterialApp(
        theme: temaVerisi(AppTheme.light),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showDialog(context: context, builder: (_) => const DenemeEkleDialog()),
                child: const Text('aç'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();

    // Sıra: Türkçe D/Y, Sosyal D/Y, Matematik D/Y, Fen D/Y (+ deneme adı alanı en başta).
    final alanlar = find.byType(TextField);
    await tester.enterText(alanlar.at(1), '30'); // Türkçe doğru
    await tester.enterText(alanlar.at(2), '8'); // Türkçe yanlış
    await tester.enterText(alanlar.at(5), '25'); // Matematik doğru
    await tester.enterText(alanlar.at(6), '4'); // Matematik yanlış
    await tester.pump();
    // 30 − 2 + 25 − 1 = 52 net
    expect(find.text('52.00'), findsOneWidget);

    // Soru sayısını aşan giriş uyarı verir.
    await tester.enterText(alanlar.at(3), '25'); // Sosyal (20 soru)
    await tester.pump();
    expect(find.text('En fazla 20 soru'), findsOneWidget);
    await tester.enterText(alanlar.at(3), '');
    await tester.pump();

    await tester.ensureVisible(find.text('Denemeyi Kaydet'));
    await tester.tap(find.text('Denemeyi Kaydet'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    final kayitlar = kapsayici.read(netProvider);
    expect(kayitlar.length, 2);
    expect(kayitlar.map((k) => k.denemeAdi).toSet().length, 1, reason: 'Aynı denemenin dersleri aynı adı taşımalı');
    final turkce = kayitlar.firstWhere((k) => k.ders == 'Türkçe');
    expect(turkce.bos, 2); // 40 − 30 − 8

    final gruplar = kapsayici.read(denemeGruplariProvider);
    expect(gruplar.length, 1);
    expect(gruplar.first.toplamNet, 52);

    // Analizde tek deneme noktası olarak görünür.
    final noktalar = denemeNoktalari(kayitlar, SinavAlani.TYT);
    expect(noktalar.length, 1);
    expect(noktalar.first.net, 52);
  });
}
