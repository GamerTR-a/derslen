import 'package:flutter/material.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

import '../../../../core/services/okul_service.dart';
import '../../../../data/models/okul_modelleri.dart';
import '../../../widgets/ui_kit.dart';
import '../../okul/okul_ortak.dart';

/// Uygulama yöneticisi: okul açar, müdür kodunu üretir, okulu durdurur.
/// Müdür kodu tek kullanımlıktır ve müdüre güvenli bir yoldan iletilir.
class AdminOkullarTab extends StatefulWidget {
  const AdminOkullarTab({super.key});

  @override
  State<AdminOkullarTab> createState() => _AdminOkullarTabState();
}

class _AdminOkullarTabState extends State<AdminOkullarTab> {
  final _govde = GlobalKey<VeriGovdesiState<List<AdminOkul>>>();

  Future<void> _calistir(Future<void> Function() islem, {String? basari}) async {
    try {
      await islem();
      if (basari != null && mounted) okulBildir(context, basari);
      await _govde.currentState?.yenile();
    } on OkulHatasi catch (e) {
      if (mounted) okulBildir(context, e.mesaj, hata: true);
    }
  }

  Future<void> _okulEkle() async {
    final ad = TextEditingController();
    final il = TextEditingController();
    final ilce = TextEditingController();
    final onay = await okulSayfasiGoster<bool>(
      context,
      baslik: 'Okul ekle',
      insa: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: ad,
            autofocus: true,
            maxLength: 120,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(color: ctx.colors.textPrimary),
            decoration: okulGirdisi(ctx, ipucu: 'Okulun adı').copyWith(counterText: ''),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: il,
                  maxLength: 40,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(color: ctx.colors.textPrimary),
                  decoration: okulGirdisi(ctx, ipucu: 'İl').copyWith(counterText: ''),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: ilce,
                  maxLength: 40,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(color: ctx.colors.textPrimary),
                  decoration: okulGirdisi(ctx, ipucu: 'İlçe').copyWith(counterText: ''),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnaDugme(
            etiket: 'Okulu aç ve müdür kodu üret',
            onPressed: () {
              if (ad.text.trim().length < 3) return;
              Navigator.pop(ctx, true);
            },
          ),
        ],
      ),
    );
    if (onay != true) return;
    await _calistir(
      () => OkulService.adminOkulOlustur(ad: ad.text.trim(), il: il.text.trim(), ilce: ilce.text.trim()),
      basari: 'Okul açıldı. Müdür kodunu listeden kopyalayıp müdüre ilet.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return VeriGovdesi<List<AdminOkul>>(
      key: _govde,
      yukle: OkulService.adminOkullar,
      padding: const EdgeInsets.all(16),
      insa: (context, okullar, yenile) => [
        AnaDugme(etiket: 'Okul ekle', ikon: Icons.add_rounded, onPressed: _okulEkle),
        const SizedBox(height: 14),
        if (okullar.isEmpty)
          const BosDurum(
            ikon: Icons.account_balance_outlined,
            baslik: 'Henüz okul yok',
            aciklama: 'Bir okul açtığında tek kullanımlık bir müdür kodu üretilir. Müdür hesabını açıp bu kodu girer.',
          ),
        for (final o in okullar)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: YumusakKart(
              padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(o.ad,
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: c.textPrimary)),
                      ),
                      if (!o.aktif)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: c.danger.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(8)),
                          child: Text('Durduruldu',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: c.textPrimary)),
                        ),
                      PopupMenuButton<String>(
                        tooltip: 'Okul seçenekleri',
                        icon: Icon(Icons.more_vert_rounded, color: c.textMuted),
                        onSelected: (secim) {
                          if (secim == 'kod') {
                            _calistir(() => OkulService.adminMudurKodu(o.id), basari: 'Yeni müdür kodu üretildi.');
                          } else {
                            _calistir(() => OkulService.adminOkulAktiflik(o.id, !o.aktif),
                                basari: o.aktif ? 'Okul durduruldu; paneller veri göstermez.' : 'Okul yeniden etkin.');
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'kod', child: Text('Yeni müdür kodu üret')),
                          PopupMenuItem(value: 'aktif', child: Text(o.aktif ? 'Okulu durdur' : 'Okulu etkinleştir')),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    [
                      if (o.konum.isNotEmpty) o.konum,
                      '${o.ogrenci} öğrenci',
                      '${o.ogretmen} öğretmen',
                    ].join('  ·  '),
                    style: TextStyle(fontSize: 12.5, color: c.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    o.mudurler.isEmpty ? 'Müdür henüz katılmadı' : 'Müdür: ${o.mudurler.join(', ')}',
                    style: TextStyle(fontSize: 12.5, color: o.mudurler.isEmpty ? c.warning : c.textSecondary),
                  ),
                  if (o.bekleyenKod != null) ...[
                    const SizedBox(height: 8),
                    KodKutusu(kod: o.bekleyenKod!, aciklama: 'Müdür kodu (tek kullanımlık, 30 gün)'),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
