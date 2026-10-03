import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/bahce_data.dart';
import '../../cizimler/cizim_widgetlari.dart';
import '../../providers/bahce_provider.dart';
import '../../widgets/ui_kit.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

class BahceMagazaSheet extends ConsumerStatefulWidget {
  const BahceMagazaSheet({super.key});

  static Future<void> goster(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const FractionallySizedBox(heightFactor: 0.86, child: BahceMagazaSheet()),
    );
  }

  @override
  ConsumerState<BahceMagazaSheet> createState() => _BahceMagazaSheetState();
}

class _BahceMagazaSheetState extends ConsumerState<BahceMagazaSheet> {
  BahceUrunTip _tip = BahceUrunTip.tohum;
  String? _islemdeki;

  Future<void> _satinAl(BahceUrunu urun) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: UrunCizimi(urunId: urun.id, boyut: 64),
        title: Text(urun.ad),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${urun.fiyat} '),
            const YildizIkon(boyut: 16),
            const Flexible(child: Text(' karşılığında satın alınsın mı?')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Satın al')),
        ],
      ),
    );
    if (onay != true || !mounted) return;

    setState(() => _islemdeki = urun.id);
    final hata = await ref.read(bahceProvider.notifier).satinAl(urun);
    if (!mounted) return;
    setState(() => _islemdeki = null);
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(hata ??
          switch (urun.tip) {
            BahceUrunTip.tohum => '${urun.ad} tohum kesene eklendi. Boş bir saksıya dokunup ekebilirsin.',
            BahceUrunTip.dekor => '${urun.ad} bahçene yerleştirildi.',
            BahceUrunTip.saksi => 'Bahçene yeni bir saksı eklendi.',
          }),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bahce = ref.watch(bahceProvider);
    final c = context.colors;
    final urunler = bahceUrunleri.where((u) => u.tip == _tip).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(c.gece ? 'Tohum Pazarı' : 'Bahçe Mağazası', style: context.baslik(24))),
              SayacRozeti(ikon: const YildizIkon(boyut: 15), deger: '${bahce.yildiz}', renk: c.star, semantik: '${bahce.yildiz} yıldız'),
            ],
          ),
          const SizedBox(height: 4),
          Text('Yıldızları Çalış sekmesinde odaklanarak kazanırsın: 25 dakika = 10 yıldız.',
              style: TextStyle(fontSize: 13, color: c.textMuted)),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final t in BahceUrunTip.values) ...[
                Expanded(
                  child: HapSecim(
                    etiket: switch (t) {
                      BahceUrunTip.tohum => 'Tohum',
                      BahceUrunTip.dekor => 'Dekor',
                      BahceUrunTip.saksi => 'Saksı',
                    },
                    secili: _tip == t,
                    onTap: () => setState(() => _tip = t),
                  ),
                ),
                if (t != BahceUrunTip.values.last) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: urunler.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemBuilder: (_, i) {
                final u = urunler[i];
                final sahip = u.tip == BahceUrunTip.dekor && bahce.dekorlar.contains(u.id);
                final yetersiz = bahce.yildiz < u.fiyat;
                final islemde = _islemdeki == u.id;
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.background,
                    borderRadius: BorderRadius.circular(20),
                    border: c.gece ? Border.all(color: c.border) : null,
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 70,
                        child: Center(
                          child: Salinan(aci: 0.03, aktif: u.tip == BahceUrunTip.tohum, child: UrunCizimi(urunId: u.id, boyut: 64)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(u.ad,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w800, color: c.textPrimary)),
                      if (u.aciklama.isNotEmpty)
                        Text(u.aciklama,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11.5, color: c.textMuted)),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: FilledButton(
                          onPressed: sahip || _islemdeki != null ? null : () => _satinAl(u),
                          style: FilledButton.styleFrom(
                            backgroundColor: yetersiz ? c.textMuted : c.success,
                            foregroundColor: c.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: islemde
                              ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: c.onPrimary))
                              : sahip
                                  ? const Text('Sahipsin')
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [Text('${u.fiyat} '), const YildizIkon(boyut: 15)],
                                    ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
