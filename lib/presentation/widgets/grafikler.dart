/// Gelişim takibinde kullanılan grafik ve tablo bileşenleri (fl_chart tabanlı).
/// Tüm renkler tema belirteçlerinden (context.colors) ve ders renklerinden
/// gelir; açık ve koyu temada okunabilir kalır.
library;

import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

import '../../core/algorithms/analiz_motoru.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/tarih.dart';

Color grafikDersRengi(BuildContext context, String ders) {
  if (ders == 'Deneme') return context.colors.info;
  if (ders == 'Genel') return context.colors.textMuted;
  return dersRengi(ders);
}

String dersKisaAdi(String ders) {
  switch (ders) {
    case 'Türk Dili ve Edebiyatı':
      return 'Edebiyat';
    case 'Fen Bilimleri':
      return 'Fen';
    case 'Sosyal Bilimler':
      return 'Sosyal';
    default:
      return ders;
  }
}

TextStyle _eksenYazisi(BuildContext context) => TextStyle(fontSize: 10.5, color: context.colors.textMuted);

/// Grafik ipucu balonu: temaya göre ters renk (koyu zemin/açık yazı ya da tersi).
Color _ipucuZemin(BuildContext context) => context.colors.textPrimary;
TextStyle _ipucuYazi(BuildContext context) =>
    TextStyle(color: context.colors.background, fontWeight: FontWeight.w700, fontSize: 12);

/// Sabit başlık + alt açıklama + içerik kartı.
class GrafikKarti extends StatelessWidget {
  final String baslik;
  final String? aciklama;
  final Widget? sagUst;
  final Widget child;

  const GrafikKarti({super.key, required this.baslik, this.aciklama, this.sagUst, required this.child});

  @override
  Widget build(BuildContext context) {
    final koyu = context.colors.gece;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: koyu ? Border.all(color: context.colors.border) : null,
        boxShadow: koyu
            ? null
            : [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.05), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(baslik, style: context.baslik(17)),
                    if (aciklama != null) ...[
                      const SizedBox(height: 3),
                      Text(aciklama!, style: TextStyle(fontSize: 12.5, color: context.colors.textMuted, height: 1.3)),
                    ],
                  ],
                ),
              ),
              ?sagUst,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Küçük gösterge kutusu (KPI).
class KpiKutusu extends StatelessWidget {
  final IconData ikon;
  final String deger;
  final String etiket;
  final String? alt;
  final Color? altRenk;
  final Color? renk;

  const KpiKutusu({super.key, required this.ikon, required this.deger, required this.etiket, this.alt, this.altRenk, this.renk});

