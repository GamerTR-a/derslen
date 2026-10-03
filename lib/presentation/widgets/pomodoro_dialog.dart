import 'dart:async';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bahce_provider.dart';
import '../providers/profil_provider.dart';
import '../../core/services/supabase_data_service.dart';
import '../cizimler/cizim_widgetlari.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

/// Odak (Pomodoro) seansı — sunucu tarafında doğrulanan süreye göre yıldız
/// ödülü kazandırır (bkz. supabase_schema.sql §18 complete_study_session).
/// Ağ yoksa/oturum sunucuda oluşturulamazsa yerel sayaç yine de çalışır,
/// sadece yıldız ödülü verilmez — deneyim çevrimdışıyken bozulmaz.
class PomodoroDialog extends ConsumerStatefulWidget {
  final String konuBasligi;
  final int sureDakika;

  /// Analiz kayıtlarında (ders dağılımı) kullanılacak ders adı.
  final String? ders;

  /// Seans bittiğinde gerçekleşen dakikayla çağrılır (ör. plan bloğunu
  /// tamamlandı işaretlemek için).
  final void Function(int dakika)? onTamamlandi;

  const PomodoroDialog({
    super.key,
    required this.konuBasligi,
    required this.sureDakika,
    this.ders,
    this.onTamamlandi,
  });

  @override
  ConsumerState<PomodoroDialog> createState() => _PomodoroDialogState();
}

enum _Asama { hazir, calisiyor, duraklatildi, tamamlandi }

class _PomodoroDialogState extends ConsumerState<PomodoroDialog> {
  late int _kalanSaniye;
  Timer? _timer;
  _Asama _asama = _Asama.hazir;

