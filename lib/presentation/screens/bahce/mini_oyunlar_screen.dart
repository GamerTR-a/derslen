import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'oyunlar/dikkat_oyunlari.dart';
import 'oyunlar/hafiza_oyunlari.dart';
import 'oyunlar/mantik_oyunlari.dart';
import 'oyunlar/oyun_ortak.dart';
import '../../widgets/ui_kit.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

enum _OyunKategori {
  hafiza('Hafıza', Icons.psychology_rounded),
  dikkat('Dikkat', Icons.center_focus_strong_rounded),
  hiz('Hız', Icons.speed_rounded),
  problem('Problem Çözme', Icons.extension_rounded),
  dil('Dil', Icons.translate_rounded);

  const _OyunKategori(this.ad, this.ikon);
  final String ad;
  final IconData ikon;
}

class _Oyun {
  final String id;
  final IconData ikon;
  final String ad;
  final String aciklama;
  final _OyunKategori kategori;
  final String birim;
  final bool azIyi;
  final Widget Function() sayfa;

  const _Oyun(this.id, this.ikon, this.ad, this.aciklama, this.kategori, this.birim, this.sayfa, {this.azIyi = false});
}

final List<_Oyun> _oyunlar = [
  _Oyun('hafiza', Icons.pin_rounded, 'Sayı Hafızası', 'Gösterilen sayıyı aklında tut, basamaklar uzar', _OyunKategori.hafiza, 'basamak', () => const _SayiHafizasi()),
  _Oyun('eslestirme', Icons.grid_view_rounded, 'Kart Eşleştirme', 'Kapalı kartlardan eşleri en az hamlede bul', _OyunKategori.hafiza, 'puan', () => const KartEslestirme()),
  _Oyun('simon', Icons.lightbulb_rounded, 'Işık Sırası', 'Yanan ışıkların sırasını tekrarla', _OyunKategori.hafiza, 'adım', () => const IsikSirasi()),
  _Oyun('kare', Icons.apps_rounded, 'Kare Hafızası', 'Bir anlık yanan kareleri hatırla', _OyunKategori.hafiza, 'tur', () => const KareHafizasi()),
  _Oyun('ikigeri', Icons.history_rounded, '2-Geri', 'Harf iki önceki harfle aynı mı? Çalışma belleği', _OyunKategori.hafiza, 'doğru', () => const IkiGeri()),
  _Oyun('stroop', Icons.palette_rounded, 'Renk Tuzağı', 'Kelimeyi değil, yazının rengini seç', _OyunKategori.dikkat, 'puan', () => const _RenkTuzagi()),
  _Oyun('schulte', Icons.format_list_numbered_rounded, 'Schulte Tablosu', '1\'den 25\'e sayıları sırayla bul', _OyunKategori.dikkat, 'sn', () => const SchulteTablosu(), azIyi: true),
  _Oyun('farklirenk', Icons.invert_colors_rounded, 'Farklı Rengi Bul', 'Tonu farklı kareyi yakala', _OyunKategori.dikkat, 'doğru', () => const FarkliRenk()),
  _Oyun('okyonu', Icons.swap_horiz_rounded, 'Ok Yönü', 'Yanıltıcı okların ortasındakine odaklan', _OyunKategori.dikkat, 'puan', () => const OkYonu()),
  _Oyun('hesap', Icons.calculate_rounded, 'Hızlı Hesap', '60 saniyede en çok işlemi çöz', _OyunKategori.hiz, 'doğru', () => const _HizliHesap()),
  _Oyun('buyuk', Icons.compare_arrows_rounded, 'Hangisi Büyük?', 'Kesir, çarpım ve üslüleri hızla karşılaştır', _OyunKategori.hiz, 'doğru', () => const HangisiBuyuk()),
  _Oyun('oruntu', Icons.timeline_rounded, 'Örüntü Bul', 'Sayı dizisinin kuralını keşfet', _OyunKategori.problem, 'doğru', () => const OruntuBul()),
  _Oyun('anlam', Icons.spellcheck_rounded, 'Eş / Zıt Anlam', 'Sözcüklerin anlamdaşını bul', _OyunKategori.dil, 'doğru', () => const EsZitAnlam()),
];

