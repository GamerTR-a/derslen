/// Yeni sekmelerde ortak kullanılan yumuşak, sade yapı taşları.
library;

import 'package:flutter/material.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

class YumusakKart extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? renk;
  final Gradient? gradient;

  const YumusakKart({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.renk,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final koyu = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: gradient == null ? (renk ?? context.colors.surface) : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(22),
          border: koyu ? Border.all(color: context.colors.border) : null,
          boxShadow: koyu
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class BolumBasligi extends StatelessWidget {
  final String baslik;
  final String? aksiyon;
  final VoidCallback? onAksiyon;

  const BolumBasligi(this.baslik, {super.key, this.aksiyon, this.onAksiyon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              baslik,
              style: context.baslik(19),
            ),
          ),
          if (aksiyon != null)
            TextButton(
              onPressed: onAksiyon,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 40),
                foregroundColor: context.colors.primary,
              ),
              child: Text(aksiyon!, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

/// Yıldız, damla gibi sayaç rozetleri.
class SayacRozeti extends StatelessWidget {
  final String? emoji;
  final Widget? ikon;
  final String deger;
  final Color renk;
  final String? semantik;

  const SayacRozeti({super.key, this.emoji, this.ikon, required this.deger, required this.renk, this.semantik});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semantik,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: renk.withValues(alpha: context.colors.gece ? 0.18 : 0.16),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ikon ?? Text(emoji ?? '', style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 5),
            Text(deger, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: context.colors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

/// Hap şeklinde seçilebilir buton (süre, ders, sahne seçimleri).
class HapSecim extends StatelessWidget {
  final String etiket;
  final bool secili;
  final VoidCallback? onTap;

  const HapSecim({super.key, required this.etiket, required this.secili, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: secili,
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: secili ? context.colors.primary : context.colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: secili ? context.colors.primary : context.colors.border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Center(
                widthFactor: 1,
                child: Text(
                  etiket,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: secili ? context.colors.onPrimary : (onTap == null ? context.colors.textMuted : context.colors.textSecondary),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
