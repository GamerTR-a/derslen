import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/tarih.dart';
import '../../providers/mufredat_provider.dart';
import '../../providers/net_provider.dart';
import '../../widgets/deneme_ekle_dialog.dart';
import '../../widgets/deneme_karsilastir_sheet.dart';
import '../../widgets/empty_state_widget.dart';
import 'widgets/haftalik_rapor_card.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

class NetTakibiTab extends ConsumerWidget {
  const NetTakibiTab({super.key});

  void _denemeSilOnay(BuildContext context, WidgetRef ref, DenemeGrubu grup) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Denemeyi Sil?', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          '"${grup.ad}" denemesinin tüm ders sonuçları silinecek. Bu işlem geri alınamaz.',
          style: TextStyle(color: context.colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: TextStyle(color: context.colors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();
              ref.read(netProvider.notifier).denemeSil(grup.anahtar);
            },
            style: ElevatedButton.styleFrom(backgroundColor: context.colors.danger),
            child: Text('Sil', style: TextStyle(color: context.colors.onPrimary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gruplar = ref.watch(denemeGruplariProvider);
    final serbest = ref.watch(serbestModProvider);
    final dersOrtalamalari = ref.watch(dersNetOrtalamalariProvider);

    final toplamDeneme = gruplar.length;

    return Scaffold(
      backgroundColor: context.colors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          showDialog(
            context: context,
            builder: (_) => const DenemeEkleDialog(),
          );
        },
        backgroundColor: context.colors.primary,
        foregroundColor: context.colors.onPrimary,
        icon: Icon(Icons.add_rounded),
        label: Text(serbest ? 'Sonuç Ekle' : 'Deneme Ekle', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Üst Başlık & İstatistikler
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          serbest ? 'Sınav Sonuçları' : 'Deneme Net Takibi',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: context.colors.textPrimary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: context.colors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.colors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            serbest ? '$toplamDeneme sınav' : '$toplamDeneme Kayıtlı Deneme',
                            style: TextStyle(
                                color: context.colors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const HaftalikRaporCard(),
                    const SizedBox(height: 20),

                    // Ders Ortalamaları Kartları
                    if (dersOrtalamalari.isNotEmpty) ...[
                      Text(
                        serbest ? 'Ders bazlı ortalamaların' : 'Ders Bazlı Net Ortalamaların',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: context.colors.textPrimary),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: dersOrtalamalari.length,
                          itemBuilder: (context, index) {
                            final key = dersOrtalamalari.keys.elementAt(index);
                            final val = dersOrtalamalari[key]!;
                            return Container(
                              width: 130,
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: context.colors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: context.colors.border),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(
                                    serbest ? key.replaceFirst('TYT ', '') : key,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: context.colors.textSecondary,
                                        fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    serbest ? '$val' : '$val Net',
                                    style: TextStyle(
                                        fontSize: 18,
                                        color: context.colors.success,
                                        fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Deneme Kayıtları Başlığı
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Text(
                  serbest ? 'Sınavların' : 'Denemelerin',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary),
                ),
              ),
            ),

            // Deneme Listesi
            if (gruplar.isEmpty)
              SliverToBoxAdapter(
                child: EmptyStateWidget(
                  icon: '📝',
                  baslik: serbest ? 'Henüz sınav sonucu eklenmedi' : 'Henüz Deneme Kaydı Eklenmedi',
                  aciklama: 'Sağ alttaki düğmeyi kullanarak ilk sonucunu kaydedebilirsin.',
                  butonMetni: serbest ? 'İlk sonucunu ekle' : 'İlk Denemeni Ekle',
                  onButonPressed: () {
                    HapticFeedback.lightImpact();
                    showDialog(
                      context: context,
                      builder: (_) => const DenemeEkleDialog(),
                    );
                  },
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _denemeKarti(context, ref, gruplar[index], serbest),
                    childCount: gruplar.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _denemeKarti(BuildContext context, WidgetRef ref, DenemeGrubu g, bool serbest) {
    final ustDeger = serbest ? g.toplamNet / g.dersler.length : g.toplamNet;
    final c = context.colors;
    final tarih = DateTime.tryParse(g.tarih);
    final dersler = [...g.dersler]..sort((a, b) => b.net.compareTo(a.net));
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 8, 10),
          shape: const RoundedRectangleBorder(),
          leading: Container(
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: (g.alan == SinavAlani.TYT ? c.primary : c.accent).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  child: Text(ustDeger.toStringAsFixed(ustDeger % 1 == 0 ? 0 : (serbest ? 1 : 2)),
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: c.textPrimary)),
                ),
                Text(serbest ? 'puan' : g.alan.name, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: c.textMuted)),
              ],
            ),
          ),
          title: Text(g.ad, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: c.textPrimary)),
          subtitle: Text(
            serbest
                ? '${tarih == null ? g.tarih : kisaTarih(tarih)} · ${g.dersler.length} ders'
                : '${tarih == null ? g.tarih : kisaTarih(tarih)} · ${g.dersler.length} ders · ${g.dogru}D ${g.yanlis}Y ${g.bos}B',
            style: TextStyle(fontSize: 12, color: c.textSecondary),
          ),
          children: [
            for (final k in dersler)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(width: 4, height: 28, decoration: BoxDecoration(color: k.renk, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(k.ders, style: TextStyle(fontWeight: FontWeight.w700, color: c.textPrimary)),
                          if (!serbest) Text('${k.dogru} D · ${k.yanlis} Y · ${k.bos} B', style: TextStyle(fontSize: 11.5, color: c.textMuted)),
                        ],
                      ),
                    ),
                    Text('${k.net}', style: TextStyle(fontWeight: FontWeight.w900, color: c.primary)),
                    if (!serbest && !otomatikDenemeAdi(k.denemeAdi))
                      IconButton(
                        icon: Icon(Icons.leaderboard_outlined, color: c.primary, size: 20),
                        tooltip: 'Topluluk ile karşılaştır',
                        onPressed: () => denemeKarsilastirSheetGoster(context, k),
                      ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _denemeSilOnay(context, ref, g),
                icon: Icon(Icons.delete_outline_rounded, color: c.danger, size: 18),
                label: Text(serbest ? 'Sınavı sil' : 'Denemeyi sil', style: TextStyle(color: c.danger)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
