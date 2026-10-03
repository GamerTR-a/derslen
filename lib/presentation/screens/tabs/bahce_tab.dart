import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/bahce_data.dart';
import '../../cizimler/cizim_widgetlari.dart';
import '../../cizimler/sahne_boyaci.dart';
import '../../providers/bahce_provider.dart';
import '../../widgets/ui_kit.dart';
import '../bahce/bahce_magaza_sheet.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

class BahceTab extends ConsumerWidget {
  const BahceTab({super.key});

  void _mesaj(BuildContext context, String m) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bahce = ref.watch(bahceProvider);
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(bahceProvider.notifier).yildizYenile(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              Row(
                children: [
                  Expanded(child: Text(c.gece ? 'Ay Işığı Serası' : 'Bahçem', style: context.baslik(28))),
                  SayacRozeti(ikon: const YildizIkon(boyut: 15), deger: '${bahce.yildiz}', renk: c.star, semantik: '${bahce.yildiz} yıldız'),
                  const SizedBox(width: 8),
                  SayacRozeti(ikon: const DamlaIkon(boyut: 15), deger: '${bahce.damla}', renk: c.water, semantik: '${bahce.damla} su damlası'),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                bahce.ekiliBitki == 0
                    ? 'Bir tohum ek ve odaklandıkça büyümesini izle.'
                    : bahce.susuzBitki > 0
                        ? '${bahce.susuzBitki} bitkin ${c.gece ? 'bu gece' : 'bugün'} su bekliyor'
                        : 'Bugün tüm bitkilerini suladın, harika!',
                style: TextStyle(fontSize: 14, color: c.textSecondary),
              ),
              const SizedBox(height: 16),
              _BahceSahnesi(onSaksi: (i) => _saksiIslemleri(context, ref, i)),
              const SizedBox(height: 14),
              if (bahce.envanter.isNotEmpty) ...[
                _envanter(context, bahce),
                const SizedBox(height: 14),
              ],
              _orman(context, bahce),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _erisimKarti(
                      context,
                      ikon: Icons.storefront_rounded,
                      baslik: c.gece ? 'Tohum Pazarı' : 'Bahçe Mağazası',
                      alt: 'Tohum, dekor, saksı',
                      renk: c.success,
                      onTap: () => BahceMagazaSheet.goster(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _erisimKarti(
                      context,
                      ikon: Icons.extension_rounded,
                      baslik: c.gece ? 'Gece Bulmacaları' : 'Zihin Açıcı',
                      alt: 'Mola oyunları',
                      renk: c.primary,
                      onTap: () => context.push('/mini-oyunlar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _nasilBuyur(context),
            ],
          ),
        ),
      ),
    );
  }

