/// Okul panellerinin (öğretmen, veli, müdür) ortak yapı taşları.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

import '../../../core/algorithms/okul_hesaplari.dart';
import '../../../core/services/okul_service.dart';
import '../../../data/models/okul_modelleri.dart';
import '../../widgets/ui_kit.dart';

void okulBildir(BuildContext context, String mesaj, {bool hata = false}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(mesaj),
      backgroundColor: hata ? context.colors.danger : null,
      behavior: SnackBarBehavior.floating,
    ));
}

/// Sunucudan bir kez yüklenen, aşağı çekince yenilenen kaydırılabilir gövde.
/// Hata ve "sunucuda henüz kurulmadı" durumlarını kendisi gösterir.
class VeriGovdesi<T> extends StatefulWidget {
  final Future<T> Function() yukle;
  final List<Widget> Function(BuildContext context, T veri, Future<void> Function() yenile) insa;
  final EdgeInsetsGeometry padding;

  const VeriGovdesi({
    super.key,
    required this.yukle,
    required this.insa,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 32),
  });

  @override
  State<VeriGovdesi<T>> createState() => VeriGovdesiState<T>();
}

class VeriGovdesiState<T> extends State<VeriGovdesi<T>> {
  T? _veri;
  bool _yuklendi = false;
  OkulHatasi? _hata;

  @override
  void initState() {
    super.initState();
    yenile();
  }

  Future<void> yenile() async {
    try {
      final v = await widget.yukle();
      if (!mounted) return;
      setState(() {
        _veri = v;
        _yuklendi = true;
        _hata = null;
      });
    } on OkulHatasi catch (e) {
      if (!mounted) return;
      setState(() => _hata = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (!_yuklendi && _hata == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final List<Widget> cocuklar;
    if (!_yuklendi) {
      cocuklar = [
        const SizedBox(height: 60),
        Icon(_hata!.kurulmamis ? Icons.cloud_off_rounded : Icons.wifi_off_rounded, size: 44, color: c.textMuted),
        const SizedBox(height: 14),
        Text(_hata!.mesaj, textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary, height: 1.4)),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton.icon(
            onPressed: yenile,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Tekrar dene'),
          ),
        ),
      ];
    } else {
      cocuklar = [
        if (_hata != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('Yenilenemedi: ${_hata!.mesaj}', style: TextStyle(fontSize: 12.5, color: c.danger)),
          ),
        ...widget.insa(context, _veri as T, yenile),
      ];
    }
    return RefreshIndicator(
      onRefresh: yenile,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: widget.padding,
        children: cocuklar,
      ),
    );
  }
}

/// Sekme başlığı: büyük başlık + alt satır.
class PanelBasligi extends StatelessWidget {
  final String baslik;
  final String? alt;
  final Widget? sag;

  const PanelBasligi(this.baslik, {super.key, this.alt, this.sag});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(baslik, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.baslik(26)),
                if (alt != null && alt!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(alt!,
                      style: TextStyle(fontSize: 13.5, color: context.colors.textSecondary, fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
          ?sag,
        ],
      ),
    );
  }
}

/// Boş liste mesajı (ikon + açıklama).
class BosDurum extends StatelessWidget {
  final IconData ikon;
  final String baslik;
  final String aciklama;

  const BosDurum({super.key, required this.ikon, required this.baslik, required this.aciklama});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: c.primarySoft, shape: BoxShape.circle),
            child: Icon(ikon, size: 30, color: c.gece ? c.accent : c.primary),
          ),
          const SizedBox(height: 14),
          Text(baslik, textAlign: TextAlign.center, style: context.baslik(18)),
          const SizedBox(height: 6),
          Text(aciklama, textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, color: c.textSecondary, height: 1.45)),
        ],
      ),
    );
  }
}

/// Kopyalanabilir davet / katılım kodu.
class KodKutusu extends StatelessWidget {
  final String kod;
  final String? aciklama;

