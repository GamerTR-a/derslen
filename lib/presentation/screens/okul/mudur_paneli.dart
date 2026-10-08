import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

import '../../../core/algorithms/okul_hesaplari.dart';
import '../../../core/services/okul_service.dart';
import '../../../core/utils/tarih.dart';
import '../../../data/models/okul_modelleri.dart';
import '../../widgets/grafikler.dart';
import '../../widgets/ui_kit.dart';
import 'okul_ortak.dart';
import 'rol_kabugu.dart';

/// Müdür paneli: Okul özeti, Yönetim (şubeler, öğretmenler, kodlar), Rapor,
/// Hesap. Müdür yalnızca şube toplamlarını görür; öğrenci detayı rehber
/// öğretmendedir.
class MudurPaneli extends StatelessWidget {
  const MudurPaneli({super.key});

  @override
  Widget build(BuildContext context) {
    return RolKabugu(
      sekmeler: [
        PanelSekmesi(
          etiket: 'Okul',
          ikon: Icons.account_balance_outlined,
          seciliIkon: Icons.account_balance_rounded,
          insa: (_) => const _OkulOzetiSekmesi(),
        ),
        PanelSekmesi(
          etiket: 'Yönetim',
          ikon: Icons.manage_accounts_outlined,
          seciliIkon: Icons.manage_accounts_rounded,
          insa: (_) => const _Yonetim(),
        ),
        PanelSekmesi(
          etiket: 'Rapor',
          ikon: Icons.summarize_outlined,
          seciliIkon: Icons.summarize_rounded,
          insa: (_) => const _Rapor(),
        ),
        PanelSekmesi(
          etiket: 'Hesap',
          ikon: Icons.person_outline_rounded,
          seciliIkon: Icons.person_rounded,
          insa: (_) => const RolProfilSekmesi(),
        ),
      ],
    );
  }
}

// ─── Okul özeti ──────────────────────────────────────────────────────

