/// Zihin Açıcı oyunlarının ortak parçaları: rekor kaydı, üst bilgi çubuğu,
/// geri sayım ve oyun sonu ekranı.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

import '../../../providers/profil_provider.dart';
import '../../../widgets/ui_kit.dart';

const String _rekorKey = 'mini_oyun_rekorlar';

final oyunRekorlariProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final map = await ref.read(localStorageServiceProvider).getMap(_rekorKey) ?? {};
  return map.map((k, v) => MapEntry(k, (v as num).toInt()));
});

/// Skoru kaydeder; yeni rekorsa true döner. [azIyi] süre gibi küçüğün
/// daha iyi olduğu skorlar içindir.
Future<bool> oyunRekoruKaydet(WidgetRef ref, String oyun, int skor, {bool azIyi = false}) async {
  if (skor <= 0) return false;
  final storage = ref.read(localStorageServiceProvider);
  final map = await storage.getMap(_rekorKey) ?? {};
  final eski = (map[oyun] as num?)?.toInt();
  final rekor = eski == null || (azIyi ? skor < eski : skor > eski);
  if (!rekor) return false;
  map[oyun] = skor;
  await storage.setMap(_rekorKey, map);
  ref.invalidate(oyunRekorlariProvider);
  return true;
}

/// Oyun sonu ortak ekranı.
class OyunSonucu extends StatelessWidget {
  final int skor;
  final bool rekor;
  final String birim;
  final String? aciklama;
  final VoidCallback tekrar;

  const OyunSonucu({super.key, required this.skor, required this.rekor, required this.birim, required this.tekrar, this.aciklama});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(rekor ? Icons.emoji_events_rounded : Icons.celebration_rounded, size: 64, color: rekor ? c.star : c.primary),
            const SizedBox(height: 10),
            Text('$skor $birim', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: c.textPrimary)),
            const SizedBox(height: 6),
            Text(rekor ? 'Yeni rekor!' : 'Güzel mola! Şimdi çalışmaya dönmeye hazırsın.',
                textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary, fontSize: 15)),
            if (aciklama != null) ...[
              const SizedBox(height: 8),
              Text(aciklama!, textAlign: TextAlign.center, style: TextStyle(color: c.textMuted, fontSize: 13)),
            ],
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50)),
                      child: const Text('Bitir'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: tekrar,
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 50)),
                      child: const FittedBox(fit: BoxFit.scaleDown, child: Text('Tekrar oyna')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Süre ve skor rozetleri.
class OyunUstBar extends StatelessWidget {
  final String? sure;
  final String skor;
  final IconData skorIkon;
  final Widget? orta;

  const OyunUstBar({super.key, this.sure, required this.skor, this.skorIkon = Icons.check_rounded, this.orta});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget sigdir(Widget w, Alignment hiza) => Flexible(
          child: FittedBox(fit: BoxFit.scaleDown, alignment: hiza, child: w),
        );
    return Row(
      children: [
        if (sure != null)
          sigdir(SayacRozeti(ikon: Icon(Icons.timer_outlined, size: 16, color: c.warning), deger: sure!, renk: c.warning), Alignment.centerLeft),
        const SizedBox(width: 8),
        Expanded(child: Center(child: orta == null ? null : FittedBox(fit: BoxFit.scaleDown, child: orta))),
        const SizedBox(width: 8),
        sigdir(SayacRozeti(ikon: Icon(skorIkon, size: 16, color: c.success), deger: skor, renk: c.success), Alignment.centerRight),
      ],
    );
  }
}

/// Oyun sayfası iskeleti: başlık, kısa kural açıklaması ve gövde.
class OyunIskeleti extends StatelessWidget {
  final String baslik;
  final Widget govde;

  const OyunIskeleti({super.key, required this.baslik, required this.govde});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(backgroundColor: context.colors.background, title: Text(baslik)),
      body: SafeArea(child: govde),
    );
  }
}

/// Saniyelik geri sayım yardımcısı. [bitti] süre dolunca bir kez çağrılır.
class GeriSayim {
  Timer? _timer;
  int kalan = 0;

  void baslat(int saniye, {required VoidCallback tik, required VoidCallback bitti}) {
    _timer?.cancel();
    kalan = saniye;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      kalan--;
      if (kalan <= 0) {
        t.cancel();
        kalan = 0;
        bitti();
      } else {
        tik();
      }
    });
  }

  void durdur() => _timer?.cancel();
}