class MiniOyunlarScreen extends ConsumerStatefulWidget {
  const MiniOyunlarScreen({super.key});

  @override
  ConsumerState<MiniOyunlarScreen> createState() => _MiniOyunlarScreenState();
}

class _MiniOyunlarScreenState extends ConsumerState<MiniOyunlarScreen> {
  _OyunKategori? _kategori;

  @override
  Widget build(BuildContext context) {
    final rekorlar = ref.watch(oyunRekorlariProvider).value ?? {};
    final c = context.colors;
    final gorunen = _oyunlar.where((o) => _kategori == null || o.kategori == _kategori).toList();

    Widget oyunKarti(_Oyun o) {
      final renk = switch (o.kategori) {
        _OyunKategori.hafiza => c.primary,
        _OyunKategori.dikkat => c.danger,
        _OyunKategori.hiz => c.accent,
        _OyunKategori.problem => c.info,
        _OyunKategori.dil => c.success,
      };
      final rekor = rekorlar[o.id];
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: YumusakKart(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => o.sayfa())),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: renk.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(16)),
                child: Icon(o.ikon, color: renk, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.ad, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.textPrimary)),
                    const SizedBox(height: 2),
                    Text(o.aciklama, style: TextStyle(fontSize: 13, color: c.textMuted)),
                    const SizedBox(height: 4),
                    Text('${o.kategori.ad} · Rekor: ${rekor == null ? '—' : '$rekor ${o.birim}'}',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.play_circle_fill_rounded, color: renk, size: 36),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        title: const Text('Zihin Açıcı', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Molada 1-2 dakikalık oyunlarla hafızanı, dikkatini ve hızını tazele; sonra çalışmaya dön.',
              style: TextStyle(color: c.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                HapSecim(etiket: 'Tümü (${_oyunlar.length})', secili: _kategori == null, onTap: () => setState(() => _kategori = null)),
                for (final k in _OyunKategori.values) ...[
                  const SizedBox(width: 8),
                  HapSecim(etiket: k.ad, secili: _kategori == k, onTap: () => setState(() => _kategori = k)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final o in gorunen) oyunKarti(o),
        ],
      ),
    );
  }
}

// ─── Hızlı Hesap ─────────────────────────────────────────────

class _HizliHesap extends ConsumerStatefulWidget {
  const _HizliHesap();

  @override
  ConsumerState<_HizliHesap> createState() => _HizliHesapState();
}

class _HizliHesapState extends ConsumerState<_HizliHesap> {
  final _rng = Random();
  Timer? _timer;
  int _kalan = 60;
  int _skor = 0;
  String _soru = '';
  int _cevap = 0;
  List<int> _secenekler = [];
  bool? _sonDogru;
  bool _bitti = false;
  bool _rekor = false;

  @override
  void initState() {
    super.initState();
    _basla();
  }

