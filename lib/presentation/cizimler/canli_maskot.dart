/// Canlı maskotlar — yan profilden, tam gövdeli, her karede yeniden çizilen
/// sevimli hayvanlar. Yürürken dört ayak çapraz adım atar (yengeç yan yan
/// yürür), gövde hafifçe yaylanır, kuyruk sallanır; dururken nefes alır,
/// göz kırpar, kulak oynatır ve başını çevirir. Ruh hali yüz ifadesini ve
/// küçük efektleri (düşünce baloncuğu, ter damlası, parıltı, kulaklık)
/// belirler.
///
/// Çizim alanı 100×80 birimdir; widget genişliği `boyut`, yüksekliği
/// `boyut * 0.8`'dir. Karakterler varsayılan olarak sağa bakar.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

enum MaskotRuh { mutlu, dusunceli, endiseli, odakli, gururlu }

/// Seçilebilir karakter kimlikleri (AsistanKarakter.name ile aynı).
const List<String> maskotKarakterleri = ['kedi', 'siyam', 'kopek', 'yengec', 'tilki', 'panda'];

enum _Kuyruk { uzun, tuylu, kisa, top }

enum _Kulak { sivri, buyukSivri, yuvarlak }

enum _Yuz { kedi, kopek, tilki, panda }

class _Tur {
  final Color govde;
  final Color koyu;
  final Color acik;
  final Color uc;
  final Color kulakIc;
  final Color goz;
  final double bacak;
  final double govdeRx;
  final double basR;
  final _Kuyruk kuyruk;
  final _Kulak kulak;
  final _Yuz yuz;

  /// Uç renkli bölgeler: siyam maskesi/pati/kuyruk, tilki çorabı, panda bacakları.
  final bool ucBacak;
  final bool ucKuyruk;
  final bool ucKulak;
  final bool maske;
  final bool gozBandi;
  final bool beyazCorap;

  const _Tur({
    required this.govde,
    required this.koyu,
    required this.acik,
    required this.uc,
    required this.kulakIc,
    required this.goz,
    required this.bacak,
    required this.govdeRx,
    this.basR = 16.5,
    required this.kuyruk,
    required this.kulak,
    required this.yuz,
    this.ucBacak = false,
    this.ucKuyruk = false,
    this.ucKulak = false,
    this.maske = false,
    this.gozBandi = false,
    this.beyazCorap = false,
  });
}

const Map<String, _Tur> _turler = {
  // Pati — turuncu kedi, sarımsı kuyruk ucu
  'kedi': _Tur(
    govde: Color(0xFFF26B3A),
    koyu: Color(0xFFD4532A),
    acik: Color(0xFFFFF3E6),
    uc: Color(0xFFF9B233),
    kulakIc: Color(0xFFFFB3A7),
    goz: Color(0xFF2F3E8F),
    bacak: 13,
    govdeRx: 19,
    kuyruk: _Kuyruk.uzun,
    kulak: _Kulak.sivri,
    yuz: _Yuz.kedi,
    ucKuyruk: true,
  ),
  // Pamuk — siyam kedi, koyu uçlar ve mavi gözler
  'siyam': _Tur(
    govde: Color(0xFFF3E9DD),
    koyu: Color(0xFFD9CCBF),
    acik: Color(0xFFFFFFFF),
    uc: Color(0xFF6E5E58),
    kulakIc: Color(0xFFE9B7B0),
    goz: Color(0xFF3D7BF0),
    bacak: 13,
    govdeRx: 19,
    kuyruk: _Kuyruk.uzun,
    kulak: _Kulak.sivri,
    yuz: _Yuz.kedi,
    ucBacak: true,
    ucKuyruk: true,
    ucKulak: true,
    maske: true,
  ),
  // Bisküvi — corgi: kısa bacaklar, büyük kulaklar, beyaz göğüs ve çoraplar
  'kopek': _Tur(
    govde: Color(0xFFE69A4A),
    koyu: Color(0xFFC77D34),
    acik: Color(0xFFFFF6EA),
    uc: Color(0xFFFFF6EA),
    kulakIc: Color(0xFFF6C49B),
    goz: Color(0xFF2B1D14),
    bacak: 8,
    govdeRx: 23,
    basR: 15.5,
    kuyruk: _Kuyruk.kisa,
    kulak: _Kulak.buyukSivri,
    yuz: _Yuz.kopek,
    beyazCorap: true,
  ),
  // Tilki — gür kuyruk, koyu çoraplar
  'tilki': _Tur(
    govde: Color(0xFFE27330),
    koyu: Color(0xFFBC5520),
    acik: Color(0xFFFFF4E8),
    uc: Color(0xFF4A2E24),
    kulakIc: Color(0xFF4A2E24),
    goz: Color(0xFF2B1D14),
    bacak: 13,
    govdeRx: 19,
    basR: 15.5,
    kuyruk: _Kuyruk.tuylu,
    kulak: _Kulak.sivri,
    yuz: _Yuz.tilki,
    ucBacak: true,
  ),
  // Panda — siyah bacaklar, kulaklar ve göz bantları
  'panda': _Tur(
    govde: Color(0xFFFAFAF7),
    koyu: Color(0xFFE4E4DE),
    acik: Color(0xFFFFFFFF),
    uc: Color(0xFF2B2B2B),
    kulakIc: Color(0xFF2B2B2B),
    goz: Color(0xFFFFFFFF),
    bacak: 10,
    govdeRx: 21,
    basR: 17,
    kuyruk: _Kuyruk.top,
    kulak: _Kulak.yuvarlak,
    yuz: _Yuz.panda,
    ucBacak: true,
    gozBandi: true,
  ),
};

