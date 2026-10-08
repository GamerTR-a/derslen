/// İklim bölgelerinin orman manzaraları. Zemin, sahnenin alt yarısını
/// kaplar; bitkiler widget olarak üzerine yerleştirilir.
library;

import 'dart:math';
import 'package:flutter/material.dart';

double _dalga(double t, num kat, [double faz = 0]) => sin((t * kat + faz) * 2 * pi);

class IklimSahnesiBoyaci extends CustomPainter {
  final String iklim;
  final bool gece;
  final double t;

  IklimSahnesiBoyaci(this.iklim, this.gece, this.t);

  /// Zeminin başladığı yükseklik oranı.
  static const double ufuk = 0.52;

  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.clipRect(Offset.zero & s);
    switch (iklim) {
      case 'akdeniz':
        _akdeniz(c, s);
      case 'step':
        _step(c, s);
      case 'ekvatoral':
        _ekvatoral(c, s);
      case 'savan':
        _savan(c, s);
      case 'col':
        _col(c, s);
      case 'tayga':
        _tayga(c, s);
      case 'tundra':
        _tundra(c, s);
      default:
        _iliman(c, s);
    }
    if (gece) _geceOrtusu(c, s);
    c.restore();
  }

  // ─── Ortak parçalar ───────────────────────────────────────

  void _gok(Canvas c, Size s, Color ust, Color alt) {
    final r = Offset.zero & s;
    c.drawRect(r, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [ust, alt]).createShader(r));
  }

  void _tepe(Canvas c, Size s, double y, double genlik, Color renk, {double faz = 0, double siklik = 2}) {
    final path = Path()..moveTo(0, s.height * y);
    for (var x = 0.0; x <= s.width + 8; x += 8) {
      path.lineTo(x, s.height * y + sin(x / s.width * pi * siklik + faz) * genlik);
    }
    path
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    c.drawPath(path, Paint()..color = renk);
  }

  void _bulut(Canvas c, Offset o, double w, Color renk) {
    final p = Paint()..color = renk;
    c.drawOval(Rect.fromCenter(center: o, width: w, height: w * 0.3), p);
    c.drawOval(Rect.fromCenter(center: o.translate(w * 0.18, -w * 0.1), width: w * 0.6, height: w * 0.32), p);
  }

  void _gunes(Canvas c, Offset o, double r, Color renk) {
    c.drawCircle(o, r * 1.45 + _dalga(t, 4) * 1.5, Paint()..color = renk.withValues(alpha: 0.25));
    c.drawCircle(o, r, Paint()..color = renk);
  }

  void _dag(Canvas c, Size s, double x, double taban, double w, double h, Color renk, {Color? kar}) {
    final tepe = Offset(s.width * x, s.height * taban - h);
    c.drawPath(
        Path()
          ..moveTo(s.width * x - w / 2, s.height * taban)
          ..lineTo(tepe.dx, tepe.dy)
          ..lineTo(s.width * x + w / 2, s.height * taban)
          ..close(),
        Paint()..color = renk);
    if (kar != null) {
      c.drawPath(
          Path()
            ..moveTo(tepe.dx, tepe.dy)
            ..lineTo(tepe.dx - w * 0.14, tepe.dy + h * 0.28)
            ..lineTo(tepe.dx - w * 0.04, tepe.dy + h * 0.22)
            ..lineTo(tepe.dx + w * 0.05, tepe.dy + h * 0.3)
            ..lineTo(tepe.dx + w * 0.14, tepe.dy + h * 0.28)
            ..close(),
          Paint()..color = kar);
    }
  }

  void _konifer(Canvas c, Offset taban, double h, Color renk) {
    c.drawPath(
        Path()
          ..moveTo(taban.dx, taban.dy - h)
          ..lineTo(taban.dx + h * 0.3, taban.dy)
          ..lineTo(taban.dx - h * 0.3, taban.dy)
          ..close(),
        Paint()..color = renk);
  }

  /// Yukarıdan düşen çizgiler (yağmur) ya da tanecikler (kar).
  void _yagis(Canvas c, Size s, {required int adet, required Color renk, required bool kar}) {
    final r = Random(17);
    final p = Paint()
      ..color = renk
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < adet; i++) {
      final x0 = r.nextDouble();
      final faz = r.nextDouble();
      final hiz = kar ? 1 : 3;
      final y = ((t * hiz + faz) % 1) * s.height;
      final x = x0 * s.width + (kar ? _dalga(t, 3, faz) * 6 : -y * 0.12);
      if (kar) {
        c.drawCircle(Offset(x, y), 1.2 + (i % 3) * 0.5, p);
      } else {
        c.drawLine(Offset(x, y), Offset(x - 2, y + 9), p);
      }
    }
  }

  void _geceOrtusu(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFF0B1030).withValues(alpha: 0.62));
    final r = Random(5);
    for (var i = 0; i < 26; i++) {
      final o = Offset(r.nextDouble() * s.width, r.nextDouble() * s.height * 0.42);
      final a = 0.3 + 0.7 * ((_dalga(t, 6 + i % 5, i * 0.13) + 1) / 2);
      c.drawCircle(o, i % 4 == 0 ? 1.5 : 1, Paint()..color = const Color(0xFFF3EEDF).withValues(alpha: a));
    }
    if (iklim == 'tundra' || iklim == 'tayga') {
      // Kutup ışıkları.
      for (var i = 0; i < 3; i++) {
        final path = Path()..moveTo(0, s.height * (0.16 + i * 0.07));
        for (var x = 0.0; x <= s.width + 8; x += 8) {
          path.lineTo(x, s.height * (0.16 + i * 0.07) + sin(x / s.width * pi * 3 + t * 2 * pi + i) * 9);
        }
        c.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 9
              ..strokeCap = StrokeCap.round
              ..color = (i == 1 ? const Color(0xFF9B8CFF) : const Color(0xFF7FE8B4)).withValues(alpha: 0.22));
      }
    } else {
      final ay = Offset(s.width * 0.84, s.height * 0.17);
      c.drawCircle(ay, 13, Paint()..color = const Color(0xFFF3EEDF));
      c.drawCircle(ay.translate(6, -4), 11, Paint()..color = const Color(0xFF232A52));
    }
  }

  // ─── Bölgeler ─────────────────────────────────────────────

  void _iliman(Canvas c, Size s) {
    _gok(c, s, const Color(0xFFC3D3DB), const Color(0xFFE4ECEA));
    _bulut(c, Offset(s.width * 0.28 + _dalga(t, 1) * 24, s.height * 0.14), 110, const Color(0xFFF2F5F5));
    _bulut(c, Offset(s.width * 0.72 + _dalga(t, 1, 0.4) * 18, s.height * 0.22), 90, const Color(0xFFE9EEEE));
    _dag(c, s, 0.2, ufuk, s.width * 0.6, s.height * 0.34, const Color(0xFF7FB096));
    _dag(c, s, 0.72, ufuk, s.width * 0.7, s.height * 0.4, const Color(0xFF6BA286));
    _tepe(c, s, ufuk - 0.08, 9, const Color(0xFF4F9372), siklik: 3);
    // Yamaçlara çöken sis.
    for (var i = 0; i < 2; i++) {
      final x = ((t * (i == 0 ? 1 : -1) + i * 0.5) % 1) * (s.width + 200) - 100;
      c.drawOval(Rect.fromCenter(center: Offset(x, s.height * (ufuk - 0.06 + i * 0.05)), width: 190, height: 16),
          Paint()..color = Colors.white.withValues(alpha: 0.42));
    }
    _tepe(c, s, ufuk, 5, const Color(0xFF5BA571), faz: 0.8);
    _tepe(c, s, 0.84, 5, const Color(0xFF468C5C), faz: 2.1);
    _yagis(c, s, adet: 10, renk: Colors.white.withValues(alpha: 0.35), kar: false);
  }

  void _akdeniz(Canvas c, Size s) {
    _gok(c, s, const Color(0xFF9FD4EE), const Color(0xFFDDF0F5));
    _gunes(c, Offset(s.width * 0.82, s.height * 0.16), 15, const Color(0xFFFFD86B));
    final deniz = Rect.fromLTRB(0, s.height * (ufuk - 0.16), s.width, s.height * ufuk + 4);
    c.drawRect(deniz, Paint()..color = const Color(0xFF3F9CC4));
    final pul = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 9; i++) {
      final x = ((i * 0.137 + t * (i.isEven ? 1 : -1)) % 1) * s.width;
      final y = deniz.top + 6 + (i % 4) * 6.0;
      c.drawLine(Offset(x, y), Offset(x + 10, y), pul);
    }
    // Uzak burun ve serviler.
    c.drawOval(Rect.fromCenter(center: Offset(s.width * 0.12, s.height * ufuk), width: s.width * 0.5, height: s.height * 0.22),
        Paint()..color = const Color(0xFF9DB07A));
    for (final x in [0.06, 0.13, 0.22]) {
      c.drawOval(Rect.fromCenter(center: Offset(s.width * x, s.height * (ufuk - 0.13)), width: 9, height: 34), Paint()..color = const Color(0xFF3F6B4A));
    }
    _tepe(c, s, ufuk, 5, const Color(0xFFCBD59B), faz: 1.1);
    _tepe(c, s, 0.84, 5, const Color(0xFFB7C285), faz: 2.6);
  }

  void _step(Canvas c, Size s) {
    _gok(c, s, const Color(0xFFBBDDF0), const Color(0xFFF1F3DC));
    _gunes(c, Offset(s.width * 0.16, s.height * 0.16), 14, const Color(0xFFFFE08A));
    _bulut(c, Offset(s.width * 0.55 + _dalga(t, 1) * 30, s.height * 0.13), 120, Colors.white);
    _bulut(c, Offset(s.width * 0.85 + _dalga(t, 1, 0.3) * 20, s.height * 0.26), 80, const Color(0xFFF7FAFA));
    _tepe(c, s, ufuk - 0.07, 7, const Color(0xFFDADCA6), siklik: 1.5);
    _tepe(c, s, ufuk, 4, const Color(0xFFCBCF88), faz: 1.6);
    _tepe(c, s, 0.84, 4, const Color(0xFFB7BC70), faz: 0.4);
    // Rüzgârda yatan otlar.
    final ot = Paint()
      ..color = const Color(0xFF9AA25A)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final r = Random(3);
    for (var i = 0; i < 34; i++) {
      final taban = Offset(r.nextDouble() * s.width, s.height * (ufuk + 0.06 + r.nextDouble() * 0.4));
      final egim = 3 + _dalga(t, 4, taban.dx / s.width) * 3;
      c.drawLine(taban, taban.translate(egim, -8), ot);
    }
  }

  void _ekvatoral(Canvas c, Size s) {
    _gok(c, s, const Color(0xFFA9D8C4), const Color(0xFFE2F1D9));
    _tepe(c, s, ufuk - 0.2, 8, const Color(0xFF6FB388), siklik: 3);
    // Üst üste binen ağaç tepeleri.
    final r = Random(9);
    for (final (y, renk, cap) in [
      (ufuk - 0.12, const Color(0xFF4E9A6B), 26.0),
      (ufuk - 0.04, const Color(0xFF2F7A55), 22.0),
    ]) {
      for (var x = -10.0; x < s.width + 20; x += cap * 1.25) {
        c.drawCircle(Offset(x + r.nextDouble() * 8, s.height * y + r.nextDouble() * 8), cap, Paint()..color = renk);
      }
    }
    c.drawOval(Rect.fromCenter(center: Offset(s.width * 0.5 + _dalga(t, 1) * 30, s.height * (ufuk - 0.2)), width: s.width * 0.9, height: 14),
        Paint()..color = Colors.white.withValues(alpha: 0.4));
    _tepe(c, s, ufuk, 4, const Color(0xFF3E8A5A), faz: 0.5);
    _tepe(c, s, 0.84, 5, const Color(0xFF2E6B47), faz: 2.2);
    _yagis(c, s, adet: 26, renk: Colors.white.withValues(alpha: 0.4), kar: false);
  }

  void _savan(Canvas c, Size s) {
    _gok(c, s, const Color(0xFFF8C873), const Color(0xFFFCE9B8));
    _gunes(c, Offset(s.width * 0.24, s.height * 0.26), 20, const Color(0xFFF58F4D));
    _tepe(c, s, ufuk - 0.06, 5, const Color(0xFFDDAA60), siklik: 1.2);
    // Uzakta şemsiye akasyalar.
    final golge = Paint()..color = const Color(0xFF7A6A3A);
    for (final (x, h) in [(0.62, 34.0), (0.86, 26.0)]) {
      final taban = Offset(s.width * x, s.height * (ufuk - 0.02));
      c.drawRect(Rect.fromLTWH(taban.dx - 1.5, taban.dy - h, 3, h), golge);
      c.drawOval(Rect.fromCenter(center: taban.translate(0, -h), width: h * 1.5, height: h * 0.32), golge);
    }
    _tepe(c, s, ufuk, 3, const Color(0xFFE4BB68), faz: 1);
    _tepe(c, s, 0.84, 4, const Color(0xFFD2A452), faz: 2.4);
  }

  void _col(Canvas c, Size s) {
    _gok(c, s, const Color(0xFFF9D99A), const Color(0xFFFDF0CF));
    _gunes(c, Offset(s.width * 0.78, s.height * 0.15), 16, const Color(0xFFFFF3C4));
    _tepe(c, s, ufuk - 0.1, 14, const Color(0xFFEFC98A), siklik: 1.6, faz: 0.6);
    _tepe(c, s, ufuk, 10, const Color(0xFFE6B66E), siklik: 2.2, faz: 2);
    _tepe(c, s, 0.8, 8, const Color(0xFFDBA65B), siklik: 2.8, faz: 3.4);
    // Kumulların üzerinde savrulan kum.
    final kum = Paint()..color = const Color(0xFFFDF0CF).withValues(alpha: 0.7);
    for (var i = 0; i < 12; i++) {
      final x = ((i * 0.083 + t * 2) % 1) * s.width;
      c.drawCircle(Offset(x, s.height * (ufuk + 0.02 + (i % 5) * 0.08)), 1.1, kum);
    }
  }

  void _tayga(Canvas c, Size s) {
    _gok(c, s, const Color(0xFFB9CEDD), const Color(0xFFE6EEF2));
    _dag(c, s, 0.22, ufuk, s.width * 0.55, s.height * 0.36, const Color(0xFF8FA5B5), kar: Colors.white);
    _dag(c, s, 0.7, ufuk, s.width * 0.62, s.height * 0.42, const Color(0xFF7F97A9), kar: Colors.white);
    for (var i = 0; i < 16; i++) {
      final x = s.width * (i / 15);
      _konifer(c, Offset(x, s.height * ufuk + 3), 24.0 + (i * 7 % 5) * 5, const Color(0xFF2F5D4C));
    }
    _tepe(c, s, ufuk, 3, const Color(0xFFEDF3F5), faz: 0.7);
    _tepe(c, s, 0.84, 4, const Color(0xFFD9E4E9), faz: 2);
    _yagis(c, s, adet: 22, renk: Colors.white.withValues(alpha: 0.85), kar: true);
  }

  void _tundra(Canvas c, Size s) {
    _gok(c, s, const Color(0xFFCADCE8), const Color(0xFFF7E6D8));
    _gunes(c, Offset(s.width * 0.72, s.height * (ufuk - 0.05)), 15, const Color(0xFFFFD9A8));
    _dag(c, s, 0.18, ufuk, s.width * 0.5, s.height * 0.16, const Color(0xFFDCE6EC));
    _tepe(c, s, ufuk, 2, const Color(0xFFF1F5F6), faz: 1.3, siklik: 1.2);
    // Kar erimiş yerlerde yosun ve taşlar.
    final r = Random(21);
    for (var i = 0; i < 9; i++) {
      final o = Offset(r.nextDouble() * s.width, s.height * (ufuk + 0.08 + r.nextDouble() * 0.38));
      c.drawOval(Rect.fromCenter(center: o, width: 28 + r.nextDouble() * 26, height: 7), Paint()..color = const Color(0xFFA9B98A).withValues(alpha: 0.75));
      if (i % 3 == 0) c.drawOval(Rect.fromCenter(center: o.translate(12, -3), width: 11, height: 7), Paint()..color = const Color(0xFF8E979C));
    }
    _yagis(c, s, adet: 14, renk: Colors.white.withValues(alpha: 0.8), kar: true);
  }

  @override
  bool shouldRepaint(covariant IklimSahnesiBoyaci old) => old.t != t || old.gece != gece || old.iklim != iklim;
}