  @override
  Widget build(BuildContext context) {
    final r = renk ?? context.colors.primary;
    return Semantics(
      label: '$etiket: $deger${alt != null ? ', $alt' : ''}',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: r.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
              child: Icon(ikon, size: 18, color: r),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(deger, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: context.colors.textPrimary)),
            ),
            Text(etiket, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: context.colors.textMuted)),
            if (alt != null)
              Text(alt!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: altRenk ?? context.colors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

/// Günlere ya da haftalara göre çalışma süresi çubukları + hedef çizgisi.
class CalismaCubukGrafigi extends StatelessWidget {
  final List<String> gunler;
  final List<int> dakikalar;
  final int hedefDk;
  final double yukseklik;

  const CalismaCubukGrafigi({super.key, required this.gunler, required this.dakikalar, required this.hedefDk, this.yukseklik = 170});

  @override
  Widget build(BuildContext context) {
    final haftalik = gunler.length > 35;
    final etiketler = <String>[];
    final degerler = <int>[];
    if (haftalik) {
      for (var i = 0; i < gunler.length; i += 7) {
        final son = min(i + 7, gunler.length);
        etiketler.add(kisaTarih(DateTime.parse(gunler[i])));
        degerler.add(dakikalar.sublist(i, son).fold(0, (a, b) => a + b));
      }
    } else {
      for (var i = 0; i < gunler.length; i++) {
        final t = DateTime.parse(gunler[i]);
        etiketler.add(gunler.length <= 7 ? gunKisaAdlari[t.weekday - 1] : '${t.day}');
        degerler.add(dakikalar[i]);
      }
    }
    final hedef = haftalik ? hedefDk * 7 : hedefDk;
    final enBuyuk = degerler.fold<int>(0, max);
    final maxY = max(max(enBuyuk, hedef), 60) * 1.18;
    final c = context.colors;
    final genislik = gunler.length <= 7 ? 22.0 : (haftalik ? 14.0 : 7.0);
    final etiketAraligi = gunler.length <= 7 || haftalik ? 1 : 5;

    return SizedBox(
      height: yukseklik,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: _aralik(maxY),
            getDrawingHorizontalLine: (_) => FlLine(color: c.border, strokeWidth: 1),
          ),
          extraLinesData: hedef > 0
              ? ExtraLinesData(horizontalLines: [
                  HorizontalLine(
                    y: hedef.toDouble(),
                    color: c.warning,
                    strokeWidth: 1.5,
                    dashArray: [6, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c.warning),
                      labelResolver: (_) => 'Hedef',
                    ),
                  ),
                ])
              : null,
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                interval: _aralik(maxY),
                getTitlesWidget: (v, meta) => v == meta.max
                    ? const SizedBox.shrink()
                    : Text(v >= 60 ? '${(v / 60).toStringAsFixed(v % 60 == 0 ? 0 : 1)}sa' : '${v.toInt()}dk', style: _eksenYazisi(context)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= etiketler.length) return const SizedBox.shrink();
                  final goster = i % etiketAraligi == 0 || i == etiketler.length - 1;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(goster ? etiketler[i] : '', style: _eksenYazisi(context)),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => _ipucuZemin(context),
              getTooltipItem: (grup, _, rod, _) => BarTooltipItem(
                '${etiketler[grup.x]}\n${sureMetni(rod.toY.round())}',
                _ipucuYazi(context),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < degerler.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: degerler[i].toDouble(),
                  width: genislik,
                  color: degerler[i] >= hedef && hedef > 0 ? c.success : c.primary,
                  borderRadius: BorderRadius.circular(genislik / 3),
                  backDrawRodData: BackgroundBarChartRodData(show: true, toY: maxY, color: c.border.withValues(alpha: 0.35)),
                ),
              ]),
          ],
        ),
      ),
    );
  }
}

double _aralik(double maxY) {
  if (maxY <= 90) return 30;
  if (maxY <= 240) return 60;
  if (maxY <= 600) return 120;
  if (maxY <= 1500) return 300;
  return 600;
}

/// Planlanan ve tamamlanan dakika (yan yana çubuklar).
class PlanUyumGrafigi extends StatelessWidget {
  final List<String> gunler;
  final List<int> planlanan;
  final List<int> tamamlanan;

