/// Konularım — müfredattaki konuların takibi: tamamlandı / zayıf işaretleri,
/// derse göre süzme ve (9-11. sınıf konularında) tek dokunuşla konu testi.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/sinif_mufredati.dart';
import '../../../core/constants/soru_havuzu.dart';
import '../../../data/models/konu.dart';
import '../../providers/konu_provider.dart';
import '../../providers/mufredat_provider.dart';
import '../../providers/test_provider.dart';
import '../../widgets/grafikler.dart';
import '../../widgets/ui_kit.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

class KonuTakibiTab extends ConsumerStatefulWidget {
  const KonuTakibiTab({super.key});

  @override
  ConsumerState<KonuTakibiTab> createState() => _KonuTakibiTabState();
}

class _KonuTakibiTabState extends ConsumerState<KonuTakibiTab> {
  String _gorunum = 'TYT';
  String _seciliDersFilter = 'hepsi';

  void _konuTesti(Konu konu) {
    HapticFeedback.selectionClick();
    ref.read(aktifTestProvider.notifier).konuTestiOlustur(konu.id);
    context.push('/test-coz');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final serbest = ref.watch(serbestModProvider);
    final sinif = ref.watch(sinifProvider);
    final tumu = ref.watch(konuProvider);
    final ozelVar = tumu.any((k) => k.ozel);

    // Görünümler: sınıf modunda [Sınıf, Derslerim]; YKS'de [TYT, AYT, Derslerim].
    final gorunumler = <(String, String)>[
      if (!serbest && sinif != null) ('SINIF', '$sinif. sınıf'),
      if (!serbest && sinif == null) ...[('TYT', 'TYT'), ('AYT', 'AYT')],
      if (serbest || ozelVar) ('OZEL', 'Derslerim'),
    ];
    final gorunum = gorunumler.any((g) => g.$1 == _gorunum) ? _gorunum : gorunumler.first.$1;
    final konular = switch (gorunum) {
      'OZEL' => tumu.where((k) => k.ozel).toList(),
      'AYT' => tumu.where((k) => !k.ozel && k.alan == SinavAlani.AYT).toList(),
      'SINIF' => tumu.where((k) => !k.ozel).toList(),
      _ => tumu.where((k) => !k.ozel && k.alan == SinavAlani.TYT).toList(),
    };

    final tamamlananSayisi = konular.where((k) => k.tamamlandi).length;
    final zayifSayisi = konular.where((k) => k.zayif).length;
    final yuzde = konular.isEmpty ? 0.0 : tamamlananSayisi / konular.length;

    final dersler = <String>['hepsi'];
    for (final k in konular) {
      if (!dersler.contains(k.ders)) dersler.add(k.ders);
    }
    final dersFiltre = dersler.contains(_seciliDersFilter) ? _seciliDersFilter : 'hepsi';
    final filtrelenmis = dersFiltre == 'hepsi' ? konular : konular.where((k) => k.ders == dersFiltre).toList();

    // Liste: ders (ve varsa tema) başlıklarıyla gruplanır.
    final satirlar = <Widget>[];
    String? sonBaslik;
    for (final k in filtrelenmis) {
      final tema = konuTemasi(k.id);
      final baslik = [if (dersFiltre == 'hepsi') dersKisaAdi(k.ders), ?tema].join(' · ');
      if (baslik.isNotEmpty && baslik != sonBaslik) {
        sonBaslik = baslik;
        satirlar.add(Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
          child: Text(baslik, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: c.textMuted)),
        ));
      }
      satirlar.add(_konuSatiri(k));
    }

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: konular.isEmpty && gorunumler.length == 1 && gorunum == 'OZEL'
            ? _bosMufredat()
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Konularım', style: context.baslik(24))),
                      IconButton(
                        icon: Icon(Icons.playlist_add_rounded, color: c.primary),
                        tooltip: 'Müfredatı düzenle (ders/konu ekle-çıkar)',
                        onPressed: () => context.push('/mufredat'),
                      ),
                    ],
                  ),
                  if (!serbest) ...[
                    YumusakKart(
                      onTap: () => context.push('/test-olustur'),
                      renk: c.primarySoft,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Icon(Icons.quiz_rounded, size: 26, color: c.gece ? c.accent : c.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Test ve deneme', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w800, fontSize: 15)),
                                const SizedBox(height: 2),
                                Text(
                                  sinif != null ? 'Konu testi, $sinif. sınıf denemesi ve yanlışlarının tekrarı' : 'Konu testi, deneme ve yanlışlarının tekrarı',
                                  style: TextStyle(color: c.textSecondary, fontSize: 12.5),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: c.textMuted),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (gorunumler.length > 1) ...[
                    SegmentedButton<String>(
                      segments: [for (final (deger, etiket) in gorunumler) ButtonSegment(value: deger, label: Text(etiket))],
                      selected: {gorunum},
                      showSelectedIcon: false,
                      onSelectionChanged: (v) => setState(() {
                        _gorunum = v.first;
                        _seciliDersFilter = 'hepsi';
                      }),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: c.border)),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Tamamlanan konular',
                                style: TextStyle(color: c.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              '$tamamlananSayisi / ${konular.length} (%${(yuzde * 100).round()})',
                              style: TextStyle(color: c.gece ? c.accent : c.primary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(value: yuzde, minHeight: 10, backgroundColor: c.border, color: c.success),
                        ),
                        if (zayifSayisi > 0) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('$zayifSayisi konu zayıf olarak işaretli; programın bu konulara öncelik verir.',
                                style: TextStyle(fontSize: 12, color: c.textMuted)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (dersler.length > 2)
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: dersler.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final ders = dersler[index];
                          return HapSecim(
                            etiket: ders == 'hepsi' ? 'Tüm dersler' : dersKisaAdi(ders),
                            secili: dersFiltre == ders,
                            onTap: () => setState(() => _seciliDersFilter = ders),
                          );
                        },
                      ),
                    ),
                  if (konular.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text('Bu bölümde konu yok. Müfredatını düzenleyerek ders ve konu ekleyebilirsin.',
                          textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary)),
                    ),
                  ...satirlar,
                ],
              ),
      ),
    );
  }

  Widget _bosMufredat() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Müfredatında henüz ders yok.', style: TextStyle(color: context.colors.textSecondary, fontSize: 15)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.push('/mufredat'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ders ve konu ekle'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _konuSatiri(Konu konu) {
    final c = context.colors;
    final sinifKonusu = sinifKonusuBul(konu.id);
    final testVar = sinifKonusu != null && (konuHazirSorulari(konu.id).isNotEmpty || konuSablonlari(konu.id).isNotEmpty);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(4, 4, 6, 4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: konu.zayif ? c.danger.withValues(alpha: 0.45) : c.border),
      ),
      child: Row(
        children: [
          Checkbox(
            value: konu.tamamlandi,
            activeColor: c.success,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            onChanged: (_) => ref.read(konuProvider.notifier).toggleTamamlandi(konu.id),
          ),
          Container(width: 4, height: 30, decoration: BoxDecoration(color: konu.renk, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                konu.baslik,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: konu.tamamlandi ? c.textMuted : c.textPrimary,
                  decoration: konu.tamamlandi ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ),
          if (testVar)
            IconButton(
              tooltip: 'Bu konudan test çöz',
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.quiz_outlined, color: c.gece ? c.accent : c.primary),
              onPressed: () => _konuTesti(konu),
            ),
          IconButton(
            tooltip: konu.zayif ? 'Zayıf işaretini kaldır' : 'Zayıf konu olarak işaretle',
            visualDensity: VisualDensity.compact,
            icon: Icon(konu.zayif ? Icons.flag_rounded : Icons.outlined_flag_rounded, color: konu.zayif ? c.danger : c.textMuted),
            onPressed: () => ref.read(konuProvider.notifier).toggleZayif(konu.id),
          ),
        ],
      ),
    );
  }
}
