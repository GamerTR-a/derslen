/// Bir öğrencinin çalışma özeti: öğretmenin öğrenci detayında ve veli
/// panelinde aynı bölümler kullanılır.
library;

import 'package:flutter/material.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

import '../../../core/algorithms/okul_hesaplari.dart';
import '../../../core/utils/tarih.dart';
import '../../../data/models/okul_modelleri.dart';
import '../../widgets/grafikler.dart';
import 'okul_ortak.dart';

/// Bu haftanın göstergeleri ve günlük çubukları.
List<Widget> haftaBolumu(BuildContext context, OgrenciOzeti o) {
  final c = context.colors;
  final bu = haftaOzeti(o.gunler);
  final gecen = haftaOzeti(o.gunler, geri: 1);
  final fark = bu.toplamDk - gecen.toplamDk;
  return [
    IkiliSatir(
      KpiKutusu(
        ikon: Icons.timer_outlined,
        deger: sureMetni(bu.toplamDk),
        etiket: o.brans == null ? 'Son 7 gün' : 'Son 7 gün · ${o.brans}',
        alt: fark == 0 ? 'geçen haftayla aynı' : '${fark > 0 ? '+' : '-'}${sureMetni(fark.abs())}',
        altRenk: fark < 0 ? c.danger : (fark > 0 ? c.success : null),
      ),
      KpiKutusu(
        ikon: Icons.event_available_outlined,
        deger: '${bu.aktifGun} / 7',
        etiket: 'Çalışılan gün',
        alt: 'önceki hafta ${gecen.aktifGun}',
        renk: c.info,
      ),
    ),
    const SizedBox(height: 10),
    IkiliSatir(
      KpiKutusu(
        ikon: Icons.task_alt_rounded,
        deger: bu.planUyumu == null ? '—' : '%${bu.planUyumu}',
        etiket: 'Program uyumu',
        alt: bu.planUyumu == null ? 'program verisi yok' : '${bu.planTamam} / ${bu.planBlok} blok',
        renk: c.success,
      ),
      KpiKutusu(
        ikon: Icons.speed_rounded,
        deger: sureMetni(bu.gunlukOrtalama),
        etiket: 'Günlük ortalama',
        alt: 'önceki hafta ${sureMetni(gecen.gunlukOrtalama)}',
        renk: c.warning,
      ),
    ),
    const SizedBox(height: 14),
    GrafikKarti(
      baslik: 'Son 7 gün',
      aciklama: 'Uygulamadaki odak sayacıyla ölçülen çalışma süresi',
      child: bu.toplamDk == 0
          ? const BosGrafikMesaji(metin: 'Bu hafta henüz çalışma kaydı yok.')
          : CalismaCubukGrafigi(
              gunler: [for (final g in bu.gunler) g.gun],
              dakikalar: [for (final g in bu.gunler) gunSuresi(g)],
              hedefDk: 0,
              yukseklik: 150,
            ),
    ),
  ];
}

/// Son dört hafta: günlük süre, ders dağılımı, denemeler ve testler.
List<Widget> gecmisBolumu(BuildContext context, OgrenciOzeti o) {
  final c = context.colors;
  final toplam = o.gunler.fold<int>(0, (t, g) => t + gunSuresi(g));
  return [
    GrafikKarti(
      baslik: 'Son 4 hafta',
      aciklama: 'Toplam ${sureMetni(toplam)}',
      child: toplam == 0
          ? const BosGrafikMesaji(metin: 'Son dört haftada çalışma kaydı yok.')
          : CalismaCubukGrafigi(
              gunler: [for (final g in o.gunler) g.gun],
              dakikalar: [for (final g in o.gunler) gunSuresi(g)],
              hedefDk: 0,
            ),
    ),
    if (o.dersDk.isNotEmpty) ...[
      const SizedBox(height: 14),
      GrafikKarti(
        baslik: 'Derslere dağılım',
        aciklama: 'Son 4 haftada hangi derse ne kadar çalışıldı',
        child: DersDagilimGrafigi(dagilim: o.dersDk),
      ),
    ],
    if (o.konuTamam != null) ...[
      const SizedBox(height: 14),
      GrafikKarti(
        baslik: 'Konu ilerlemesi',
        child: Row(
          children: [
            Expanded(child: _sayi(context, '${o.konuTamam}', 'tamamlanan konu', c.success)),
            Expanded(child: _sayi(context, '${o.konuZayif ?? 0}', 'zayıf işaretli konu', c.warning)),
          ],
        ),
      ),
    ],
    const SizedBox(height: 14),
    GrafikKarti(
      baslik: 'Denemeler',
      aciklama: 'Öğrencinin uygulamaya girdiği son deneme sonuçları',
      child: o.netler.isEmpty
          ? const BosGrafikMesaji(metin: 'Henüz deneme sonucu girilmemiş.')
          : Column(
              children: [
                for (final n in o.netler)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(8)),
                          child: Text(n.alan,
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: c.textPrimary)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.deneme,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontWeight: FontWeight.w700, color: c.textPrimary)),
                              if (n.tarih != null)
                                Text(kisaTarih(n.tarih!), style: TextStyle(fontSize: 12, color: c.textMuted)),
                            ],
                          ),
                        ),
                        Text('${netMetni(n.net)} net',
                            style: TextStyle(fontWeight: FontWeight.w800, color: c.textPrimary)),
                      ],
                    ),
                  ),
              ],
            ),
    ),
    if (o.testler.isNotEmpty) ...[
      const SizedBox(height: 14),
      GrafikKarti(
        baslik: 'Uygulama içi testler',
        aciklama: 'Son 30 günde ders bazında doğru oranı',
        child: Column(
          children: [
            for (final t in o.testler)
              OranSatiri(
                etiket: t.ders,
                deger: '%${t.basari}',
                oran: t.basari / 100,
                renk: t.basari >= 70 ? c.success : (t.basari >= 45 ? c.warning : c.danger),
                alt: '${t.toplam} soru: ${t.dogru} doğru, ${t.yanlis} yanlış, ${t.bos} boş',
              ),
          ],
        ),
      ),
    ],
  ];
}

Widget _sayi(BuildContext context, String deger, String etiket, Color renk) {
  return Column(
    children: [
      Text(deger, style: context.baslik(26, color: renk)),
      const SizedBox(height: 2),
      Text(etiket, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: context.colors.textMuted)),
    ],
  );
}