  const PlanUyumGrafigi({super.key, required this.gunler, required this.planlanan, required this.tamamlanan});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final haftalik = gunler.length > 14;
    final etiketler = <String>[];
    final p = <int>[];
    final t = <int>[];
    if (haftalik) {
      for (var i = 0; i < gunler.length; i += 7) {
        final son = min(i + 7, gunler.length);
        etiketler.add(kisaTarih(DateTime.parse(gunler[i])));
        p.add(planlanan.sublist(i, son).fold(0, (a, b) => a + b));
        t.add(tamamlanan.sublist(i, son).fold(0, (a, b) => a + b));
      }
    } else {
      for (var i = 0; i < gunler.length; i++) {
        final d = DateTime.parse(gunler[i]);
        etiketler.add(gunler.length <= 7 ? gunKisaAdlari[d.weekday - 1] : '${d.day}');
        p.add(planlanan[i]);
        t.add(tamamlanan[i]);
      }
    }
    final maxY = max(p.fold<int>(0, max), 60) * 1.15;
    final w = etiketler.length <= 7 ? 10.0 : 6.0;

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: _aralik(maxY),
                getDrawingHorizontalLine: (_) => FlLine(color: c.border, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34,
                    interval: _aralik(maxY),
                    getTitlesWidget: (v, meta) => v == meta.max
                        ? const SizedBox.shrink()
                        : Text(v >= 60 ? '${(v / 60).toStringAsFixed(v % 60 == 0 ? 0 : 1)}sa' : '${v.toInt()}dk', style: _eksenYazisi(context)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (v, meta) {
                      final i = v.toInt();
                      if (i < 0 || i >= etiketler.length) return const SizedBox.shrink();
                      final goster = etiketler.length <= 8 || i % 3 == 0;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(goster ? etiketler[i] : '', style: _eksenYazisi(context)),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => _ipucuZemin(context),
                  getTooltipItem: (grup, _, rod, rodIndex) => BarTooltipItem(
                    '${etiketler[grup.x]} · ${rodIndex == 0 ? 'Planlanan' : 'Tamamlanan'}\n${sureMetni(rod.toY.round())}',
                    _ipucuYazi(context),
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < p.length; i++)
                  BarChartGroupData(x: i, barsSpace: 3, barRods: [
                    BarChartRodData(toY: p[i].toDouble(), width: w, color: c.primary.withValues(alpha: 0.28), borderRadius: BorderRadius.circular(3)),
                    BarChartRodData(toY: t[i].toDouble(), width: w, color: c.success, borderRadius: BorderRadius.circular(3)),
                  ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 6,
          children: [
            Lejant(renk: c.primary.withValues(alpha: 0.35), etiket: 'Planlanan'),
            Lejant(renk: c.success, etiket: 'Tamamlanan'),
          ],
        ),
      ],
    );
  }
}

class Lejant extends StatelessWidget {
  final Color renk;
  final String etiket;
  final String? deger;
  final bool kesikli;

  const Lejant({super.key, required this.renk, required this.etiket, this.deger, this.kesikli = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: kesikli ? 14 : 10,
          height: kesikli ? 3 : 10,
          decoration: BoxDecoration(color: renk, borderRadius: BorderRadius.circular(kesikli ? 2 : 3)),
        ),
        const SizedBox(width: 6),
        Text(etiket, style: TextStyle(fontSize: 12, color: context.colors.textSecondary, fontWeight: FontWeight.w600)),
        if (deger != null) ...[
          const SizedBox(width: 4),
          Text(deger!, style: TextStyle(fontSize: 12, color: context.colors.textPrimary, fontWeight: FontWeight.w800)),
        ],
      ],
    );
  }
}

/// Ders bazında dakika dağılımı: halka grafik + yüzdeli lejant.
class DersDagilimGrafigi extends StatelessWidget {
  final Map<String, int> dagilim;
  final double cap;

  const DersDagilimGrafigi({super.key, required this.dagilim, this.cap = 150});

