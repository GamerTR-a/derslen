import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

import '../../../core/algorithms/okul_hesaplari.dart';
import '../../../core/services/okul_service.dart';
import '../../../data/models/okul_modelleri.dart';
import '../../providers/auth_provider.dart';
import '../../providers/okul_provider.dart';
import '../../widgets/ui_kit.dart';
import 'ogrenci_ozet_gorunumu.dart';
import 'okul_ortak.dart';
import 'rol_kabugu.dart';

/// Velinin birden fazla çocuğu varsa seçili olan (null: ilki).
final _seciliCocukProvider = StateProvider<String?>((ref) => null);

final _cocukOzetiProvider = FutureProvider.autoDispose.family<OgrenciOzeti, String>(
  (ref, id) => OkulService.ogrenciOzeti(id),
);

Cocuk? _seciliCocuk(WidgetRef ref) {
  final cocuklar = ref.watch(okulDurumuProvider).value?.cocuklar ?? const <Cocuk>[];
  if (cocuklar.isEmpty) return null;
  final secili = ref.watch(_seciliCocukProvider);
  return cocuklar.where((c) => c.id == secili).firstOrNull ?? cocuklar.first;
}

/// Veli paneli: Özet, Geçmiş, Hesap. Veli yalnızca kendisine kod veren
/// çocuğunun çalışma özetini görür.
class VeliPaneli extends StatelessWidget {
  const VeliPaneli({super.key});

  @override
  Widget build(BuildContext context) {
    return RolKabugu(
      sekmeler: [
        PanelSekmesi(
          etiket: 'Özet',
          ikon: Icons.insights_outlined,
          seciliIkon: Icons.insights_rounded,
          insa: (_) => const _CocukSekmesi(gecmis: false),
        ),
        PanelSekmesi(
          etiket: 'Geçmiş',
          ikon: Icons.calendar_month_outlined,
          seciliIkon: Icons.calendar_month_rounded,
          insa: (_) => const _CocukSekmesi(gecmis: true),
        ),
        PanelSekmesi(
          etiket: 'Hesap',
          ikon: Icons.person_outline_rounded,
          seciliIkon: Icons.person_rounded,
          insa: (_) => const RolProfilSekmesi(ekBolumler: [_Baglantilar()]),
        ),
      ],
    );
  }
}

/// Veli kodu girme sayfası. Başarılıysa true döner.
Future<bool> veliKoduSayfasi(BuildContext context) async {
  final kod = TextEditingController();
  var islemde = false;
  String? hata;
  final sonuc = await okulSayfasiGoster<bool>(
    context,
    baslik: 'Veli kodu gir',
    insa: (ctx) => StatefulBuilder(
      builder: (ctx, guncelle) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Çocuğun DersNet\'te Profil › Okulum ve velim bölümünden bir veli kodu üretir. Kod 7 gün geçerlidir.',
            style: TextStyle(fontSize: 13.5, color: ctx.colors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: kod,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            enableSuggestions: false,
            maxLength: 14,
            style: TextStyle(color: ctx.colors.textPrimary, fontWeight: FontWeight.w700, letterSpacing: 1.2),
            decoration: okulGirdisi(ctx, ipucu: 'V-XXXX-XXXX', ikon: Icons.key_rounded).copyWith(counterText: ''),
          ),
          if (hata != null) ...[
            const SizedBox(height: 8),
            Text(hata!, style: TextStyle(color: ctx.colors.danger, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 14),
          AnaDugme(
            etiket: 'Bağlan',
            yukleniyor: islemde,
            onPressed: () async {
              if (kodTemizle(kod.text).length != 9) {
                guncelle(() => hata = 'Kod 9 karakterdir (ör. V-ABCD-2345).');
                return;
              }
              guncelle(() {
                islemde = true;
                hata = null;
              });
              try {
                final s = await OkulService.koduKullan(kod.text, KullaniciRolu.veli);
                if (!ctx.mounted) return;
                if (s.basarili) {
                  Navigator.pop(ctx, true);
                } else {
                  guncelle(() {
                    islemde = false;
                    hata = kodHataMetni(s.durum, KullaniciRolu.veli);
                  });
                }
              } on OkulHatasi catch (e) {
                guncelle(() {
                  islemde = false;
                  hata = e.mesaj;
                });
              }
            },
          ),
        ],
      ),
    ),
  );
  return sonuc == true;
}

class _CocukSekmesi extends ConsumerWidget {
  final bool gecmis;
  const _CocukSekmesi({required this.gecmis});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final durum = ref.watch(okulDurumuProvider);
    final cocuklar = durum.value?.cocuklar ?? const <Cocuk>[];
    final cocuk = _seciliCocuk(ref);
    final ozet = cocuk == null ? null : ref.watch(_cocukOzetiProvider(cocuk.id));

    Future<void> yenile() async {
      ref.invalidate(okulDurumuProvider);
      if (cocuk != null) ref.invalidate(_cocukOzetiProvider(cocuk.id));
      await ref.read(okulDurumuProvider.future);
    }

