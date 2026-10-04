/// Gelişim Analizi — üç sekmede sade bir düzen:
///  * Özet: dört temel gösterge, koçun notları ve çalışma süresi grafiği.
///  * Çalışma: plan uyumu, derslere dağılım, çalışma takvimi, enerji/odak/stres.
///  * Başarı: konu ilerlemesi, test ve deneme sonuçları, net gelişimi.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

import '../../../core/algorithms/analiz_motoru.dart';
import '../../../core/utils/tarih.dart';
import '../../providers/analiz_provider.dart';
import '../../providers/mufredat_provider.dart';
import '../../providers/test_provider.dart';
import '../../widgets/grafikler.dart';

class AnalizScreen extends ConsumerWidget {
  const AnalizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donem = ref.watch(analizDonemiProvider);
    final analiz = ref.watch(donemAnaliziProvider(donem));
    final yukleniyor = ref.watch(analizGirdisiProvider).isLoading && analiz == null;
    final serbest = ref.watch(serbestModProvider);
    final sinif = ref.watch(sinifProvider);
    final denemeler = ref.watch(denemeGecmisiProvider).valueOrNull ?? const <DenemeKaydi>[];
    final c = context.colors;

    Widget sekme(List<Widget> Function(DonemAnalizi a) icerik) {
      return RefreshIndicator(
        onRefresh: () => ref.refresh(analizGirdisiProvider.future),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            if (yukleniyor)
              const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()))
            else if (analiz == null)
              const BosGrafikMesaji(metin: 'Analizleri görmek için önce profilini (hedef alan ve günlük süre) tamamla.')
            else
              ...icerik(analiz),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
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
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(104),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                  child: SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 7, label: Text('7 gün')),
                        ButtonSegment(value: 30, label: Text('30 gün')),
                        ButtonSegment(value: 90, label: Text('3 ay')),
                      ],
                      selected: {donem},
                      showSelectedIcon: false,
                      onSelectionChanged: (s) => ref.read(analizDonemiProvider.notifier).state = s.first,
                    ),
                  ),
                ),
                const TabBar(
                  labelStyle: TextStyle(fontWeight: FontWeight.w800),
                  tabs: [Tab(text: 'Özet'), Tab(text: 'Çalışma'), Tab(text: 'Başarı')],
                ),
              ],
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: TabBarView(
            children: [
              sekme((a) => _ozet(context, a)),
              sekme((a) => _calisma(context, a)),
              sekme((a) => _basari(context, a, serbest: serbest, sinif: sinif, denemeler: denemeler)),
            ],
          ),
        ),
      ),
    );
  }

  static const _bosluk = SizedBox(height: 14);

  // ─── Özet ───────────────────────────────────────────────────────────

  List<Widget> _ozet(BuildContext context, DonemAnalizi a) {
    final c = context.colors;
    final degisim = a.calismaDegisimYuzde;
    final testSoru = a.testOzeti.fold<int>(0, (t, d) => t + d.soru);
    final testDogru = a.testOzeti.fold<int>(0, (t, d) => t + d.dogru);

    return [
      _KpiIzgarasi(kutular: [
        KpiKutusu(
          ikon: Icons.timer_outlined,
          deger: sureMetni(a.toplamDk),
          etiket: 'Toplam çalışma',
          alt: degisim == null ? 'günde ort. ${sureMetni(a.gunlukOrtalamaDk.round())}' : '${degisim >= 0 ? '+' : ''}${degisim.toStringAsFixed(0)}% önceki döneme göre',
          altRenk: degisim == null ? null : (degisim >= 0 ? c.success : c.danger),
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
          ikon: Icons.checklist_rounded,
          deger: '%${(a.konuOrani * 100).round()}',
          etiket: 'Konu tamamlama',
          alt: '${a.tamamlananKonu}/${a.toplamKonu} · ${a.zayifKonu} zayıf',
          renk: c.primary,
        ),
        KpiKutusu(
          ikon: Icons.quiz_outlined,
          deger: testSoru == 0 ? '—' : '%${(testDogru * 100 / testSoru).round()}',
          etiket: 'Test doğruluğu',
          alt: testSoru == 0 ? 'henüz test yok' : '$testSoru soru çözüldü',
          renk: c.accent,
        ),
      ]),
      _bosluk,
      Row(
        children: [
          Icon(Icons.local_fire_department_rounded, size: 18, color: c.warning),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${a.seri} günlük seri · en uzun ${a.enUzunSeri} gün · günlük hedef ${sureMetni(a.hedefDk)}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textSecondary),
            ),
          ),
        ],
      ),
      _bosluk,
      if (a.icgoruler.isNotEmpty) ...[
        GrafikKarti(
          baslik: 'Koçundan notlar',
          aciklama: 'Verilerine göre otomatik yorumlar',
          child: Column(children: [for (final i in a.icgoruler.take(4)) IcgoruSatiri(icgoru: i)]),
        ),
        _bosluk,
      ],
      GrafikKarti(
        baslik: 'Çalışma süresi',
        aciklama: a.gunSayisi > 35
            ? 'Haftalık toplamlar · hedef çizgisi haftalık hedefin'
            : '${a.aktifGun}/${a.gunSayisi} gün çalıştın · ${a.hedefeUlasilanGun} gün hedefe ulaştın',
        child: CalismaCubukGrafigi(gunler: a.gunler, dakikalar: a.gunlukDk, hedefDk: a.hedefDk),
      ),
    ];
  }

  // ─── Çalışma ────────────────────────────────────────────────────────

  List<Widget> _calisma(BuildContext context, DonemAnalizi a) {
    return [
      GrafikKarti(
        baslik: 'Plan uyumu',
        aciklama: 'Ders programındaki blokların ne kadarını tamamladın',
        sagUst: TextButton(onPressed: () => context.push('/program'), child: const Text('Programım')),
        child: a.planUyumu == null
            ? const BosGrafikMesaji(metin: 'Programım ekranında ders programını oluştur; blokları tamamladıkça uyumun burada çizilir.')
            : PlanUyumGrafigi(gunler: a.gunler, planlanan: a.planlananDk, tamamlanan: a.tamamlananDk),
      ),
      _bosluk,
      GrafikKarti(
        baslik: 'Derslere göre dağılım',
        aciklama: 'Odak seanslarında seçtiğin derslere göre',
        child: DersDagilimGrafigi(dagilim: a.dersDagilimi),
      ),
      _bosluk,
      GrafikKarti(
        baslik: 'Çalışma takvimi',
        aciklama: 'Son 12 hafta · koyu kareler hedefe ulaştığın günler',
        child: CalismaIsiHaritasi(haftalar: a.isiHaritasi, hedefDk: a.hedefDk),
      ),
      _bosluk,
      GrafikKarti(
        baslik: 'Enerji, odak ve stres',
        aciklama: 'Programım ekranında girdiğin günlük durum (1–5)',
        child: CheckinGrafigi(gunler: a.gunler, seri: a.checkinSerisi),
      ),
    ];
  }

  // ─── Başarı ─────────────────────────────────────────────────────────

  List<Widget> _basari(BuildContext context, DonemAnalizi a, {required bool serbest, required int? sinif, required List<DenemeKaydi> denemeler}) {
    final c = context.colors;
    final sonDenemeler = denemeler.reversed.take(5).toList();
    // Ara sınıflarda TYT/AYT net takibi yerine uygulama içi denemeler öne çıkar.
    final netVar = !a.tyt.bos || !a.ayt.bos;

    return [
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
      _bosluk,
      GrafikKarti(
        baslik: 'Test performansı',
        aciklama: 'Uygulama içi testlerde ders bazında doğru oranı',
        sagUst: TextButton(onPressed: () => context.push('/test-olustur'), child: const Text('Test çöz')),
        child: a.testOzeti.isEmpty
            ? const BosGrafikMesaji(metin: 'Bu dönemde test çözmedin. Konu testleri çözdükçe ders bazında doğruluk oranın burada görünür.')
            : TestDogrulukCubuklari(dersler: a.testOzeti),
      ),
      _bosluk,
      GrafikKarti(
        baslik: 'Uygulama içi denemeler',
        aciklama: sonDenemeler.isEmpty ? null : 'Son ${sonDenemeler.length} deneme · net = doğru − yanlış / 4',
        sagUst: TextButton(onPressed: () => context.push('/test-olustur?bolum=deneme'), child: const Text('Deneme çöz')),
        child: sonDenemeler.isEmpty
            ? BosGrafikMesaji(
                metin: sinif != null
                    ? '$sinif. sınıf genel denemesi ya da ders denemesi çözdüğünde sonuçların burada listelenir.'
                    : 'Deneme çözdüğünde sonuçların burada listelenir.',
              )
            : Column(
                children: [
                  for (final d in sonDenemeler)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d.baslik, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, color: c.textPrimary)),
                                Text(
                                  '${DateTime.tryParse(d.tarih) == null ? d.tarih : kisaTarih(DateTime.parse(d.tarih))} · ${d.dogru} D · ${d.yanlis} Y · ${d.bos} B',
                                  style: TextStyle(fontSize: 12, color: c.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Text('${d.net.toStringAsFixed(2)} net', style: TextStyle(fontWeight: FontWeight.w800, color: c.textPrimary)),
                          SizedBox(
                            width: 52,
                            child: Text('%${(d.basari * 100).round()}', textAlign: TextAlign.end, style: TextStyle(color: c.textMuted)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
      if (sinif == null || netVar) ...[
        _bosluk,
        GrafikKarti(
          baslik: serbest ? 'Sınav puanı gelişimi' : 'Net gelişimi',
          aciklama: a.tyt.noktalar.length >= 3
              ? '${serbest ? 'Eğilim: sınav' : 'TYT eğilimi: deneme'} başına ${a.tyt.egim >= 0 ? '+' : ''}${a.tyt.egim.toStringAsFixed(1)} ${serbest ? 'puan' : 'net'}'
              : (serbest ? 'Girdiğin sınav sonuçları (derslerin ortalama puanı)' : 'Girdiğin deneme sonuçları (toplam net)'),
          sagUst: TextButton(onPressed: () => context.push('/netler'), child: Text(serbest ? 'Sonuçlar' : 'Netler')),
          child: NetGelisimGrafigi(tyt: a.tyt, ayt: a.ayt, serbest: serbest),
        ),
        _bosluk,
        GrafikKarti(
          baslik: serbest ? 'Ders bazında sonuç tablosu' : 'Ders bazında net tablosu',
          aciklama: 'Değişim: son 3 denemenin ortalaması − önceki 3 denemenin ortalaması',
          child: DersNetTablosu(satirlar: a.dersNetTablosu),
        ),
      ],
    ];
  }
}

class _KpiIzgarasi extends StatelessWidget {
  final List<Widget> kutular;
  const _KpiIzgarasi({required this.kutular});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, k) {
      final sutun = k.maxWidth >= 520 ? 4 : 2;
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
