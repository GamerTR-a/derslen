/// Hareketli arka plan sahneleri (CustomPainter). Tüm sahneler 0..1 arası
/// dönen tek bir `t` değeriyle canlanır; "hareketi azalt" açıkken t sabit kalır.
library;

import 'dart:math';
import 'package:flutter/material.dart';

/// Sonsuz döngüde [t] üreten ve bir painter'ı yeniden çizen sarmalayıcı.
class HareketliSahne extends StatefulWidget {
  final CustomPainter Function(double t) boyaci;
  final Duration dongu;
  final Widget? child;

  const HareketliSahne({super.key, required this.boyaci, this.dongu = const Duration(seconds: 20), this.child});

  @override
  State<HareketliSahne> createState() => _HareketliSahneState();
}

class _HareketliSahneState extends State<HareketliSahne> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.dongu)..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return CustomPaint(painter: widget.boyaci(0.3), child: widget.child);
    }
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) => CustomPaint(painter: widget.boyaci(_c.value), child: child),
        child: widget.child,
      ),
    );
  }
}

double _dalga(double t, num kat, [double faz = 0]) => sin((t * kat + faz) * 2 * pi);

final List<Offset> _yildizlar = List.generate(40, (i) {
  final r = Random(i * 7 + 3);
  return Offset(r.nextDouble(), r.nextDouble() * 0.55);
});

void _yildizCiz(Canvas c, Size s, double t, {double ust = 0.55, Color renk = const Color(0xFFF3EEDF)}) {
  final p = Paint()..color = renk;
  for (var i = 0; i < _yildizlar.length; i++) {
    final y = _yildizlar[i];
    if (y.dy > ust) continue;
    final a = 0.25 + 0.75 * ((_dalga(t, 6 + i % 5, i * 0.13) + 1) / 2);
    p.color = renk.withValues(alpha: a);
    c.drawCircle(Offset(y.dx * s.width, y.dy * s.height), i % 4 == 0 ? 1.6 : 1.1, p);
  }
}

void _bulut(Canvas c, Offset o, double w, Color renk) {
  final p = Paint()..color = renk;
  c.drawOval(Rect.fromCenter(center: o, width: w, height: w * 0.3), p);
  c.drawOval(Rect.fromCenter(center: o.translate(w * 0.18, -w * 0.1), width: w * 0.6, height: w * 0.32), p);
}

void _tepe(Canvas c, Size s, double y, double genlik, Color renk, {double faz = 0}) {
  final path = Path()..moveTo(0, s.height * y);
  for (var x = 0.0; x <= s.width; x += 10) {
    path.lineTo(x, s.height * y + sin(x / s.width * pi * 2 + faz) * genlik);
  }
  path
    ..lineTo(s.width, s.height)
    ..lineTo(0, s.height)
    ..close();
  c.drawPath(path, Paint()..color = renk);
}

void _cam(Canvas c, Offset taban, double h, Color renk, double aci) {
  c.save();
  c.translate(taban.dx, taban.dy);
  c.rotate(aci);
  final p = Paint()..color = renk;
  c.drawRect(Rect.fromLTWH(-2.5, -h * 0.18, 5, h * 0.18), p);
  final path = Path()
    ..moveTo(0, -h)
    ..lineTo(h * 0.32, -h * 0.15)
    ..lineTo(-h * 0.32, -h * 0.15)
    ..close();
  c.drawPath(path, p);
  c.restore();
}

// ─── Çalış ekranı manzaraları ───────────────────────────────

class OdakSahnesiBoyaci extends CustomPainter {
  final String sahne;
  final double t;

  OdakSahnesiBoyaci(this.sahne, this.t);

  @override
  void paint(Canvas c, Size s) {
    switch (sahne) {
      case 'gunBatimi':
        _gunBatimi(c, s);
      case 'gece':
        _sehirGecesi(c, s);
      case 'deniz':
        _deniz(c, s);
      case 'kutuphane':
        _kutuphane(c, s);
      case 'ozel':
        break;
      default:
        _orman(c, s);
    }
  }

