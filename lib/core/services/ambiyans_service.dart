/// Odak ambiyans sesleri — ses dosyası gerektirmeden cihazda üretilen
/// döngüsel sesler (yağmur, okyanus, şömine, kuşlar…) ve kullanıcının kendi
/// yüklediği ses dosyaları.
library;

import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum AmbiyansKategori { doga, mekan, gurultu }

enum AmbiyansSes {
  sessiz('Sessiz', AmbiyansKategori.gurultu),
  yagmur('Yağmur', AmbiyansKategori.doga),
  firtina('Gök gürültülü yağmur', AmbiyansKategori.doga),
  okyanus('Okyanus dalgaları', AmbiyansKategori.doga),
  dere('Dere şırıltısı', AmbiyansKategori.doga),
  ruzgar('Rüzgâr', AmbiyansKategori.doga),
  orman('Orman ve kuşlar', AmbiyansKategori.doga),
  somine('Şömine çıtırtısı', AmbiyansKategori.mekan),
  kafe('Kafe uğultusu', AmbiyansKategori.mekan),
  saat('Saat tik-takı', AmbiyansKategori.mekan),
  fan('Vantilatör', AmbiyansKategori.mekan),
  beyaz('Beyaz gürültü', AmbiyansKategori.gurultu),
  pembe('Pembe gürültü', AmbiyansKategori.gurultu),
  derin('Kahverengi gürültü', AmbiyansKategori.gurultu),
  alfa('Alfa dalgası (kulaklıkla)', AmbiyansKategori.gurultu),
  ozel('Kendi sesim', AmbiyansKategori.mekan);

  const AmbiyansSes(this.etiket, this.kategori);
  final String etiket;
  final AmbiyansKategori kategori;

  /// Cihazda üretilen (dosya gerektirmeyen) sesler.
  bool get uretilen => this != sessiz && this != ozel;
}

class AmbiyansService {
  AmbiyansService._();

  static const int ornekHizi = 22050;

  /// Döngü uzunluğu (sn). Periyodik bileşenlerin (dalga, tik-tak, ton)
  /// frekansları bu sürenin tam katına denk gelecek şekilde seçilir; böylece
  /// döngü dikişi duyulmaz.
  static const int donguSaniye = 12;

  static AudioPlayer? _player;
  static String? _aktifAnahtar;
  static double _seviye = 0.6;
  static final Map<AmbiyansSes, Uint8List> _onbellek = {};

  static bool get caliyor => _aktifAnahtar != null;

  /// [ses] çalınır; [dosya] yalnızca [AmbiyansSes.ozel] için kullanılır.
  static Future<void> cal(AmbiyansSes ses, {String? dosya, double? seviye}) async {
    if (seviye != null) _seviye = seviye.clamp(0.0, 1.0);
    if (ses == AmbiyansSes.sessiz || (ses == AmbiyansSes.ozel && dosya == null)) {
      await durdur();
      return;
    }
    final anahtar = ses == AmbiyansSes.ozel ? 'ozel:$dosya' : ses.name;
    final player = _player ??= AudioPlayer();
    if (anahtar == _aktifAnahtar) {
      await player.setVolume(_seviye);
      return;
    }
    await durdur();
    _aktifAnahtar = anahtar;
    try {
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(_seviye);
      if (ses == AmbiyansSes.ozel) {
        await player.play(DeviceFileSource(dosya!));
      } else {
        final bytes = _onbellek[ses] ??= await compute(ambiyansWavUret, ses.index);
        // Üretim sürerken başka bir ses seçildiyse bu sonucu çalma.
        if (_aktifAnahtar != anahtar) return;
        await player.play(BytesSource(bytes, mimeType: 'audio/wav'));
      }
    } catch (_) {
      _aktifAnahtar = null;
    }
  }

  static Future<void> seviyeAyarla(double seviye) async {
    _seviye = seviye.clamp(0.0, 1.0);
    try {
      await _player?.setVolume(_seviye);
    } catch (_) {}
  }

  static Future<void> durdur() async {
    _aktifAnahtar = null;
    try {
      await _player?.stop();
    } catch (_) {}
  }
}