class _OkulOzetiSekmesi extends StatelessWidget {
  const _OkulOzetiSekmesi();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return VeriGovdesi<OkulOzeti>(
      yukle: OkulService.okulOzeti,
      insa: (context, o, yenile) => [
        PanelBasligi(o.okul.isEmpty ? 'Okulum' : o.okul, alt: 'Son 7 günün özeti'),
        if (o.ogrenci == 0)
          const BosDurum(
            ikon: Icons.rocket_launch_outlined,
            baslik: 'Okulun kuruldu, sıra öğrencilerde',
            aciklama:
                'Yönetim sekmesinden şubelerini ekle ve şube kodlarını öğrencilerle paylaş. Öğrenciler katıldıkça okulun özeti burada oluşur.',
          )
        else ...[
          IkiliSatir(
            KpiKutusu(
              ikon: Icons.groups_outlined,
              deger: '${o.aktif7g} / ${o.ogrenci}',
              etiket: 'Bu hafta çalışan öğrenci',
              alt: '%${o.aktifOrani} aktif',
              altRenk: o.aktifOrani >= 50 ? c.success : c.warning,
            ),
            KpiKutusu(
              ikon: Icons.timer_outlined,
              deger: sureMetni(o.ortDk7g),
              etiket: 'Öğrenci başına haftalık',
              renk: c.info,
            ),
          ),
          const SizedBox(height: 10),
          IkiliSatir(
            KpiKutusu(
              ikon: Icons.notification_important_outlined,
              deger: '${o.risk}',
              etiket: 'İlgi bekleyen öğrenci',
              alt: 'rehber öğretmen panelinde',
              renk: o.risk > 0 ? c.danger : c.success,
            ),
            KpiKutusu(
              ikon: Icons.diversity_3_outlined,
              deger: '${o.ogretmen} / ${o.veli}',
              etiket: 'Öğretmen / bağlı veli',
              renk: c.warning,
            ),
          ),
          const SizedBox(height: 14),
          GrafikKarti(
            baslik: 'Haftalık toplam çalışma',
            aciklama: 'Son 8 hafta · okulun tüm öğrencileri',
            child: _HaftaCubuklari(haftalar: o.haftalar),
          ),
          const SizedBox(height: 14),
          GrafikKarti(
            baslik: 'Şubeler',
            aciklama: 'Bu hafta çalışan öğrenci oranı ve kişi başı ortalama süre',
            child: Column(
              children: [
                for (final s in o.subeler)
                  OranSatiri(
                    etiket: s.sube.etiket,
                    deger: '%${s.aktifOrani}',
                    oran: s.aktifOrani / 100,
                    renk: s.aktifOrani >= 60 ? c.success : (s.aktifOrani >= 30 ? c.warning : c.danger),
                    alt:
                        '${s.aktif7g} / ${s.ogrenci} öğrenci · ortalama ${sureMetni(s.ortDk7g)}${s.risk > 0 ? ' · ${s.risk} uyarı' : ''}',
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const BilgiKarti(
            ikon: Icons.lock_outline_rounded,
            baslik: 'Müdür paneli toplamları gösterir',
            maddeler: [
              'Tek tek öğrenci verisi yalnızca şubenin rehber öğretmenine açıktır.',
              'Öğrenciler arasında sıralama yapılmaz; şubeler yalnızca katılım oranıyla karşılaştırılır.',
            ],
          ),
        ],
      ],
    );
  }
}

class _HaftaCubuklari extends StatelessWidget {
  final List<HaftaToplami> haftalar;
  const _HaftaCubuklari({required this.haftalar});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enBuyuk = haftalar.fold<int>(0, (m, h) => max(m, h.toplamDk));
    if (enBuyuk == 0) return const BosGrafikMesaji(metin: 'Henüz çalışma kaydı yok.');
    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final h in haftalar)
            Expanded(
              child: Semantics(
                label: '${h.bas} haftası: ${sureMetni(h.toplamDk)}, ${h.aktif} öğrenci',
                child: Tooltip(
                  message: '${sureMetni(h.toplamDk)} · ${h.aktif} öğrenci',
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(h.toplamDk >= 60 ? '${h.toplamDk ~/ 60}sa' : '${h.toplamDk}dk',
                            maxLines: 1, style: TextStyle(fontSize: 10, color: c.textMuted, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        height: max(4, 88 * h.toplamDk / enBuyuk),
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          color: h == haftalar.last ? c.primary : c.primary.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 5),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          () {
                            final t = DateTime.tryParse(h.bas);
                            return t == null ? '' : '${t.day}.${t.month}';
                          }(),
                          maxLines: 1,
                          style: TextStyle(fontSize: 10.5, color: c.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Yönetim ─────────────────────────────────────────────────────────

class _Yonetim extends StatefulWidget {
  const _Yonetim();

  @override
  State<_Yonetim> createState() => _YonetimState();
}

class _YonetimState extends State<_Yonetim> {
  final _govde = GlobalKey<VeriGovdesiState<YonetimOzeti>>();

  Future<void> _yenile() async => _govde.currentState?.yenile();

  Future<void> _calistir(Future<void> Function() islem, {String? basari}) async {
    try {
      await islem();
      if (basari != null && mounted) okulBildir(context, basari);
      await _yenile();
    } on OkulHatasi catch (e) {
      if (mounted) okulBildir(context, e.mesaj, hata: true);
    }
  }

  Future<bool> _onay(String baslik, String metin, String eylem) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: ctx.colors.surface,
          title: Text(baslik),
          content: Text(metin),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(eylem)),
          ],
        ),
      ) ==
      true;

  Future<void> _subeEkle() async {
    var sinif = '12';
    final ad = TextEditingController();
    final eklenecek = await okulSayfasiGoster<(String, String)>(
      context,
      baslik: 'Şube ekle',
      insa: (ctx) => StatefulBuilder(
        builder: (ctx, guncelle) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sınıf', style: TextStyle(fontWeight: FontWeight.w700, color: ctx.colors.textPrimary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in okulSiniflari)
                  HapSecim(etiket: s, secili: sinif == s, onTap: () => guncelle(() => sinif = s)),
              ],
            ),
            const SizedBox(height: 14),
            Text('Şube adı', style: TextStyle(fontWeight: FontWeight.w700, color: ctx.colors.textPrimary)),
            const SizedBox(height: 8),
            TextField(
              controller: ad,
              autofocus: true,
              maxLength: 12,
              textCapitalization: TextCapitalization.characters,
              style: TextStyle(color: ctx.colors.textPrimary),
              decoration: okulGirdisi(ctx, ipucu: 'ör. A ya da FEN-1').copyWith(counterText: ''),
            ),
            const SizedBox(height: 14),
            AnaDugme(
              etiket: 'Şubeyi ekle',
              onPressed: () {
                if (ad.text.trim().isEmpty) return;
                Navigator.pop(ctx, (sinif, ad.text.trim()));
              },
            ),
          ],
        ),
      ),
    );
    if (eklenecek == null) return;
    await _calistir(() async {
      final kod = await OkulService.subeEkle(eklenecek.$1, eklenecek.$2);
      if (!mounted) return;
      okulBildir(context, kod == null ? 'Bu şube zaten var.' : 'Şube eklendi. Katılım kodunu öğrencilerle paylaşabilirsin.',
          hata: kod == null);
    });
  }

