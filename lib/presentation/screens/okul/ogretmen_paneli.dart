import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

import '../../../core/algorithms/okul_hesaplari.dart';
import '../../../core/services/okul_service.dart';
import '../../../core/utils/tarih.dart';
import '../../../data/models/okul_modelleri.dart';
import '../../widgets/ui_kit.dart';
import 'okul_ortak.dart';
import 'rol_kabugu.dart';

/// Öğretmen paneli: Sınıflarım, Uyarılar, Öneriler, Hesap.
class OgretmenPaneli extends StatelessWidget {
  const OgretmenPaneli({super.key});

  @override
  Widget build(BuildContext context) {
    return RolKabugu(
      sekmeler: [
        PanelSekmesi(
          etiket: 'Sınıflarım',
          ikon: Icons.class_outlined,
          seciliIkon: Icons.class_rounded,
          insa: (_) => const _Siniflarim(),
        ),
        PanelSekmesi(
          etiket: 'Uyarılar',
          ikon: Icons.notification_important_outlined,
          seciliIkon: Icons.notification_important_rounded,
          insa: (_) => const _Uyarilar(),
        ),
        PanelSekmesi(
          etiket: 'Öneriler',
          ikon: Icons.assignment_outlined,
          seciliIkon: Icons.assignment_rounded,
          insa: (_) => const _Oneriler(),
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

// ─── Sınıflarım ──────────────────────────────────────────────────────

class _Siniflarim extends StatelessWidget {
  const _Siniflarim();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return VeriGovdesi<OgretmenSiniflari>(
      yukle: OkulService.siniflarim,
      insa: (context, veri, yenile) => [
        PanelBasligi(
          'Sınıflarım',
          alt: [veri.okul, veri.rehber ? 'Rehber öğretmen' : '${veri.brans ?? 'Branş'} öğretmeni'].join('  ·  '),
        ),
        if (veri.siniflar.isEmpty)
          const BosDurum(
            ikon: Icons.class_outlined,
            baslik: 'Henüz bir şubeye atanmadın',
            aciklama: 'Okul müdürü seni şubelere atadığında sınıfların burada görünür. Atamadan sonra sayfayı aşağı çekerek yenile.',
          )
        else ...[
          if (!veri.rehber)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('Süreler yalnızca ${veri.brans ?? 'kendi dersinin'} çalışmalarını gösterir.',
                  style: TextStyle(fontSize: 13, color: c.textSecondary)),
            ),
          for (final s in veri.siniflar)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SinifKarti(s: s, rehber: veri.rehber),
            ),
          const SizedBox(height: 6),
          const BilgiKarti(
            ikon: Icons.visibility_outlined,
            baslik: 'Burada ne görüyorsun?',
            maddeler: [
              'Çalışma süresi, öğrencinin uygulamadaki odak sayacıyla ölçülür.',
              'Program uyumu ve konu ilerlemesi öğrencinin kendi kayıtlarından gelir.',
              'Öğrencinin ruh hâli kayıtları, asistan sohbetleri ve kişisel notları hiçbir panelde görünmez.',
            ],
          ),
        ],
      ],
    );
  }
}

class _SinifKarti extends StatelessWidget {
  final SinifKarti s;
  final bool rehber;

  const _SinifKarti({required this.s, required this.rehber});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget olcu(String deger, String etiket, {Color? renk}) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(deger, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: renk ?? c.textPrimary)),
              Text(etiket, style: TextStyle(fontSize: 11.5, color: c.textMuted)),
            ],
          ),
        );
    return Semantics(
      button: true,
      label: '${s.sube.etiket} şubesi, ${s.ogrenciSayisi} öğrenci, ${s.riskSayisi} uyarı',
      child: YumusakKart(
        onTap: () => context.push('/okul/sube/${s.sube.id}', extra: s.sube.etiket),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(12)),
                  child: Text(s.sube.etiket, style: context.baslik(19, color: c.gece ? c.accent : c.primary)),
                ),
                const Spacer(),
                if (rehber && s.riskSayisi > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(color: c.danger.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(10)),
                    child: Text('${s.riskSayisi} uyarı',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c.textPrimary)),
                  ),
                Icon(Icons.chevron_right_rounded, color: c.textMuted),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                olcu('${s.ogrenciSayisi}', 'öğrenci'),
                olcu('${s.aktif7g}', 'bu hafta çalışan'),
                olcu(sureMetni(s.ortDk7g), 'kişi başı ortalama'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Uyarılar ────────────────────────────────────────────────────────

class _Uyarilar extends StatelessWidget {
  const _Uyarilar();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return VeriGovdesi<(OgretmenSiniflari, List<OgrenciSatiri>)>(
      yukle: () async {
        final siniflar = await OkulService.siniflarim();
        return (siniflar, siniflar.rehber ? await OkulService.uyarilar() : const <OgrenciSatiri>[]);
      },
      insa: (context, veri, yenile) {
        final (siniflar, uyarilar) = veri;
        return [
          PanelBasligi('Uyarılar', alt: uyarilar.isEmpty ? null : '${uyarilar.length} öğrenci ilgini bekliyor'),
          if (!siniflar.rehber)
            const BosDurum(
              ikon: Icons.shield_outlined,
              baslik: 'Uyarılar rehber öğretmene gösterilir',
              aciklama:
                  'Bir öğrencinin genel çalışma düzeni tüm derslerini kapsadığı için bu liste yalnızca şubenin rehber öğretmenine açıktır. Kendi dersinin verisini Sınıflarım sekmesinde görebilirsin.',
            )
          else if (uyarilar.isEmpty)
            const BosDurum(
              ikon: Icons.verified_outlined,
              baslik: 'Şu an uyarı yok',
              aciklama: 'İki haftadır hiç çalışmayan ya da çalışma süresi iki hafta üst üste düşen öğrenci olduğunda burada görürsün.',
            )
          else
            for (final o in uyarilar)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: YumusakKart(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  onTap: () => context.push('/okul/ogrenci/${o.id}', extra: o.ad),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(o.ad,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: c.textPrimary)),
                                ),
                                if (o.sube != null) ...[
                                  const SizedBox(width: 8),
                                  Text(o.sube!, style: TextStyle(fontSize: 12.5, color: c.textMuted, fontWeight: FontWeight.w700)),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            RiskRozeti(o.risk),
                            const SizedBox(height: 6),
                            Text(riskAciklamasi(o), style: TextStyle(fontSize: 13, color: c.textSecondary, height: 1.35)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: c.textMuted),
                    ],
                  ),
                ),
              ),
        ];
      },
    );
  }
}