  const KodKutusu({super.key, required this.kod, this.aciklama});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bicimli = kodBicimle(kod);
    return Semantics(
      label: 'Kod $bicimli. Kopyalamak için dokun.',
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: bicimli));
          HapticFeedback.selectionClick();
          if (context.mounted) okulBildir(context, 'Kod kopyalandı.');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: c.primarySoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(bicimli,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: c.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        )),
                    if (aciklama != null)
                      Text(aciklama!, style: TextStyle(fontSize: 11.5, color: c.textMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.copy_rounded, size: 18, color: c.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

Color riskRengi(BuildContext context, RiskDurumu r) => switch (r) {
      RiskDurumu.pasif => context.colors.danger,
      RiskDurumu.dusus => context.colors.warning,
      RiskDurumu.yeni => context.colors.info,
      RiskDurumu.yok => context.colors.success,
    };

class RiskRozeti extends StatelessWidget {
  final RiskDurumu risk;

  const RiskRozeti(this.risk, {super.key});

  @override
  Widget build(BuildContext context) {
    final r = riskRengi(context, risk);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: r.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            switch (risk) {
              RiskDurumu.pasif => Icons.pause_circle_outline_rounded,
              RiskDurumu.dusus => Icons.trending_down_rounded,
              RiskDurumu.yeni => Icons.fiber_new_rounded,
              RiskDurumu.yok => Icons.check_circle_outline_rounded,
            },
            size: 14,
            color: context.colors.textPrimary,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(riskEtiketi(risk),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

/// Etiket + değer + oran çubuğu (şube karşılaştırması, konu başarısı).
class OranSatiri extends StatelessWidget {
  final String etiket;
  final String deger;
  final double oran;
  final Color? renk;
  final String? alt;
  final VoidCallback? onTap;

  const OranSatiri({super.key, required this.etiket, required this.deger, required this.oran, this.renk, this.alt, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(etiket,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w700, color: c.textPrimary)),
                ),
                const SizedBox(width: 8),
                Text(deger, style: TextStyle(fontWeight: FontWeight.w800, color: c.textPrimary)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: oran.clamp(0, 1).toDouble(),
                minHeight: 7,
                backgroundColor: c.border.withValues(alpha: 0.5),
                color: renk ?? c.primary,
              ),
            ),
            if (alt != null) ...[
              const SizedBox(height: 4),
              Text(alt!, style: TextStyle(fontSize: 12, color: c.textMuted)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Alttan açılan sayfaların ortak çerçevesi (klavye açılınca yukarı kayar).
Future<T?> okulSayfasiGoster<T>(BuildContext context, {required String baslik, required Widget Function(BuildContext) insa}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, 16 + MediaQuery.viewInsetsOf(ctx).bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(baslik, style: ctx.baslik(20)),
              const SizedBox(height: 14),
              insa(ctx),
            ],
          ),
        ),
      ),
    ),
  );
}

InputDecoration okulGirdisi(BuildContext context, {String? ipucu, IconData? ikon}) {
  final c = context.colors;
  return InputDecoration(
    hintText: ipucu,
    hintStyle: TextStyle(color: c.textMuted),
    filled: true,
    fillColor: c.background,
    prefixIcon: ikon == null ? null : Icon(ikon, color: c.textMuted),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.border)),
    focusedBorder:
        OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.primary, width: 2)),
  );
}

/// Birincil eylem düğmesi (tam genişlik, yüklenirken döner).
class AnaDugme extends StatelessWidget {
  final String etiket;
  final VoidCallback? onPressed;
  final bool yukleniyor;
  final IconData? ikon;

  const AnaDugme({super.key, required this.etiket, this.onPressed, this.yukleniyor = false, this.ikon});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: yukleniyor ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: yukleniyor
            ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: c.onPrimary, strokeWidth: 2.5))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (ikon != null) ...[Icon(ikon, size: 18), const SizedBox(width: 8)],
                  Flexible(child: Text(etiket, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
                ],
              ),
      ),
    );
  }
}

/// İki sütunlu KPI ızgarası için küçük yardımcı.
class IkiliSatir extends StatelessWidget {
  final Widget sol;
  final Widget sag;

  const IkiliSatir(this.sol, this.sag, {super.key});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [Expanded(child: sol), const SizedBox(width: 10), Expanded(child: sag)],
      ),
    );
  }
}

/// Başlıklı bilgi kartı (madde işaretli açıklamalar).
class BilgiKarti extends StatelessWidget {
  final IconData ikon;
  final String baslik;
  final List<String> maddeler;
  final Color? renk;

  const BilgiKarti({super.key, required this.ikon, required this.baslik, required this.maddeler, this.renk});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = renk ?? c.primary;
    return YumusakKart(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ikon, size: 20, color: r),
              const SizedBox(width: 8),
              Expanded(child: Text(baslik, style: TextStyle(fontWeight: FontWeight.w800, color: c.textPrimary))),
            ],
          ),
          const SizedBox(height: 8),
          for (final m in maddeler)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7, right: 8),
                    child: Container(width: 5, height: 5, decoration: BoxDecoration(color: r, shape: BoxShape.circle)),
                  ),
                  Expanded(child: Text(m, style: TextStyle(fontSize: 13.5, color: c.textSecondary, height: 1.4))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