  @override
  Widget build(BuildContext context) {
    final toplam = dagilim.values.fold<int>(0, (a, b) => a + b);
    if (toplam == 0) {
      return BosGrafikMesaji(metin: 'Bu dönemde derse göre kaydedilmiş çalışma yok. Çalış ekranında ders seçerek odak oturumu başlat.');
    }
    // 6'dan fazla ders varsa küçükler "Diğer" altında toplanır.
    final girdiler = dagilim.entries.toList();
    final gosterilen = girdiler.take(6).toList();
    final diger = girdiler.skip(6).fold<int>(0, (a, e) => a + e.value);
    if (diger > 0) gosterilen.add(MapEntry('Diğer', diger));

    return Row(
      children: [
        SizedBox(
          width: cap,
          height: cap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: cap * 0.3,
                  startDegreeOffset: -90,
                  sections: [
                    for (final e in gosterilen)
                      PieChartSectionData(
                        value: e.value.toDouble(),
                        color: e.key == 'Diğer' ? context.colors.textMuted : grafikDersRengi(context, e.key),
                        radius: cap * 0.18,
                        showTitle: false,
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(sureMetni(toplam), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: context.colors.textPrimary)),
                  Text('toplam', style: TextStyle(fontSize: 10.5, color: context.colors.textMuted)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final e in gosterilen)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: e.key == 'Diğer' ? context.colors.textMuted : grafikDersRengi(context, e.key),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(dersKisaAdi(e.key),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12.5, color: context.colors.textSecondary, fontWeight: FontWeight.w600)),
                      ),
                      Text('%${(e.value / toplam * 100).round()}',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: context.colors.textPrimary)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// TYT/AYT toplam net gelişimi: denemeler + 3'lü hareketli ortalama (kesikli).
class NetGelisimGrafigi extends StatelessWidget {
  final NetTrendi tyt;
  final NetTrendi ayt;
  final double yukseklik;

  /// Serbest müfredat: tek seri, "TYT/AYT" yerine sınav puanı.
  final bool serbest;

  const NetGelisimGrafigi({super.key, required this.tyt, required this.ayt, this.yukseklik = 180, this.serbest = false});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (tyt.bos && ayt.bos) {
      return BosGrafikMesaji(
          metin: serbest
              ? 'Sonuçlar ekranından ilk sınavını ekle; puan gelişimin burada çizilsin.'
              : 'Netler ekranından ilk denemeni ekle; TYT ve AYT gelişimin burada çizilsin.');
    }
    final seriler = <(NetTrendi, Color)>[
      if (!tyt.bos) (tyt, c.primary),
      if (!ayt.bos) (ayt, c.accent),
    ];
    final enUzun = seriler.map((s) => s.$1.noktalar.length).reduce(max);
    final maxY = seriler.expand((s) => s.$1.noktalar).fold<double>(10, (m, e) => max(m, e.net)) * 1.15;

    LineChartBarData cizgi(List<double> y, Color renk, {bool ortalama = false}) => LineChartBarData(
          spots: [for (var i = 0; i < y.length; i++) FlSpot(i.toDouble(), max(0, y[i]))],
          color: ortalama ? renk.withValues(alpha: 0.55) : renk,
          barWidth: ortalama ? 2 : 3,
          isCurved: true,
          preventCurveOverShooting: true,
          dashArray: ortalama ? [5, 4] : null,
          dotData: FlDotData(show: !ortalama),
          belowBarData: BarAreaData(show: !ortalama, color: renk.withValues(alpha: 0.08)),
        );

    final cizgiler = <LineChartBarData>[];
    final kaynak = <(NetTrendi, bool)>[];
    for (final (s, renk) in seriler) {
      cizgiler.add(cizgi(s.noktalar.map((e) => e.net).toList(), renk));
      kaynak.add((s, false));
      if (s.noktalar.length >= 3) {
        cizgiler.add(cizgi(s.hareketliOrtalama, renk, ortalama: true));
        kaynak.add((s, true));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: yukseklik,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
              minX: 0,
              maxX: max(1, enUzun - 1).toDouble(),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(color: c.border, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 1,
                    getTitlesWidget: (v, meta) {
                      final i = v.toInt();
                      final goster = enUzun <= 8 || i % (enUzun ~/ 6 + 1) == 0;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(goster ? '${i + 1}.' : '', style: _eksenYazisi(context)),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (v, meta) =>
                        v == meta.max ? const SizedBox.shrink() : Text(v.toInt().toString(), style: _eksenYazisi(context)),
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => _ipucuZemin(context),
                  getTooltipItems: (spots) => spots.map((s) {
                    final (seri, ortalama) = kaynak[s.barIndex];
                    if (ortalama) return null;
                    final i = s.x.toInt();
                    final ad = i < seri.noktalar.length ? seri.noktalar[i].ad : '';
                    return LineTooltipItem('$ad\n${s.y.toStringAsFixed(2)} net', _ipucuYazi(context));
                  }).toList(),
                ),
              ),
              lineBarsData: cizgiler,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            if (!tyt.bos) Lejant(renk: c.primary, etiket: serbest ? 'Sınav puanı' : 'TYT', deger: tyt.son!.toStringAsFixed(1)),
            if (!ayt.bos) Lejant(renk: c.accent, etiket: 'AYT', deger: ayt.son!.toStringAsFixed(1)),
            if (tyt.noktalar.length >= 3 || ayt.noktalar.length >= 3)
              Lejant(renk: c.textMuted, etiket: '3 deneme ortalaması', kesikli: true),
          ],
        ),
      ],
    );
  }
}

/// Enerji / odak / stres (1-5) günlük çizgileri; kayıt olmayan günler boşluk.
class CheckinGrafigi extends StatelessWidget {
  final List<String> gunler;
  final List<List<int>?> seri;