  String? _sessionId;
  int? _kazanilanYildiz;
  int? _gerceklesenDakika;
  int _bakiye = 0;
  bool _bakiyeYukleniyor = true;

  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2));

  @override
  void initState() {
    super.initState();
    _kalanSaniye = widget.sureDakika * 60;
    _bakiyeYukle();
  }

  Future<void> _bakiyeYukle() async {
    final bakiye = await SupabaseDataService.getWalletBalance();
    if (!mounted) return;
    setState(() {
      _bakiye = bakiye;
      _bakiyeYukleniyor = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confetti.dispose();
    // Dialog açıkken kapatılırsa (X'e basılıp) seans kaydedilmez; yarım
    // kalan oturum sunucuda yıldızsız kapatılır.
    if (_asama == _Asama.calisiyor || _asama == _Asama.duraklatildi) {
      final id = _sessionId;
      if (id != null) {
        // ignore: discarded_futures
        SupabaseDataService.completeStudySession(id, focusMinutes: 0).catchError((_) => (0, 0));
      }
    }
    super.dispose();
  }

  Future<void> _baslat() async {
    setState(() => _asama = _Asama.calisiyor);
    _sessionId ??= await SupabaseDataService.startStudySession(
      label: widget.konuBasligi,
      plannedMinutes: widget.sureDakika,
    );
    // Oturum açılırken pencere kapatıldı ya da seans duraklatıldıysa sayaç kurulmaz.
    if (!mounted || _asama != _Asama.calisiyor) return;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_kalanSaniye > 0) {
        setState(() => _kalanSaniye--);
      } else {
        _timer?.cancel();
        _bitir();
      }
    });
  }

  void _duraklat() {
    _timer?.cancel();
    setState(() => _asama = _Asama.duraklatildi);
  }

  Future<void> _bitir() async {
    _timer?.cancel();
    final id = _sessionId;
    final gecenDakika = widget.sureDakika - (_kalanSaniye / 60).ceil();

    int aktuelDakika = gecenDakika.clamp(0, widget.sureDakika).toInt();
    int yildiz = 0;
    if (id != null) {
      try {
        final sonuc = await SupabaseDataService.completeStudySession(id, focusMinutes: aktuelDakika);
        if (sonuc.$1 > 0) aktuelDakika = sonuc.$1.clamp(0, aktuelDakika);
        yildiz = sonuc.$2;
      } catch (_) {
        // Sunucuya ulaşılamazsa yerel süre kaydedilir, yıldız verilmez.
      }
    }
    if (!mounted) return;

    if (aktuelDakika > 0) {
      await ref.read(profilProvider.notifier).calismaSuresiEkle(aktuelDakika, ders: widget.ders);
      await ref.read(bahceProvider.notifier).calismaIleBuyut(aktuelDakika);
    }
    ref.read(bahceProvider.notifier).yildizEkle(yildiz);
    widget.onTamamlandi?.call(aktuelDakika);

    if (!mounted) return;
    setState(() {
      _asama = _Asama.tamamlandi;
      _gerceklesenDakika = aktuelDakika;
      _kazanilanYildiz = yildiz;
      _bakiye += yildiz;
      _sessionId = null;
    });
    if (yildiz > 0) _confetti.play();
  }

  void _resetTimer() {
    _timer?.cancel();
    final id = _sessionId;
    if (id != null) {
      // ignore: discarded_futures
      SupabaseDataService.completeStudySession(id, focusMinutes: 0).catchError((_) => (0, 0));
      _sessionId = null;
    }
    setState(() {
      _asama = _Asama.hazir;
      _kalanSaniye = widget.sureDakika * 60;
    });
  }

  String get _dakikaFormatli {
    final d = _kalanSaniye ~/ 60;
    final s = _kalanSaniye % 60;
    return '${d.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _asama == _Asama.tamamlandi
                ? _buildTamamlandiIcerik(context)
                : _buildOdakIcerik(context),
          ),
          Positioned(
            top: -8,
            child: IgnorePointer(
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                numberOfParticles: 24,
                gravity: 0.25,
                colors: [
                  context.colors.primary,
                  context.colors.accent,
                  context.colors.success,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOdakIcerik(BuildContext context) {
    final toplamSaniye = widget.sureDakika * 60;
    final yuzde = toplamSaniye == 0 ? 0.0 : 1.0 - (_kalanSaniye / toplamSaniye);
    final calisiyor = _asama == _Asama.calisiyor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _bakiyeRozeti(context),
            IconButton(
              icon: Icon(Icons.close_rounded, color: context.colors.textMuted),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Kapat',
            ),
          ],
        ),
        Text(
          'Odak Seansı',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: context.colors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.konuBasligi,
          style: TextStyle(
            fontSize: 14,
            color: context.colors.primary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 32),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 190,
              height: 190,
              child: CircularProgressIndicator(
                value: yuzde.clamp(0.0, 1.0),
                strokeWidth: 11,
                strokeCap: StrokeCap.round,
                backgroundColor: context.colors.border,
                color: context.colors.primary,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _dakikaFormatli,
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: context.colors.textPrimary,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  calisiyor ? 'devam ediyor' : (_asama == _Asama.duraklatildi ? 'duraklatıldı' : 'başlamaya hazır'),
                  style: TextStyle(fontSize: 12, color: context.colors.textMuted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _asama == _Asama.hazir ? null : _resetTimer,
              icon: Icon(Icons.refresh_rounded, color: context.colors.textSecondary),
              iconSize: 26,
              tooltip: 'Baştan başlat',
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: calisiyor ? _duraklat : _baslat,
              style: ElevatedButton.styleFrom(
                backgroundColor: calisiyor ? context.colors.warning : context.colors.primary,
                foregroundColor: context.colors.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
              child: Text(
                calisiyor ? 'Duraklat' : (_asama == _Asama.duraklatildi ? 'Devam Et' : 'Başlat'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              onPressed: _asama == _Asama.hazir ? null : _bitir,
              icon: Icon(Icons.check_circle_outline_rounded, color: context.colors.success),
              iconSize: 26,
              tooltip: 'Şimdi bitir',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTamamlandiIcerik(BuildContext context) {
    final yildiz = _kazanilanYildiz ?? 0;
    final dakika = _gerceklesenDakika ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: context.colors.success.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_rounded, color: context.colors.success, size: 40),
        ),
        const SizedBox(height: 16),
        Text(
          'Seans tamamlandı!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: context.colors.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          '$dakika dakika odaklandın',
          style: TextStyle(fontSize: 14, color: context.colors.textSecondary),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: context.colors.primaryLight.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: yildiz > 0
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const YildizIkon(boyut: 22),
                    const SizedBox(width: 8),
                    Text(
                      '+$yildiz yıldız kazandın',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.colors.textPrimary),
                    ),
                  ],
                )
              : Text(
                  'Bu oturum için yıldız kazanılamadı (çevrimdışı ya da günlük tavan doldu).',
                  style: TextStyle(fontSize: 12.5, color: context.colors.textMuted),
                  textAlign: TextAlign.center,
                ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primary,
              foregroundColor: context.colors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text('Harika!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _bakiyeRozeti(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const YildizIkon(boyut: 14),
          const SizedBox(width: 5),
          _bakiyeYukleniyor
              ? SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.textMuted),
                )
              : Text(
                  '$_bakiye',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.colors.textPrimary),
                ),
        ],
      ),
    );
  }
}
