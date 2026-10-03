/// Hafıza oyunları: Kart Eşleştirme, Işık Sırası, Kare Hafızası, 2-Geri.
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

import 'oyun_ortak.dart';

// ─── Kart Eşleştirme ─────────────────────────────────────────

class KartEslestirme extends ConsumerStatefulWidget {
  const KartEslestirme({super.key});

  @override
  ConsumerState<KartEslestirme> createState() => _KartEslestirmeState();
}

class _KartEslestirmeState extends ConsumerState<KartEslestirme> {
  static const _ikonlar = [
    Icons.local_florist_rounded,
    Icons.star_rounded,
    Icons.favorite_rounded,
    Icons.bolt_rounded,
    Icons.music_note_rounded,
    Icons.science_rounded,
    Icons.calculate_rounded,
    Icons.menu_book_rounded,
  ];
  final _rng = Random();
  List<int> _kartlar = [];
  final Set<int> _acik = {};
  final Set<int> _bulunan = {};
  int _hamle = 0;
  bool _kilit = false;
  final Stopwatch _sure = Stopwatch();
  Timer? _tik;
  bool _bitti = false;
  bool _rekor = false;
  int _puan = 0;

  @override
  void initState() {
    super.initState();
    _basla();
  }

  void _basla() {
    _kartlar = [for (var i = 0; i < _ikonlar.length; i++) ...[i, i]]..shuffle(_rng);
    _acik.clear();
    _bulunan.clear();
    _hamle = 0;
    _bitti = false;
    _kilit = false;
    _sure
      ..reset()
      ..start();
    _tik?.cancel();
    _tik = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    setState(() {});
  }

  Future<void> _ac(int i) async {
    if (_kilit || _acik.contains(i) || _bulunan.contains(i)) return;
    HapticFeedback.selectionClick();
    setState(() => _acik.add(i));
    if (_acik.length < 2) return;
    _hamle++;
    final ikisi = _acik.toList();
    if (_kartlar[ikisi[0]] == _kartlar[ikisi[1]]) {
      setState(() {
        _bulunan.addAll(ikisi);
        _acik.clear();
      });
      if (_bulunan.length == _kartlar.length) await _bitir();
    } else {
      _kilit = true;
      await Future.delayed(const Duration(milliseconds: 750));
      if (!mounted) return;
      setState(() {
        _acik.clear();
        _kilit = false;
      });
    }
  }

  Future<void> _bitir() async {
    _sure.stop();
    _tik?.cancel();
    final sn = _sure.elapsed.inSeconds;
    // En az 8 hamlede biter; fazla hamle ve süre puanı düşürür.
    _puan = max(10, 200 - (_hamle - 8) * 8 - sn);
    final rekor = await oyunRekoruKaydet(ref, 'eslestirme', _puan);
    if (mounted) {
      setState(() {
        _bitti = true;
        _rekor = rekor;
      });
    }
  }