  const CheckinGrafigi({super.key, required this.gunler, required this.seri});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (seri.every((e) => e == null)) {
      return const BosGrafikMesaji(metin: 'Günlük planındaki "Bugünkü durumun" kartından enerji, odak ve stresini işaretledikçe burada eğilimin görünür.');
    }
    LineChartBarData cizgi(int i, Color renk) => LineChartBarData(
          spots: [
            for (var g = 0; g < seri.length; g++)
              seri[g] == null ? FlSpot.nullSpot : FlSpot(g.toDouble(), seri[g]![i].toDouble()),
          ],
          color: renk,
          barWidth: 2.5,
          isCurved: true,
          preventCurveOverShooting: true,
          dotData: FlDotData(show: gunler.length <= 31),
        );
    final renkler = [c.success, c.primary, c.danger];
    const adlar = ['Enerji', 'Odak', 'Stres'];
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: LineChart(
            LineChartData(
              minY: 1,
              maxY: 5,
              minX: 0,
              maxX: max(1, gunler.length - 1).toDouble(),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (_) => FlLine(color: c.border, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 20,
                    interval: 1,
                    getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: _eksenYazisi(context)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 1,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= gunler.length) return const SizedBox.shrink();
                      final t = DateTime.parse(gunler[i]);
                      final aralik = gunler.length <= 7 ? 1 : (gunler.length <= 31 ? 5 : 15);
                      if (i % aralik != 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(gunler.length <= 7 ? gunKisaAdlari[t.weekday - 1] : '${t.day}', style: _eksenYazisi(context)),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => _ipucuZemin(context),
                  getTooltipItems: (spots) =>
                      spots.map((s) => LineTooltipItem('${adlar[s.barIndex]}: ${s.y.toInt()}', _ipucuYazi(context))).toList(),
                ),
              ),
              lineBarsData: [for (var i = 0; i < 3; i++) cizgi(i, renkler[i])],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 6,
          children: [for (var i = 0; i < 3; i++) Lejant(renk: renkler[i], etiket: adlar[i])],
        ),
      ],
    );
  }
}

/// Ders bazında konu durumu: tamamlanan / zayıf / kalan yığılı çubuklar.
class KonuIlerlemeCubuklari extends StatelessWidget {
  final List<KonuDersDurumu> dersler;

  const KonuIlerlemeCubuklari({super.key, required this.dersler});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        for (final d in dersler)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Semantics(
              label: '${d.ders}: ${d.toplam} konunun ${d.tamamlanan} tanesi tamamlandı, ${d.zayif} zayıf',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(dersKisaAdi(d.ders),
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.textPrimary)),
                      ),
                      Text('${d.tamamlanan}/${d.toplam}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c.textSecondary)),
                      if (d.zayif > 0) ...[
                        const SizedBox(width: 8),
                        Text('${d.zayif} zayıf', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: c.warning)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 10,
                      child: Row(
                        children: [
                          if (d.tamamlanan > 0) Expanded(flex: d.tamamlanan, child: Container(color: grafikDersRengi(context, d.ders))),
                          if (d.zayif > 0) Expanded(flex: d.zayif, child: Container(color: c.warning.withValues(alpha: 0.75))),
                          if (d.toplam - d.tamamlanan - d.zayif > 0)
                            Expanded(flex: max(0, d.toplam - d.tamamlanan - d.zayif), child: Container(color: c.border)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 6,
          children: [
            Lejant(renk: c.primary, etiket: 'Tamamlanan'),
            Lejant(renk: c.warning.withValues(alpha: 0.75), etiket: 'Zayıf'),
            Lejant(renk: c.border, etiket: 'Kalan'),
          ],
        ),
      ],
    );
  }
}

