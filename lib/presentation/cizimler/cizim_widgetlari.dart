/// SVG illüstrasyonları çizen ve canlandıran widget'lar.
library;

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';
import 'svg_cizimler.dart';

export 'canli_maskot.dart' show Maskot, MaskotRuh, MaskotBoyaci, maskotKarakterleri;

bool hareketAzalt(BuildContext context) => MediaQuery.of(context).disableAnimations;

class Cizim extends StatelessWidget {
  final String svg;
  final double? width;
  final double? height;
  final String? etiket;

  const Cizim(this.svg, {super.key, this.width, this.height, this.etiket});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      svg,
      width: width,
      height: height,
      semanticsLabel: etiket,
      excludeFromSemantics: etiket == null,
    );
  }
}

class YildizIkon extends StatelessWidget {
  final double boyut;
  const YildizIkon({super.key, this.boyut = 16});

  @override
  Widget build(BuildContext context) => Cizim(yildizSvg(context.colors.star.toARGB32()), width: boyut, height: boyut);
}

class DamlaIkon extends StatelessWidget {
  final double boyut;
  const DamlaIkon({super.key, this.boyut = 16});

  @override
  Widget build(BuildContext context) => Cizim(damlaSvg(context.colors.water.toARGB32()), width: boyut * 0.84, height: boyut);
}

class AlevIkon extends StatelessWidget {
  final double boyut;
  const AlevIkon({super.key, this.boyut = 16});

  @override
  Widget build(BuildContext context) => Cizim(alevSvg(0xFFF08A4B), width: boyut, height: boyut);
}

/// Esintide salınan sarmalayıcı (tabandan döner). Her örnek farklı fazda başlar.
class Salinan extends StatefulWidget {
  final Widget child;
  final bool aktif;
  final double aci;
  final Duration sure;
  final Alignment eksen;

  const Salinan({
    super.key,
    required this.child,
    this.aktif = true,
    this.aci = 0.05,
    this.sure = const Duration(milliseconds: 3400),
    this.eksen = Alignment.bottomCenter,
  });

  @override
  State<Salinan> createState() => _SalinanState();
}

class _SalinanState extends State<Salinan> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.sure)
      ..value = Random().nextDouble()
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.aktif || hareketAzalt(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.rotate(
        angle: (Curves.easeInOut.transform(_c.value) - 0.5) * 2 * widget.aci,
        alignment: widget.eksen,
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Yukarı-aşağı yumuşak nefes hareketi.
class Nefes extends StatefulWidget {
  final Widget child;
  final double genlik;
  final bool aktif;

  const Nefes({super.key, required this.child, this.genlik = 6, this.aktif = true});

  @override
  State<Nefes> createState() => _NefesState();
}

class _NefesState extends State<Nefes> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.aktif || hareketAzalt(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, -Curves.easeInOut.transform(_c.value) * widget.genlik),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Gece temasında bitkilerin arkasındaki yumuşak parıltı.
class Parilti extends StatefulWidget {
  final Color renk;
  final double boyut;
  const Parilti({super.key, required this.renk, required this.boyut});

  @override
  State<Parilti> createState() => _ParlitiState();
}

class _ParlitiState extends State<Parilti> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))
      ..value = Random().nextDouble()
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sabit = hareketAzalt(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Container(
        width: widget.boyut,
        height: widget.boyut,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            widget.renk.withValues(alpha: sabit ? 0.35 : 0.22 + 0.22 * _c.value),
            widget.renk.withValues(alpha: 0),
          ]),
        ),
      ),
    );
  }
}

/// Saksısıyla birlikte bir bitki. [bitkiId] null ise boş saksı çizer.
///
/// [ilerleme] bulunulan aşama içindeki büyüme oranıdır (0..1); filiz ve fide
/// bir sonraki aşamaya yaklaştıkça yavaşça büyür. [bitkiOlcegi] dışarıdan
/// verilen animasyon ölçeğidir (ör. aşama atlarken "boy atma").
class SaksiliBitki extends StatelessWidget {
  final String? bitkiId;
  final int asama;
  final bool solgun;
  final double genislik;
  final double ilerleme;
  final double bitkiOlcegi;

  const SaksiliBitki({
    super.key,
    this.bitkiId,
    this.asama = 0,
    this.solgun = false,
    this.genislik = 80,
    this.ilerleme = 1,
    this.bitkiOlcegi = 1,
  });

  double get _boy => (asama == 1 || asama == 2) ? 0.8 + 0.2 * ilerleme.clamp(0.0, 1.0) : 1.0;

  @override
  Widget build(BuildContext context) {
    final gece = context.colors.gece;
    final bitkiYukseklik = genislik * 1.25;
    final saksiYukseklik = genislik * 0.55;
    final sure = hareketAzalt(context) ? Duration.zero : const Duration(milliseconds: 900);
    return SizedBox(
      width: genislik,
      height: bitkiYukseklik + saksiYukseklik - genislik * 0.08,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          if (gece && bitkiId != null && !solgun)
            Positioned(
              bottom: saksiYukseklik * 0.6,
              child: Parilti(renk: asama >= 3 ? context.colors.success : context.colors.primary, boyut: genislik * 1.3),
            ),
          if (bitkiId != null)
            Positioned(
              bottom: saksiYukseklik - genislik * 0.08,
              child: Opacity(
                opacity: solgun ? 0.75 : 1,
                child: Salinan(
                  aktif: !solgun && asama > 0,
                  aci: 0.03 + 0.012 * asama,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: _boy),
                    duration: sure,
                    curve: Curves.easeOutBack,
                    builder: (_, boy, child) => Transform.scale(
                      scale: boy * bitkiOlcegi,
                      alignment: Alignment.bottomCenter,
                      child: child,
                    ),
                    child: Cizim(bitkiSvg(bitkiId!, asama, gece: gece, solgun: solgun), width: genislik, height: bitkiYukseklik),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            child: Cizim(saksiSvg(gece: gece, bos: bitkiId == null), width: genislik, height: saksiYukseklik),
          ),
        ],
      ),
    );
  }
}

/// Mağaza ve envanter için olgun bitki / dekor önizlemesi.
class UrunCizimi extends StatelessWidget {
  final String urunId;
  final double boyut;
  const UrunCizimi({super.key, required this.urunId, this.boyut = 56});

  @override
  Widget build(BuildContext context) {
    final gece = context.colors.gece;
    if (urunId.startsWith('seed_')) {
      return Cizim(bitkiSvg(urunId, 3, gece: gece), width: boyut * 0.8, height: boyut);
    }
    if (urunId.startsWith('pot_')) {
      return Cizim(saksiSvg(gece: gece), width: boyut, height: boyut * 0.55);
    }
    return Cizim(dekorSvg(urunId, gece: gece), width: boyut, height: boyut);
  }
}