/// [sesIndex] numaralı ambiyans sesini WAV baytları olarak üretir.
/// `compute` ile ayrı bir isolate'te çalıştırılır.
Uint8List ambiyansWavUret(int sesIndex) {
  final ses = AmbiyansSes.values[sesIndex];
  const hiz = AmbiyansService.ornekHizi;
  const n = hiz * AmbiyansService.donguSaniye;
  const gecis = hiz ~/ 3;
  final u = _Uretici(Random(7 + sesIndex));
  if (ses == AmbiyansSes.alfa) {
    final sol = Float64List(n + gecis);
    final sag = Float64List(n + gecis);
    u.alfa(sol, sag);
    return _wav([_dongule(sol, n, gecis), _dongule(sag, n, gecis)]);
  }
  final x = Float64List(n + gecis);
  switch (ses) {
    case AmbiyansSes.yagmur:
      u.yagmur(x, 1);
    case AmbiyansSes.firtina:
      u.yagmur(x, 0.85);
      u.gokGurultusu(x);
    case AmbiyansSes.okyanus:
      u.okyanus(x);
    case AmbiyansSes.dere:
      u.dere(x);
    case AmbiyansSes.ruzgar:
      u.ruzgar(x, 1);
    case AmbiyansSes.orman:
      u.ruzgar(x, 0.35);
      u.kuslar(x);
    case AmbiyansSes.somine:
      u.somine(x);
    case AmbiyansSes.kafe:
      u.kafe(x);
    case AmbiyansSes.saat:
      u.saat(x);
    case AmbiyansSes.fan:
      u.fan(x);
    case AmbiyansSes.beyaz:
      u.beyaz(x);
    case AmbiyansSes.pembe:
      u.pembe(x, 0.9);
    case AmbiyansSes.derin:
      u.kahverengi(x, 1);
    case AmbiyansSes.sessiz || AmbiyansSes.ozel || AmbiyansSes.alfa:
      break;
  }
  _normalle(x, 0.16);
  return _wav([_dongule(x, n, gecis)]);
}

/// Sondaki [gecis] örneği başa çapraz geçişle karıştırıp [n] uzunluğunda
/// kesintisiz bir döngü döndürür. Periyodu döngüye bölünen bileşenler
/// (tik-tak, dalga) bu işlemden etkilenmez.
Float64List _dongule(Float64List x, int n, int gecis) {
  final out = Float64List(n);
  for (var i = 0; i < n; i++) {
    out[i] = x[i];
  }
  for (var i = 0; i < gecis; i++) {
    final t = i / gecis;
    out[i] = x[i] * t + x[n + i] * (1 - t);
  }
  return out;
}

/// Sesi hedef ortalama güce (RMS) getirir; seyrek tepeler (çıtırtı, tik)
/// yumuşak kırpmayla sınırlanır.
void _normalle(Float64List x, double hedefRms) {
  var tepe = 0.0;
  var kare = 0.0;
  for (final v in x) {
    tepe = max(tepe, v.abs());
    kare += v * v;
  }
  if (tepe < 1e-9) return;
  final rms = sqrt(kare / x.length);
  final k = min(hedefRms / rms, 1.5 / tepe);
  for (var i = 0; i < x.length; i++) {
    final v = x[i] * k;
    final e = exp(2 * v.clamp(-10.0, 10.0));
    x[i] = (e - 1) / (e + 1) * 0.92;
  }
}

class _Uretici {
  final Random r;
  _Uretici(this.r);

  static const double hiz = AmbiyansService.ornekHizi * 1.0;
  static const double donguSn = AmbiyansService.donguSaniye * 1.0;

  double get _b => r.nextDouble() * 2 - 1;

  void beyaz(Float64List x) {
    for (var i = 0; i < x.length; i++) {
      x[i] += _b * 0.3;
    }
  }