/// Tek bir animasyon karesinin durumu (repaint tetikleyicisi).
class MaskotKaresi extends ChangeNotifier {
  double t = 0;
  double faz = 0;
  double yuru = 0;
  double hop = 0;

  void guncelle(double t, double faz, double yuru, double hop) {
    this.t = t;
    this.faz = faz;
    this.yuru = yuru;
    this.hop = hop;
    notifyListeners();
  }
}

/// Canlı, yürüyebilen maskot.
///
/// * [yuruyor]: ayaklar adım atar (geçiş yumuşaktır; aniden durmaz).
/// * [sagaBakiyor]: yön; false ise karakter aynalanır.
/// * [zipla]: birkaç saniyede bir küçük sevinç zıplaması.
class Maskot extends StatefulWidget {
  final String karakter;
  final MaskotRuh ruh;
  final double boyut;
  final bool yuruyor;
  final bool sagaBakiyor;
  final bool zipla;

  const Maskot({
    super.key,
    required this.karakter,
    this.ruh = MaskotRuh.mutlu,
    this.boyut = 60,
    this.yuruyor = false,
    this.sagaBakiyor = true,
    this.zipla = false,
  });

  @override
  State<Maskot> createState() => _MaskotState();
}

class _MaskotState extends State<Maskot> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _kare = MaskotKaresi();
  final double _baslangic = Random().nextDouble() * 10;
  Duration _onceki = Duration.zero;
  double _t = 0;
  double _faz = 0;
  double _yuru = 0;

  @override
  void initState() {
    super.initState();
    _t = _baslangic;
    _ticker = createTicker(_tik);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final hareketsiz = MediaQuery.of(context).disableAnimations;
    if (hareketsiz && _ticker.isActive) _ticker.stop();
    if (!hareketsiz && !_ticker.isActive) {
      _onceki = Duration.zero;
      _ticker.start();
    }
  }

  void _tik(Duration gecen) {
    final dt = ((gecen - _onceki).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _onceki = gecen;
    _t += dt;
    final hedef = widget.yuruyor ? 1.0 : 0.0;
    _yuru += (hedef - _yuru) * min(1.0, dt * 5);
    _faz += dt * 1.9 * _yuru;
    var hop = 0.0;
    if (widget.zipla && _yuru < 0.2) {
      const periyot = 3.8;
      final u = (_t % periyot) / 0.6;
      if (u < 1) hop = u;
    }
    _kare.guncelle(_t, _faz, _yuru, hop);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _kare.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.boyut,
      height: widget.boyut * 0.8,
      child: CustomPaint(
        painter: MaskotBoyaci(
          karakter: widget.karakter,
          ruh: widget.ruh,
          sagaBakiyor: widget.sagaBakiyor,
          kare: _kare,
        ),
      ),
    );
  }
}

/// Maskotu çizer. [kare] verilmezse sabit bir poz çizilir (ör. testler).
class MaskotBoyaci extends CustomPainter {
  final String karakter;
  final MaskotRuh ruh;
  final bool sagaBakiyor;
  final MaskotKaresi? kare;

  MaskotBoyaci({required this.karakter, required this.ruh, this.sagaBakiyor = true, this.kare}) : super(repaint: kare);

  static const double _zemin = 76;

  @override
  void paint(Canvas canvas, Size size) {
    final t = kare?.t ?? 0;
    final faz = kare?.faz ?? 0;
    final yuru = kare?.yuru ?? 0;
    final hop = kare?.hop ?? 0;

    canvas.save();
    if (!sagaBakiyor) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    final s = size.width / 100;
    canvas.scale(s, s);

    // Zıplama: çömelme → sıçrama → yere iniş.
    var ziplamaY = 0.0;
    var ezilme = 1.0;
    if (hop > 0) {
      if (hop < 0.18) {
        ezilme = 1 - 0.1 * sin(hop / 0.18 * pi);
      } else {
        final u = (hop - 0.18) / 0.82;
        ziplamaY = -sin(u * pi) * 9;
        ezilme = 1 + 0.05 * sin(u * pi);
      }
    }

    _golge(canvas, ziplamaY);
    canvas.save();
    canvas.translate(50, _zemin);
    canvas.scale(1 / ezilme.clamp(0.9, 1.1), ezilme);
    canvas.translate(-50, -_zemin + ziplamaY);

    if (karakter == 'yengec') {
      _yengec(canvas, t, faz, yuru);
    } else {
      _dortAyakli(canvas, _turler[karakter] ?? _turler['kedi']!, t, faz, yuru);
    }
    canvas.restore();
    canvas.restore();
  }

