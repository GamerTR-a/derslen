/// Problem çözme ve dil oyunları: Örüntü Bul, Hangisi Büyük, Eş/Zıt Anlam.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

import 'oyun_ortak.dart';

/// Süreli, dört seçenekli soru oyunlarının ortak iskeleti.
abstract class _SecenekliOyunState<T extends ConsumerStatefulWidget> extends ConsumerState<T> {
  final rng = Random();
  final _sayac = GeriSayim();
  int skor = 0;
  bool bitti = false;
  bool rekor = false;
  bool? sonDogru;
  String soru = '';
  List<String> secenekler = const [];
  String cevap = '';

  String get oyunId;
  int get sureSn => 60;
  void yeniSoru();

  @override
  void initState() {
    super.initState();
    basla();
  }

  @override
  void dispose() {
    _sayac.durdur();
    super.dispose();
  }

  void basla() {
    skor = 0;
    bitti = false;
    rekor = false;
    sonDogru = null;
    yeniSoru();
    _sayac.baslat(
      sureSn,
      tik: () {
        if (mounted) setState(() {});
      },
      bitti: () async {
        final r = await oyunRekoruKaydet(ref, oyunId, skor);
        if (mounted) {
          setState(() {
            bitti = true;
            rekor = r;
          });
        }
      },
    );
    setState(() {});
  }

  void sec(String s) {
    if (bitti) return;
    final dogru = s == cevap;
    dogru ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
    setState(() {
      sonDogru = dogru;
      if (dogru) skor++;
      yeniSoru();
    });
  }

  List<String> karistir(String dogru, Iterable<String> yanlislar) {
    final l = <String>{dogru, ...yanlislar}.take(4).toList()..shuffle(rng);
    return l;
  }