  /// Paul Kellet'in pembe gürültü süzgeci.
  void pembe(Float64List x, double kazanc) {
    double b0 = 0, b1 = 0, b2 = 0, b3 = 0, b4 = 0, b5 = 0, b6 = 0;
    for (var i = 0; i < x.length; i++) {
      final w = _b;
      b0 = 0.99886 * b0 + w * 0.0555179;
      b1 = 0.99332 * b1 + w * 0.0750759;
      b2 = 0.96900 * b2 + w * 0.1538520;
      b3 = 0.86650 * b3 + w * 0.3104856;
      b4 = 0.55000 * b4 + w * 0.5329522;
      b5 = -0.7616 * b5 - w * 0.0168980;
      final p = b0 + b1 + b2 + b3 + b4 + b5 + b6 + w * 0.5362;
      b6 = w * 0.115926;
      x[i] += p * 0.11 * kazanc;
    }
  }

  void kahverengi(Float64List x, double kazanc) {
    var son = 0.0;
    for (var i = 0; i < x.length; i++) {
      son = (son + 0.02 * _b) / 1.02;
      x[i] += son * 3.5 * kazanc;
    }
  }

  void yagmur(Float64List x, double kazanc) {
    double b0 = 0, b1 = 0, b2 = 0;
    for (var i = 0; i < x.length; i++) {
      final w = _b;
      b0 = 0.99765 * b0 + w * 0.0990460;
      b1 = 0.96300 * b1 + w * 0.2965164;
      b2 = 0.57000 * b2 + w * 1.0526913;
      var v = (b0 + b1 + b2 + w * 0.1848) * 0.11;
      // Tek tük iri damlalar.
      if (r.nextDouble() < 0.0009) v += _b * 0.45;
      x[i] += v * kazanc;
    }
  }

  /// Döngüde 1-2 kez uzaktan gelen, alçak frekanslı gök gürültüsü.
  void gokGurultusu(Float64List x) {
    final baslangiclar = [hiz * (1.5 + r.nextDouble() * 2), hiz * (7 + r.nextDouble() * 2)];
    var dus = 0.0;
    var dus2 = 0.0;
    for (var i = 0; i < x.length; i++) {
      dus = dus * 0.996 + _b * 0.004;
      dus2 = dus2 * 0.99 + dus * 0.01;
      var zarf = 0.0;
      for (final b in baslangiclar) {
        final t = (i - b) / hiz;
        if (t < 0 || t > 5) continue;
        final atak = min(1.0, t / 0.4);
        zarf += atak * exp(-t * 0.9) * (0.8 + 0.2 * sin(t * 9));
      }
      x[i] += dus2 * 55 * zarf;
    }
  }

  /// Kıyıya vuran dalgalar: 6 sn periyotlu (döngüde 2 dalga) zarfla
  /// şekillenen yumuşak gürültü.
  void okyanus(Float64List x) {
    double lp = 0, lp2 = 0;
    for (var i = 0; i < x.length; i++) {
      final t = i / hiz;
      final faz = (t % 6) / 6;
      final kabarma = pow(sin(pi * faz), 2).toDouble();
      final zarf = 0.18 + 0.82 * kabarma * kabarma;
      final kesim = 0.02 + 0.10 * kabarma;
      lp += kesim * (_b - lp);
      lp2 += 0.3 * (lp - lp2);
      x[i] += (lp2 * 2.6 + lp * 0.6) * zarf;
    }
  }

  /// Dere: yüksek frekanslı süzülmüş gürültü, hızlı ve düzensiz genlik
  /// değişimleri (kabarcıklar).
  void dere(Float64List x) {
    double onceki = 0, lp = 0, kab = 0;
    // Frekanslar 1/12 Hz'in katları: döngü dikişi oluşmaz.
    const f1 = 37 / 12, f2 = 67 / 12, f3 = 101 / 12;
    for (var i = 0; i < x.length; i++) {
      final t = i / hiz;
      final w = _b;
      final hp = w - onceki;
      onceki = w;
      lp += 0.35 * (hp - lp);
      final mod = 0.55 + 0.18 * sin(2 * pi * f1 * t) + 0.14 * sin(2 * pi * f2 * t + 1.3) + 0.1 * sin(2 * pi * f3 * t + 2.1);
      if (r.nextDouble() < 0.0025) kab = 0.5 + r.nextDouble() * 0.6;
      kab *= 0.9985;
      x[i] += lp * (mod + kab) * 0.9;
    }
    pembe(x, 0.35);
  }

