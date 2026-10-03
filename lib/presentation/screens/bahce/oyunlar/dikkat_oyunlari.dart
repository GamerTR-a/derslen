/// Dikkat oyunları: Schulte Tablosu, Farklı Rengi Bul, Ok Yönü.
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

import 'oyun_ortak.dart';

// ─── Schulte Tablosu ─────────────────────────────────────────

class SchulteTablosu extends ConsumerStatefulWidget {
  const SchulteTablosu({super.key});

  @override
  ConsumerState<SchulteTablosu> createState() => _SchulteTablosuState();
}

class _SchulteTablosuState extends ConsumerState<SchulteTablosu> {
  static const _n = 25;
  final _rng = Random();
  List<int> _sayilar = [];
  int _siradaki = 1;
  int? _hataliIndex;
  final Stopwatch _sure = Stopwatch();
  Timer? _tik;
  bool _bitti = false;
  bool _rekor = false;

  @override
  void initState() {
    super.initState();
    _basla();
  }

  @override
  void dispose() {
    _tik?.cancel();
    super.dispose();
  }

  void _basla() {
    _sayilar = List.generate(_n, (i) => i + 1)..shuffle(_rng);
    _siradaki = 1;
    _bitti = false;
    _sure
      ..reset()
      ..start();
    _tik?.cancel();
    _tik = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted) setState(() {});
    });
    setState(() {});
  }

  Future<void> _bas(int index) async {
    if (_bitti) return;
    if (_sayilar[index] == _siradaki) {
      HapticFeedback.selectionClick();
      setState(() => _siradaki++);
      if (_siradaki > _n) {
        _sure.stop();
        _tik?.cancel();
        final rekor = await oyunRekoruKaydet(ref, 'schulte', _sure.elapsed.inSeconds, azIyi: true);
        if (mounted) {
          setState(() {
            _bitti = true;
            _rekor = rekor;
          });
        }
      }
    } else {
      HapticFeedback.heavyImpact();
      setState(() => _hataliIndex = index);
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) setState(() => _hataliIndex = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final sn = (_sure.elapsedMilliseconds / 1000).toStringAsFixed(1);
    return OyunIskeleti(
      baslik: 'Schulte Tablosu',
      govde: _bitti
          ? OyunSonucu(
              skor: _sure.elapsed.inSeconds,
              rekor: _rekor,
              birim: 'saniye',
              aciklama: 'Bakışını merkezde tutup çevreyi görmeye çalışmak, okuma hızını ve görsel dikkati geliştirir.',
              tekrar: _basla,
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  OyunUstBar(sure: '$sn sn', skor: _siradaki > _n ? 'Bitti' : 'Sıradaki: $_siradaki', skorIkon: Icons.search_rounded),
                  const SizedBox(height: 12),
                  Text('1\'den 25\'e kadar sayılara sırayla dokun.', style: TextStyle(color: c.textSecondary, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  AspectRatio(
                    aspectRatio: 1,
                    child: GridView.count(
                      crossAxisCount: 5,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (var i = 0; i < _n; i++)
                          GestureDetector(
                            onTap: () => _bas(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _hataliIndex == i
                                    ? c.danger.withValues(alpha: 0.3)
                                    : (_sayilar[i] < _siradaki ? c.success.withValues(alpha: 0.16) : c.surface),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: c.border),
                              ),
                              child: Text(
                                '${_sayilar[i]}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: _sayilar[i] < _siradaki ? c.textMuted : c.textPrimary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
    );
  }
}

// ─── Farklı Rengi Bul ────────────────────────────────────────

class FarkliRenk extends ConsumerStatefulWidget {
  const FarkliRenk({super.key});

  @override
  ConsumerState<FarkliRenk> createState() => _FarkliRenkState();
}

class _FarkliRenkState extends ConsumerState<FarkliRenk> {
  final _rng = Random();
  final _sayac = GeriSayim();
  int _skor = 0;
  int _farkli = 0;
  Color _taban = Colors.teal;
  Color _fark = Colors.teal;
  bool _bitti = false;
  bool _rekor = false;

  int get _boyut => min(2 + _skor ~/ 3, 7);

  @override
  void initState() {
    super.initState();
    _basla();
  }

  @override
  void dispose() {
    _sayac.durdur();
    super.dispose();
  }

  void _basla() {
    _skor = 0;
    _bitti = false;
    _rekor = false;
    _yeni();
    _sayac.baslat(
      45,
      tik: () {
        if (mounted) setState(() {});
      },
      bitti: () async {
        final rekor = await oyunRekoruKaydet(ref, 'farklirenk', _skor);
        if (mounted) {
          setState(() {
            _bitti = true;
            _rekor = rekor;
          });
        }
      },
    );
  }

  void _yeni() {
    final h = _rng.nextDouble() * 360;
    final s = 0.45 + _rng.nextDouble() * 0.35;
    const l = 0.55;
    _taban = HSLColor.fromAHSL(1, h, s, l).toColor();
    // Seviye arttıkça açıklık farkı küçülür (zorlaşır).
    final fark = max(0.035, 0.2 - _skor * 0.008);
    _fark = HSLColor.fromAHSL(1, h, s, (l + (_rng.nextBool() ? fark : -fark)).clamp(0.0, 1.0)).toColor();
    _farkli = _rng.nextInt(_boyut * _boyut);
    setState(() {});
  }

  void _sec(int i) {
    if (_bitti) return;
    if (i == _farkli) {
      HapticFeedback.lightImpact();
      _skor++;
    } else {
      HapticFeedback.heavyImpact();
      _sayac.kalan = max(1, _sayac.kalan - 3);
    }
    _yeni();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return OyunIskeleti(
      baslik: 'Farklı Rengi Bul',
      govde: _bitti
          ? OyunSonucu(skor: _skor, rekor: _rekor, birim: 'doğru', tekrar: _basla)
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  OyunUstBar(sure: '${_sayac.kalan} sn', skor: '$_skor'),
                  const SizedBox(height: 12),
                  Text('Tonu diğerlerinden farklı olan kareye dokun. Yanlış seçim 3 saniye götürür.',
                      textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  AspectRatio(
                    aspectRatio: 1,
                    child: GridView.count(
                      crossAxisCount: _boyut,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (var i = 0; i < _boyut * _boyut; i++)
                          GestureDetector(
                            onTap: () => _sec(i),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: i == _farkli ? _fark : _taban,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
    );
  }
}

// ─── Ok Yönü (Flanker) ───────────────────────────────────────

class OkYonu extends ConsumerStatefulWidget {
  const OkYonu({super.key});

  @override
  ConsumerState<OkYonu> createState() => _OkYonuState();
}

class _OkYonuState extends ConsumerState<OkYonu> {
  final _rng = Random();
  final _sayac = GeriSayim();
  int _skor = 0;
  bool _sag = true;
  bool _uyumlu = true;
  bool _bitti = false;
  bool _rekor = false;
  bool? _son;

  @override
  void initState() {
    super.initState();
    _basla();
  }

  @override
  void dispose() {
    _sayac.durdur();
    super.dispose();
  }

  void _basla() {
    _skor = 0;
    _bitti = false;
    _rekor = false;
    _son = null;
    _yeni();
    _sayac.baslat(
      30,
      tik: () {
        if (mounted) setState(() {});
      },
      bitti: () async {
        final rekor = await oyunRekoruKaydet(ref, 'okyonu', _skor);
        if (mounted) {
          setState(() {
            _bitti = true;
            _rekor = rekor;
          });
        }
      },
    );
  }

  void _yeni() {
    _sag = _rng.nextBool();
    _uyumlu = _rng.nextDouble() < 0.4;
    setState(() {});
  }

  void _cevap(bool sag) {
    if (_bitti) return;
    final dogru = sag == _sag;
    dogru ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
    _skor = max(0, _skor + (dogru ? 1 : -1));
    _son = dogru;
    _yeni();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final orta = _sag ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded;
    final yan = (_uyumlu ? _sag : !_sag) ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded;
    return OyunIskeleti(
      baslik: 'Ok Yönü',
      govde: _bitti
          ? OyunSonucu(skor: _skor, rekor: _rekor, birim: 'puan', tekrar: _basla)
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  OyunUstBar(sure: '${_sayac.kalan} sn', skor: '$_skor'),
                  const SizedBox(height: 12),
                  Text('Yalnızca ORTADAKİ okun yönünü seç; yandakiler seni yanıltmaya çalışır.',
                      textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
                    decoration: BoxDecoration(
                      color: _son == null ? c.surface : (_son! ? c.success : c.danger).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < 5; i++)
                          Icon(i == 2 ? orta : yan, size: 48, color: i == 2 ? c.textPrimary : c.textSecondary),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 64,
                          child: FilledButton.tonal(
                            onPressed: () => _cevap(false),
                            child: const Icon(Icons.arrow_back_rounded, size: 34),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 64,
                          child: FilledButton.tonal(
                            onPressed: () => _cevap(true),
                            child: const Icon(Icons.arrow_forward_rounded, size: 34),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
    );
  }
}
