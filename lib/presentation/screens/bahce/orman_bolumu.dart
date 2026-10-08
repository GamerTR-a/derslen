import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/bahce_data.dart';
import '../../../core/constants/bahce_iklim.dart';
import '../../cizimler/cizim_widgetlari.dart';
import '../../cizimler/iklim_boyaci.dart';
import '../../cizimler/sahne_boyaci.dart';
import '../../providers/bahce_provider.dart';
import '../../widgets/ui_kit.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

/// Bir bölgenin ormanında görünecek bitkiler: taşınanlar ve aralarına
/// kendiliğinden yerleşen yerli türler.
List<String> ormanGorunumu(IklimBolgesi bolge, List<String> bitkiler) {
  final yerli = yerliTurSayisi(bitkiler.length);
  final liste = <String>[];
  for (var i = 0; i < bitkiler.length; i++) {
    liste.add(bitkiler[i]);
    if ((i + 1) % yerliTurAraligi == 0 && (i + 1) ~/ yerliTurAraligi <= yerli) liste.add(bolge.yerliTurId);
  }
  return liste;
}

/// Seçili iklim bölgesinin ormanı: manzara, bitkiler ve bölge bilgisi.
class OrmanKarti extends ConsumerWidget {
  const OrmanKarti({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bahce = ref.watch(bahceProvider);
    final c = context.colors;
    final bolge = iklimBul(bahce.iklim);
    final bitkiler = bahce.aktifOrman;
    final yerli = yerliTurSayisi(bitkiler.length);
    final sonrakiYerli = yerli >= maksYerliTur ? 0 : yerliTurAraligi - bitkiler.length % yerliTurAraligi;

    return YumusakKart(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(c.gece ? 'Işıklı ormanım' : 'Ormanım', style: context.baslik(18))),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => IklimSecimSheet.goster(context),
                icon: const Icon(Icons.public_rounded, size: 18),
                label: const Text('Bölge seç', style: TextStyle(fontWeight: FontWeight.w800)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${bolge.ad} · ${bolge.iklimTipi}',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.textSecondary)),
          const SizedBox(height: 10),
          OrmanSahnesi(bolge: bolge, bitkiler: bitkiler),
          const SizedBox(height: 10),
          Text(
            [
              ormanSeviyesi(bitkiler.length),
              '${bitkiler.length} bitki',
              if (yerli > 0) '$yerli ${bolge.yerliTur.toLowerCase()}',
            ].join(' · '),
            style: TextStyle(fontWeight: FontWeight.w800, color: c.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            sonrakiYerli == 0
                ? 'Bu bölgenin yerli türleri ormanına yerleşti. Yeni bir bölge keşfetmeye ne dersin?'
                : '$sonrakiYerli bitki daha taşıdığında ormanına yerli bir ${bolge.yerliTur.toLowerCase()} yerleşir.',
            style: TextStyle(fontSize: 12.5, color: c.textMuted, height: 1.35),
          ),
          const SizedBox(height: 10),
          _Sevenler(bolge: bolge),
        ],
      ),
    );
  }
}

/// "Bu iklimi sevenler" satırı.
class _Sevenler extends StatelessWidget {
  final IklimBolgesi bolge;
  const _Sevenler({required this.bolge});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final adlar = bolge.sevenler.map((id) => bahceUrunuBul(id)?.ad ?? id).join(', ');
    return Semantics(
      label: 'Bu iklimi sevenler: $adlar. Sulandıklarında iki kat büyürler.',
      excludeSemantics: true,
      child: Row(
        children: [
          for (final id in bolge.sevenler) Padding(padding: const EdgeInsets.only(right: 2), child: UrunCizimi(urunId: id, boyut: 28)),
          const SizedBox(width: 6),
          Expanded(
            child: Text('Bu iklimi sever, sulayınca 2 kat büyür',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.success)),
          ),
        ],
      ),
    );
  }
}

/// İklim manzarası üzerinde, arkadan öne üç sıra hâlinde dizilen bitkiler.
class OrmanSahnesi extends StatelessWidget {
  final IklimBolgesi bolge;
  final List<String> bitkiler;
  final double yukseklik;

  const OrmanSahnesi({super.key, required this.bolge, required this.bitkiler, this.yukseklik = 190});

  static const int _enCokGorunen = 30;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hepsi = ormanGorunumu(bolge, bitkiler);
    final gorunen = hepsi.length > _enCokGorunen ? hepsi.sublist(hepsi.length - _enCokGorunen) : hepsi;
    const boyutlar = [36.0, 46.0, 58.0];
    const tabanlar = [0.34, 0.2, 0.05];

