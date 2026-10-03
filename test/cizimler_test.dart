import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yks_kocu/core/constants/bahce_data.dart';
import 'package:yks_kocu/core/theme/app_theme.dart';
import 'package:yks_kocu/core/theme/tema_verisi.dart';
import 'package:yks_kocu/presentation/cizimler/cizim_widgetlari.dart';
import 'package:yks_kocu/presentation/cizimler/sahne_boyaci.dart';
import 'package:yks_kocu/presentation/cizimler/svg_cizimler.dart';

List<String> _tumSvgler() {
  final svgler = <String>[
    yildizSvg(0xFFE9A23B),
    damlaSvg(0xFF3D8EBF),
    alevSvg(0xFFF08A4B),
    kutuGovdeSvg(),
    kutuGovdeSvg(gece: true),
    kutuKapakSvg(),
    kutuKapakSvg(gece: true),
    saksiSvg(),
    saksiSvg(gece: true),
    saksiSvg(bos: true),
  ];
  for (final gece in [false, true]) {
    for (final u in bahceUrunleri) {
      if (u.tip == BahceUrunTip.tohum) {
        for (var a = 0; a < 4; a++) {
          svgler.add(bitkiSvg(u.id, a, gece: gece));
          svgler.add(bitkiSvg(u.id, a, gece: gece, solgun: true));
        }
      } else if (u.tip == BahceUrunTip.dekor) {
        svgler.add(dekorSvg(u.id, gece: gece));
      }
    }
  }
  return svgler;
}

void main() {
  testWidgets('tüm SVG çizimleri hatasız ayrıştırılır', (tester) async {
    final svgler = _tumSvgler();
    expect(svgler.length, greaterThan(60));
    await tester.runAsync(() async {
      for (final s in svgler) {
        final info = await vg.loadPicture(SvgStringLoader(s), null);
        expect(info.size.width, greaterThan(0), reason: s);
        info.picture.dispose();
      }
    });
  });

  for (final tema in [AppTheme.light, AppTheme.dark]) {
    testWidgets('sahneler ve maskot ${tema.gece ? 'gece' : 'gündüz'} temasında çizilir', (tester) async {
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          theme: temaVerisi(tema),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  for (final sahne in ['orman', 'gunBatimi', 'gece', 'deniz', 'kutuphane'])
                    SizedBox(height: 120, width: 390, child: CustomPaint(painter: OdakSahnesiBoyaci(sahne, 0.4))),
                  SizedBox(height: 200, width: 350, child: CustomPaint(painter: BahceArkaPlanBoyaci(tema.gece, 0.4))),
                  SizedBox(height: 130, width: 350, child: CustomPaint(painter: EtutSalonuBoyaci(tema.gece, 0.4))),
                  SizedBox(height: 40, width: 350, child: CustomPaint(painter: AskiIpiBoyaci(tema.gece, 0.4))),
                  SizedBox(
                    height: 86,
                    width: 318,
                    child: CustomPaint(
                      painter: TakimyildizBoyaci(toplam: 5, biten: 3, t: 0.4, yanik: tema.accent, sirada: tema.primary, sonuk: tema.border),
                    ),
                  ),
                  for (final k in maskotKarakterleri) Maskot(karakter: k, ruh: MaskotRuh.odakli, yuruyor: true),
                  const SaksiliBitki(bitkiId: 'seed_kiraz', asama: 3),
                  const SaksiliBitki(bitkiId: 'seed_lale', asama: 2, solgun: true),
                  const SaksiliBitki(),
                ],
              ),
            ),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.byType(Maskot), findsNWidgets(maskotKarakterleri.length));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });
  }
}
