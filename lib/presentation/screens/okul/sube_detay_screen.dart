import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

import '../../../core/algorithms/okul_hesaplari.dart';
import '../../../core/services/okul_service.dart';
import '../../../core/utils/tarih.dart';
import '../../../data/models/okul_modelleri.dart';
import '../../widgets/grafikler.dart';
import '../../widgets/ui_kit.dart';
import 'okul_ortak.dart';

/// Öğretmenin bir şubesi: öğrenci listesi (haftalık süre, program uyumu, son
/// etkinlik, uyarı) ve şubenin en çok zorlandığı konular.
class SubeDetayScreen extends StatelessWidget {
  final String subeId;
  final String? etiket;

  const SubeDetayScreen({super.key, required this.subeId, this.etiket});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          backgroundColor: c.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: c.textPrimary),
          title: Text(etiket == null ? 'Şube' : '$etiket şubesi',
              style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w800)),
          bottom: TabBar(
            labelColor: c.gece ? c.accent : c.primary,
            unselectedLabelColor: c.textMuted,
            indicatorColor: c.gece ? c.accent : c.primary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800),
            tabs: const [Tab(text: 'Öğrenciler'), Tab(text: 'Konular')],
          ),
        ),
        body: SafeArea(
          top: false,
          child: TabBarView(
            children: [
              _Ogrenciler(subeId: subeId),
              _Konular(subeId: subeId),
            ],
          ),
        ),
      ),
    );
  }
}

class _Ogrenciler extends StatefulWidget {
  final String subeId;
  const _Ogrenciler({required this.subeId});

  @override
  State<_Ogrenciler> createState() => _OgrencilerState();
}

class _OgrencilerState extends State<_Ogrenciler> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final c = context.colors;
    return VeriGovdesi<SubeOzeti>(
      yukle: () => OkulService.subeOzeti(widget.subeId),
      insa: (context, ozet, yenile) {
        final liste = ozet.ogrenciler;
        if (liste.isEmpty) {
          return const [
            BosDurum(
              ikon: Icons.group_add_outlined,
              baslik: 'Bu şubede henüz öğrenci yok',
              aciklama: 'Öğrenciler, müdürün paylaştığı şube koduyla DersNet\'te Profil › Okulum ve velim bölümünden katılır.',
            ),
          ];
        }
        final aktif = liste.where((o) => o.dk7g > 0).length;
        final ort = (liste.fold<int>(0, (t, o) => t + o.dk7g) / liste.length).round();
        final uyari = liste.where((o) => o.risk.uyari).length;
        return [
          if (ozet.brans != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('Süreler yalnızca ${ozet.brans} çalışmalarını gösterir.',
                  style: TextStyle(fontSize: 13, color: c.textSecondary)),
            ),
          Row(
            children: [
              Expanded(
                child: KpiKutusu(
                  ikon: Icons.groups_outlined,
                  deger: '$aktif / ${liste.length}',
                  etiket: 'Bu hafta çalışan',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: KpiKutusu(ikon: Icons.timer_outlined, deger: sureMetni(ort), etiket: 'Kişi başı ortalama', renk: c.info),
              ),
              if (ozet.rehber) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: KpiKutusu(
                    ikon: Icons.notification_important_outlined,
                    deger: '$uyari',
                    etiket: 'Uyarı',
                    renk: uyari > 0 ? c.danger : c.success,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          for (final o in liste)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OgrenciKarti(o: o, rehber: ozet.rehber),
            ),
        ];
      },
    );
  }
}

class _OgrenciKarti extends StatelessWidget {
  final OgrenciSatiri o;
  final bool rehber;

  const _OgrenciKarti({required this.o, required this.rehber});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fark = o.dk7g - o.dkOnceki7g;
    final farkRengi = fark < 0 ? c.danger : (fark > 0 ? c.success : c.textMuted);
    return Semantics(
      button: true,
      label: '${o.ad}, bu hafta ${sureMetni(o.dk7g)}, ${riskEtiketi(o.risk)}',
      child: YumusakKart(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        onTap: () => context.push('/okul/ogrenci/${o.id}', extra: o.ad),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: (o.risk.uyari ? riskRengi(context, o.risk) : c.primary).withValues(alpha: 0.14),
              child: Text(
                o.ad.characters.first.toUpperCase(),
                style: TextStyle(fontWeight: FontWeight.w800, color: c.textPrimary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(o.ad,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: c.textPrimary)),
                  const SizedBox(height: 3),
                  Text(
                    [
                      'Son etkinlik: ${sonAktifMetni(o.sonAktif)}',
                      if (o.planUyumu != null) 'Program %${o.planUyumu}',
                    ].join('  ·  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: c.textMuted),
                  ),
                  if (rehber && o.risk != RiskDurumu.yok) ...[
                    const SizedBox(height: 6),
                    RiskRozeti(o.risk),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(sureMetni(o.dk7g), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: c.textPrimary)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      fark < 0
                          ? Icons.arrow_downward_rounded
                          : (fark > 0 ? Icons.arrow_upward_rounded : Icons.remove_rounded),
                      size: 13,
                      color: farkRengi,
                    ),
                    Text(fark == 0 ? 'aynı' : sureMetni(fark.abs()),
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: farkRengi)),
                  ],
                ),
              ],
            ),
            Icon(Icons.chevron_right_rounded, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}

class _Konular extends StatefulWidget {
  final String subeId;
  const _Konular({required this.subeId});

  @override
  State<_Konular> createState() => _KonularState();
}

class _KonularState extends State<_Konular> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final c = context.colors;
    return VeriGovdesi<List<KonuSatiri>>(
      yukle: () => OkulService.subeKonuOzeti(widget.subeId),
      insa: (context, konular, yenile) {
        if (konular.isEmpty) {
          return const [
            BosDurum(
              ikon: Icons.quiz_outlined,
              baslik: 'Henüz yeterli test verisi yok',
              aciklama:
                  'Bir konu, son 30 günde en az 3 öğrenci o konudan uygulama içi test çözdüğünde burada görünür. Böylece tek bir öğrencinin sonucu sınıf verisi gibi okunmaz.',
            ),
          ];
        }
        return [
          Text('Son 30 gün · doğru oranı en düşük konular başta',
              style: TextStyle(fontSize: 13, color: c.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          GrafikKarti(
            baslik: 'Şubenin zorlandığı konular',
            aciklama: 'Uygulama içi konu testlerinden',
            child: Column(
              children: [
                for (final k in konular)
                  OranSatiri(
                    etiket: k.konu,
                    deger: '%${k.basari}',
                    oran: k.basari / 100,
                    renk: k.basari >= 70 ? c.success : (k.basari >= 45 ? c.warning : c.danger),
                    alt: '${k.ders} · ${k.ogrenci} öğrenci · ${k.toplam} soru',
                  ),
              ],
            ),
          ),
        ];
      },
    );
  }
}