  void _basla() {
    _timer?.cancel();
    setState(() {
      _kalan = 60;
      _skor = 0;
      _bitti = false;
      _rekor = false;
      _sonDogru = null;
    });
    _yeniSoru();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (_kalan <= 1) {
        t.cancel();
        final rekor = await oyunRekoruKaydet(ref, 'hesap', _skor);
        if (mounted) {
          setState(() {
            _kalan = 0;
            _bitti = true;
            _rekor = rekor;
          });
        }
      } else {
        setState(() => _kalan--);
      }
    });
  }

  void _yeniSoru() {
    final zorluk = 1 + _skor ~/ 5;
    final tip = _rng.nextInt(3);
    int a, b;
    switch (tip) {
      case 0:
        a = _rng.nextInt(20 * zorluk) + 2;
        b = _rng.nextInt(20 * zorluk) + 2;
        _cevap = a + b;
        _soru = '$a + $b';
      case 1:
        a = _rng.nextInt(20 * zorluk) + 10;
        b = _rng.nextInt(a);
        _cevap = a - b;
        _soru = '$a − $b';
      default:
        a = _rng.nextInt(8 + zorluk) + 2;
        b = _rng.nextInt(9) + 2;
        _cevap = a * b;
        _soru = '$a × $b';
    }
    final s = <int>{_cevap};
    while (s.length < 4) {
      final sapma = _rng.nextInt(10) + 1;
      s.add(_rng.nextBool() ? _cevap + sapma : max(0, _cevap - sapma));
    }
    _secenekler = s.toList()..shuffle(_rng);
  }

  void _sec(int v) {
    if (_bitti) return;
    final dogru = v == _cevap;
    dogru ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
    setState(() {
      _sonDogru = dogru;
      if (dogru) _skor++;
      _yeniSoru();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(backgroundColor: context.colors.background, title: const Text('Hızlı Hesap')),
      body: _bitti
          ? OyunSonucu(skor: _skor, rekor: _rekor, birim: 'doğru', tekrar: _basla)
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      SayacRozeti(ikon: Icon(Icons.timer_outlined, size: 16, color: context.colors.warning), deger: '$_kalan sn', renk: context.colors.warning),
                      const Spacer(),
                      SayacRozeti(ikon: Icon(Icons.check_rounded, size: 16, color: context.colors.success), deger: '$_skor', renk: context.colors.success),
                    ],
                  ),
                  const Spacer(),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    decoration: BoxDecoration(
                      color: _sonDogru == null
                          ? context.colors.surface
                          : (_sonDogru! ? context.colors.success : context.colors.danger).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(_soru, style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: context.colors.textPrimary)),
                  ),
                  const Spacer(),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.2,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (final v in _secenekler)
                        FilledButton.tonal(
                          onPressed: () => _sec(v),
                          style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                          child: Text('$v', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

// ─── Sayı Hafızası ───────────────────────────────────────────

class _SayiHafizasi extends ConsumerStatefulWidget {
  const _SayiHafizasi();

  @override
  ConsumerState<_SayiHafizasi> createState() => _SayiHafizasiState();
}

enum _HafizaAsama { goster, gir, bitti }

class _SayiHafizasiState extends ConsumerState<_SayiHafizasi> {
  final _rng = Random();
  int _uzunluk = 3;
  String _sayi = '';
  String _girilen = '';
  _HafizaAsama _asama = _HafizaAsama.goster;
  Timer? _timer;
  bool _rekor = false;

  @override
  void initState() {
    super.initState();
    _tur();
  }

  void _tur() {
    _timer?.cancel();
    _sayi = List.generate(_uzunluk, (_) => _rng.nextInt(10)).join();
    _girilen = '';
    setState(() => _asama = _HafizaAsama.goster);
    _timer = Timer(Duration(milliseconds: 1200 + _uzunluk * 450), () {
      if (mounted) setState(() => _asama = _HafizaAsama.gir);
    });
  }

  Future<void> _kontrol() async {
    if (_girilen == _sayi) {
      HapticFeedback.lightImpact();
      _uzunluk++;
      _tur();
    } else {
      HapticFeedback.heavyImpact();
      final skor = _uzunluk - 1;
      final rekor = await oyunRekoruKaydet(ref, 'hafiza', skor);
      if (mounted) {
        setState(() {
          _rekor = rekor;
          _asama = _HafizaAsama.bitti;
        });
      }
    }
  }

  void _tus(String t) {
    setState(() {
      if (t == '⌫') {
        if (_girilen.isNotEmpty) _girilen = _girilen.substring(0, _girilen.length - 1);
      } else if (_girilen.length < _uzunluk) {
        _girilen += t;
      }
    });
    if (_girilen.length == _uzunluk) _kontrol();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(backgroundColor: context.colors.background, title: const Text('Sayı Hafızası')),
      body: _asama == _HafizaAsama.bitti
          ? OyunSonucu(
              skor: _uzunluk - 1,
              rekor: _rekor,
              birim: 'basamak',
              tekrar: () {
                _uzunluk = 3;
                _tur();
              },
            )
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  SayacRozeti(ikon: Icon(Icons.pin_rounded, size: 16, color: context.colors.primary), deger: '$_uzunluk basamak', renk: context.colors.primary),
                  const Spacer(),
                  Text(
                    _asama == _HafizaAsama.goster ? _sayi : (_girilen.isEmpty ? 'Sayıyı gir' : _girilen),
                    style: TextStyle(
                      fontSize: _asama == _HafizaAsama.goster || _girilen.isNotEmpty ? 44 : 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                      color: _asama == _HafizaAsama.goster ? context.colors.primary : context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(_asama == _HafizaAsama.goster ? 'Aklında tut…' : '',
                      style: TextStyle(color: context.colors.textMuted)),
                  const Spacer(),
                  if (_asama == _HafizaAsama.gir)
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.8,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (final t in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'])
                          t.isEmpty
                              ? const SizedBox.shrink()
                              : FilledButton.tonal(
                                  onPressed: () => _tus(t),
                                  style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                                  child: Text(t, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                                ),
                      ],
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

// ─── Renk Tuzağı (Stroop) ────────────────────────────────────

class _RenkTuzagi extends ConsumerStatefulWidget {
  const _RenkTuzagi();

  @override
  ConsumerState<_RenkTuzagi> createState() => _RenkTuzagiState();
}

class _RenkTuzagiState extends ConsumerState<_RenkTuzagi> {
  static const _renkler = <String, Color>{
    'KIRMIZI': Color(0xFFEF4444),
    'MAVİ': Color(0xFF3B82F6),
    'YEŞİL': Color(0xFF16A34A),
    'SARI': Color(0xFFEAB308),
  };
  final _rng = Random();
  Timer? _timer;
  int _kalan = 30;
  int _skor = 0;
  String _kelime = 'KIRMIZI';
  String _murekkep = 'MAVİ';
  bool _bitti = false;
  bool _rekor = false;

  @override
  void initState() {
    super.initState();
    _basla();
  }

  void _basla() {
    _timer?.cancel();
    setState(() {
      _kalan = 30;
      _skor = 0;
      _bitti = false;
      _rekor = false;
    });
    _yeni();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (_kalan <= 1) {
        t.cancel();
        final rekor = await oyunRekoruKaydet(ref, 'stroop', _skor);
        if (mounted) {
          setState(() {
            _bitti = true;
            _rekor = rekor;
          });
        }
      } else {
        setState(() => _kalan--);
      }
    });
  }

  void _yeni() {
    final adlar = _renkler.keys.toList();
    _kelime = adlar[_rng.nextInt(adlar.length)];
    do {
      _murekkep = adlar[_rng.nextInt(adlar.length)];
    } while (_murekkep == _kelime && _rng.nextDouble() < 0.8);
  }

  void _sec(String ad) {
    if (_bitti) return;
    if (ad == _murekkep) {
      HapticFeedback.lightImpact();
      _skor++;
    } else {
      HapticFeedback.heavyImpact();
      _skor = max(0, _skor - 1);
    }
    setState(_yeni);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(backgroundColor: context.colors.background, title: const Text('Renk Tuzağı')),
      body: _bitti
          ? OyunSonucu(skor: _skor, rekor: _rekor, birim: 'puan', tekrar: _basla)
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      SayacRozeti(ikon: Icon(Icons.timer_outlined, size: 16, color: context.colors.warning), deger: '$_kalan sn', renk: context.colors.warning),
                      const Spacer(),
                      SayacRozeti(ikon: Icon(Icons.track_changes_rounded, size: 16, color: context.colors.success), deger: '$_skor', renk: context.colors.success),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Yazının RENGİNE dokun, kelimeye değil.',
                      style: TextStyle(color: context.colors.textSecondary, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(_kelime, style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: _renkler[_murekkep])),
                  const Spacer(),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.4,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (final e in _renkler.entries)
                        FilledButton(
                          onPressed: () => _sec(e.key),
                          style: FilledButton.styleFrom(
                            backgroundColor: e.value,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          child: Text(e.key, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