  void _orman(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFF35554F));
    _bulut(c, Offset(s.width * 0.25 + _dalga(t, 1) * 30, s.height * 0.18), 120, const Color(0xFF4B6B64));
    _bulut(c, Offset(s.width * 0.78 + _dalga(t, 1, 0.4) * 24, s.height * 0.27), 140, const Color(0xFF44635C));
    _tepe(c, s, 0.66, 12, const Color(0xFF284540));
    for (final a in [(0.12, 70.0, 0.0), (0.88, 86.0, 0.3), (0.7, 52.0, 0.6), (0.3, 44.0, 0.8)]) {
      _cam(c, Offset(s.width * a.$1, s.height * 0.72), a.$2, const Color(0xFF1D3833), _dalga(t, 5, a.$3) * 0.035);
    }
    _tepe(c, s, 0.8, 8, const Color(0xFF1A302C), faz: 1.4);
  }

  void _gunBatimi(Canvas c, Size s) {
    const bantlar = [Color(0xFFF3A15F), Color(0xFFEB8A5B), Color(0xFFD4705F), Color(0xFFA85C6E)];
    for (var i = 0; i < bantlar.length; i++) {
      c.drawRect(Rect.fromLTWH(0, s.height * i * 0.17, s.width, s.height * 0.17 + 1), Paint()..color = bantlar[i]);
    }
    c.drawRect(Rect.fromLTWH(0, s.height * 0.68, s.width, s.height), Paint()..color = const Color(0xFF7D4E6E));
    final gunes = Offset(s.width * 0.5, s.height * (0.64 + 0.02 * _dalga(t, 1)));
    c.drawCircle(gunes, 54, Paint()..color = const Color(0x33FFE0A8));
    c.drawCircle(gunes, 38, Paint()..color = const Color(0xFFFFD29B));
    _tepe(c, s, 0.7, 14, const Color(0xFF5A3D63));
    _tepe(c, s, 0.82, 10, const Color(0xFF3B2D52), faz: 2);
    final kus = Paint()
      ..color = const Color(0xFF3B2D52)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final x = ((t + i * 0.23) % 1) * (s.width + 60) - 30;
      final y = s.height * (0.25 + i * 0.06) + _dalga(t, 8, i * 0.2) * 4;
      final kanat = 4 + _dalga(t, 30, i * 0.3) * 3;
      c.drawPath(Path()
        ..moveTo(x - 8, y)
        ..quadraticBezierTo(x - 4, y - kanat, x, y)
        ..quadraticBezierTo(x + 4, y - kanat, x + 8, y), kus);
    }
  }

  void _sehirGecesi(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFF151B36));
    _yildizCiz(c, s, t, ust: 0.5);
    final ay = Offset(s.width * 0.8, s.height * 0.18);
    c.drawCircle(ay, 30, Paint()..color = const Color(0x22F3EEDF));
    c.drawCircle(ay, 20, Paint()..color = const Color(0xFFF3EEDF));
    c.drawCircle(ay.translate(8, -5), 17, Paint()..color = const Color(0xFF151B36));
    final bina = Paint()..color = const Color(0xFF0D1226);
    final isik = Paint()..color = const Color(0xFFFFC66B);
    final r = Random(11);
    var x = 0.0;
    var i = 0;
    while (x < s.width) {
      final w = 26.0 + r.nextInt(26);
      final h = s.height * (0.18 + r.nextDouble() * 0.28);
      final top = s.height * 0.86 - h;
      c.drawRect(Rect.fromLTWH(x, top, w, h + s.height * 0.14), bina);
      for (var wy = top + 10; wy < s.height * 0.82; wy += 16) {
        for (var wx = x + 6; wx < x + w - 8; wx += 12) {
          final k = (wx * 13 + wy * 7).toInt() % 17;
          final yanik = k < 5 && ((t * 6 + k * 0.37) % 1) > 0.25;
          if (yanik) c.drawRect(Rect.fromLTWH(wx, wy, 5, 7), isik);
        }
      }
      x += w + 2;
      i++;
      if (i > 40) break;
    }
    c.drawRect(Rect.fromLTWH(0, s.height * 0.9, s.width, s.height * 0.1), Paint()..color = const Color(0xFF1E2547));
  }

  void _deniz(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFF9ED7EA));
    c.drawCircle(Offset(s.width * 0.22, s.height * 0.22), 26, Paint()..color = const Color(0xFFFFE39A));
    _bulut(c, Offset(s.width * 0.7 + _dalga(t, 1) * 26, s.height * 0.2), 120, const Color(0xFFF4FBFD));
    final ufuk = s.height * 0.58;
    c.drawRect(Rect.fromLTWH(0, ufuk, s.width, s.height - ufuk), Paint()..color = const Color(0xFF2B7FA6));
    final dalga = Paint()
      ..color = const Color(0x66FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var row = 0; row < 5; row++) {
      final y = ufuk + 18 + row * 26.0;
      final kay = ((t * (row.isEven ? 1 : -1) * 3) % 1) * 60;
      for (var x = -60.0 + kay; x < s.width; x += 60) {
        c.drawPath(Path()
          ..moveTo(x, y)
          ..quadraticBezierTo(x + 10, y - 5, x + 20, y), dalga);
      }
    }
    final by = ufuk - 6 + _dalga(t, 6) * 3;
    final bx = s.width * 0.62 + _dalga(t, 1) * 12;
    c.drawPath(Path()
      ..moveTo(bx - 22, by)
      ..lineTo(bx + 22, by)
      ..lineTo(bx + 14, by + 10)
      ..lineTo(bx - 14, by + 10)
      ..close(), Paint()..color = const Color(0xFF7A4B22));
    c.drawPath(Path()
      ..moveTo(bx, by - 2)
      ..lineTo(bx, by - 40)
      ..lineTo(bx + 20, by - 4)
      ..close(), Paint()..color = const Color(0xFFF6F3EC));
  }

  void _kutuphane(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFF5E4533));
    const kitapRenk = [Color(0xFFB2582F), Color(0xFF2F7A55), Color(0xFF3D7EA6), Color(0xFFE9A23B), Color(0xFF8B6B4A), Color(0xFF7C5A9E)];
    final r = Random(5);
    for (var raf = 0; raf < 4; raf++) {
      final y = s.height * (0.14 + raf * 0.2);
      c.drawRect(Rect.fromLTWH(0, y + 44, s.width, 6), Paint()..color = const Color(0xFF3F2D20));
      var x = 8.0;
      while (x < s.width - 10) {
        final w = 8.0 + r.nextInt(8);
        final h = 30.0 + r.nextInt(14);
        c.drawRect(Rect.fromLTWH(x, y + 44 - h, w, h), Paint()..color = kitapRenk[r.nextInt(kitapRenk.length)]);
        x += w + 2;
      }
    }
    final lamba = Offset(s.width * 0.5, s.height * 0.12);
    final parla = 0.18 + 0.06 * _dalga(t, 8);
    c.drawCircle(lamba.translate(0, 40), s.width * 0.55, Paint()..color = const Color(0xFFFFC66B).withValues(alpha: parla));
    c.drawCircle(lamba, 9, Paint()..color = const Color(0xFFFFE39A));
  }

  @override
  bool shouldRepaint(covariant OdakSahnesiBoyaci old) => old.t != t || old.sahne != sahne;
}

