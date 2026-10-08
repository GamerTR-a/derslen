import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yks_kocu/core/constants/bahce_data.dart';
import 'package:yks_kocu/core/constants/bahce_iklim.dart';
import 'package:yks_kocu/core/storage/storage_service.dart';
import 'package:yks_kocu/core/theme/app_theme.dart';
import 'package:yks_kocu/core/theme/tema_verisi.dart';
import 'package:yks_kocu/presentation/providers/bahce_provider.dart';
import 'package:yks_kocu/core/storage/storage_provider.dart';
import 'package:yks_kocu/presentation/screens/bahce/orman_bolumu.dart';
import 'package:yks_kocu/presentation/screens/tabs/bahce_tab.dart';

String _gun(DateTime t) =>
    '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

Future<ProviderContainer> _kapsayici(Map<String, dynamic> bahce) async {
  SharedPreferences.setMockInitialValues({});
  final depo = SharedPrefsStorageService();
  await depo.init();
  await depo.setMap('bahce_durumu', bahce);
  final c = ProviderContainer(overrides: [
    storageServiceProvider.overrideWithValue(depo),

  ]);
  addTearDown(c.dispose);
  c.read(bahceProvider);
  // Yükleme bitene kadar bekle (iklimSec yüklemeyi bekler; geçersiz bölge değişiklik yapmaz).
  await c.read(bahceProvider.notifier).iklimSec('gecersiz');
  return c;
}

/// ORMAN_GORSEL ortam değişkeni verilirse ekran görüntüsünü o klasöre yazar.
Future<void> _goruntuKaydet(WidgetTester tester, String ad) async {
  final klasor = Platform.environment['ORMAN_GORSEL'];
  if (klasor == null) return;
  final sinir = tester.renderObject<RenderRepaintBoundary>(find.byType(RepaintBoundary).first);
  await tester.runAsync(() async {
    final ui.Image resim = await sinir.toImage(pixelRatio: 2);
    final veri = await resim.toByteData(format: ui.ImageByteFormat.png);
    File('$klasor/$ad.png').writeAsBytesSync(veri!.buffer.asUint8List());
  });
}