  Future<void> _ogretmenKodu() async {
    var rehber = true;
    var brans = okulBranslari.first;
    final secim = await okulSayfasiGoster<(bool, String)>(
      context,
      baslik: 'Öğretmen kodu üret',
      insa: (ctx) => StatefulBuilder(
        builder: (ctx, guncelle) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GorevSecici(
              rehber: rehber,
              brans: brans,
              degisti: (r, b) => guncelle(() {
                rehber = r;
                brans = b;
              }),
            ),
            const SizedBox(height: 8),
            Text('Kod tek kullanımlıktır ve 14 gün geçerlidir. Öğretmen hesabını açarken bu kodu girer.',
                style: TextStyle(fontSize: 12.5, color: ctx.colors.textMuted, height: 1.4)),
            const SizedBox(height: 14),
            AnaDugme(etiket: 'Kodu üret', onPressed: () => Navigator.pop(ctx, (rehber, brans))),
          ],
        ),
      ),
    );
    if (secim == null) return;
    await _calistir(() async {
      await OkulService.ogretmenKoduUret(rehber: secim.$1, brans: secim.$1 ? null : secim.$2);
    }, basari: 'Kod üretildi. Aşağıdaki listeden kopyalayıp öğretmene iletebilirsin.');
  }

  Future<void> _ogretmenDuzenle(YonetimOgretmeni o, List<YonetimSubesi> subeler) async {
    var rehber = o.rehber;
    var brans = o.brans ?? okulBranslari.first;
    final secili = {...o.subeIdleri};
    final sonuc = await okulSayfasiGoster<String>(
      context,
      baslik: o.ad,
      insa: (ctx) => StatefulBuilder(
        builder: (ctx, guncelle) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GorevSecici(
              rehber: rehber,
              brans: brans,
              degisti: (r, b) => guncelle(() {
                rehber = r;
                brans = b;
              }),
            ),
            const SizedBox(height: 14),
            Text('Şubeleri', style: TextStyle(fontWeight: FontWeight.w700, color: ctx.colors.textPrimary)),
            const SizedBox(height: 8),
            if (subeler.isEmpty)
              Text('Önce şube ekle.', style: TextStyle(color: ctx.colors.textMuted))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in subeler)
                    HapSecim(
                      etiket: s.sube.etiket,
                      secili: secili.contains(s.sube.id),
                      onTap: () => guncelle(() => secili.contains(s.sube.id) ? secili.remove(s.sube.id) : secili.add(s.sube.id)),
                    ),
                ],
              ),
            const SizedBox(height: 8),
            Text(
              rehber
                  ? 'Rehber öğretmen, seçili şubelerdeki öğrencilerin tüm derslerini ve uyarıları görür.'
                  : 'Branş öğretmeni, seçili şubelerdeki öğrencilerin yalnızca $brans çalışmalarını görür.',
              style: TextStyle(fontSize: 12.5, color: ctx.colors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 14),
            AnaDugme(etiket: 'Kaydet', onPressed: () => Navigator.pop(ctx, 'kaydet')),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(ctx, 'cikar'),
                child: Text('Öğretmeni okuldan çıkar', style: TextStyle(color: ctx.colors.danger)),
              ),
            ),
          ],
        ),
      ),
    );
    if (sonuc == 'kaydet') {
      await _calistir(
        () => OkulService.ogretmenAyarla(
          ogretmenId: o.id,
          subeIdleri: secili.toList(),
          rehber: rehber,
          brans: rehber ? null : brans,
        ),
        basari: 'Öğretmen güncellendi.',
      );
    } else if (sonuc == 'cikar') {
      if (await _onay('Öğretmeni çıkar', '${o.ad} artık okulunun şubelerini ve öğrencilerini göremeyecek.', 'Çıkar')) {
        await _calistir(() => OkulService.uyeyiCikar(o.id), basari: 'Öğretmen okuldan çıkarıldı.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return VeriGovdesi<YonetimOzeti>(
      key: _govde,
      yukle: OkulService.yonetimOzeti,
      insa: (context, y, yenile) => [
        PanelBasligi('Yönetim', alt: y.okulAd),
        BolumBasligi('Şubeler', aksiyon: 'Şube ekle', onAksiyon: _subeEkle),
        if (y.subeler.isEmpty)
          const BosDurum(
            ikon: Icons.meeting_room_outlined,
            baslik: 'Henüz şube yok',
            aciklama: 'Her şubenin kendi katılım kodu olur. Öğrenciler bu kodla sınıfına katılır.',
          )
        else
          for (final s in y.subeler)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: YumusakKart(
                padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(s.sube.etiket, style: context.baslik(19)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('${s.ogrenciSayisi} öğrenci',
                              style: TextStyle(fontSize: 13, color: c.textMuted, fontWeight: FontWeight.w600)),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Şube seçenekleri',
                          icon: Icon(Icons.more_vert_rounded, color: c.textMuted),
                          onSelected: (secim) async {
                            if (secim == 'yenile') {
                              if (await _onay('Kodu yenile',
                                  'Eski kod geçersiz olur. Zaten katılmış öğrenciler etkilenmez.', 'Yenile')) {
                                await _calistir(() => OkulService.subeKoduYenile(s.sube.id), basari: 'Yeni kod üretildi.');
                              }
                            } else if (secim == 'sil') {
                              if (await _onay('Şubeyi sil', '${s.sube.etiket} şubesi silinecek.', 'Sil')) {
                                await _calistir(() async {
                                  final sonuc = await OkulService.subeSil(s.sube.id);
                                  if (mounted && sonuc == 'dolu') {
                                    okulBildir(this.context, 'Öğrencisi olan şube silinemez.', hata: true);
                                  }
                                });
                              }
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'yenile', child: Text('Katılım kodunu yenile')),
                            PopupMenuItem(value: 'sil', child: Text('Şubeyi sil')),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    KodKutusu(kod: s.kod, aciklama: 'Öğrenci katılım kodu'),
                    const SizedBox(height: 8),
                    Text(
                      s.ogretmenler.isEmpty ? 'Atanmış öğretmen yok' : 'Öğretmenler: ${s.ogretmenler.join(', ')}',
                      style: TextStyle(fontSize: 12.5, color: s.ogretmenler.isEmpty ? c.warning : c.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
        const SizedBox(height: 12),
        BolumBasligi('Öğretmenler', aksiyon: 'Kod üret', onAksiyon: _ogretmenKodu),
        if (y.ogretmenler.isEmpty && y.davetler.isEmpty)
          const BosDurum(
            ikon: Icons.co_present_outlined,
            baslik: 'Henüz öğretmen yok',
            aciklama: 'Her öğretmen için bir kod üret. Öğretmen hesabını açıp kodu girdikten sonra onu şubelerine ata.',
          ),
        for (final o in y.ogretmenler)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: YumusakKart(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              onTap: () => _ogretmenDuzenle(o, y.subeler),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o.ad, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: c.textPrimary)),
                        const SizedBox(height: 2),
                        Text(
                          [
                            o.gorev,
                            o.subeIdleri.isEmpty
                                ? 'şube atanmadı'
                                : y.subeler.where((s) => o.subeIdleri.contains(s.sube.id)).map((s) => s.sube.etiket).join(', '),
                          ].join('  ·  '),
                          style: TextStyle(fontSize: 12.5, color: o.subeIdleri.isEmpty ? c.warning : c.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.tune_rounded, color: c.textMuted, size: 20),
                ],
              ),
            ),
          ),
        if (y.davetler.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('Bekleyen öğretmen kodları',
              style: TextStyle(fontSize: 13, color: c.textSecondary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final d in y.davetler)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: KodKutusu(
                      kod: d.kod,
                      aciklama:
                          '${d.gorev}${d.sonGecerlilik == null ? '' : ' · ${kisaTarih(d.sonGecerlilik!)} tarihine kadar'}',
                    ),
                  ),
                  IconButton(
                    tooltip: 'Kodu iptal et',
                    onPressed: () => _calistir(() => OkulService.davetIptal(d.kod), basari: 'Kod iptal edildi.'),
                    icon: Icon(Icons.close_rounded, color: c.textMuted),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

/// Rehber / branş seçimi; branşta ders de seçilir.
class _GorevSecici extends StatelessWidget {
  final bool rehber;
  final String brans;
  final void Function(bool rehber, String brans) degisti;

  const _GorevSecici({required this.rehber, required this.brans, required this.degisti});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Görevi', style: TextStyle(fontWeight: FontWeight.w700, color: c.textPrimary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            HapSecim(etiket: 'Rehber öğretmen', secili: rehber, onTap: () => degisti(true, brans)),
            HapSecim(etiket: 'Branş öğretmeni', secili: !rehber, onTap: () => degisti(false, brans)),
          ],
        ),
        if (!rehber) ...[
          const SizedBox(height: 14),
          Text('Dersi', style: TextStyle(fontWeight: FontWeight.w700, color: c.textPrimary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in okulBranslari) HapSecim(etiket: d, secili: brans == d, onTap: () => degisti(false, d)),
            ],
          ),
        ],
      ],
    );
  }
}

// ─── Rapor ───────────────────────────────────────────────────────────

class _Rapor extends StatelessWidget {
  const _Rapor();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return VeriGovdesi<OkulOzeti>(
      yukle: OkulService.okulOzeti,
      insa: (context, o, yenile) {
        final metin = okulRaporuMetni(o);
        return [
          const PanelBasligi('Rapor', alt: 'Veli toplantısı ya da kurul için paylaşılabilir özet'),
          YumusakKart(
            padding: const EdgeInsets.all(16),
            child: SelectableText(metin, style: TextStyle(fontSize: 13.5, color: c.textPrimary, height: 1.55)),
          ),
          const SizedBox(height: 14),
          AnaDugme(
            etiket: 'Raporu kopyala',
            ikon: Icons.copy_rounded,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: metin));
              if (context.mounted) okulBildir(context, 'Rapor kopyalandı. E-postaya ya da belgeye yapıştırabilirsin.');
            },
          ),
          const SizedBox(height: 10),
          Text('Rapor yalnızca toplamları içerir; öğrenci adı ve kişisel veri bulunmaz.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: c.textMuted)),
        ];
      },
    );
  }
}