    final List<Widget> govde;
    if (durum.isLoading && cocuklar.isEmpty) {
      govde = const [SizedBox(height: 120), Center(child: CircularProgressIndicator())];
    } else if (cocuk == null) {
      govde = [
        const BosDurum(
          ikon: Icons.family_restroom_rounded,
          baslik: 'Henüz bağlı bir öğrenci yok',
          aciklama: 'Çocuğunun ürettiği veli kodunu girerek haftalık çalışma özetini görmeye başlayabilirsin.',
        ),
        AnaDugme(
          etiket: 'Veli kodu gir',
          ikon: Icons.key_rounded,
          onPressed: () async {
            if (await veliKoduSayfasi(context)) await yenile();
          },
        ),
      ];
    } else {
      govde = [
        if (cocuklar.length > 1) ...[
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cocuklar.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => HapSecim(
                etiket: cocuklar[i].ad,
                secili: cocuklar[i].id == cocuk.id,
                onTap: () => ref.read(_seciliCocukProvider.notifier).state = cocuklar[i].id,
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        ...switch (ozet!) {
          AsyncData(:final value) => [
              if (!gecmis) ...[
                ...haftaBolumu(context, value),
                const SizedBox(height: 14),
                YumusakKart(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Haftalık özet', style: context.baslik(17)),
                      const SizedBox(height: 8),
                      Text(veliOzetMetni(value), style: TextStyle(fontSize: 13.5, color: c.textSecondary, height: 1.5)),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: veliOzetMetni(value)));
                            if (context.mounted) okulBildir(context, 'Özet kopyalandı.');
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('Kopyala'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const BilgiKarti(
                  ikon: Icons.visibility_outlined,
                  baslik: 'Bu özet neyi gösterir?',
                  maddeler: [
                    'Süre, çocuğun uygulamadaki odak sayacıyla ölçülür; sayaç dışındaki çalışmalar görünmeyebilir.',
                    'Ruh hâli kayıtları, asistan sohbetleri ve kişisel notlar hiçbir zaman paylaşılmaz.',
                    'Çocuğun bu bağlantıyı kendi uygulamasından istediği zaman kaldırabilir.',
                  ],
                ),
              ] else
                ...gecmisBolumu(context, value),
            ],
          AsyncError(:final error) => [
              const SizedBox(height: 60),
              Icon(Icons.wifi_off_rounded, size: 44, color: c.textMuted),
              const SizedBox(height: 12),
              Text('$error', textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary)),
              const SizedBox(height: 12),
              Center(child: OutlinedButton(onPressed: yenile, child: const Text('Tekrar dene'))),
            ],
          _ => const [SizedBox(height: 120), Center(child: CircularProgressIndicator())],
        },
      ];
    }

    return RefreshIndicator(
      onRefresh: yenile,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          PanelBasligi(
            gecmis ? 'Geçmiş' : (cocuk?.ad ?? 'Özet'),
            alt: gecmis
                ? (cocuk == null ? null : '${cocuk.ad} · son 4 hafta')
                : (cocuk == null ? null : [if (cocuk.sinif != null) cocuk.sinif!, 'bu haftanın özeti'].join('  ·  ')),
          ),
          ...govde,
        ],
      ),
    );
  }
}

/// Hesap sekmesinde: bağlı çocuklar, yeni kod girme, bağlantıyı kaldırma.
class _Baglantilar extends ConsumerWidget {
  const _Baglantilar();

  Future<void> _kaldir(BuildContext context, WidgetRef ref, Cocuk cocuk) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.colors.surface,
        title: const Text('Bağlantıyı kaldır'),
        content: Text('${cocuk.ad} adlı öğrencinin özetini artık göremeyeceksin. Yeniden bağlanmak için yeni bir veli kodu gerekir.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kaldır')),
        ],
      ),
    );
    if (onay != true) return;
    try {
      final baglantilar = await OkulService.veliBaglantilari();
      final cocuklar = ref.read(okulDurumuProvider).value?.cocuklar ?? const <Cocuk>[];
      final hedef = baglantilar.where((b) => b.aktif && !b.benOgrenci && b.karsiId == cocuk.id).firstOrNull;
      if (hedef == null) {
        if (context.mounted) okulBildir(context, 'Bağlantı bulunamadı. Sayfayı yenileyip tekrar dene.', hata: true);
        return;
      }
      await OkulService.veliBaglantisiniBitir(hedef.id);
      ref.invalidate(okulDurumuProvider);
      // Son çocuk da kaldırıldıysa hesap öğrenci rolüne döner.
      if (cocuklar.length <= 1) await ref.read(authProvider.notifier).rolTamamlandi();
    } on OkulHatasi catch (e) {
      if (context.mounted) okulBildir(context, e.mesaj, hata: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final cocuklar = ref.watch(okulDurumuProvider).value?.cocuklar ?? const <Cocuk>[];
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: YumusakKart(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bağlı öğrenciler', style: context.baslik(17)),
            const SizedBox(height: 6),
            if (cocuklar.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('Henüz bağlı öğrenci yok.', style: TextStyle(color: c.textMuted)),
              ),
            for (final cocuk in cocuklar)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.school_outlined, color: c.textSecondary),
                title: Text(cocuk.ad, style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700)),
                subtitle: cocuk.sinif == null ? null : Text(cocuk.sinif!, style: TextStyle(color: c.textMuted)),
                trailing: IconButton(
                  tooltip: 'Bağlantıyı kaldır',
                  onPressed: () => _kaldir(context, ref, cocuk),
                  icon: Icon(Icons.link_off_rounded, color: c.textMuted),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  if (await veliKoduSayfasi(context)) ref.invalidate(okulDurumuProvider);
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Başka bir öğrenci ekle'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