  /// Esen rüzgâr: yavaşça açılıp kapanan süzgeçten geçen gürültü.
  void ruzgar(Float64List x, double kazanc) {
    double lp = 0, lp2 = 0;
    for (var i = 0; i < x.length; i++) {
      final t = i / hiz;
      final e = 0.5 + 0.3 * sin(2 * pi * t / donguSn) + 0.2 * sin(2 * pi * 3 * t / donguSn + 0.8);
      final kesim = 0.006 + 0.03 * e * e;
      lp += kesim * (_b - lp);
      lp2 += kesim * (lp - lp2);
      x[i] += lp2 * (8 + 22 * e) * kazanc;
    }
  }

  /// Kuş cıvıltıları: rastgele aralıklarla 2-5 notalık frekans kaydırmalı
  /// kısa ötüşler.
  void kuslar(Float64List x) {
    var t0 = 0.6;
    while (t0 < donguSn - 1) {
      final notaSayisi = 2 + r.nextInt(4);
      final taban = 2600 + r.nextDouble() * 1800;
      final yukari = r.nextBool();
      for (var k = 0; k < notaSayisi; k++) {
        final bas = ((t0 + k * (0.09 + r.nextDouble() * 0.05)) * hiz).round();
        final sure = (0.06 + r.nextDouble() * 0.05) * hiz;
        final f0 = taban * (1 + 0.1 * k * (yukari ? 1 : -1));
        final f1 = f0 * (yukari ? 1.35 : 0.75);
        var faz = 0.0;
        for (var j = 0; j < sure; j++) {
          final i = bas + j;
          if (i >= x.length) break;
          final p = j / sure;
          final f = f0 + (f1 - f0) * p;
          faz += 2 * pi * f / hiz;
          final zarf = sin(pi * p);
          x[i] += sin(faz) * zarf * zarf * 0.22;
        }
      }
      t0 += 0.8 + r.nextDouble() * 2.2;
    }
  }

  /// Şömine: alçak uğultu + rastgele çıtırtılar.
  void somine(Float64List x) {
    kahverengi(x, 0.55);
    var catirti = 0.0;
    var onceki = 0.0;
    for (var i = 0; i < x.length; i++) {
      if (r.nextDouble() < 0.0007) catirti = 0.4 + r.nextDouble() * 0.9;
      if (r.nextDouble() < 0.004) catirti = max(catirti, 0.08 + r.nextDouble() * 0.12);
      final w = _b;
      final hp = w - onceki;
      onceki = w;
      x[i] += hp * catirti;
      catirti *= 0.991;
    }
  }

  /// Kafe: konuşma frekanslarına süzülmüş, hece hızında dalgalanan
  /// birkaç "ses" + ara sıra fincan tıkırtısı.
  void kafe(Float64List x) {
    const sesSayisi = 6;
    final fazlar = [for (var k = 0; k < sesSayisi; k++) r.nextDouble() * 2 * pi];
    // Hece hızları (≈3-6 Hz), 1/12 Hz katları.
    final hizlar = [for (var k = 0; k < sesSayisi; k++) (36 + r.nextInt(36)) / 12];
    final lp = List.filled(sesSayisi, 0.0);
    final hp = List.filled(sesSayisi, 0.0);
    for (var i = 0; i < x.length; i++) {
      final t = i / hiz;
      var toplam = 0.0;
      for (var k = 0; k < sesSayisi; k++) {
        final w = _b;
        lp[k] += 0.12 * (w - lp[k]);
        hp[k] += 0.02 * (lp[k] - hp[k]);
        final bant = lp[k] - hp[k];
        final hece = max(0.0, sin(2 * pi * hizlar[k] * t + fazlar[k]));
        final cumle = 0.5 + 0.5 * sin(2 * pi * (k + 1) * t / donguSn + fazlar[k] * 2);
        toplam += bant * hece * cumle;
      }
      x[i] += toplam * 0.9;
    }
    pembe(x, 0.25);
    // Fincan-kaşık tıkırtıları.
    var t0 = 1.0 + r.nextDouble() * 2;
    while (t0 < donguSn - 0.5) {
      final bas = (t0 * hiz).round();
      final f = 2400 + r.nextDouble() * 1800;
      for (var j = 0; j < hiz * 0.18; j++) {
        final i = bas + j;
        if (i >= x.length) break;
        x[i] += sin(2 * pi * f * j / hiz) * exp(-j / (hiz * 0.03)) * 0.25;
      }
      t0 += 2 + r.nextDouble() * 4;
    }
  }