  void _golge(Canvas canvas, double ziplamaY) {
    final k = 1 + ziplamaY / 30;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(50, _zemin + 1.5), width: 56 * k, height: 5 * k),
      Paint()..color = const Color(0xFF0F172A).withValues(alpha: 0.13 * k),
    );
  }

  static bool _kirpiyor(double t) {
    final u = t % 3.9;
    return u < 0.12 || (t % 11.7 > 11.4 && u > 0.25 && u < 0.35);
  }

  // ─── Dört ayaklılar ───────────────────────────────────────────────────

  void _dortAyakli(Canvas canvas, _Tur tur, double t, double faz, double yuru) {
    final L = tur.bacak;
    final kalcaY = _zemin - L - 2;
    final nefes = sin(t * 2 * pi / 2.6) * (1 - yuru);
    final yaylanma = -(1 - cos(faz * 4 * pi)) / 2 * 1.8 * yuru;
    const bx = 44.0;
    final by = kalcaY - 4 + yaylanma;
    final rx = tur.govdeRx;
    const ry = 12.0;
    final onKalca = bx + rx * 0.58;
    final arkaKalca = bx - rx * 0.58;

    double bacakAcisi(double ofset) => sin(faz * 2 * pi + ofset) * 0.55 * yuru;
    double kaldirma(double ofset) => max(0.0, cos(faz * 2 * pi + ofset)) * 2.6 * yuru;

    // Uzak bacaklar (koyu, gövdenin arkasında)
    _bacak(canvas, tur, Offset(onKalca - 3, kalcaY + yaylanma), bacakAcisi(pi), kaldirma(pi), L, uzak: true);
    _bacak(canvas, tur, Offset(arkaKalca - 3, kalcaY + yaylanma), bacakAcisi(0), kaldirma(0), L, uzak: true);

    // Kuyruk
    _kuyruk(canvas, tur, Offset(bx - rx + 3, by - 3), t, yuru);

    // Gövde
    final govdeRect = Rect.fromCenter(center: Offset(bx, by - nefes * 0.3), width: rx * 2, height: ry * 2 * (1 + nefes * 0.02));
    canvas.drawRRect(RRect.fromRectAndRadius(govdeRect, const Radius.circular(ry)), Paint()..color = tur.govde);
    // Yumuşak ışık
    canvas.drawOval(
      Rect.fromCenter(center: Offset(bx - 2, by - 6), width: rx * 1.4, height: 7),
      Paint()..color = Colors.white.withValues(alpha: 0.16),
    );
    // Göğüs / karın
    if (tur.yuz == _Yuz.kopek || tur.yuz == _Yuz.tilki) {
      canvas.drawOval(Rect.fromCenter(center: Offset(bx + rx - 4, by + 1), width: 15, height: 19), Paint()..color = tur.acik);
    } else if (tur.yuz == _Yuz.panda) {
      // Omuz bandı
      final bant = Path()
        ..moveTo(bx + rx * 0.28, by - ry)
        ..quadraticBezierTo(bx + rx * 0.42, by, bx + rx * 0.34, by + ry)
        ..lineTo(bx + rx * 0.6, by + ry)
        ..quadraticBezierTo(bx + rx * 0.66, by, bx + rx * 0.52, by - ry)
        ..close();
      canvas.save();
      canvas.clipRRect(RRect.fromRectAndRadius(govdeRect, const Radius.circular(ry)));
      canvas.drawPath(bant, Paint()..color = tur.uc);
      canvas.restore();
    } else {
      canvas.drawOval(Rect.fromCenter(center: Offset(bx + 2, by + 6), width: rx * 1.3, height: 9), Paint()..color = tur.acik);
    }

    // Yakın bacaklar
    _bacak(canvas, tur, Offset(arkaKalca + 1, kalcaY + yaylanma), bacakAcisi(pi), kaldirma(pi), L);
    _bacak(canvas, tur, Offset(onKalca + 1, kalcaY + yaylanma), bacakAcisi(0), kaldirma(0), L);

    // Baş
    final hx = bx + rx + 5;
    final hy = by - 13 - (tur.basR - 14) * 0.75 + nefes * 0.6;
    final basAcisi = sin(faz * 4 * pi) * 0.035 * yuru + sin(t * 2 * pi / 6.3) * 0.07 * (1 - yuru);
    canvas.save();
    canvas.translate(hx, hy + 6);
    canvas.rotate(basAcisi);
    canvas.translate(-hx, -hy - 6);
    _bas(canvas, tur, Offset(hx, hy), t, yuru);
    canvas.restore();
  }

  void _bacak(Canvas canvas, _Tur tur, Offset kalca, double aci, double kaldir, double L, {bool uzak = false}) {
    final uzunluk = L + 1 - kaldir;
    final son = kalca + Offset(sin(aci) * uzunluk, cos(aci) * uzunluk);
    final kalinlik = tur.bacak < 10 ? 6.2 : 5.4;
    final ana = uzak ? tur.koyu : tur.govde;
    Color alt;
    if (tur.ucBacak) {
      alt = uzak ? Color.lerp(tur.uc, Colors.black, 0.15)! : tur.uc;
    } else if (tur.beyazCorap) {
      alt = uzak ? Color.lerp(tur.acik, Colors.black, 0.1)! : tur.acik;
    } else {
      alt = ana;
    }
    final p = Paint()
      ..strokeWidth = kalinlik
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(kalca, son, p..color = tur.yuz == _Yuz.panda ? alt : ana);
    if (alt != ana) {
      final orta = Offset.lerp(kalca, son, tur.yuz == _Yuz.panda ? 0 : 0.5)!;
      canvas.drawLine(orta, son, p..color = alt);
    }
    // Pati
    canvas.drawOval(Rect.fromCenter(center: son + const Offset(0.8, 0.4), width: kalinlik + 1.2, height: kalinlik * 0.8), Paint()..color = alt);
  }

  void _kuyruk(Canvas canvas, _Tur tur, Offset kok, double t, double yuru) {
    final mutlu = ruh == MaskotRuh.mutlu || ruh == MaskotRuh.gururlu;
    canvas.save();
    canvas.translate(kok.dx, kok.dy);
    switch (tur.kuyruk) {
      case _Kuyruk.uzun:
        final salla = sin(t * 2 * pi * (mutlu ? 0.9 : 0.5)) * 0.28 + sin(t * 2 * pi * 1.8) * 0.1 * yuru;
        canvas.rotate(salla);
        final yol = Path()
          ..moveTo(0, 0)
          ..cubicTo(-10, -2, -16, -8, -14, -18)
          ..cubicTo(-13, -24, -8, -27, -5, -24);
        final p = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 5.2
          ..color = tur.govde;
        canvas.drawPath(yol, p);
        if (tur.ucKuyruk) {
          final metrik = yol.computeMetrics().first;
          final uc = metrik.extractPath(metrik.length * (tur.maske ? 0.25 : 0.62), metrik.length);
          canvas.drawPath(uc, p..color = tur.uc);
        }
      case _Kuyruk.tuylu:
        final salla = sin(t * 2 * pi * 0.7) * 0.18 + sin(t * 2 * pi * 1.8) * 0.08 * yuru;
        canvas.rotate(-0.35 + salla);
        final yol = Path()
          ..moveTo(0, 0)
          ..cubicTo(-8, -7, -24, -8, -26, 2)
          ..cubicTo(-22, 6, -10, 7, 0, 3)
          ..close();
        canvas.drawPath(yol, Paint()..color = tur.govde);
        canvas.drawOval(Rect.fromCenter(center: const Offset(-23, 0.5), width: 8, height: 7), Paint()..color = tur.acik);
      case _Kuyruk.kisa:
        final salla = sin(t * 2 * pi * (mutlu ? 3.2 : 1.2)) * (mutlu ? 0.45 : 0.2);
        canvas.rotate(-0.6 + salla);
        canvas.drawOval(Rect.fromCenter(center: const Offset(-4, -1), width: 10, height: 6.5), Paint()..color = tur.govde);
        canvas.drawOval(Rect.fromCenter(center: const Offset(-7, -1.5), width: 4.5, height: 4), Paint()..color = tur.acik);
      case _Kuyruk.top:
        canvas.drawCircle(const Offset(-1.5, 0), 3.8, Paint()..color = tur.govde);
    }
    canvas.restore();
  }

  void _bas(Canvas canvas, _Tur tur, Offset m, double t, double yuru) {
    // Yüz ayrıntıları 14 birimlik kafaya göre yerleştirilir, sonra türün
    // kafa boyutuna ölçeklenir (iri kafa = daha sevimli oran).
    canvas.save();
    canvas.translate(m.dx, m.dy);
    canvas.scale(tur.basR / 14);
    canvas.translate(-m.dx, -m.dy);
    _basCiz(canvas, tur, m, t);
    canvas.restore();
  }

  void _basCiz(Canvas canvas, _Tur tur, Offset m, double t) {
    const r = 14.0;
    final kulakSeyirme = (t % 5.3 < 0.25) ? sin((t % 5.3) / 0.25 * pi) * 0.25 : 0.0;

    // Kulaklar (başın arkasında)
    switch (tur.kulak) {
      case _Kulak.sivri:
      case _Kulak.buyukSivri:
        final buyuk = tur.kulak == _Kulak.buyukSivri;
        final yuk = buyuk ? 24.0 : 20.0;
        void kulak(double x1, double x2, double tepeX, double donus) {
          canvas.save();
          canvas.translate((x1 + x2) / 2, m.dy - r * 0.55);
          canvas.rotate(donus);
          canvas.translate(-(x1 + x2) / 2, -(m.dy - r * 0.55));
          final dis = Path()
            ..moveTo(x1, m.dy - r * 0.35)
            ..quadraticBezierTo(tepeX - 1, m.dy - yuk + 2, tepeX, m.dy - yuk)
            ..quadraticBezierTo(tepeX + 1.5, m.dy - yuk + 3, x2, m.dy - r * 0.55)
            ..close();
          canvas.drawPath(dis, Paint()..color = tur.ucKulak ? tur.uc : tur.govde);
          final ic = Path()
            ..moveTo(x1 + 2.2, m.dy - r * 0.45)
            ..lineTo(tepeX + 0.2, m.dy - yuk + 4.5)
            ..lineTo(x2 - 2.2, m.dy - r * 0.6)
            ..close();
          canvas.drawPath(ic, Paint()..color = tur.kulakIc);
          canvas.restore();
        }

        kulak(m.dx - r * 0.85, m.dx - 1, m.dx - r * 0.55, -0.05);
        kulak(m.dx + 1, m.dx + r * 0.85, m.dx + r * 0.45, 0.08 + kulakSeyirme);
      case _Kulak.yuvarlak:
        canvas.drawCircle(Offset(m.dx - r * 0.62, m.dy - r * 0.78), 5.6, Paint()..color = tur.uc);
        canvas.drawCircle(Offset(m.dx + r * 0.55, m.dy - r * 0.82 - kulakSeyirme * 3), 5.6, Paint()..color = tur.uc);
    }

    // Kafa
    canvas.drawCircle(m, r, Paint()..color = tur.govde);
    canvas.drawOval(Rect.fromCenter(center: m + Offset(-2, -r * 0.5), width: r * 1.1, height: r * 0.5),
        Paint()..color = Colors.white.withValues(alpha: 0.15));

    // Yüz yerleşimi (3/4 profil, sağa dönük)
    final kopekgil = tur.yuz == _Yuz.kopek || tur.yuz == _Yuz.tilki;
    final gozSol = m + (kopekgil ? const Offset(-1.5, -2.5) : const Offset(0, -0.5));
    final gozSag = m + (kopekgil ? const Offset(6.5, -3) : const Offset(8.5, -0.5));
    final burunMerkez = m + (kopekgil ? const Offset(11.5, 4) : const Offset(5.5, 5.5));

    if (tur.maske) {
      canvas.drawOval(Rect.fromCenter(center: m + const Offset(6, 5), width: 15, height: 11),
          Paint()..color = tur.uc.withValues(alpha: 0.6));
    }
    if (tur.gozBandi) {
      for (final g in [gozSol, gozSag]) {
        canvas.save();
        canvas.translate(g.dx, g.dy + 0.8);
        canvas.rotate(g == gozSol ? 0.35 : -0.35);
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 7, height: 9), Paint()..color = tur.uc);
        canvas.restore();
      }
    }
    if (tur.yuz == _Yuz.kopek) {
      // Alında beyaz alev
      final alev = Path()
        ..moveTo(m.dx + 2.5, m.dy - r + 1)
        ..quadraticBezierTo(m.dx + 1, m.dy + 1, m.dx + 5, m.dy + 4)
        ..lineTo(m.dx + 8, m.dy + 2)
        ..quadraticBezierTo(m.dx + 4, m.dy - 2, m.dx + 3.5, m.dy - r + 1)
        ..close();
      canvas.drawPath(alev, Paint()..color = tur.acik);
    }
    if (kopekgil) {
      // Burun çıkıntısı
      final burun = Path();
      if (tur.yuz == _Yuz.tilki) {
        burun
          ..moveTo(m.dx + 3, m.dy)
          ..quadraticBezierTo(m.dx + 14, m.dy + 1, m.dx + 19, m.dy + 4)
          ..quadraticBezierTo(m.dx + 14, m.dy + 10, m.dx + 3, m.dy + 9)
          ..close();
        canvas.drawPath(burun, Paint()..color = tur.acik);
        canvas.drawOval(Rect.fromCenter(center: m + const Offset(-4, 6), width: 9, height: 7), Paint()..color = tur.acik);
      } else {
        canvas.drawOval(Rect.fromCenter(center: burunMerkez, width: 15, height: 10.5), Paint()..color = tur.acik);
      }
      canvas.drawOval(Rect.fromCenter(center: m + Offset(tur.yuz == _Yuz.tilki ? 18.5 : 18, 2.2), width: 4.6, height: 3.6),
          Paint()..color = const Color(0xFF2A1E1A));
    } else if (tur.yuz == _Yuz.panda) {
      canvas.drawOval(Rect.fromCenter(center: burunMerkez + const Offset(1, 0.5), width: 11, height: 7.5), Paint()..color = tur.acik);
      canvas.drawOval(Rect.fromCenter(center: burunMerkez + const Offset(1.5, -1.2), width: 3.8, height: 2.6), Paint()..color = tur.uc);
    } else {
      // Kedi ağzı bölgesi
      if (!tur.maske) {
        canvas.drawOval(Rect.fromCenter(center: burunMerkez, width: 11, height: 7.5), Paint()..color = tur.acik);
      }
      final nb = Path()
        ..moveTo(burunMerkez.dx - 1.3, burunMerkez.dy - 2.2)
        ..lineTo(burunMerkez.dx + 1.3, burunMerkez.dy - 2.2)
        ..lineTo(burunMerkez.dx, burunMerkez.dy - 0.8)
        ..close();
      canvas.drawPath(nb, Paint()..color = const Color(0xFFE9798F));
      // Bıyıklar
      final by = Paint()
        ..color = (tur.maske ? Colors.white : const Color(0xFF6B5A55)).withValues(alpha: 0.55)
        ..strokeWidth = 0.6
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(burunMerkez + const Offset(4, -0.5), burunMerkez + const Offset(11, -2), by);
      canvas.drawLine(burunMerkez + const Offset(4, 1), burunMerkez + const Offset(11, 1.5), by);
    }

    // Yanak allığı
    canvas.drawCircle(m + (kopekgil ? const Offset(0, 5) : const Offset(-2.5, 4.5)), 2.6,
        Paint()..color = const Color(0xFFFF8FA3).withValues(alpha: tur.yuz == _Yuz.panda ? 0.35 : 0.45));

    _gozler(canvas, tur, gozSol, gozSag, t);
    _agiz(canvas, tur, burunMerkez, kopekgil, t);
    _efektler(canvas, m, r, t);
  }

  void _gozler(Canvas canvas, _Tur tur, Offset sol, Offset sag, double t) {
    final kirp = _kirpiyor(t);
    final cizgi = Paint()
      ..color = tur.gozBandi ? Colors.white : const Color(0xFF1F2A2A)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final bakis = ruh == MaskotRuh.dusunceli ? const Offset(0.6, -1) : const Offset(0.5, 0);
    for (final g in [sol, sag]) {
      if (ruh == MaskotRuh.gururlu) {
        canvas.drawPath(Path()
          ..moveTo(g.dx - 2.4, g.dy + 0.8)
          ..quadraticBezierTo(g.dx, g.dy - 2.4, g.dx + 2.4, g.dy + 0.8), cizgi);
      } else if (kirp || ruh == MaskotRuh.odakli) {
        canvas.drawLine(g + const Offset(-2.2, 0.5), g + const Offset(2.2, 0.5), cizgi);
      } else {
        final gozR = g == sol ? 3.3 : 3.1;
        canvas.drawOval(Rect.fromCenter(center: g, width: gozR * 2, height: gozR * 2.25), Paint()..color = tur.gozBandi ? const Color(0xFF1B1B1B) : tur.goz);
        if (tur.gozBandi) {
          canvas.drawCircle(g + bakis, 1.5, Paint()..color = Colors.white);
        } else {
          canvas.drawCircle(g + bakis * 0.6, gozR * 0.45, Paint()..color = const Color(0xFF111827).withValues(alpha: tur.goz == const Color(0xFF2B1D14) ? 0 : 0.55));
          canvas.drawCircle(g + const Offset(-0.9, -1.1), gozR * 0.36, Paint()..color = Colors.white);
          canvas.drawCircle(g + const Offset(1, 1), gozR * 0.16, Paint()..color = Colors.white.withValues(alpha: 0.8));
        }
      }
    }
    if (ruh == MaskotRuh.endiseli) {
      canvas.drawLine(sol + const Offset(-2.5, -4.2), sol + const Offset(2, -5.2), cizgi);
      canvas.drawLine(sag + const Offset(-2, -5.2), sag + const Offset(2.5, -4.2), cizgi);
    }
  }

  void _agiz(Canvas canvas, _Tur tur, Offset burun, bool kopekgil, double t) {
    final p = Paint()
      ..color = tur.yuz == _Yuz.panda ? tur.uc : const Color(0xFF3B2A26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    final a = kopekgil ? burun + const Offset(1.5, 3.2) : burun + const Offset(0, 0.6);
    switch (ruh) {
      case MaskotRuh.mutlu:
      case MaskotRuh.gururlu:
        if (kopekgil) {
          canvas.drawPath(Path()
            ..moveTo(a.dx - 3.5, a.dy - 0.5)
            ..quadraticBezierTo(a.dx, a.dy + 3, a.dx + 3.5, a.dy - 1), p);
          if (tur.yuz == _Yuz.kopek) {
            final hirilti = 1 + sin(t * 2 * pi * 2.4) * 0.12;
            canvas.drawRRect(
              RRect.fromRectAndRadius(Rect.fromCenter(center: a + Offset(0.2, 2.6 * hirilti), width: 3.6, height: 4.8 * hirilti), const Radius.circular(1.8)),
              Paint()..color = const Color(0xFFF0648A),
            );
          }
        } else {
          canvas.drawPath(Path()
            ..moveTo(a.dx - 2.6, a.dy)
            ..quadraticBezierTo(a.dx - 1.3, a.dy + 1.8, a.dx, a.dy)
            ..quadraticBezierTo(a.dx + 1.3, a.dy + 1.8, a.dx + 2.6, a.dy), p);
        }
      case MaskotRuh.dusunceli:
        canvas.drawOval(Rect.fromCenter(center: a + const Offset(0, 1.4), width: 2.2, height: 2.4), p);
      case MaskotRuh.endiseli:
        canvas.drawPath(Path()
          ..moveTo(a.dx - 2.5, a.dy + 1.4)
          ..quadraticBezierTo(a.dx - 1.2, a.dy + 0.2, a.dx, a.dy + 1.4)
          ..quadraticBezierTo(a.dx + 1.2, a.dy + 2.6, a.dx + 2.5, a.dy + 1.4), p);
      case MaskotRuh.odakli:
        canvas.drawLine(a + const Offset(-1.8, 1), a + const Offset(1.8, 1), p);
    }
  }

  void _efektler(Canvas canvas, Offset m, double r, double t) {
    switch (ruh) {
      case MaskotRuh.dusunceli:
        final p = Paint()..color = const Color(0xFFA9B0CC);
        final u = (t % 1.8) / 1.8;
        for (var i = 0; i < 3; i++) {
          final gorunur = ((u * 4) - i).clamp(0.0, 1.0);
          if (gorunur <= 0) continue;
          canvas.drawCircle(m + Offset(-r * 0.9 - i * 5.5, -r - 3 - i * 5.5), (1.4 + i * 0.9) * gorunur, p);
        }
      case MaskotRuh.endiseli:
        final u = (t % 1.6) / 1.6;
        final d = m + Offset(-r * 0.95, -r * 0.3 + u * 6);
        final damla = Path()
          ..moveTo(d.dx, d.dy - 3.2)
          ..quadraticBezierTo(d.dx + 2.2, d.dy, d.dx, d.dy + 1.6)
          ..quadraticBezierTo(d.dx - 2.2, d.dy, d.dx, d.dy - 3.2);
        canvas.drawPath(damla, Paint()..color = const Color(0xFF7CC4F2).withValues(alpha: 1 - u * 0.6));
      case MaskotRuh.gururlu:
        for (final (ofset, faz) in [(Offset(r + 3, -r - 1), 0.0), (Offset(-r - 1, -r + 2), 0.5)]) {
          final k = 0.6 + 0.4 * sin((t / 1.4 + faz) * 2 * pi).abs();
          _parilti(canvas, m + ofset, 3.2 * k, const Color(0xFFF6C343));
        }
      case MaskotRuh.odakli:
        final p = Paint()
          ..color = const Color(0xFF2A3363)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(Rect.fromCircle(center: m, radius: r + 1.5), pi * 1.05, pi * 0.9, false, p);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: m + Offset(-r + 0.5, 0), width: 5.5, height: 8.5), const Radius.circular(2.5)),
            Paint()..color = const Color(0xFFA5B4FF));
      case MaskotRuh.mutlu:
        break;
    }
  }

  void _parilti(Canvas canvas, Offset c, double r, Color renk) {
    final p = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r);
    canvas.drawPath(p, Paint()..color = renk);
  }

  // ─── Yengeç ──────────────────────────────────────────────────────────

  void _yengec(Canvas canvas, double t, double faz, double yuru) {
    const govde = Color(0xFFF4511E);
    const koyu = Color(0xFFC63F17);
    const acik = Color(0xFFFF8A50);
    final yanSalinim = sin(faz * 2 * pi) * 2.2 * yuru;
    final nefes = sin(t * 2 * pi / 2.4) * (1 - yuru);
    final bx = 50 + yanSalinim;
    final by = 55 - (1 - cos(faz * 4 * pi)) / 2 * 1.4 * yuru + nefes * 0.4;

    // Bacaklar: her yanda 3, yürürken sırayla kalkar
    final bacak = Paint()
      ..color = koyu
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var yan = -1; yan <= 1; yan += 2) {
      for (var i = 0; i < 3; i++) {
        final ofset = i * 2.1 + (yan > 0 ? pi : 0);
        final kalk = max(0.0, sin(faz * 2 * pi + ofset)) * 3.5 * yuru;
        final kok = Offset(bx + yan * (16 - i), by + 2 + i * 3);
        final diz = Offset(bx + yan * (26 + i * 4), by - 6 + i * 4 - kalk);
        final ayak = Offset(bx + yan * (30 + i * 6), _zemin - kalk * 0.6);
        canvas.drawPath(Path()
          ..moveTo(kok.dx, kok.dy)
          ..lineTo(diz.dx, diz.dy)
          ..lineTo(ayak.dx, ayak.dy), bacak);
      }
    }

    // Göz sapları
    final sapSalla = sin(t * 2 * pi / 3.1) * 1.2;
    final sap = Paint()
      ..color = govde
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    final gozSol = Offset(bx - 8 + sapSalla * 0.5, by - 22);
    final gozSag = Offset(bx + 8 + sapSalla * 0.5, by - 22.5);
    canvas.drawLine(Offset(bx - 6, by - 10), gozSol, sap);
    canvas.drawLine(Offset(bx + 6, by - 10), gozSag, sap);

    // Kıskaçlar (şık şık açılıp kapanır)
    final kiskacAc = (ruh == MaskotRuh.mutlu || ruh == MaskotRuh.gururlu)
        ? (sin(t * 2 * pi * 1.3) * 0.5 + 0.5)
        : (sin(t * 2 * pi * 0.4) * 0.5 + 0.5) * 0.5;
    for (var yan = -1; yan <= 1; yan += 2) {
      final omuz = Offset(bx + yan * 18, by - 4);
      final dirsek = Offset(bx + yan * 28, by - 13 + sin(t * 2 * pi * 0.8 + yan) * 1.4);
      canvas.drawPath(Path()
        ..moveTo(omuz.dx, omuz.dy)
        ..quadraticBezierTo(bx + yan * 28, by - 4, dirsek.dx, dirsek.dy), bacak..strokeWidth = 4);
      bacak.strokeWidth = 3.2;
      final k = dirsek + Offset(yan * 2, -7);
      // Üst çene (açılıp kapanan) — alt çenenin arkasında
      canvas.save();
      canvas.translate(k.dx + yan * 2, k.dy - 3);
      canvas.rotate(-yan * (0.1 + kiskacAc * 0.6));
      canvas.drawOval(Rect.fromCenter(center: Offset(yan * 1.5, -5), width: 8, height: 11), Paint()..color = govde);
      canvas.restore();
      // Alt çene (büyük, yuvarlak)
      canvas.drawOval(Rect.fromCenter(center: k, width: 14, height: 12), Paint()..color = govde);
      canvas.drawOval(Rect.fromCenter(center: k + const Offset(-1, -2.5), width: 7, height: 3.5), Paint()..color = acik.withValues(alpha: 0.7));
    }

    // Gövde
    final rect = Rect.fromCenter(center: Offset(bx, by), width: 44, height: 28 * (1 + nefes * 0.015));
    canvas.drawOval(rect, Paint()..color = govde);
    canvas.drawOval(Rect.fromCenter(center: Offset(bx - 3, by - 6), width: 28, height: 9), Paint()..color = acik.withValues(alpha: 0.7));
    // Kabuk benekleri
    for (final o in const [Offset(-12, -2), Offset(10, -4), Offset(3, -8)]) {
      canvas.drawCircle(Offset(bx, by) + o, 1.4, Paint()..color = acik);
    }

    // Gözler
    final kirp = _kirpiyor(t);
    for (final g in [gozSol, gozSag]) {
      canvas.drawCircle(g, 4.6, Paint()..color = Colors.white);
      if (kirp || ruh == MaskotRuh.odakli) {
        canvas.drawLine(g + const Offset(-2.4, 0), g + const Offset(2.4, 0),
            Paint()
              ..color = const Color(0xFF1F2A2A)
              ..strokeWidth = 1.4
              ..strokeCap = StrokeCap.round);
      } else if (ruh == MaskotRuh.gururlu) {
        canvas.drawPath(
            Path()
              ..moveTo(g.dx - 2.4, g.dy + 1)
              ..quadraticBezierTo(g.dx, g.dy - 2.2, g.dx + 2.4, g.dy + 1),
            Paint()
              ..color = const Color(0xFF1F2A2A)
              ..strokeWidth = 1.4
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round);
      } else {
        final bak = ruh == MaskotRuh.dusunceli ? const Offset(0.4, -1.4) : const Offset(0.6, 0.4);
        canvas.drawCircle(g + bak, 2.5, Paint()..color = const Color(0xFF111827));
        canvas.drawCircle(g + bak + const Offset(-0.8, -0.9), 0.9, Paint()..color = Colors.white);
      }
    }

    // Yüz
    final agiz = Offset(bx, by + 2);
    final p = Paint()
      ..color = const Color(0xFF5A1A08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    switch (ruh) {
      case MaskotRuh.mutlu:
      case MaskotRuh.gururlu:
        canvas.drawPath(Path()
          ..moveTo(agiz.dx - 4, agiz.dy - 1)
          ..quadraticBezierTo(agiz.dx, agiz.dy + 3.5, agiz.dx + 4, agiz.dy - 1), p);
      case MaskotRuh.dusunceli:
        canvas.drawOval(Rect.fromCenter(center: agiz, width: 2.6, height: 2.8), p);
      case MaskotRuh.endiseli:
        canvas.drawPath(Path()
          ..moveTo(agiz.dx - 3.5, agiz.dy + 1)
          ..quadraticBezierTo(agiz.dx, agiz.dy - 2, agiz.dx + 3.5, agiz.dy + 1), p);
      case MaskotRuh.odakli:
        canvas.drawLine(agiz + const Offset(-2.5, 0), agiz + const Offset(2.5, 0), p);
    }
    for (final yan in [-1, 1]) {
      canvas.drawCircle(Offset(bx + yan * 9, by + 1), 2.6, Paint()..color = const Color(0xFFFFB199).withValues(alpha: 0.7));
    }
    _efektler(canvas, Offset(bx, by - 18), 9, t);
  }

  @override
  bool shouldRepaint(MaskotBoyaci old) =>
      old.karakter != karakter || old.ruh != ruh || old.sagaBakiyor != sagaBakiyor || old.kare != kare;
}