  void _saksiIslemleri(BuildContext context, WidgetRef ref, int index) {
    HapticFeedback.selectionClick();
    final bahce = ref.read(bahceProvider);
    final saksi = bahce.saksilar[index];
    final n = ref.read(bahceProvider.notifier);
    final c = context.colors;

    if (saksi.bos) {
      if (bahce.envanter.isEmpty) {
        _mesaj(context, 'Ekecek tohumun yok. Mağazadan tohum alabilirsin.');
        BahceMagazaSheet.goster(context);
        return;
      }
      showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BolumBasligi('Hangi tohumu ekelim?'),
                for (final e in bahce.envanter.entries)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: UrunCizimi(urunId: e.key, boyut: 44),
                    title: Text(bahceUrunuBul(e.key)?.ad ?? e.key, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('${e.value} adet'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final hata = await n.ek(index, e.key);
                      if (context.mounted) _mesaj(context, hata ?? 'Tohum ekildi! Sulamayı unutma.');
                    },
                  ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    final urun = bahceUrunuBul(saksi.bitkiId!);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SaksiliBitki(bitkiId: saksi.bitkiId, asama: saksi.asama, solgun: saksi.solgun, ilerleme: saksiIlerleme(saksi), genislik: 110),
              const SizedBox(height: 10),
              Text(urun?.ad ?? 'Bitki', style: context.baslik(22)),
              const SizedBox(height: 4),
              Text(
                '${buyumeEtiketleri[saksi.asama]}${saksi.solgun ? ' · susuz kaldı' : ''}',
                style: TextStyle(color: saksi.solgun ? c.warning : c.textSecondary, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              _BuyumeCubugu(saksi: saksi),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: saksi.olgun
                    ? FilledButton.icon(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await n.hasatEt(index);
                          if (context.mounted) _mesaj(context, '${urun?.ad ?? 'Bitki'} ormanına taşındı. Saksı yeni tohuma hazır.');
                        },
                        icon: const Icon(Icons.forest_rounded),
                        label: const Text('Ormanıma taşı'),
                      )
                    : FilledButton.icon(
                        onPressed: saksi.bugunSulandi
                            ? null
                            : () async {
                                HapticFeedback.lightImpact();
                                Navigator.pop(ctx);
                                final hata = await n.sula(index);
                                if (context.mounted) _mesaj(context, hata ?? 'Sulandı! Bitkin biraz daha büyüdü.');
                              },
                        style: FilledButton.styleFrom(backgroundColor: c.water, foregroundColor: c.onPrimary),
                        icon: const Icon(Icons.water_drop_rounded),
                        label: Text(saksi.bugunSulandi ? 'Bugün sulandı' : 'Sula (1 damla)'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _envanter(BuildContext context, BahceState bahce) {
    return YumusakKart(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text('Tohum kesem', style: TextStyle(fontWeight: FontWeight.w800, color: context.colors.textSecondary)),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                for (final e in bahce.envanter.entries)
                  Semantics(
                    label: '${bahceUrunuBul(e.key)?.ad ?? e.key}, ${e.value} adet',
                    excludeSemantics: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        UrunCizimi(urunId: e.key, boyut: 30),
                        Text('×${e.value}', style: TextStyle(fontWeight: FontWeight.w800, color: context.colors.textPrimary)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _orman(BuildContext context, BahceState bahce) {
    return YumusakKart(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(context.colors.gece ? 'Işıklı ormanım' : 'Ormanım', style: context.baslik(18))),
              Text('${bahce.orman.length} bitki', style: TextStyle(color: context.colors.textMuted, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          bahce.orman.isEmpty
              ? Text('Olgunlaşan bitkilerini buraya taşıyarak kalıcı bir orman kur.',
                  style: TextStyle(fontSize: 13, color: context.colors.textMuted))
              : Wrap(
                  spacing: 2,
                  runSpacing: 2,
                  children: [for (final id in bahce.orman) Salinan(aci: 0.03, child: UrunCizimi(urunId: id, boyut: 40))],
                ),
        ],
      ),
    );
  }

  Widget _erisimKarti(BuildContext context,
      {required IconData ikon, required String baslik, required String alt, required Color renk, required VoidCallback onTap}) {
    return YumusakKart(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: renk.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14)),
            child: Icon(ikon, color: renk),
          ),
          const SizedBox(height: 12),
          Text(baslik, style: context.baslik(17)),
          const SizedBox(height: 2),
          Text(alt, style: TextStyle(fontSize: 12.5, color: context.colors.textMuted)),
        ],
      ),
    );
  }

  Widget _nasilBuyur(BuildContext context) {
    final c = context.colors;
    Widget satir(Widget ikon, String m) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 28, child: ikon),
              Expanded(child: Text(m, style: TextStyle(fontSize: 13.5, color: c.textSecondary, height: 1.4))),
            ],
          ),
        );
    return YumusakKart(
      renk: c.primarySoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bahçen nasıl büyür?', style: context.baslik(17)),
          const SizedBox(height: 6),
          satir(Icon(Icons.timer_outlined, size: 18, color: c.primary), 'Her 25 dakikalık odak, ekili tüm bitkilere büyüme verir.'),
          satir(const DamlaIkon(boyut: 17), 'Günde bir kez sulamak da büyütür. Damlaları check-in ve kart tekrarıyla kazanırsın.'),
          satir(const YildizIkon(boyut: 17), 'Odaklandıkça kazandığın yıldızlarla mağazadan yeni tohum ve dekor al.'),
          satir(Icon(Icons.spa_outlined, size: 18, color: c.warning), '$solmaGunu gün sulanmayan bitki solar ama ölmez; sulayınca canlanır.'),
        ],
      ),
    );
  }
}