/// Tamamlanan konu sayısının zaman içindeki değişimi (tek çizgi).
class TekCizgiGrafigi extends StatelessWidget {
  final List<String> gunler;
  final List<int?> degerler;
  final Color? renk;
  final String birim;

  const TekCizgiGrafigi({super.key, required this.gunler, required this.degerler, this.renk, this.birim = ''});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = renk ?? c.success;
    final mevcut = degerler.whereType<int>().toList();
    if (mevcut.isEmpty) return const SizedBox.shrink();
    final maxY = max(mevcut.reduce(max), 5) * 1.2;
    return SizedBox(
      height: 110,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          minX: 0,
          maxX: max(1, gunler.length - 1).toDouble(),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => _ipucuZemin(context),
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem('${kisaTarih(DateTime.parse(gunler[s.x.toInt()]))}\n${s.y.toInt()}$birim', _ipucuYazi(context)))
                  .toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < degerler.length; i++)
                  degerler[i] == null ? FlSpot.nullSpot : FlSpot(i.toDouble(), degerler[i]!.toDouble()),
              ],
              color: r,
              barWidth: 3,
              isStepLineChart: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: r.withValues(alpha: 0.12)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Son 12 haftanın çalışma takvimi (satır = gün, sütun = hafta).
class CalismaIsiHaritasi extends StatelessWidget {
  final List<List<int>> haftalar;
  final int hedefDk;

  const CalismaIsiHaritasi({super.key, required this.haftalar, required this.hedefDk});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final esik = max(hedefDk, 60);
    Color renk(int dk) {
      if (dk < 0) return Colors.transparent;
      if (dk == 0) return c.border.withValues(alpha: 0.6);
      final oran = (dk / esik).clamp(0.0, 1.0);
      return c.success.withValues(alpha: 0.25 + 0.75 * oran);
    }

    return LayoutBuilder(builder: (context, kutu) {
      const etiketGenislik = 28.0;
      final hucre = min(22.0, (kutu.maxWidth - etiketGenislik) / haftalar.length - 3);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var g = 0; g < 7; g++)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: etiketGenislik,
                    child: Text(g.isEven ? gunKisaAdlari[g] : '', style: _eksenYazisi(context)),
                  ),
                  for (final hafta in haftalar)
                    Tooltip(
                      message: hafta[g] < 0 ? '' : sureMetni(hafta[g]),
                      child: Container(
                        width: hucre,
                        height: hucre,
                        margin: const EdgeInsets.only(right: 3),
                        decoration: BoxDecoration(color: renk(hafta[g]), borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Az', style: _eksenYazisi(context)),
              const SizedBox(width: 4),
              for (final o in [0, esik ~/ 4, esik ~/ 2, esik])
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(color: renk(o), borderRadius: BorderRadius.circular(3)),
                ),
              Text('Hedef', style: _eksenYazisi(context)),
            ],
          ),
        ],
      );
    });
  }
}

/// Ders bazında net tablosu (son, ortalama, en iyi, değişim, doğruluk).
class DersNetTablosu extends StatelessWidget {
  final List<DersNetSatiri> satirlar;