  @override
  void dispose() {
    _tik?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return OyunIskeleti(
      baslik: 'Kart Eşleştirme',
      govde: _bitti
          ? OyunSonucu(skor: _puan, rekor: _rekor, birim: 'puan', aciklama: '$_hamle hamle · ${_sure.elapsed.inSeconds} sn', tekrar: _basla)
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  OyunUstBar(sure: '${_sure.elapsed.inSeconds} sn', skor: '$_hamle hamle', skorIkon: Icons.touch_app_rounded),
                  const SizedBox(height: 10),
                  Text('Eş kartları bul. Ne kadar az hamle, o kadar çok puan.', style: TextStyle(color: c.textSecondary)),
                  const Spacer(),
                  AspectRatio(
                    aspectRatio: 1,
                    child: GridView.count(
                      crossAxisCount: 4,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (var i = 0; i < _kartlar.length; i++)
                          GestureDetector(
                            onTap: () => _ac(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              decoration: BoxDecoration(
                                color: _bulunan.contains(i)
                                    ? c.success.withValues(alpha: 0.18)
                                    : (_acik.contains(i) ? c.surface : c.primary),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _bulunan.contains(i) ? c.success : c.border),
                              ),
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  transitionBuilder: (w, a) => ScaleTransition(scale: a, child: w),
                                  child: _acik.contains(i) || _bulunan.contains(i)
                                      ? Icon(_ikonlar[_kartlar[i]], key: ValueKey('a$i'), size: 30, color: _bulunan.contains(i) ? c.success : c.primary)
                                      : Icon(Icons.help_outline_rounded, key: ValueKey('k$i'), size: 22, color: c.onPrimary.withValues(alpha: 0.6)),
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

// ─── Işık Sırası (Simon) ─────────────────────────────────────

class IsikSirasi extends ConsumerStatefulWidget {
  const IsikSirasi({super.key});

  @override
  ConsumerState<IsikSirasi> createState() => _IsikSirasiState();
}

enum _SimonAsama { izle, tekrarla, bitti }

class _IsikSirasiState extends ConsumerState<IsikSirasi> {
  static const _renkler = [Color(0xFF22C55E), Color(0xFFEF4444), Color(0xFFEAB308), Color(0xFF3B82F6), Color(0xFFA855F7), Color(0xFFF97316)];
  final _rng = Random();
  final List<int> _sira = [];
  int _girilen = 0;
  int? _yanan;
  _SimonAsama _asama = _SimonAsama.izle;
  bool _rekor = false;
  bool _iptal = false;

  int get _seviye => max(0, _sira.length - 1);

  @override
  void initState() {
    super.initState();
    _yeniOyun();
  }

  @override
  void dispose() {
    _iptal = true;
    super.dispose();
  }

  void _yeniOyun() {
    _sira.clear();
    _rekor = false;
    _ekle();
  }

  Future<void> _ekle() async {
    _sira.add(_rng.nextInt(_renkler.length));
    _girilen = 0;
    setState(() => _asama = _SimonAsama.izle);
    await Future.delayed(const Duration(milliseconds: 700));
    final hiz = max(260, 620 - _sira.length * 25);
    for (final r in _sira) {
      if (_iptal || !mounted) return;
      setState(() => _yanan = r);
      await Future.delayed(Duration(milliseconds: hiz));
      if (_iptal || !mounted) return;
      setState(() => _yanan = null);
      await Future.delayed(const Duration(milliseconds: 180));
    }
    if (mounted) setState(() => _asama = _SimonAsama.tekrarla);
  }

  Future<void> _bas(int i) async {
    if (_asama != _SimonAsama.tekrarla) return;
    HapticFeedback.selectionClick();
    setState(() => _yanan = i);
    Future.delayed(const Duration(milliseconds: 160), () {
      if (mounted && _yanan == i) setState(() => _yanan = null);
    });
    if (_sira[_girilen] != i) {
      HapticFeedback.heavyImpact();
      final rekor = await oyunRekoruKaydet(ref, 'simon', _seviye);
      if (mounted) {
        setState(() {
          _rekor = rekor;
          _asama = _SimonAsama.bitti;
        });
      }
      return;
    }
    _girilen++;
    if (_girilen == _sira.length) {
      HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) await _ekle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return OyunIskeleti(
      baslik: 'Işık Sırası',
      govde: _asama == _SimonAsama.bitti
          ? OyunSonucu(skor: _seviye, rekor: _rekor, birim: 'adım', tekrar: () => setState(_yeniOyun))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  OyunUstBar(skor: '${_sira.length}. tur', skorIkon: Icons.flag_rounded),
                  const SizedBox(height: 12),
                  Text(
                    _asama == _SimonAsama.izle ? 'Yanan ışıkları sırasıyla izle…' : 'Şimdi aynı sırayla dokun (${_girilen + 1}/${_sira.length})',
                    style: TextStyle(fontWeight: FontWeight.w700, color: c.textSecondary),
                  ),
                  const Spacer(),
                  AspectRatio(
                    aspectRatio: 3 / 2,
                    child: GridView.count(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (var i = 0; i < _renkler.length; i++)
                          GestureDetector(
                            onTap: () => _bas(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              decoration: BoxDecoration(
                                color: _renkler[i].withValues(alpha: _yanan == i ? 1 : 0.28),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: _yanan == i ? [BoxShadow(color: _renkler[i].withValues(alpha: 0.6), blurRadius: 18)] : null,
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

// ─── Kare Hafızası ───────────────────────────────────────────

class KareHafizasi extends ConsumerStatefulWidget {
  const KareHafizasi({super.key});

  @override
  ConsumerState<KareHafizasi> createState() => _KareHafizasiState();
}

class _KareHafizasiState extends ConsumerState<KareHafizasi> {
  final _rng = Random();
  int _tur = 1;
  int _can = 3;
  Set<int> _hedef = {};
  final Set<int> _secilen = {};
  bool _goster = true;
  bool _bitti = false;
  bool _rekor = false;
  Set<int> _hatali = {};
  Timer? _timer;

  int get _boyut => _tur < 3 ? 3 : (_tur < 7 ? 4 : 5);
  int get _kareSayisi => min(2 + _tur, _boyut * _boyut - 2);

  @override
  void initState() {
    super.initState();
    _yeniTur();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _yeniTur() {
    final n = _boyut * _boyut;
    final havuz = List.generate(n, (i) => i)..shuffle(_rng);
    _hedef = havuz.take(_kareSayisi).toSet();
    _secilen.clear();
    _hatali = {};
    setState(() => _goster = true);
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: 900 + _kareSayisi * 180), () {
      if (mounted) setState(() => _goster = false);
    });
  }

  Future<void> _sec(int i) async {
    if (_goster || _secilen.contains(i) || _hatali.contains(i)) return;
    if (_hedef.contains(i)) {
      HapticFeedback.selectionClick();
      setState(() => _secilen.add(i));
      if (_secilen.length == _hedef.length) {
        await Future.delayed(const Duration(milliseconds: 350));
        if (!mounted) return;
        _tur++;
        _yeniTur();
      }
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _hatali.add(i);
        _can--;
      });
      if (_can <= 0) {
        final skor = _tur - 1;
        final rekor = await oyunRekoruKaydet(ref, 'kare', skor);
        if (mounted) {
          setState(() {
            _rekor = rekor;
            _bitti = true;
          });
        }
      } else {
        // Hatalı turda desen yeniden gösterilir.
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) _yeniTur();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return OyunIskeleti(
      baslik: 'Kare Hafızası',
      govde: _bitti
          ? OyunSonucu(
              skor: _tur - 1,
              rekor: _rekor,
              birim: 'tur',
              tekrar: () {
                _tur = 1;
                _can = 3;
                _bitti = false;
                _yeniTur();
              },
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  OyunUstBar(
                    skor: '$_tur. tur',
                    skorIkon: Icons.flag_rounded,
                    orta: Row(
                      children: [for (var i = 0; i < 3; i++) Icon(i < _can ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: c.danger, size: 22)],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(_goster ? '$_kareSayisi kareyi aklında tut…' : 'Yanan kareleri işaretle', style: TextStyle(fontWeight: FontWeight.w700, color: c.textSecondary)),
                  const Spacer(),
                  AspectRatio(
                    aspectRatio: 1,
                    child: GridView.count(
                      crossAxisCount: _boyut,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (var i = 0; i < _boyut * _boyut; i++)
                          GestureDetector(
                            onTap: () => _sec(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              decoration: BoxDecoration(
                                color: _hatali.contains(i)
                                    ? c.danger.withValues(alpha: 0.6)
                                    : ((_goster && _hedef.contains(i)) || _secilen.contains(i) ? c.primary : c.surface),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: c.border),
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

// ─── 2-Geri (N-Back) ─────────────────────────────────────────

class IkiGeri extends ConsumerStatefulWidget {
  const IkiGeri({super.key});

  @override
  ConsumerState<IkiGeri> createState() => _IkiGeriState();
}

class _IkiGeriState extends ConsumerState<IkiGeri> {
  static const _harfler = ['A', 'B', 'C', 'D', 'E', 'H', 'K', 'M'];
  static const _toplam = 24;
  final _rng = Random();
  final List<String> _dizi = [];
  int _i = -1;
  bool _basildi = false;
  int _dogru = 0;
  int _yanlis = 0;
  bool _bitti = false;
  bool _rekor = false;
  Color? _geriBildirim;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _basla();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _basla() {
    _dizi.clear();
    for (var k = 0; k < _toplam; k++) {
      // Yaklaşık üçte bir olasılıkla 2 önceki harf tekrar edilir.
      if (k >= 2 && _rng.nextDouble() < 0.33) {
        _dizi.add(_dizi[k - 2]);
      } else {
        String h;
        do {
          h = _harfler[_rng.nextInt(_harfler.length)];
        } while (k >= 2 && h == _dizi[k - 2]);
        _dizi.add(h);
      }
    }
    _i = -1;
    _dogru = 0;
    _yanlis = 0;
    _bitti = false;
    _rekor = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 2200), (_) => _ilerle());
    _ilerle();
  }

  bool get _eslesme => _i >= 2 && _dizi[_i] == _dizi[_i - 2];

  Future<void> _ilerle() async {
    // Önceki harf için basılmayan eşleşme kaçırılmış sayılır.
    if (_i >= 2 && !_basildi && _eslesme) _yanlis++;
    if (_i + 1 >= _dizi.length) {
      _timer?.cancel();
      final rekor = await oyunRekoruKaydet(ref, 'ikigeri', _dogru);
      if (mounted) {
        setState(() {
          _bitti = true;
          _rekor = rekor;
          _geriBildirim = null;
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _i++;
      _basildi = false;
      _geriBildirim = null;
    });
  }

  void _ayni() {
    if (_bitti || _basildi || _i < 0) return;
    _basildi = true;
    final dogru = _eslesme;
    dogru ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
    setState(() {
      if (dogru) {
        _dogru++;
      } else {
        _yanlis++;
      }
      _geriBildirim = dogru ? context.colors.success : context.colors.danger;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return OyunIskeleti(
      baslik: '2-Geri',
      govde: _bitti
          ? OyunSonucu(
              skor: _dogru,
              rekor: _rekor,
              birim: 'doğru',
              aciklama: '$_yanlis hata (yanlış basma veya kaçırılan eşleşme) · doğruluk %${(_dogru * 100 / max(1, _dogru + _yanlis)).round()}',
              tekrar: () => setState(_basla),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  OyunUstBar(sure: '${max(0, _i + 1)}/$_toplam', skor: '$_dogru', orta: Text('$_yanlis hata', style: TextStyle(color: c.danger, fontWeight: FontWeight.w700))),
                  const SizedBox(height: 12),
                  Text('Ekrandaki harf, iki önceki harfle aynıysa “Aynı” düğmesine bas.',
                      textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 160,
                    height: 160,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: (_geriBildirim ?? c.primary).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: _geriBildirim ?? c.border, width: 2),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Text(_i < 0 ? '' : _dizi[_i], key: ValueKey(_i), style: context.baslik(72)),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: FilledButton(
                      onPressed: _ayni,
                      style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                      child: const Text('Aynı', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
    );
  }
}
