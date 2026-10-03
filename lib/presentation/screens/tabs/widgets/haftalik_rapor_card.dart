/// Haftalık/aylık ilerleme raporu: net trendi (fl_chart) + özet istatistikler.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';
import 'package:yks_kocu/core/theme/app_theme.dart';
import '../../../providers/mufredat_provider.dart';
import '../../../providers/net_provider.dart';
import '../../../providers/rapor_provider.dart';
import '../../../../core/algorithms/analiz_motoru.dart' show denemeNoktalari;
import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/net_kaydi.dart';

class HaftalikRaporCard extends ConsumerWidget {
  const HaftalikRaporCard({super.key});

  List<NetKaydi> _periyotIcindekiler(List<NetKaydi> tumKayitlar, int gunSayisi) {
    final sinir = DateTime.now().subtract(Duration(days: gunSayisi));
    return tumKayitlar.where((k) {
      final tarih = DateTime.tryParse(k.tarih);
      return tarih != null && tarih.isAfter(sinir);
    }).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final tumKayitlar = ref.watch(netProvider);
    final periyot = ref.watch(raporPeriyotProvider);
    final calismaLogAsync = ref.watch(calismaGunlukLogProvider(periyot));

    final periyotKayitlari = _periyotIcindekiler(tumKayitlar, periyot);
    final serbest = ref.watch(serbestModProvider);
    final tyt = denemeNoktalari(periyotKayitlari, SinavAlani.TYT, ortalama: serbest);
    final ayt = denemeNoktalari(periyotKayitlari, SinavAlani.AYT);
    final denemeSayisi = tyt.length + ayt.length;
    final anaSeri = tyt.length >= ayt.length ? tyt : ayt;
    final anaAlan = serbest ? 'puan' : (identical(anaSeri, tyt) ? 'TYT' : 'AYT');
    final ortNet = anaSeri.isEmpty ? 0.0 : anaSeri.map((k) => k.net).reduce((a, b) => a + b) / anaSeri.length;

    final toplamCalismaDk = calismaLogAsync.maybeWhen(
      data: (log) => log.values.fold<int>(0, (a, b) => a + b),
      orElse: () => 0,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.insights_rounded, size: 18, color: colors.textPrimary),
                  const SizedBox(width: 6),
                  Text(
                    'İlerleme Raporu',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
                  ),
                ],
              ),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 7, label: Text('Haftalık')),
                  ButtonSegment(value: 30, label: Text('Aylık')),
                ],
                selected: {periyot},
                showSelectedIcon: false,
                onSelectionChanged: (selection) {
                  ref.read(raporPeriyotProvider.notifier).state = selection.first;
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _raporStat(colors, serbest ? 'Sınav' : 'Deneme', '$denemeSayisi'),
              _raporStat(colors, 'Ort. $anaAlan', anaSeri.isEmpty ? '—' : ortNet.toStringAsFixed(1)),
              _raporStat(colors, 'Çalışma', '${toplamCalismaDk ~/ 60}s ${toplamCalismaDk % 60}dk'),
            ],
          ),
          const SizedBox(height: 16),
          if (anaSeri.length < 2)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Grafiği görmek için bu dönemde aynı alandan en az 2 deneme kaydın olmalı.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
              ),
            )
          else
            SizedBox(
              height: 140,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineTouchData: const LineTouchData(enabled: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < anaSeri.length; i++)
                          FlSpot(i.toDouble(), anaSeri[i].net),
                      ],
                      isCurved: true,
                      color: colors.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colors.primary.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _raporStat(AppTheme colors, String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: colors.textMuted)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary)),
      ],
    );
  }
}
