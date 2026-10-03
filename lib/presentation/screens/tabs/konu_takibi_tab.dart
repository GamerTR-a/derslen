import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/konu_provider.dart';
import '../../providers/mufredat_provider.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

class KonuTakibiTab extends ConsumerStatefulWidget {
  const KonuTakibiTab({super.key});

  @override
  ConsumerState<KonuTakibiTab> createState() => _KonuTakibiTabState();
}

class _KonuTakibiTabState extends ConsumerState<KonuTakibiTab> {
  String _gorunum = 'TYT';
  String _seciliDersFilter = 'hepsi';

  @override
  Widget build(BuildContext context) {
    final serbest = ref.watch(serbestModProvider);
    final tumu = ref.watch(konuProvider);
    final ozelVar = tumu.any((k) => k.ozel);
    final gorunum = serbest ? 'OZEL' : (_gorunum == 'OZEL' && !ozelVar ? 'TYT' : _gorunum);
    final konular = switch (gorunum) {
      'OZEL' => tumu.where((k) => k.ozel).toList(),
      'AYT' => tumu.where((k) => !k.ozel && k.alan == SinavAlani.AYT).toList(),
      _ => tumu.where((k) => !k.ozel && k.alan == SinavAlani.TYT).toList(),
    };

    final tamamlananSayisi = konular.where((k) => k.tamamlandi).length;
    final yuzde = konular.isEmpty ? 0.0 : tamamlananSayisi / konular.length;

    final dersler = ['hepsi', ...konular.map((k) => k.ders).toSet()];
    if (!dersler.contains(_seciliDersFilter)) _seciliDersFilter = 'hepsi';
    final filtrelenmis = _seciliDersFilter == 'hepsi'
        ? konular
        : konular.where((k) => k.ders == _seciliDersFilter).toList();

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Üst Başlık & İlerleme Kartı
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Konu Takibi',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: context.colors.textPrimary),
                      ),
                      IconButton(
                        icon: Icon(Icons.playlist_add_rounded, color: context.colors.primary),
                        tooltip: 'Müfredatı düzenle (ders/konu ekle-çıkar)',
                        onPressed: () => context.push('/mufredat'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Soru havuzu (YKS derslerini içerir)
                  if (!serbest) GestureDetector(
                    onTap: () => context.push('/test-olustur'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [context.colors.primary, context.colors.success],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: context.colors.primary.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.science_outlined, size: 26, color: context.colors.onPrimary),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Soru Havuzu',
                                  style: TextStyle(
                                      color: context.colors.onPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Konu & zorluk seçip özel test oluştur',
                                  style: TextStyle(
                                      color: context.colors.onPrimary.withValues(alpha: 0.70), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios,
                              color: context.colors.onPrimary, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Görünüm seçici (serbest müfredatta gerekmez)
                  if (!serbest) ...[
                    SegmentedButton<String>(
                      segments: [
                        const ButtonSegment(value: 'TYT', label: Text('TYT')),
                        const ButtonSegment(value: 'AYT', label: Text('AYT')),
                        if (ozelVar) const ButtonSegment(value: 'OZEL', label: Text('Derslerim')),
                      ],
                      selected: {gorunum},
                      showSelectedIcon: false,
                      onSelectionChanged: (v) => setState(() {
                        _gorunum = v.first;
                        _seciliDersFilter = 'hepsi';
                      }),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // İlerleme Kartı
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.colors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                gorunum == 'OZEL' ? 'Tamamlanan konular' : 'Tamamlanan konular ($gorunum)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: context.colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              '$tamamlananSayisi / ${konular.length} (%${(yuzde * 100).round()})',
                              style: TextStyle(
                                  color: context.colors.primary,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: yuzde,
                            minHeight: 10,
                            backgroundColor: context.colors.border,
                            color: context.colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Ders Filtre Yatay Listesi
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: dersler.length,
                itemBuilder: (context, index) {
                  final ders = dersler[index];
                  final isSelected = _seciliDersFilter == ders;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(ders == 'hepsi' ? 'Tüm Dersler' : ders),
                      selected: isSelected,
                      selectedColor: context.colors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : context.colors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (val) {
                        setState(() => _seciliDersFilter = ders);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Konu Listesi
            Expanded(
              child: konular.isEmpty
                  ? Center(
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
                    )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: filtrelenmis.length,
                itemBuilder: (context, index) {
                  final konu = filtrelenmis[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.colors.border),
                    ),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      leading: Checkbox(
                        value: konu.tamamlandi,
                        activeColor: context.colors.success,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                        onChanged: (_) {
                          ref
                              .read(konuProvider.notifier)
                              .toggleTamamlandi(konu.id);
                        },
                      ),
                      title: Text(
                        konu.baslik,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: konu.tamamlandi ? context.colors.textMuted : context.colors.textPrimary,
                          decoration:
                              konu.tamamlandi ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      subtitle: Text(
                        konu.ders,
                        style: TextStyle(
                            fontSize: 12, color: context.colors.primary, fontWeight: FontWeight.bold),
                      ),
                      trailing: ActionChip(
                        avatar: Icon(
                          konu.zayif ? Icons.warning_amber_rounded : Icons.star_border,
                          size: 16,
                          color: konu.zayif ? context.colors.danger : context.colors.textMuted,
                        ),
                        label: Text(
                          konu.zayif ? 'Zayıf Konu' : 'Zayıf İşaretle',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: konu.zayif ? context.colors.danger : context.colors.textSecondary,
                          ),
                        ),
                        backgroundColor: konu.zayif
                            ? context.colors.danger.withValues(alpha: 0.12)
                            : context.colors.background,
                        onPressed: () {
                          ref.read(konuProvider.notifier).toggleZayif(konu.id);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