  /// Saniyede bir tik / tak (döngü 12 sn olduğundan kesintisiz).
  void saat(Float64List x) {
    pembe(x, 0.05);
    final n = AmbiyansService.ornekHizi * AmbiyansService.donguSaniye;
    for (var s = 0; s < AmbiyansService.donguSaniye; s++) {
      final f = s.isEven ? 2100.0 : 1600.0;
      final bas = s * AmbiyansService.ornekHizi;
      for (var j = 0; j < hiz * 0.03; j++) {
        final zarf = exp(-j / (hiz * 0.004));
        final v = (sin(2 * pi * f * j / hiz) * 0.7 + _b * 0.3) * zarf * 0.8;
        x[bas + j] += v;
        // Döngü sonrası kuyruk (çapraz geçiş bölgesi) aynı periyodu sürdürür.
        if (bas + j + n < x.length) x[bas + j + n] += v;
      }
    }
  }

  /// Vantilatör: motor uğultusu (100 Hz ve harmonikleri) + hava akışı.
  void fan(Float64List x) {
    double lp = 0, lp2 = 0;
    for (var i = 0; i < x.length; i++) {
      final t = i / hiz;
      lp += 0.05 * (_b - lp);
      lp2 += 0.2 * (lp - lp2);
      final ugultu = 0.06 * sin(2 * pi * 100 * t) + 0.03 * sin(2 * pi * 200 * t) + 0.012 * sin(2 * pi * 300 * t);
      final kanat = 1 + 0.12 * sin(2 * pi * 12.5 * t);
      x[i] += (lp2 * 3.2 * kanat) + ugultu;
    }
  }

  /// Binoral alfa ritmi: sol 200 Hz, sağ 210 Hz (10 Hz fark) + yumuşak zemin.
  void alfa(Float64List sol, Float64List sag) {
    pembe(sol, 0.18);
    pembe(sag, 0.18);
    for (var i = 0; i < sol.length; i++) {
      final t = i / hiz;
      sol[i] += 0.28 * sin(2 * pi * 200 * t);
      sag[i] += 0.28 * sin(2 * pi * 210 * t);
    }
  }
}

/// 16 bit PCM WAV. [kanallar] tek (mono) ya da iki (stereo) elemanlıdır.
Uint8List _wav(List<Float64List> kanallar) {
  final kanal = kanallar.length;
  final n = kanallar.first.length;
  final veriBoyutu = n * 2 * kanal;
  final b = ByteData(44 + veriBoyutu);
  void yaz(int ofset, String s) {
    for (var i = 0; i < s.length; i++) {
      b.setUint8(ofset + i, s.codeUnitAt(i));
    }
  }

  const hiz = AmbiyansService.ornekHizi;
  yaz(0, 'RIFF');
  b.setUint32(4, 36 + veriBoyutu, Endian.little);
  yaz(8, 'WAVE');
  yaz(12, 'fmt ');
  b.setUint32(16, 16, Endian.little);
  b.setUint16(20, 1, Endian.little);
  b.setUint16(22, kanal, Endian.little);
  b.setUint32(24, hiz, Endian.little);
  b.setUint32(28, hiz * 2 * kanal, Endian.little);
  b.setUint16(32, 2 * kanal, Endian.little);
  b.setUint16(34, 16, Endian.little);
  yaz(36, 'data');
  b.setUint32(40, veriBoyutu, Endian.little);
  var o = 44;
  for (var i = 0; i < n; i++) {
    for (final k in kanallar) {
      b.setInt16(o, (k[i].clamp(-1.0, 1.0) * 32767).round(), Endian.little);
      o += 2;
    }
  }
  return b.buffer.asUint8List();
}