class _BahceSahnesi extends ConsumerWidget {
  final void Function(int) onSaksi;
  const _BahceSahnesi({required this.onSaksi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bahce = ref.watch(bahceProvider);
    final gece = context.colors.gece;
    final satir = (bahce.saksilar.length / 3).ceil();

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: HareketliSahne(
        dongu: const Duration(seconds: 24),
        boyaci: (t) => BahceArkaPlanBoyaci(gece, t),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 16),
          child: Column(
            children: [
              SizedBox(
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final d in bahce.dekorlar)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Semantics(label: bahceUrunuBul(d)?.ad, child: UrunCizimi(urunId: d, boyut: 44)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bahce.saksilar.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 6,
                  childAspectRatio: 0.66,
                ),
                itemBuilder: (_, i) => _SaksiKutusu(index: i, saksi: bahce.saksilar[i], onTap: () => onSaksi(i)),
              ),
              if (satir == 0) const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bulunulan aşama içindeki büyüme oranı (0..1).
double saksiIlerleme(Saksi s) {
  final a = s.asama;
  if (a >= buyumeEsikleri.length - 1) return 1;
  final alt = buyumeEsikleri[a];
  final ust = buyumeEsikleri[a + 1];
  return ((s.buyume - alt) / (ust - alt)).clamp(0.0, 1.0);
}

enum _BahceOlayi { ekim, buyume, sulama }

class _SaksiKutusu extends StatefulWidget {
  final int index;
  final Saksi saksi;
  final VoidCallback onTap;

  const _SaksiKutusu({required this.index, required this.saksi, required this.onTap});

  @override
  State<_SaksiKutusu> createState() => _SaksiKutusuState();
}

class _SaksiKutusuState extends State<_SaksiKutusu> with SingleTickerProviderStateMixin {
  /// Uygulama açıkken her saksının en son görülen hâli. Başka bir sekmede
  /// (ör. odak seansıyla) büyüyen bitki, bahçeye dönülünce de canlanarak büyür.
  static final Map<int, (String?, int, bool)> _sonGorulen = {};

  late final AnimationController _c;
  _BahceOlayi? _olay;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    WidgetsBinding.instance.addPostFrameCallback((_) => _karsilastir());
  }

  @override
  void didUpdateWidget(covariant _SaksiKutusu old) {
    super.didUpdateWidget(old);
    _karsilastir();
  }

  void _karsilastir() {
    if (!mounted) return;
    final s = widget.saksi;
    final simdi = (s.bitkiId, s.asama, s.bugunSulandi);
    final onceki = _sonGorulen[widget.index];
    _sonGorulen[widget.index] = simdi;
    if (onceki == null || s.bos) return;
    _BahceOlayi? olay;
    if (onceki.$1 != s.bitkiId) {
      olay = _BahceOlayi.ekim;
    } else if (s.asama > onceki.$2) {
      olay = _BahceOlayi.buyume;
    } else if (s.bugunSulandi && !onceki.$3) {
      olay = _BahceOlayi.sulama;
    }
    if (olay == null || MediaQuery.of(context).disableAnimations) return;
    setState(() => _olay = olay);
    _c.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _olay = null);
    });
    if (olay == _BahceOlayi.buyume) HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _olcek(double t) {
    switch (_olay) {
      case _BahceOlayi.ekim:
        return Curves.elasticOut.transform(t.clamp(0.0, 1.0)) * 0.9 + 0.1;
      case _BahceOlayi.buyume:
        // Önce hafifçe çömelir, sonra boy atıp yerine oturur.
        if (t < 0.15) return 1 - 0.12 * (t / 0.15);
        return 0.88 + 0.12 * Curves.elasticOut.transform(((t - 0.15) / 0.85).clamp(0.0, 1.0)) + 0.1 * sin(pi * t) * (1 - t);
      case _BahceOlayi.sulama:
        return 1 + 0.05 * sin(pi * t * 2) * (1 - t);
      case null:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final saksi = widget.saksi;
    final urun = saksi.bos ? null : bahceUrunuBul(saksi.bitkiId!);
    final etiketRenk = c.gece ? c.textPrimary : const Color(0xFF14532D);
    return Semantics(
      button: true,
      label: saksi.bos
          ? 'Boş saksı, tohum ek'
          : '${urun?.ad ?? 'Bitki'}, ${buyumeEtiketleri[saksi.asama]}${saksi.solgun ? ', susuz' : ''}${saksi.bugunSulandi ? ', bugün sulandı' : ''}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Expanded(
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, _) => Stack(
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.none,
                  children: [
                    FittedBox(
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      child: SaksiliBitki(
                        bitkiId: saksi.bitkiId,
                        asama: saksi.asama,
                        solgun: saksi.solgun,
                        ilerleme: saksiIlerleme(saksi),
                        bitkiOlcegi: _olcek(_c.value),
                        genislik: 80,
                      ),
                    ),
                    if (_olay != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _BahceEfektBoyaci(
                              olay: _olay!,
                              t: _c.value,
                              renk: _olay == _BahceOlayi.sulama ? c.water : (c.gece ? c.accent : c.star),
                              yaprak: c.success,
                            ),
                          ),
                        ),
                      ),
                    if (saksi.bos)
                      Positioned(
                        bottom: 44,
                        child: Icon(Icons.add_circle_outline_rounded, size: 28, color: c.gece ? c.textMuted : const Color(0xFF6E5238)),
                      ),
                    if (!saksi.bos && !saksi.bugunSulandi && !saksi.olgun)
                      const Positioned(top: 4, right: 6, child: DamlaIkon(boyut: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              saksi.bos ? 'Boş' : (urun?.ad ?? ''),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: etiketRenk),
            ),
            if (!saksi.bos) ...[
              const SizedBox(height: 4),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: _BuyumeCubugu(saksi: saksi, ince: true)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Saksı olaylarının kısa efektleri: ekimde toprağa düşen tohum ve filiz
/// parıltısı, büyümede yükselen yıldızcıklar ve yapraklar, sulamada damlalar.
class _BahceEfektBoyaci extends CustomPainter {
  final _BahceOlayi olay;
  final double t;
  final Color renk;
  final Color yaprak;

  _BahceEfektBoyaci({required this.olay, required this.t, required this.renk, required this.yaprak});

  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(olay.index * 31 + 7);
    final merkez = Offset(size.width / 2, size.height * 0.55);
    switch (olay) {
      case _BahceOlayi.sulama:
        final p = Paint()..color = renk.withValues(alpha: (1 - t).clamp(0.0, 1.0));
        for (var i = 0; i < 9; i++) {
          final x = size.width * (0.25 + 0.5 * r.nextDouble());
          final gecikme = r.nextDouble() * 0.35;
          final u = ((t - gecikme) / 0.65).clamp(0.0, 1.0);
          if (u <= 0 || u >= 1) continue;
          final y = size.height * (0.05 + 0.6 * u * u);
          final path = Path()
            ..moveTo(x, y - 5)
            ..quadraticBezierTo(x + 3.5, y + 1, x, y + 3.5)
            ..quadraticBezierTo(x - 3.5, y + 1, x, y - 5);
          canvas.drawPath(path, p);
        }
      case _BahceOlayi.ekim:
      case _BahceOlayi.buyume:
        final adet = olay == _BahceOlayi.buyume ? 12 : 7;
        for (var i = 0; i < adet; i++) {
          final aci = -pi / 2 + (r.nextDouble() - 0.5) * pi * 1.1;
          final hiz = 0.25 + r.nextDouble() * 0.35;
          final u = Curves.easeOut.transform(t);
          final konum = merkez + Offset(cos(aci), sin(aci)) * (size.height * hiz * u);
          final saydam = (1 - t).clamp(0.0, 1.0);
          final boy = 2.5 + r.nextDouble() * 3;
          if (i.isEven) {
            _yildiz(canvas, konum, boy, renk.withValues(alpha: saydam));
          } else {
            canvas.save();
            canvas.translate(konum.dx, konum.dy);
            canvas.rotate(aci + t * 3);
            canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: boy * 2.2, height: boy), Paint()..color = yaprak.withValues(alpha: saydam));
            canvas.restore();
          }
        }
    }
  }

  void _yildiz(Canvas canvas, Offset o, double b, Color renk) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * pi / 4;
      final uz = i.isEven ? b * 1.6 : b * 0.55;
      final nokta = o + Offset(cos(a), sin(a)) * uz;
      i == 0 ? path.moveTo(nokta.dx, nokta.dy) : path.lineTo(nokta.dx, nokta.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = renk);
  }

  @override
  bool shouldRepaint(covariant _BahceEfektBoyaci old) => old.t != t || old.olay != olay;
}

class _BuyumeCubugu extends StatelessWidget {
  final Saksi saksi;
  final bool ince;

  const _BuyumeCubugu({required this.saksi, this.ince = false});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: (saksi.buyume / buyumeEsikleri.last).clamp(0.0, 1.0),
        minHeight: ince ? 5 : 10,
        backgroundColor: c.gece ? c.border : const Color(0xFF14532D).withValues(alpha: 0.12),
        color: saksi.solgun ? c.textMuted : c.success,
      ),
    );
  }
}