  const DersNetTablosu({super.key, required this.satirlar});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (satirlar.isEmpty) {
      return const BosGrafikMesaji(metin: 'Deneme ekledikçe her dersin son neti, ortalaması ve değişimi burada tablolanır.');
    }
    final baslik = TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: c.textMuted);
    final hucre = TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.textPrimary);

    Widget degisim(double? d) {
      if (d == null) return Text('—', style: hucre.copyWith(color: c.textMuted));
      final renk = d > 0.25 ? c.success : (d < -0.25 ? c.danger : c.textMuted);
      final ikon = d > 0.25 ? Icons.arrow_upward_rounded : (d < -0.25 ? Icons.arrow_downward_rounded : Icons.remove_rounded);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: 13, color: renk),
          Text(d.abs().toStringAsFixed(1), style: hucre.copyWith(color: renk, fontWeight: FontWeight.w800)),
        ],
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 32,
        dataRowMinHeight: 36,
        dataRowMaxHeight: 40,
        columnSpacing: 16,
        horizontalMargin: 4,
        dividerThickness: 0.6,
        headingTextStyle: baslik,
        columns: const [
          DataColumn(label: Text('Ders')),
          DataColumn(label: Text('Son'), numeric: true),
          DataColumn(label: Text('Ort.'), numeric: true),
          DataColumn(label: Text('En iyi'), numeric: true),
          DataColumn(label: Text('Değişim')),
          DataColumn(label: Text('Doğru %'), numeric: true),
        ],
        rows: [
          for (final s in satirlar)
            DataRow(cells: [
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: grafikDersRengi(context, s.ders), shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('${s.alan.name} ${dersKisaAdi(s.ders)}', style: hucre),
                ],
              )),
              DataCell(Text(s.son.toStringAsFixed(1), style: hucre.copyWith(fontWeight: FontWeight.w800))),
              DataCell(Text(s.ortalama.toStringAsFixed(1), style: hucre)),
              DataCell(Text(s.enIyi.toStringAsFixed(1), style: hucre)),
              DataCell(degisim(s.degisim)),
              DataCell(Text('%${(s.dogruluk * 100).round()}', style: hucre)),
            ]),
        ],
      ),
    );
  }
}

/// Uygulama içi test doğruluğu (ders bazında yatay çubuk).
class TestDogrulukCubuklari extends StatelessWidget {
  final List<TestDersOzeti> dersler;

  const TestDogrulukCubuklari({super.key, required this.dersler});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        for (final d in dersler)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  child: Text(dersKisaAdi(d.ders),
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.textPrimary)),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: d.dogruluk,
                      minHeight: 10,
                      backgroundColor: c.border,
                      color: d.dogruluk >= 0.7 ? c.success : (d.dogruluk >= 0.45 ? c.warning : c.danger),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 78,
                  child: Text('%${(d.dogruluk * 100).round()} · ${d.soru} soru',
                      textAlign: TextAlign.right, style: TextStyle(fontSize: 11.5, color: c.textSecondary, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class BosGrafikMesaji extends StatelessWidget {
  final String metin;
  const BosGrafikMesaji({super.key, required this.metin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(color: context.colors.background, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(Icons.insights_rounded, color: context.colors.textMuted),
          const SizedBox(width: 10),
          Expanded(child: Text(metin, style: TextStyle(fontSize: 12.5, color: context.colors.textSecondary, height: 1.35))),
        ],
      ),
    );
  }
}

/// İçgörü satırı (olumlu / uyarı / bilgi ikonlu).
class IcgoruSatiri extends StatelessWidget {
  final Icgoru icgoru;
  const IcgoruSatiri({super.key, required this.icgoru});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (ikon, renk) = switch (icgoru.tur) {
      IcgoruTuru.olumlu => (Icons.trending_up_rounded, c.success),
      IcgoruTuru.uyari => (Icons.error_outline_rounded, c.warning),
      IcgoruTuru.bilgi => (Icons.lightbulb_outline_rounded, c.info),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: renk.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: Icon(ikon, size: 16, color: renk),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(icgoru.metin, style: TextStyle(fontSize: 13, color: c.textPrimary, height: 1.4)),
            ),
          ),
        ],
      ),
    );
  }
}
