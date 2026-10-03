/// Ekranın sağ altında duran koç asistanı karakteri. Duruma göre ruh hali
/// değişir; dokununca sohbet paneli açılır (deneme analizi, ders programı
/// önerileri, soru-cevap — bkz. asistan_sohbet_sheet.dart).
library;

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/algorithms/asistan_motoru.dart';
import '../cizimler/cizim_widgetlari.dart';
import '../providers/asistan_provider.dart';
import '../providers/bahce_provider.dart';
import '../providers/flashkart_provider.dart';
import '../providers/net_provider.dart';
import '../providers/odak_provider.dart';
import '../providers/ortam_provider.dart';
import '../providers/plan_provider.dart';
import 'asistan_sohbet_sheet.dart';

const List<String> _motivasyonlar = [
  'Küçük adımlar büyük farklar yaratır. Bugün 25 dakika yeter!',
  'Mola vermek de çalışmanın bir parçası. Su içmeyi unutma.',
  'Zor konular, en çok büyüten konulardır.',
  'Dünkü senden biraz daha iyi olman yeterli.',
  'Telefonu uzağa koy, sayacı başlat; ben seni beklerim.',
];

class AsistanWidget extends ConsumerStatefulWidget {
  const AsistanWidget({super.key});

  @override
  ConsumerState<AsistanWidget> createState() => _AsistanWidgetState();
}

class _AsistanWidgetState extends ConsumerState<AsistanWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
  final _rng = Random();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  (MaskotRuh, String) _ruhHali() {
    final odak = ref.read(odakProvider);
    final due = ref.read(desteDueSayilariProvider)['hepsi'] ?? 0;
    final bahce = ref.read(bahceProvider);
    if (odak.asama == OdakAsama.calisiyor) return (MaskotRuh.odakli, 'odaklanmış');
    if (odak.asama == OdakAsama.tamamlandi) return (MaskotRuh.gururlu, 'gururlu');
    if (bahce.solgunVar) return (MaskotRuh.endiseli, 'endişeli');
    if (due > 0) return (MaskotRuh.dusunceli, 'düşünceli');
    return (MaskotRuh.mutlu, 'mutlu');
  }

  /// Sohbet açılırken gösterilecek, o anki duruma uygun öneri.
  (String, AsistanAksiyon?) _oneriSec() {
    final odak = ref.read(odakProvider);
    if (odak.asama == OdakAsama.calisiyor) {
      return ('${odak.gecenDakika} dakikadır odaktasın, harika gidiyorsun!', null);
    }
    final bahce = ref.read(bahceProvider);
    final due = ref.read(desteDueSayilariProvider)['hepsi'] ?? 0;
    final siradaki = ref.read(gunlukPlanProvider).where((b) => b.isCalismaBloku && !b.tamamlandi).firstOrNull;
    final netler = ref.read(netProvider);
    final sonDeneme = netler.isEmpty ? null : netler.map((k) => k.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);

    if (sonDeneme != null && DateTime.now().difference(sonDeneme).inDays < 2) {
      return ('Yeni bir deneme eklemişsin; istersen hemen analiz edelim.',
          const AsistanAksiyon.niyet('Son denememi analiz et', AsistanNiyet.denemeAnalizi));
    }
    if (siradaki != null) {
      return ('Programındaki sıradaki blok ${siradaki.saatFormatli}\'de: ${siradaki.konu} (${siradaki.sure} dk).',
          AsistanAksiyon.komut('Çalışmaya başla', AsistanKomut.odak(odakDersAdi(siradaki.ders ?? 'Genel'), sayi: siradaki.sure >= 45 ? 50 : 25)));
    }
    final yanlis = ref.read(desteDueSayilariProvider)['yanlislar'] ?? 0;
    if (yanlis > 0) {
      return ('Yanlışlarım destende $yanlis kart tekrar bekliyor.', const AsistanAksiyon.komut('Yanlışlarımı tekrar et', AsistanKomut.deste('yanlislar')));
    }
    if (due > 0) return ('$due tekrar kartın bekliyor.', const AsistanAksiyon.komut('Kartları tekrar et', AsistanKomut.deste('hepsi')));
    if (bahce.solgunVar) return ('Bazı bitkilerin susuz kaldı.', const AsistanAksiyon.rota('Bahçeye git', '/bahce'));
    return (_motivasyonlar[_rng.nextInt(_motivasyonlar.length)], null);
  }

  void _dokun() {
    HapticFeedback.selectionClick();
    final (oneri, aksiyon) = _oneriSec();
    ref.read(asistanProvider.notifier).karsilama(oneri, aksiyon: aksiyon);
    asistanSohbetiniAc(context);
  }

  @override
  Widget build(BuildContext context) {
    final ortam = ref.watch(ortamProvider);
    ref.watch(odakProvider.select((o) => o.asama));
    ref.watch(desteDueSayilariProvider);
    ref.watch(bahceProvider.select((b) => b.solgunVar));
    if (!ortam.asistanGorunur) return const SizedBox.shrink();

    final (ruh, ruhAd) = _ruhHali();
    final hareketsiz = MediaQuery.of(context).disableAnimations;
    final genislik = MediaQuery.of(context).size.width;

    Widget karakter({required bool yuruyor, required bool sagaBakiyor}) => Semantics(
          button: true,
          label: '${ortam.asistan.ad}, koç asistanın. Şu an $ruhAd. Deneme analizi ve ders programı için dokun.',
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _dokun,
            onLongPress: () => context.push('/ayarlar'),
            child: Maskot(
              key: ValueKey(ortam.asistan.name),
              karakter: ortam.asistan.name,
              ruh: ruh,
              boyut: _boyut,
              yuruyor: yuruyor,
              sagaBakiyor: sagaBakiyor,
              zipla: ortam.hareket == AsistanHareket.zipla && !hareketsiz,
            ),
          ),
        );

    if (hareketsiz || ortam.hareket != AsistanHareket.gezin) {
      return Stack(
        children: [
          Positioned(right: 12, bottom: 12, child: karakter(yuruyor: false, sagaBakiyor: false)),
        ],
      );
    }

    final menzil = max(0.0, genislik - _boyut - 40);
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _c,
          builder: (_, _) {
            final g = _gezinti(_c.value);
            return Positioned(
              right: 12 + g.konum * menzil,
              bottom: 12,
              child: karakter(yuruyor: g.yuruyor, sagaBakiyor: g.sagaBakiyor),
            );
          },
        ),
      ],
    );
  }

  static const double _boyut = 76;

  /// 20 saniyelik gezinti döngüsü: sağ köşede bekle → sola yürü → bekle,
  /// etrafa bak → sağa yürü. [konum] 0 = sağ köşe, 1 = en sol.
  static ({double konum, bool yuruyor, bool sagaBakiyor}) _gezinti(double v) {
    double yumusak(double a, double b) => Curves.easeInOut.transform(((v - a) / (b - a)).clamp(0.0, 1.0));
    if (v < 0.12) return (konum: 0, yuruyor: false, sagaBakiyor: false);
    if (v < 0.42) return (konum: yumusak(0.12, 0.42), yuruyor: true, sagaBakiyor: false);
    if (v < 0.52) return (konum: 1, yuruyor: false, sagaBakiyor: false);
    if (v < 0.58) return (konum: 1, yuruyor: false, sagaBakiyor: true);
    if (v < 0.88) return (konum: 1 - yumusak(0.58, 0.88), yuruyor: true, sagaBakiyor: true);
    return (konum: 0, yuruyor: false, sagaBakiyor: v < 0.94);
  }
}