  Widget oyunGovdesi(BuildContext context, {required String baslik, required String kural, double soruBoyutu = 34}) {
    final c = context.colors;
    return OyunIskeleti(
      baslik: baslik,
      govde: bitti
          ? OyunSonucu(skor: skor, rekor: rekor, birim: 'doğru', tekrar: basla)
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  OyunUstBar(sure: '${_sayac.kalan} sn', skor: '$skor'),
                  const SizedBox(height: 12),
                  Text(kural, textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
                    decoration: BoxDecoration(
                      color: sonDogru == null ? c.surface : (sonDogru! ? c.success : c.danger).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(soru, textAlign: TextAlign.center, style: TextStyle(fontSize: soruBoyutu, fontWeight: FontWeight.w900, color: c.textPrimary)),
                    ),
                  ),
                  const Spacer(),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.3,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (final s in secenekler)
                        FilledButton.tonal(
                          onPressed: () => sec(s),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          child: FittedBox(fit: BoxFit.scaleDown, child: Text(s, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
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

// ─── Örüntü Bul ──────────────────────────────────────────────

class OruntuBul extends ConsumerStatefulWidget {
  const OruntuBul({super.key});

  @override
  ConsumerState<OruntuBul> createState() => _OruntuBulState();
}

class _OruntuBulState extends _SecenekliOyunState<OruntuBul> {
  @override
  String get oyunId => 'oruntu';

  @override
  int get sureSn => 90;

  /// Rastgele bir kurala göre 6 terim üretir; ilk 5'i gösterilir.
  List<int> _dizi() {
    final zor = skor >= 6;
    switch (rng.nextInt(zor ? 7 : 4)) {
      case 0: // aritmetik
        final a = rng.nextInt(20) + 1;
        final d = (rng.nextInt(9) + 2) * (rng.nextDouble() < 0.25 ? -1 : 1);
        return [for (var i = 0; i < 6; i++) a + i * d];
      case 1: // geometrik
        final a = rng.nextInt(4) + 1;
        final r = rng.nextInt(2) + 2;
        return [for (var i = 0; i < 6; i++) a * pow(r, i).toInt()];
      case 2: // farkı artan
        final a = rng.nextInt(10) + 1;
        final d = rng.nextInt(3) + 1;
        final e = rng.nextInt(2) + 1;
        final l = [a];
        for (var i = 0; i < 5; i++) {
          l.add(l.last + d + i * e);
        }
        return l;
      case 3: // kareler
        final s = rng.nextInt(5) + 1;
        return [for (var i = 0; i < 6; i++) (s + i) * (s + i)];
      case 4: // Fibonacci benzeri
        final l = [rng.nextInt(5) + 1, rng.nextInt(5) + 2];
        while (l.length < 6) {
          l.add(l[l.length - 1] + l[l.length - 2]);
        }
        return l;
      case 5: // iç içe iki dizi
        final a = rng.nextInt(10) + 1;
        final b = rng.nextInt(10) + 20;
        final d = rng.nextInt(4) + 2;
        final e = rng.nextInt(3) + 1;
        return [a, b, a + d, b - e, a + 2 * d, b - 2 * e];
      default: // ×2 + k
        final a = rng.nextInt(4) + 1;
        final k = rng.nextInt(3) + 1;
        final l = [a];
        while (l.length < 6) {
          l.add(l.last * 2 + k);
        }
        return l;
    }
  }

  @override
  void yeniSoru() {
    final d = _dizi();
    final dogru = d.last;
    soru = '${d.take(5).join(',  ')},  ?';
    cevap = '$dogru';
    final yanlis = <String>{};
    while (yanlis.length < 3) {
      final sapma = (rng.nextInt(6) + 1) * (rng.nextBool() ? 1 : -1);
      final aday = dogru + sapma;
      if (aday != dogru) yanlis.add('$aday');
    }
    secenekler = karistir(cevap, yanlis);
  }

  @override
  Widget build(BuildContext context) =>
      oyunGovdesi(context, baslik: 'Örüntü Bul', kural: 'Dizinin kuralını bul ve sıradaki sayıyı seç.', soruBoyutu: 30);
}

// ─── Hangisi Büyük ───────────────────────────────────────────

class HangisiBuyuk extends ConsumerStatefulWidget {
  const HangisiBuyuk({super.key});

  @override
  ConsumerState<HangisiBuyuk> createState() => _HangisiBuyukState();
}

class _HangisiBuyukState extends _SecenekliOyunState<HangisiBuyuk> {
  @override
  String get oyunId => 'buyuk';

  @override
  int get sureSn => 45;

  (String, double) _ifade(int tur) {
    switch (tur) {
      case 0:
        final a = rng.nextInt(9) + 1;
        final b = a + rng.nextInt(9) + 1;
        return ('$a/$b', a / b);
      case 1:
        final a = rng.nextInt(12) + 3;
        final b = rng.nextInt(12) + 3;
        return ('$a × $b', (a * b).toDouble());
      case 2:
        final t = rng.nextInt(3) + 2;
        final u = rng.nextInt(4) + 2;
        return ('$t^$u', pow(t, u).toDouble());
      default:
        final y = (rng.nextInt(9) + 1) * 10;
        final s = (rng.nextInt(19) + 2) * 10;
        return ('$s\'in %$y\'ı', s * y / 100);
    }
  }

  @override
  void yeniSoru() {
    final tur = rng.nextInt(4);
    var a = _ifade(tur);
    var b = _ifade(tur);
    var deneme = 0;
    while ((a.$2 - b.$2).abs() < 1e-9 && deneme++ < 20) {
      b = _ifade(tur);
    }
    if ((a.$2 - b.$2).abs() < 1e-9) {
      a = ('${a.$2.round() + 1}', a.$2.round() + 1.0);
    }
    soru = 'Hangisi daha büyük?';
    cevap = a.$2 > b.$2 ? a.$1 : b.$1;
    secenekler = [a.$1, b.$1];
  }

  @override
  Widget build(BuildContext context) =>
      oyunGovdesi(context, baslik: 'Hangisi Büyük?', kural: 'İki ifadeden değeri büyük olana dokun. Hızlı ol!', soruBoyutu: 26);
}

// ─── Eş / Zıt Anlam ──────────────────────────────────────────

class EsZitAnlam extends ConsumerStatefulWidget {
  const EsZitAnlam({super.key});

  @override
  ConsumerState<EsZitAnlam> createState() => _EsZitAnlamState();
}

class _EsZitAnlamState extends _SecenekliOyunState<EsZitAnlam> {
  static const _esAnlamlilar = [
    ('kent', 'şehir'), ('sınav', 'imtihan'), ('öğüt', 'nasihat'), ('yurt', 'vatan'), ('konuk', 'misafir'),
    ('doğa', 'tabiat'), ('özgür', 'hür'), ('uygarlık', 'medeniyet'), ('ulus', 'millet'), ('yoksul', 'fakir'),
    ('varsıl', 'zengin'), ('deneyim', 'tecrübe'), ('yapıt', 'eser'), ('olanak', 'imkân'), ('gereksinim', 'ihtiyaç'),
    ('amaç', 'gaye'), ('neden', 'sebep'), ('sorun', 'mesele'), ('yaşam', 'hayat'), ('anı', 'hatıra'),
    ('tutsak', 'esir'), ('ivedi', 'acil'), ('görev', 'vazife'), ('sözcük', 'kelime'), ('tümce', 'cümle'),
    ('eleştiri', 'tenkit'), ('barış', 'sulh'), ('yüzyıl', 'asır'), ('çağdaş', 'muasır'), ('evren', 'kâinat'),
    ('kanıt', 'delil'), ('örnek', 'misal'), ('yanıt', 'cevap'), ('onur', 'şeref'), ('bellek', 'hafıza'),
  ];
  static const _zitAnlamlilar = [
    ('cömert', 'cimri'), ('erken', 'geç'), ('iyimser', 'kötümser'), ('dost', 'düşman'), ('kolay', 'zor'),
    ('cesur', 'korkak'), ('hızlı', 'yavaş'), ('genç', 'yaşlı'), ('ucuz', 'pahalı'), ('geniş', 'dar'),
    ('alçak', 'yüksek'), ('giriş', 'çıkış'), ('kazanç', 'kayıp'), ('nesnel', 'öznel'), ('somut', 'soyut'),
    ('ileri', 'geri'), ('bolluk', 'kıtlık'), ('eksik', 'tam'), ('uzak', 'yakın'), ('ak', 'kara'),
    ('aydınlık', 'karanlık'), ('dolu', 'boş'), ('sevinç', 'keder'), ('öncül', 'ardıl'), ('kalın', 'ince'),
  ];

  @override
  String get oyunId => 'anlam';

  @override
  void yeniSoru() {
    final es = rng.nextBool();
    final liste = es ? _esAnlamlilar : _zitAnlamlilar;
    final cift = liste[rng.nextInt(liste.length)];
    final ters = rng.nextBool();
    final sorulan = ters ? cift.$2 : cift.$1;
    cevap = ters ? cift.$1 : cift.$2;
    soru = '“$sorulan”\n${es ? 'eş anlamlısı' : 'zıt anlamlısı'}';
    final havuz = [
      for (final p in [..._esAnlamlilar, ..._zitAnlamlilar])
        if (p != cift) ...[p.$1, p.$2],
    ]..shuffle(rng);
    secenekler = karistir(cevap, havuz.where((w) => w != cevap && w != sorulan).take(3));
  }

  @override
  Widget build(BuildContext context) =>
      oyunGovdesi(context, baslik: 'Eş / Zıt Anlam', kural: 'Sözcüğün istenen anlamdaşını bul. Türkçe kelime bilgini tazele.', soruBoyutu: 28);
}
