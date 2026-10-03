/// Gelişim Analizi — sürecin tablo ve grafiklerle takibi: çalışma süresi,
/// plan uyumu, ders dağılımı, net gelişimi, konu ilerlemesi, test doğruluğu,
/// enerji/odak/stres eğilimi, çalışma takvimi ve otomatik içgörüler.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

import '../../../core/algorithms/analiz_motoru.dart';
import '../../../core/utils/tarih.dart';
import '../../providers/analiz_provider.dart';
import '../../providers/mufredat_provider.dart';
import '../../widgets/grafikler.dart';

class AnalizScreen extends ConsumerWidget {
  const AnalizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donem = ref.watch(analizDonemiProvider);
    final analiz = ref.watch(donemAnaliziProvider(donem));
    final yukleniyor = ref.watch(analizGirdisiProvider).isLoading && analiz == null;
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: c.textPrimary),
        title: Text('Gelişim Analizi', style: context.baslik(20)),
        actions: [
          IconButton(
            tooltip: 'Ders programım',
            onPressed: () => context.push('/program'),
            icon: Icon(Icons.calendar_month_rounded, color: c.textSecondary),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(analizGirdisiProvider.future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 7, label: Text('7 gün')),
                  ButtonSegment(value: 30, label: Text('30 gün')),
                  ButtonSegment(value: 90, label: Text('3 ay')),
                ],
                selected: {donem},
                showSelectedIcon: false,
                onSelectionChanged: (s) => ref.read(analizDonemiProvider.notifier).state = s.first,
              ),
              const SizedBox(height: 16),
              if (yukleniyor)
                const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()))
              else if (analiz == null)
                const BosGrafikMesaji(metin: 'Analizleri görmek için önce profilini (hedef alan ve günlük süre) tamamla.')
              else
                ..._icerik(context, analiz, ref.watch(serbestModProvider)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _icerik(BuildContext context, DonemAnalizi a, bool serbest) {
    final c = context.colors;
    const bosluk = SizedBox(height: 14);
    final degisim = a.calismaDegisimYuzde;
    final tytDegisim = a.tyt.degisim;

    String isaretli(double v, {int basamak = 1}) => '${v >= 0 ? '+' : ''}${v.toStringAsFixed(basamak)}';

    return [
      _KpiIzgarasi(kutular: [
        KpiKutusu(
          ikon: Icons.timer_outlined,
          deger: sureMetni(a.toplamDk),
          etiket: 'Toplam çalışma',
          alt: degisim == null ? 'önceki dönem: —' : '${isaretli(degisim, basamak: 0)}% önceki döneme göre',
          altRenk: degisim == null ? null : (degisim >= 0 ? c.success : c.danger),
        ),
        KpiKutusu(
          ikon: Icons.today_rounded,
          deger: sureMetni(a.gunlukOrtalamaDk.round()),
          etiket: 'Günlük ortalama',
          alt: 'hedef ${sureMetni(a.hedefDk)}',
          renk: c.info,
        ),
        KpiKutusu(
          ikon: Icons.local_fire_department_rounded,
          deger: '${a.seri} gün',
          etiket: 'Çalışma serisi',
          alt: 'en uzun ${a.enUzunSeri} gün',
          renk: c.warning,
        ),
        KpiKutusu(
          ikon: Icons.task_alt_rounded,
          deger: a.planUyumu == null ? '—' : '%${(a.planUyumu! * 100).round()}',
          etiket: 'Plan uyumu',
          alt: a.planUyumu == null
              ? 'plan verisi yok'
              : '${a.tamamlananBlok.fold<int>(0, (x, y) => x + y)}/${a.planlananBlok.fold<int>(0, (x, y) => x + y)} blok',
          renk: c.success,
        ),
        KpiKutusu(
          ikon: Icons.show_chart_rounded,
          deger: a.tyt.son == null ? '—' : a.tyt.son!.toStringAsFixed(1),
          etiket: serbest ? 'Son sınav puanı' : 'Son TYT neti',
          alt: tytDegisim == null ? '${a.tyt.noktalar.length} ${serbest ? 'sınav' : 'deneme'}' : '${isaretli(tytDegisim)} önceki ${serbest ? 'sınava' : 'denemeye'} göre',
          altRenk: tytDegisim == null ? null : (tytDegisim >= 0 ? c.success : c.danger),
          renk: c.accent,
        ),
        KpiKutusu(
          ikon: Icons.checklist_rounded,
          deger: '%${(a.konuOrani * 100).round()}',
          etiket: 'Konu tamamlama',
          alt: '${a.tamamlananKonu}/${a.toplamKonu} · ${a.zayifKonu} zayıf',
          renk: c.primary,
        ),
      ]),
      bosluk,
      if (a.icgoruler.isNotEmpty) ...[
        GrafikKarti(
          baslik: 'Koçundan notlar',
          aciklama: 'Verilerine göre otomatik yorumlar',
          child: Column(children: [for (final i in a.icgoruler.take(6)) IcgoruSatiri(icgoru: i)]),
        ),
        bosluk,
      ],
      GrafikKarti(
        baslik: 'Çalışma süresi',
        aciklama: a.gunSayisi > 35
            ? 'Haftalık toplamlar · hedef çizgisi haftalık hedefin'
            : '${a.aktifGun}/${a.gunSayisi} gün çalıştın · ${a.hedefeUlasilanGun} gün hedefe ulaştın',
        child: CalismaCubukGrafigi(gunler: a.gunler, dakikalar: a.gunlukDk, hedefDk: a.hedefDk),
      ),
      bosluk,
      GrafikKarti(
        baslik: 'Plan uyumu',
        aciklama: 'Ders programındaki blokların ne kadarını tamamladın',
        sagUst: TextButton(onPressed: () => context.push('/program'), child: const Text('Programım')),
        child: a.planUyumu == null
            ? const BosGrafikMesaji(metin: 'Programım ekranında ders programını oluştur; blokları tamamladıkça uyumun burada çizilir.')
            : PlanUyumGrafigi(gunler: a.gunler, planlanan: a.planlananDk, tamamlanan: a.tamamlananDk),
      ),
      bosluk,
      GrafikKarti(
        baslik: 'Derslere göre dağılım',
        aciklama: 'Odak oturumlarında seçtiğin derslere göre',
        child: DersDagilimGrafigi(dagilim: a.dersDagilimi),
      ),
      bosluk,
      GrafikKarti(
        baslik: serbest ? 'Sınav puanı gelişimi' : 'Net gelişimi',
        aciklama: a.tyt.noktalar.length >= 3
            ? '${serbest ? 'Eğilim: sınav' : 'TYT eğilimi: deneme'} başına ${a.tyt.egim >= 0 ? '+' : ''}${a.tyt.egim.toStringAsFixed(1)} ${serbest ? 'puan' : 'net'}'
            : (serbest ? 'Tüm sınavların (derslerin ortalama puanı)' : 'Tüm denemelerin (toplam net)'),
        sagUst: TextButton(onPressed: () => context.push('/netler'), child: Text(serbest ? 'Sonuçlar' : 'Netler')),
        child: NetGelisimGrafigi(tyt: a.tyt, ayt: a.ayt, serbest: serbest),
      ),
      bosluk,
      GrafikKarti(
        baslik: serbest ? 'Ders bazında sonuç tablosu' : 'Ders bazında net tablosu',
        aciklama: 'Değişim: son 3 denemenin ortalaması − önceki 3 denemenin ortalaması',
        child: DersNetTablosu(satirlar: a.dersNetTablosu),
      ),
      bosluk,
      GrafikKarti(
        baslik: 'Konu ilerlemesi',
        aciklama: '${a.tamamlananKonu}/${a.toplamKonu} konu tamamlandı',
        sagUst: TextButton(onPressed: () => context.push('/konular'), child: const Text('Konular')),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (a.konuTamamlananSerisi.whereType<int>().length >= 2) ...[
              Text('Tamamlanan konu sayısı', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.textMuted)),
              const SizedBox(height: 6),
              TekCizgiGrafigi(gunler: a.gunler, degerler: a.konuTamamlananSerisi, birim: ' konu'),
              const SizedBox(height: 14),
            ],
            KonuIlerlemeCubuklari(dersler: a.konuDurumu),
          ],
        ),
      ),
      bosluk,
      if (a.testOzeti.isNotEmpty) ...[
        GrafikKarti(
          baslik: 'Test performansı',
          aciklama: 'Uygulama içi testlerde ders bazında doğru oranı',
          child: TestDogrulukCubuklari(dersler: a.testOzeti),
        ),
        bosluk,
      ],
      GrafikKarti(
        baslik: 'Enerji, odak ve stres',
        aciklama: 'Günlük check-in kayıtların (1–5)',
        child: CheckinGrafigi(gunler: a.gunler, seri: a.checkinSerisi),
      ),
      bosluk,
      GrafikKarti(
        baslik: 'Çalışma takvimi',
        aciklama: 'Son 12 hafta · koyu kareler hedefe ulaştığın günler',
        child: CalismaIsiHaritasi(haftalar: a.isiHaritasi, hedefDk: a.hedefDk),
      ),
    ];
  }
}

class _KpiIzgarasi extends StatelessWidget {
  final List<Widget> kutular;
  const _KpiIzgarasi({required this.kutular});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, k) {
      final sutun = k.maxWidth >= 520 ? 3 : 2;
      const aralik = 10.0;
      final genislik = (k.maxWidth - aralik * (sutun - 1)) / sutun;
      return Wrap(
        spacing: aralik,
        runSpacing: aralik,
        children: [for (final w in kutular) SizedBox(width: genislik, child: w)],
      );
    });
  }
}