    return Semantics(
      label: bitkiler.isEmpty
          ? '${bolge.ad} ormanı, henüz bitki yok'
          : '${bolge.ad} ormanı, ${bitkiler.length} bitki',
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: yukseklik,
          width: double.infinity,
          child: HareketliSahne(
            dongu: const Duration(seconds: 18),
            boyaci: (t) => IklimSahnesiBoyaci(bolge.id, c.gece, t),
            child: LayoutBuilder(
              builder: (context, kisit) {
                final w = kisit.maxWidth;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var sira = 0; sira < 3; sira++)
                      for (var i = sira; i < gorunen.length; i += 3)
                        Positioned(
                          left: 6 + (((i ~/ 3) * 0.618 + sira * 0.29) % 1) * (w - 12 - boyutlar[sira] * 0.8),
                          bottom: yukseklik * tabanlar[sira],
                          child: Salinan(aci: 0.025, child: UrunCizimi(urunId: gorunen[i], boyut: boyutlar[sira])),
                        ),
                    if (bitkiler.isEmpty)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: c.surface.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(12)),
                          child: Text('Olgunlaşan bitkilerini buraya taşıyarak bu bölgede kalıcı bir orman kur.',
                              textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: c.textSecondary)),
                        ),
                      ),
                    if (hepsi.length > gorunen.length)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: c.surface.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(10)),
                          child: Text('+${hepsi.length - gorunen.length}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c.textPrimary)),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// İklim bölgesi seçimi.
class IklimSecimSheet extends ConsumerWidget {
  const IklimSecimSheet({super.key});

  static Future<void> goster(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const FractionallySizedBox(heightFactor: 0.88, child: IklimSecimSheet()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bahce = ref.watch(bahceProvider);
    final c = context.colors;
    final doluBolge = iklimBolgeleri.where((b) => bahce.bolgeOrmani(b.id).isNotEmpty).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
          child: Text('Ormanın nerede büyüsün?', style: context.baslik(22)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Text(
            'Bir iklim bölgesi seç. Olgunlaşan bitkilerin o bölgenin ormanına taşınır; her bölgenin ormanı ayrı büyür ve diğerleri yerinde kalır.'
            '${bahce.orman.isEmpty ? '' : ' Şu an $doluBolge bölgede toplam ${bahce.orman.length} bitkin var.'}',
            style: TextStyle(fontSize: 13, color: c.textMuted, height: 1.4),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            itemCount: iklimBolgeleri.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final b = iklimBolgeleri[i];
              final secili = b.id == bahce.iklim;
              final sayi = bahce.bolgeOrmani(b.id).length;
              return Semantics(
                button: true,
                selected: secili,
                label: '${b.ad}, ${b.iklimTipi}. ${b.aciklama} Bitki örtüsü: ${b.bitkiOrtusu}. $sayi bitki.',
                excludeSemantics: true,
                child: Material(
                  color: c.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: secili ? c.primary : c.border, width: secili ? 2 : 1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(context);
                      if (secili) return;
                      await ref.read(bahceProvider.notifier).iklimSec(b.id);
                      messenger
                        ..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(content: Text('Ormanın artık ${b.ad} bölgesinde büyüyor.')));
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 84,
                          width: double.infinity,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CustomPaint(painter: IklimSahnesiBoyaci(b.id, c.gece, 0.3)),
                              Positioned(left: 14, bottom: 4, child: UrunCizimi(urunId: b.yerliTurId, boyut: 50)),
                              if (secili)
                                Positioned(
                                  right: 10,
                                  top: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(12)),
                                    child: Text('Seçili', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c.onPrimary)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(b.ad, style: context.baslik(17))),
                                  Text(sayi == 0 ? 'Keşfedilmedi' : '${ormanSeviyesi(sayi)} · $sayi bitki',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: sayi == 0 ? c.textMuted : c.success)),
                                ],
                              ),
                              Text(b.iklimTipi, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.primary)),
                              const SizedBox(height: 4),
                              Text(b.aciklama, style: TextStyle(fontSize: 12.5, color: c.textSecondary, height: 1.35)),
                              const SizedBox(height: 4),
                              Text('Bitki örtüsü: ${b.bitkiOrtusu} · Yerli tür: ${b.yerliTur}',
                                  style: TextStyle(fontSize: 12, color: c.textMuted, height: 1.35)),
                              const SizedBox(height: 8),
                              _Sevenler(bolge: b),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
