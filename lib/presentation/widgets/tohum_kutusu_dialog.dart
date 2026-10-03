import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/bahce_data.dart';
import '../cizimler/cizim_widgetlari.dart';
import '../cizimler/svg_cizimler.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

/// Onboarding sonunda açılan sürpriz tohum kutusu. Kullanıcı kutuya
/// dokununca kutu sallanır, kapağı açılır ve tohum çıkar.
class TohumKutusuDialog extends StatefulWidget {
  final String tohumId;

  const TohumKutusuDialog({super.key, required this.tohumId});

  static Future<void> goster(BuildContext context, String tohumId) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      pageBuilder: (_, _, _) => TohumKutusuDialog(tohumId: tohumId),
    );
  }

  @override
  State<TohumKutusuDialog> createState() => _TohumKutusuDialogState();
}

class _TohumKutusuDialogState extends State<TohumKutusuDialog> with TickerProviderStateMixin {
  late final AnimationController _bekle =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
  late final AnimationController _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  late final ConfettiController _confetti = ConfettiController(duration: const Duration(seconds: 2));
  bool _acildi = false;

  @override
  void dispose() {
    _bekle.dispose();
    _ac.dispose();
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _kutuyuAc() async {
    if (_acildi) return;
    HapticFeedback.mediumImpact();
    setState(() => _acildi = true);
    _bekle.stop();
    await _ac.forward();
    if (!mounted) return;
    setState(() {});
    HapticFeedback.heavyImpact();
    _confetti.play();
  }

  @override
  Widget build(BuildContext context) {
    final urun = bahceUrunuBul(widget.tohumId);
    final hareketsiz = MediaQuery.of(context).disableAnimations;

    return Material(
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            margin: const EdgeInsets.all(28),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(32)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _acildi ? 'İlk tohumun geldi!' : 'Sana bir sürprizimiz var',
                  textAlign: TextAlign.center,
                  style: context.baslik(26),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 180,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_bekle, _ac]),
                    builder: (_, _) {
                      final t = _ac.value;
                      final salla = !_acildi && !hareketsiz ? sin(_bekle.value * pi * 4) * 0.06 : (t < 0.35 ? sin(t * 60) * 0.12 * (1 - t / 0.35) : 0.0);
                      final kapakY = t < 0.35 ? 0.0 : -Curves.easeOut.transform(((t - 0.35) / 0.4).clamp(0, 1)) * 90;
                      final kapakOpak = t < 0.6 ? 1.0 : (1 - (t - 0.6) / 0.3).clamp(0.0, 1.0);
                      final tohumOlcek = t < 0.45 ? 0.0 : Curves.elasticOut.transform(((t - 0.45) / 0.55).clamp(0, 1));
                      final kutuOpak = t < 0.55 ? 1.0 : (1 - (t - 0.55) / 0.35).clamp(0.0, 1.0);
                      return Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Opacity(
                            opacity: kutuOpak,
                            child: Transform.rotate(
                              angle: salla,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Transform.translate(
                                    offset: Offset(0, kapakY),
                                    child: Opacity(opacity: kapakOpak, child: _kapak()),
                                  ),
                                  _govde(),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 30,
                            child: Transform.scale(
                              scale: tohumOlcek,
                              child: Column(
                                children: [
                                  Cizim(bitkiSvg(widget.tohumId, 3, gece: context.colors.gece), width: 96, height: 120),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _acildi
                      ? Text(
                          '${urun?.ad ?? 'Bir tohum'} çıktı! Bahçendeki ilk saksıya ekildi. Odaklandıkça ve suladıkça büyüyecek.',
                          key: const ValueKey('acik'),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, color: context.colors.textSecondary, height: 1.4),
                        )
                      : Text(
                          'Açmak için kutuya dokun',
                          key: const ValueKey('kapali'),
                          style: TextStyle(fontSize: 15, color: context.colors.textMuted),
                        ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: _acildi ? (_ac.isCompleted ? () => Navigator.of(context).pop() : null) : _kutuyuAc,
                    style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                    child: Text(_acildi ? 'Hadi başlayalım' : 'Kutuyu aç',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _acildi ? null : _kutuyuAc,
              child: const SizedBox.expand(),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: IgnorePointer(
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                numberOfParticles: 40,
                gravity: 0.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kapak() => Cizim(kutuKapakSvg(gece: context.colors.gece), width: 150, height: 62);

  Widget _govde() => Cizim(kutuGovdeSvg(gece: context.colors.gece), width: 130, height: 98);
}