// ─── Bahçe arka planı ───────────────────────────────────────

class BahceArkaPlanBoyaci extends CustomPainter {
  final bool gece;
  final double t;

  BahceArkaPlanBoyaci(this.gece, this.t);

  @override
  void paint(Canvas c, Size s) => gece ? _sera(c, s) : _gunduz(c, s);

  void _gunduz(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFFDCEBF3));
    final gunes = Offset(s.width * 0.84, 46);
    c.drawCircle(gunes, 30 + _dalga(t, 4) * 2, Paint()..color = const Color(0x40F6CD6B));
    c.drawCircle(gunes, 22, Paint()..color = const Color(0xFFF6CD6B));
    _bulut(c, Offset(s.width * 0.25 + _dalga(t, 1) * 30, 44), 96, Colors.white);
    _bulut(c, Offset(s.width * 0.6 + _dalga(t, 1, 0.5) * 20, 80), 70, const Color(0xFFF4FBFD));
    final kus = Paint()
      ..color = const Color(0xFF35554F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final bx = s.width * 0.5 + _dalga(t, 1) * 40;
    final by = 70 + _dalga(t, 2) * 8;
    final k = 5 + _dalga(t, 24) * 3;
    c.drawPath(Path()
      ..moveTo(bx - 8, by)
      ..quadraticBezierTo(bx - 4, by - k, bx, by)
      ..quadraticBezierTo(bx + 4, by - k, bx + 8, by), kus);
    _tepe(c, s, 0.3, 10, const Color(0xFFBFDCB5));
    _tepe(c, s, 0.38, 8, const Color(0xFFA6CF9B), faz: 1.2);
  }

  void _sera(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFF151B36));
    _yildizCiz(c, s, t, ust: 0.35);
    final ay = Offset(s.width * 0.82, 50);
    c.drawCircle(ay, 22, Paint()..color = const Color(0xFFF3EEDF));
    c.drawCircle(ay.translate(9, -6), 19, Paint()..color = const Color(0xFF151B36));
    final cerceve = Paint()
      ..color = const Color(0xFF3A4474)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final ince = Paint()
      ..color = const Color(0xFF2A3363)
      ..strokeWidth = 2;
    final kemer = Path()
      ..moveTo(14, s.height)
      ..lineTo(14, s.height * 0.34)
      ..quadraticBezierTo(s.width / 2, -s.height * 0.08, s.width - 14, s.height * 0.34)
      ..lineTo(s.width - 14, s.height);
    for (final x in [0.28, 0.5, 0.72]) {
      c.drawLine(Offset(s.width * x, s.height * 0.12), Offset(s.width * x, s.height), ince);
    }
    c.drawLine(Offset(14, s.height * 0.52), Offset(s.width - 14, s.height * 0.52), ince);
    c.drawPath(kemer, cerceve);
    c.drawRect(Rect.fromLTWH(0, s.height * 0.9, s.width, s.height * 0.1), Paint()..color = const Color(0xFF1E2547));
    for (var i = 0; i < 7; i++) {
      final cx = s.width * (0.15 + 0.12 * i) + _dalga(t, 2 + i % 3, i * 0.17) * 26;
      final cy = s.height * (0.3 + 0.07 * (i % 4)) + _dalga(t, 3 + i % 2, i * 0.29) * 18;
      final a = (0.3 + 0.7 * ((_dalga(t, 9 + i, i * 0.4) + 1) / 2));
      c.drawCircle(Offset(cx, cy), 7, Paint()..color = const Color(0xFFFFE39A).withValues(alpha: a * 0.25));
      c.drawCircle(Offset(cx, cy), 2.6, Paint()..color = const Color(0xFFFFE39A).withValues(alpha: a));
    }
  }

  @override
  bool shouldRepaint(covariant BahceArkaPlanBoyaci old) => old.t != t || old.gece != gece;
}