// ─── Öneriler ────────────────────────────────────────────────────────

class _Oneriler extends StatefulWidget {
  const _Oneriler();

  @override
  State<_Oneriler> createState() => _OnerilerState();
}

class _OnerilerState extends State<_Oneriler> {
  final _govde = GlobalKey<VeriGovdesiState<(OgretmenSiniflari, List<Oneri>)>>();

  Future<void> _yeni(OgretmenSiniflari siniflar) async {
    final gonderildi = await okulSayfasiGoster<bool>(
      context,
      baslik: 'Şubeye öneri gönder',
      insa: (_) => _OneriFormu(siniflar: siniflar),
    );
    if (gonderildi == true && mounted) {
      okulBildir(context, 'Öneri gönderildi. Öğrenciler ana sayfalarında görecek.');
      await _govde.currentState?.yenile();
    }
  }

  Future<void> _sil(Oneri o) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Öneriyi geri çek'),
        content: Text('“${o.konu}” önerisi öğrencilerin listesinden kaldırılacak.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Geri çek')),
        ],
      ),
    );
    if (onay != true) return;
    try {
      await OkulService.oneriSil(o.id);
      await _govde.currentState?.yenile();
    } on OkulHatasi catch (e) {
      if (mounted) okulBildir(context, e.mesaj, hata: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return VeriGovdesi<(OgretmenSiniflari, List<Oneri>)>(
      key: _govde,
      yukle: () async => (await OkulService.siniflarim(), await OkulService.ogretmenOnerileri()),
      insa: (context, veri, yenile) {
        final (siniflar, oneriler) = veri;
        return [
          const PanelBasligi('Öneriler', alt: 'Şubene çalışma önerisi gönder; zorunlu ödev değildir'),
          AnaDugme(
            etiket: 'Yeni öneri',
            ikon: Icons.add_rounded,
            onPressed: siniflar.siniflar.isEmpty ? null : () => _yeni(siniflar),
          ),
          if (siniflar.siniflar.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Öneri gönderebilmek için önce bir şubeye atanmalısın.',
                  style: TextStyle(fontSize: 12.5, color: c.textMuted)),
            ),
          const SizedBox(height: 16),
          if (oneriler.isEmpty)
            const BosDurum(
              ikon: Icons.assignment_outlined,
              baslik: 'Henüz öneri göndermedin',
              aciklama: 'Bir konu tekrarı ya da çalışma önerdiğinde öğrenci onu tek dokunuşla kendi programına ekler; kaçının eklediğini burada görürsün.',
            )
          else
            for (final o in oneriler)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: YumusakKart(
                  padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              [o.sube ?? '', o.ders, '${o.sureDk} dk', if (o.olusturma != null) kisaTarih(o.olusturma!)]
                                  .where((s) => s.isNotEmpty)
                                  .join('  ·  '),
                              style: TextStyle(fontSize: 12, color: c.textMuted, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 3),
                            Text(o.konu, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: c.textPrimary)),
                            if (o.not != null && o.not!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(o.not!, style: TextStyle(fontSize: 13, color: c.textSecondary, height: 1.35)),
                            ],
                            const SizedBox(height: 8),
                            OranSatiri(
                              etiket: 'Programına ekleyen',
                              deger: '${o.eklendi} / ${o.ogrenciSayisi}',
                              oran: o.ogrenciSayisi == 0 ? 0 : o.eklendi / o.ogrenciSayisi,
                              renk: c.success,
                              alt: '${o.tamamlandi} öğrenci tamamladı',
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Öneriyi geri çek',
                        onPressed: () => _sil(o),
                        icon: Icon(Icons.delete_outline_rounded, size: 20, color: c.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
        ];
      },
    );
  }
}

class _OneriFormu extends StatefulWidget {
  final OgretmenSiniflari siniflar;
  const _OneriFormu({required this.siniflar});

  @override
  State<_OneriFormu> createState() => _OneriFormuState();
}

class _OneriFormuState extends State<_OneriFormu> {
  static const List<int> _sureler = [20, 30, 45, 60, 90];

  final _konu = TextEditingController();
  final _not = TextEditingController();
  late String _subeId = widget.siniflar.siniflar.first.sube.id;
  late String _ders = widget.siniflar.brans ?? okulBranslari.first;
  int _sure = 30;
  bool _islemde = false;

  @override
  void dispose() {
    _konu.dispose();
    _not.dispose();
    super.dispose();
  }

  Future<void> _gonder() async {
    if (_konu.text.trim().length < 2) {
      okulBildir(context, 'Konuyu yaz.', hata: true);
      return;
    }
    setState(() => _islemde = true);
    try {
      await OkulService.oneriOlustur(subeId: _subeId, ders: _ders, konu: _konu.text, not: _not.text, sureDk: _sure);
      if (mounted) Navigator.pop(context, true);
    } on OkulHatasi catch (e) {
      if (!mounted) return;
      setState(() => _islemde = false);
      okulBildir(context, e.mesaj, hata: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget baslik(String s) => Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Text(s, style: TextStyle(fontWeight: FontWeight.w700, color: c.textPrimary)),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Şube', style: TextStyle(fontWeight: FontWeight.w700, color: c.textPrimary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in widget.siniflar.siniflar)
              HapSecim(etiket: s.sube.etiket, secili: _subeId == s.sube.id, onTap: () => setState(() => _subeId = s.sube.id)),
          ],
        ),
        if (widget.siniflar.rehber) ...[
          baslik('Ders'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in okulBranslari) HapSecim(etiket: d, secili: _ders == d, onTap: () => setState(() => _ders = d)),
            ],
          ),
        ],
        baslik('Konu'),
        TextField(
          controller: _konu,
          maxLength: 120,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(color: c.textPrimary),
          decoration: okulGirdisi(context, ipucu: 'ör. Türev: zincir kuralı tekrarı').copyWith(counterText: ''),
        ),
        baslik('Önerilen süre'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in _sureler) HapSecim(etiket: '$s dk', secili: _sure == s, onTap: () => setState(() => _sure = s)),
          ],
        ),
        baslik('Not (isteğe bağlı)'),
        TextField(
          controller: _not,
          maxLength: 400,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(color: c.textPrimary),
          decoration: okulGirdisi(context, ipucu: 'ör. Çarşamba dersinden önce bakarsanız iyi olur.').copyWith(counterText: ''),
        ),
        const SizedBox(height: 16),
        AnaDugme(etiket: 'Gönder', onPressed: _gonder, yukleniyor: _islemde),
      ],
    );
  }
}
