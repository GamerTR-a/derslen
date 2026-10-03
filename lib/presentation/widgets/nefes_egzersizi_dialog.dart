import 'dart:async';
import 'package:flutter/material.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

class NefesEgzersiziDialog extends StatefulWidget {
  const NefesEgzersiziDialog({super.key});

  @override
  State<NefesEgzersiziDialog> createState() => _NefesEgzersiziDialogState();
}

class _NefesEgzersiziDialogState extends State<NefesEgzersiziDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  Timer? _phaseTimer;

  String _fazMesaji = 'Derin Nefes Al...';
  int _sayac = 4;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.8).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _startExercise();
  }

  void _startExercise() {
    _animController.forward();
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_sayac > 1) {
          _sayac--;
        } else {
          if (_fazMesaji.contains('Al')) {
            _fazMesaji = 'Nefesini Tut...';
            _sayac = 4;
          } else if (_fazMesaji.contains('Tut')) {
            _fazMesaji = 'Yavaşça Ver...';
            _sayac = 4;
            _animController.reverse();
          } else {
            _fazMesaji = 'Derin Nefes Al...';
            _sayac = 4;
            _animController.forward();
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nefes & Odaklanma',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: context.colors.textMuted),
                  tooltip: 'Kapat',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _fazMesaji,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.colors.success),
            ),
            const SizedBox(height: 36),

            // Animasyonlu Nefes Dairesi
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          context.colors.success.withValues(alpha: 0.9),
                          context.colors.success.withValues(alpha: 0.5),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: context.colors.success.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$_sayac',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: context.colors.onPrimary),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 48),
            Text(
              '4-4-4 Kutu Nefes Tekniği ile zihnini sakinleştir ve strese son ver.',
              style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.success,
                foregroundColor: context.colors.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              child: Text('Tamamla ve Çalışmaya Dön', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