// ─── Etüt salonu (Topluluk) ─────────────────────────────────

class EtutSalonuBoyaci extends CustomPainter {
  final bool gece;
  final double t;

  EtutSalonuBoyaci(this.gece, this.t);

  @override
  void paint(Canvas c, Size s) {
    c.drawRRect(RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(18)),
        Paint()..color = gece ? const Color(0xFF151B36) : const Color(0xFFF3EDE2));
    if (!gece) {
      c.drawRect(Rect.fromLTWH(0, 0, s.width, 34), Paint()..color = const Color(0xFFE8DFCF));
      final r = Random(3);
      for (var x = 16.0; x < s.width - 16; x += 13) {
        if (r.nextInt(5) == 0) continue;
        final h = 14.0 + r.nextInt(12);
        c.drawRect(Rect.fromLTWH(x, 32 - h, 9, h), Paint()..color = const Color(0xFFC9B08E));
      }
    }
    const govdeler = [Color(0xFF3D7EA6), Color(0xFFC8693F), Color(0xFF5AA77B), Color(0xFF8B6B4A)];
    const tenler = [Color(0xFFE9B98F), Color(0xFFC98E62), Color(0xFFF0C9A4), Color(0xFFD9A77F)];
    final masaW = s.width / 4;
    for (var i = 0; i < 4; i++) {
      final cx = masaW * i + masaW / 2;
      final masaY = s.height * 0.78;
      if (gece) {
        final isik = 0.28 + 0.1 * _dalga(t, 4, i * 0.25);
        c.drawPath(Path()
          ..moveTo(cx - 4, 18)
          ..lineTo(cx + 4, 18)
          ..lineTo(cx + masaW * 0.46, masaY)
          ..lineTo(cx - masaW * 0.46, masaY)
          ..close(), Paint()..color = const Color(0xFFFFC66B).withValues(alpha: isik));
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, 16), width: 14, height: 12), const Radius.circular(3)),
            Paint()..color = const Color(0xFF3A4474));
      }
      final nefes = _dalga(t, 7, i * 0.3) * 1.5;
      final govde = gece ? const Color(0xFF2A3363) : govdeler[i];
      final bas = gece ? const Color(0xFF2A3363) : tenler[i];
      c.drawPath(Path()
        ..moveTo(cx - 20, masaY)
        ..quadraticBezierTo(cx - 18, masaY - 26, cx, masaY - 28 + nefes)
        ..quadraticBezierTo(cx + 18, masaY - 26, cx + 20, masaY)
        ..close(), Paint()..color = govde);
      c.drawCircle(Offset(cx, masaY - 40 + nefes), 12, Paint()..color = bas);
      if (!gece) {
        c.drawArc(Rect.fromCircle(center: Offset(cx, masaY - 42 + nefes), radius: 12.5), pi, pi, true,
            Paint()..color = const Color(0xFF3A2A20));
      }
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - masaW * 0.42, masaY - 2, masaW * 0.84, 8), const Radius.circular(3)),
          Paint()..color = gece ? const Color(0xFF5B6488) : const Color(0xFF8B6B4A));
      c.drawRect(Rect.fromLTWH(cx - 12, masaY - 10, 22, 8), Paint()..color = gece ? const Color(0xFFF3EEDF) : Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant EtutSalonuBoyaci old) => old.t != t || old.gece != gece;
}