void main() {
  group('İklim kataloğu', () {
    test('kimlikler benzersiz, sevilen bitkiler katalogda var', () {
      expect(iklimBolgeleri.map((b) => b.id).toSet().length, iklimBolgeleri.length);
      expect(iklimBolgeleri.any((b) => b.id == varsayilanIklim), isTrue);
      final tohumlar = bahceUrunleri.where((u) => u.tip == BahceUrunTip.tohum).map((u) => u.id).toSet();
      for (final b in iklimBolgeleri) {
        expect(b.sevenler, isNotEmpty, reason: b.id);
        expect(tohumlar.containsAll(b.sevenler), isTrue, reason: b.id);
      }
      // Her tohumun rahat ettiği en az bir bölge var.
      for (final t in tohumlar) {
        expect(iklimBolgeleri.any((b) => b.sevenler.contains(t)), isTrue, reason: t);
      }
    });

    test('yerli türler ve orman seviyesi bitki sayısına göre artar', () {
      expect(yerliTurSayisi(2), 0);
      expect(yerliTurSayisi(3), 1);
      expect(yerliTurSayisi(100), maksYerliTur);
      expect(ormanSeviyesi(0), 'Boş arazi');
      expect(ormanSeviyesi(4), 'Koru');
      expect(ormanSeviyesi(12), 'Olgun orman');
      final bolge = iklimBul('akdeniz');
      expect(ormanGorunumu(bolge, List.filled(7, 'seed_cam')).where((id) => id == bolge.yerliTurId).length, 2);
    });
  });

  group('Bölgelere göre orman', () {
    test('eski sürümdeki düz orman listesi varsayılan bölgeye taşınır', () {
      final s = BahceState.fromJson({'orman': ['seed_kiraz', 'seed_cam']});
      expect(s.iklim, varsayilanIklim);
      expect(s.aktifOrman, ['seed_kiraz', 'seed_cam']);
      expect(BahceState.fromJson({'iklim': 'yok_boyle_bolge'}).iklim, varsayilanIklim);
      // Eski sürümler için düz liste de yazılmaya devam eder.
      expect(s.toJson()['orman'], ['seed_kiraz', 'seed_cam']);
    });

    test('hasat seçili bölgenin ormanına gider, diğer bölgeler korunur', () async {
      final c = await _kapsayici({
        'saksilar': [
          {'bitkiId': 'seed_cam', 'buyume': 9},
          {'bitkiId': 'seed_kaktus', 'buyume': 9},
        ],
        'orman': ['seed_lale'],
      });
      final n = c.read(bahceProvider.notifier);
      await n.iklimSec('tayga');
      await n.hasatEt(0);
      await n.iklimSec('col');
      await n.hasatEt(1);
      await n.iklimSec('gecersiz');
      final s = c.read(bahceProvider);
      expect(s.iklim, 'col');
      expect(s.bolgeOrmani(varsayilanIklim), ['seed_lale']);
      expect(s.bolgeOrmani('tayga'), ['seed_cam']);
      expect(s.aktifOrman, ['seed_kaktus']);
      expect(s.orman.length, 3);

      // Kalıcı: yeniden yüklenince aynı durum.
      final geri = BahceState.fromJson(s.toJson());
      expect(geri.iklim, 'col');
      expect(geri.bolgeOrmani('tayga'), ['seed_cam']);
    });

    test('iklimini seven bitki sulanınca 2 kat büyür', () async {
      final dun = _gun(DateTime.now().subtract(const Duration(days: 1)));
      final c = await _kapsayici({
        'iklim': 'col',
        'damla': 5,
        'saksilar': [
          {'bitkiId': 'seed_kaktus', 'buyume': 0, 'sonSulama': dun},
          {'bitkiId': 'seed_lale', 'buyume': 0, 'sonSulama': dun},
        ],
      });
      final n = c.read(bahceProvider.notifier);
      expect(await n.sula(0), isNull);
      expect(await n.sula(1), isNull);
      final s = c.read(bahceProvider);
      expect(s.saksilar[0].buyume, 1 + iklimSulamaBonusu);
      expect(s.saksilar[1].buyume, 1);
      expect(s.damla, 3);
    });
  });

  for (final (ad, tema) in [('acik', AppTheme.light), ('koyu', AppTheme.dark)]) {
    testWidgets('Bahçe: bölge seçilir, orman o bölgede görünür ($ad tema)', (tester) async {
      tester.view.physicalSize = const Size(360, 1500) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      late ProviderContainer c;
      await tester.runAsync(() async {
        c = await _kapsayici({
          'saksilar': [
            {'bitkiId': 'seed_kaktus', 'buyume': 9},
            {},
            {},
          ],
          'ormanlar': {
            'iliman': ['seed_kiraz', 'seed_hus', 'seed_cam', 'seed_papatya', 'seed_lale', 'seed_limon', 'seed_cam'],
          },
        });
      });
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: RepaintBoundary(child: MaterialApp(theme: temaVerisi(tema), home: const BahceTab())),
      ));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('Doğu Karadeniz · Ilıman okyanusal iklim'), findsOneWidget);
      expect(find.textContaining('Genç orman · 7 bitki · 2 kayın'), findsOneWidget);
      await _goruntuKaydet(tester, 'bahce_$ad');

      await tester.tap(find.text('Bölge seç'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Ormanın nerede büyüsün?'), findsOneWidget);
      await _goruntuKaydet(tester, 'secim_$ad');

      await tester.scrollUntilVisible(find.text('Büyük Sahra'), 200, scrollable: find.byType(Scrollable).last);
      await tester.pump(const Duration(milliseconds: 200));
      await _goruntuKaydet(tester, 'secim2_$ad');
      await tester.tap(find.text('Büyük Sahra'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();

      expect(c.read(bahceProvider).iklim, 'col');
      expect(find.textContaining('Büyük Sahra · Çöl iklimi'), findsOneWidget);
      expect(find.textContaining('Boş arazi · 0 bitki'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await _goruntuKaydet(tester, 'bahce_col_$ad');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Tüm iklim manzaraları hatasız çizilir', (tester) async {
    tester.view.physicalSize = const Size(360, 1700) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    for (final (ad, tema) in [('acik', AppTheme.light), ('koyu', AppTheme.dark)]) {
      await tester.pumpWidget(RepaintBoundary(
        child: MaterialApp(
          theme: temaVerisi(tema),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  for (final b in iklimBolgeleri)
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: OrmanSahnesi(
                        bolge: b,
                        bitkiler: [...b.sevenler, ...b.sevenler, 'seed_lale', 'seed_kiraz', 'seed_limon'],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      await _goruntuKaydet(tester, 'manzaralar_$ad');
    }
  });
}