// ─── Plan takımyıldızı (gece teması Ana Sayfa) ──────────────

class TakimyildizBoyaci extends CustomPainter {
  final int toplam;
  final int biten;
  final double t;
  final Color yanik;
  final Color sirada;
  final Color sonuk;

  TakimyildizBoyaci({required this.toplam, required this.biten, required this.t, required this.yanik, required this.sirada, required this.sonuk});

  @override
  void paint(Canvas c, Size s) {
    if (toplam == 0) return;
    final noktalar = List.generate(toplam, (i) {
      final x = toplam == 1 ? s.width / 2 : 14 + (s.width - 28) * i / (toplam - 1);
      final y = s.height * (i.isEven ? 0.68 : 0.3) + (i % 3) * 4;
      return Offset(x, y);
    });
    final kesik = Paint()
      ..color = sonuk
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < noktalar.length - 1; i++) {
      final a = noktalar[i], b = noktalar[i + 1];
      if (i < biten - 1) {
        c.drawLine(a, b, Paint()
          ..color = yanik
          ..strokeWidth = 2);
      } else {
        const adim = 8.0;
        final d = (b - a).distance;
        for (var k = 0.0; k < d; k += adim) {
          c.drawLine(a + (b - a) * (k / d), a + (b - a) * (min(k + 3, d) / d), kesik);
        }
      }
    }
    for (var i = 0; i < noktalar.length; i++) {
      final p = noktalar[i];
      if (i < biten) {
        final a = 0.14 + 0.08 * ((_dalga(t, 6, i * 0.2) + 1) / 2);
        c.drawCircle(p, 13, Paint()..color = yanik.withValues(alpha: a));
        c.drawCircle(p, 6, Paint()..color = yanik);
      } else {
        c.drawCircle(p, 6, Paint()
          ..color = i == biten ? sirada : sonuk
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
      }
    }
  }

  @override
  bool shouldRepaint(covariant TakimyildizBoyaci old) => old.t != t || old.biten != biten || old.toplam != toplam;
}

// ─── Kart askı ipi: gündüz ip, gece ışıklı ip ───────────────

class AskiIpiBoyaci extends CustomPainter {
  final bool gece;
  final double t;

  AskiIpiBoyaci(this.gece, this.t);

  Offset _nokta(Size s, double x) {
    final u = x / s.width;
    return Offset(x, 10 + 6 * 4 * u * (1 - u));
  }

  @override
  void paint(Canvas c, Size s) {
    final ip = Paint()
      ..color = gece ? const Color(0xFF3A4474) : const Color(0xFF8B6B4A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final path = Path()..moveTo(0, 8);
    for (var x = 0.0; x <= s.width; x += 6) {
      final n = _nokta(s, x);
      path.lineTo(n.dx, n.dy);
    }
    c.drawPath(path, ip);
    if (!gece) return;
    for (var i = 0; i * 44.0 < s.width; i++) {
      final n = _nokta(s, 18 + i * 44.0);
      final a = 0.35 + 0.65 * ((_dalga(t, 8, i * 0.17) + 1) / 2);
      c.drawCircle(n.translate(0, 6), 9, Paint()..color = const Color(0xFFFFC66B).withValues(alpha: a * 0.25));
      c.drawCircle(n.translate(0, 6), 4, Paint()..color = const Color(0xFFFFC66B).withValues(alpha: a));
    }
  }

  @override
  bool shouldRepaint(covariant AskiIpiBoyaci old) => old.t != t || old.gece != gece;
}
