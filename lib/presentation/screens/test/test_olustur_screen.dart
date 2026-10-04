/// Test merkezi — üç bölüm:
///  * Konu testi: sınıf (9-11) ya da tüm havuz, ders ve konu seçilerek.
///  * Deneme: sınıfın tüm derslerinden ya da tek dersten süreli sınav.
///  * Yanlışlarım: daha önce yanlış yapılan soruların tekrarı.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

import '../../../core/constants/sinif_mufredati.dart';
import '../../../core/constants/soru_havuzu.dart';
import '../../../core/utils/tarih.dart';
import '../../providers/test_provider.dart';
import '../../widgets/grafikler.dart';
import '../../widgets/ui_kit.dart';

class TestOlusturScreen extends ConsumerStatefulWidget {
  /// Açılışta gösterilecek bölüm: 'konu', 'deneme' ya da 'tekrar'.
  final String? baslangicBolumu;

  const TestOlusturScreen({super.key, this.baslangicBolumu});

  @override
  ConsumerState<TestOlusturScreen> createState() => _TestOlusturScreenState();
}

class _TestOlusturScreenState extends ConsumerState<TestOlusturScreen> {
  late TestTuru _bolum = switch (widget.baslangicBolumu) {
    'deneme' => TestTuru.deneme,
    'tekrar' => TestTuru.tekrar,
    _ => TestTuru.konu,
  };
  String? _denemeDersi;

  void _basla() => context.push('/test-coz');

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final filtre = ref.watch(testFiltreProvider);
    final yanlisSayisi = yanlisSoruListesi(ref.watch(yanlisSorularProvider), sinif: filtre.sinif).length;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: c.textPrimary),
        title: Text('Test ve Deneme', style: context.baslik(20)),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            SegmentedButton<TestTuru>(
              segments: [
                const ButtonSegment(value: TestTuru.konu, label: Text('Konu testi')),
                const ButtonSegment(value: TestTuru.deneme, label: Text('Deneme')),
                ButtonSegment(value: TestTuru.tekrar, label: Text(yanlisSayisi > 0 ? 'Yanlışlarım ($yanlisSayisi)' : 'Yanlışlarım')),
              ],
              selected: {_bolum},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _bolum = s.first),
            ),
            const SizedBox(height: 14),
            _sinifSecici(filtre),
            const SizedBox(height: 14),
            ...switch (_bolum) {
              TestTuru.konu => _konuTesti(filtre),
              TestTuru.deneme => _deneme(filtre),
              TestTuru.tekrar => _tekrar(filtre, yanlisSayisi),
            },
          ],
        ),
      ),
    );
  }

  // ─── Sınıf seçimi ───────────────────────────────────────────────────

  Widget _sinifSecici(TestFiltreState filtre) {
    final n = ref.read(testFiltreProvider.notifier);
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final s in mufredatliSiniflar) ...[
            HapSecim(
              etiket: '$s. sınıf',
              secili: filtre.sinif == s,
              onTap: () {
                n.sinifDegistir(s);
                setState(() => _denemeDersi = null);
              },
            ),
            const SizedBox(width: 8),
          ],
          HapSecim(
            etiket: 'Tüm havuz (YKS)',
            secili: filtre.sinif == null,
            onTap: () {
              n.sinifDegistir(null);
              setState(() => _denemeDersi = null);
            },
          ),
        ],
      ),
    );
  }

  // ─── Konu testi ─────────────────────────────────────────────────────

  List<Widget> _konuTesti(TestFiltreState filtre) {
    final c = context.colors;
    final n = ref.read(testFiltreProvider.notifier);
    final sinif = filtre.sinif;

    final dersler = sinif != null ? sinifDersleri(sinif) : dersKonuAltBaslikHaritasi.keys.toList();
    // (değer, etiket, grup) — sınıf modunda değer konu kimliği, grup temadır.
    final konular = <(String, String, String?)>[
      if (filtre.ders != 'hepsi')
        if (sinif != null)
          for (final k in sinifKonulari(sinif))
            if (k.ders == filtre.ders) (k.id, k.baslik, k.tema)
        else
          for (final k in dersKonuAltBaslikHaritasi[filtre.ders]?.keys ?? const <String>[]) (k, k, null),
    ];
    final altBasliklar = sinif == null && filtre.ders != 'hepsi' && filtre.konu != 'hepsi'
        ? (dersKonuAltBaslikHaritasi[filtre.ders]?[filtre.konu] ?? const <String>[])
        : const <String>[];

    final hazir = filtre.hazirSorular.length;
    final sablonVar = filtre.sablonlar.isNotEmpty;
    final baslatilabilir = hazir > 0 || sablonVar;

    return [
      GrafikKarti(
        baslik: 'Konu testi',
        aciklama: sinif != null
            ? '$sinif. sınıf müfredatından ders ve konu seç; o konunun sorularıyla testin hazırlansın.'
            : 'Tüm soru havuzundan ders, konu ve alt başlık seç.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _acilir(
              etiket: 'Ders',
              deger: dersler.contains(filtre.ders) ? filtre.ders : 'hepsi',
              ogeler: [('hepsi', 'Tüm dersler (karışık)', null), for (final d in dersler) (d, d, null)],
              degisti: n.dersDegistir,
            ),
            const SizedBox(height: 12),
            _acilir(
              etiket: 'Konu',
              deger: konular.any((k) => k.$1 == filtre.konu) ? filtre.konu : 'hepsi',
              ogeler: [('hepsi', filtre.ders == 'hepsi' ? 'Önce ders seç' : 'Dersin tüm konuları', null), ...konular],
              degisti: filtre.ders == 'hepsi' ? null : n.konuDegistir,
            ),
            if (altBasliklar.length > 1) ...[
              const SizedBox(height: 12),
              _acilir(
                etiket: 'Alt başlık',
                deger: altBasliklar.contains(filtre.altBaslik) ? filtre.altBaslik : 'hepsi',
                ogeler: [('hepsi', 'Tüm alt başlıklar', null), for (final a in altBasliklar) (a, a, null)],
                degisti: n.altBaslikDegistir,
              ),
            ],
            const SizedBox(height: 16),
            Text('Zorluk', style: TextStyle(fontWeight: FontWeight.w800, color: c.textPrimary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (deger, etiket) in const [('hepsi', 'Karışık'), ('kolay', 'Kolay'), ('orta', 'Orta'), ('zor', 'Zor')])
                  HapSecim(etiket: etiket, secili: filtre.zorluk == deger, onTap: () => n.zorlukDegistir(deger)),
              ],
            ),
            const SizedBox(height: 16),
            Text('Soru sayısı', style: TextStyle(fontWeight: FontWeight.w800, color: c.textPrimary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final sayi in const [5, 10, 15, 20])
                  HapSecim(etiket: '$sayi', secili: filtre.soruSayisi == sayi, onTap: () => n.soruSayisiDegistir(sayi)),
              ],
            ),
            const SizedBox(height: 16),
            _bilgi(
              !baslatilabilir
                  ? 'Bu seçime uyan soru yok. Zorluğu “Karışık” yapmayı ya da konuyu genişletmeyi dene.'
                  : sablonVar
                      ? 'Bu seçimde $hazir hazır soru var; ayrıca her testte farklı sayılarla yeni sorular üretilir.'
                      : hazir < filtre.soruSayisi
                          ? 'Bu seçime uyan $hazir soru var; testin $hazir sorudan oluşacak.'
                          : 'Bu seçime uyan $hazir soru var.',
              uyari: !baslatilabilir,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: !baslatilabilir
                    ? null
                    : () {
                        ref.read(aktifTestProvider.notifier).testOlustur(filtre);
                        _basla();
                      },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Testi başlat'),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _acilir({
    required String etiket,
    required String deger,
    required List<(String, String, String?)> ogeler,
    required void Function(String)? degisti,
  }) {
    final c = context.colors;
    return DropdownButtonFormField<String>(
      // Seçenekler değişince (ör. ders değişti) alan yeniden kurulur.
      key: ValueKey('$etiket|$deger|${ogeler.length}|${ogeler.length > 1 ? ogeler[1].$1 : ''}'),
      initialValue: deger,
      isExpanded: true,
      dropdownColor: c.surface,
      style: TextStyle(color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: etiket,
        filled: true,
        fillColor: c.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.border)),
      ),
      items: [
        for (final (v, ad, grup) in ogeler)
          DropdownMenuItem(
            value: v,
            child: Text(grup == null ? ad : '$ad  ·  $grup', maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: degisti == null ? null : (v) => v == null ? null : degisti(v),
    );
  }

  Widget _bilgi(String metin, {bool uyari = false}) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(uyari ? Icons.warning_amber_rounded : Icons.info_outline_rounded, size: 18, color: uyari ? c.warning : c.textMuted),
        const SizedBox(width: 8),
        Expanded(child: Text(metin, style: TextStyle(fontSize: 12.5, color: c.textSecondary, height: 1.35))),
      ],
    );
  }

  // ─── Deneme ─────────────────────────────────────────────────────────

  List<Widget> _deneme(TestFiltreState filtre) {
    final c = context.colors;
    final sinif = filtre.sinif;
    final dersler = sinif != null ? sinifDersleri(sinif) : dersKonuAltBaslikHaritasi.keys.toList();
    final genelSoru = dersler.fold<int>(0, (t, d) => t + (denemeDersSoruSayisi[d] ?? 5));
    final kisaSoru = dersler.fold<int>(0, (t, d) => t + ((denemeDersSoruSayisi[d] ?? 5) / 2).round().clamp(2, 99));
    final gecmis = ref.watch(denemeGecmisiProvider).valueOrNull ?? const <DenemeKaydi>[];
    final ilgili = gecmis.where((d) => d.sinif == sinif).toList().reversed.take(6).toList();
    final n = ref.read(aktifTestProvider.notifier);
    final dersSecimi = _denemeDersi != null && dersler.contains(_denemeDersi) ? _denemeDersi : null;

    Widget secenek(IconData ikon, String baslik, String alt, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: YumusakKart(
            onTap: onTap,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: c.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                  child: Icon(ikon, color: c.gece ? c.accent : c.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(baslik, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: c.textPrimary)),
                      const SizedBox(height: 2),
                      Text(alt, style: TextStyle(fontSize: 12.5, color: c.textMuted)),
                    ],
                  ),
                ),
                Icon(Icons.play_circle_fill_rounded, color: c.primary, size: 30),
              ],
            ),
          ),
        );

    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _bilgi(
          sinif != null
              ? '$sinif. sınıf konularından, derslere dengeli dağıtılmış süreli deneme. Süre dolunca deneme kendiliğinden biter.'
              : 'Tüm havuzdan (YKS konuları), derslere dengeli dağıtılmış süreli deneme. Süre dolunca deneme kendiliğinden biter.',
        ),
      ),
      secenek(
        Icons.assignment_rounded,
        'Genel deneme',
        '$genelSoru soru · ${sureMetni(genelSoru * denemeSoruSuresi ~/ 60)} · ${dersler.length} ders',
        () {
          n.denemeOlustur(sinif: sinif);
          _basla();
        },
      ),
      secenek(
        Icons.bolt_rounded,
        'Kısa deneme',
        '$kisaSoru soru · ${sureMetni(kisaSoru * denemeSoruSuresi ~/ 60)} · ${dersler.length} ders',
        () {
          n.denemeOlustur(sinif: sinif, kisa: true);
          _basla();
        },
      ),
      GrafikKarti(
        baslik: 'Ders denemesi',
        aciklama: 'Tek dersten 20 soru · ${sureMetni(20 * denemeSoruSuresi ~/ 60)}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in dersler) HapSecim(etiket: dersKisaAdi(d), secili: dersSecimi == d, onTap: () => setState(() => _denemeDersi = d)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: dersSecimi == null
                    ? null
                    : () {
                        n.denemeOlustur(sinif: sinif, ders: dersSecimi);
                        _basla();
                      },
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(dersSecimi == null ? 'Bir ders seç' : '${dersKisaAdi(dersSecimi)} denemesini başlat'),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      GrafikKarti(
        baslik: 'Son denemelerin',
        aciklama: ilgili.isEmpty ? null : 'Net = doğru − yanlış / 4',
        child: ilgili.isEmpty
            ? const BosGrafikMesaji(metin: 'Henüz deneme çözmedin. İlk denemeni bitirdiğinde sonucun burada görünür.')
            : Column(
                children: [
                  for (final d in ilgili)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d.baslik, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, color: c.textPrimary)),
                                Text(
                                  '${_tarih(d.tarih)} · ${d.dogru} D · ${d.yanlis} Y · ${d.bos} B',
                                  style: TextStyle(fontSize: 12, color: c.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${d.net.toStringAsFixed(2)} net', style: TextStyle(fontWeight: FontWeight.w800, color: c.textPrimary)),
                              Text('%${(d.basari * 100).round()} başarı', style: TextStyle(fontSize: 12, color: c.textMuted)),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    ];
  }

  String _tarih(String anahtar) {
    final t = DateTime.tryParse(anahtar);
    return t == null ? anahtar : kisaTarih(t);
  }

  // ─── Yanlışlarım ────────────────────────────────────────────────────

  List<Widget> _tekrar(TestFiltreState filtre, int yanlisSayisi) {
    final c = context.colors;
    final sorular = yanlisSoruListesi(ref.watch(yanlisSorularProvider), sinif: filtre.sinif);
    final dersler = <String, int>{};
    for (final s in sorular) {
      dersler[s.ders] = (dersler[s.ders] ?? 0) + 1;
    }
    final adet = yanlisSayisi.clamp(0, 20);

    return [
      GrafikKarti(
        baslik: 'Yanlışlarımın tekrarı',
        aciklama: 'Testlerde yanlış yaptığın sorular burada birikir. Tekrar testinde doğru cevapladığın soru listeden çıkar; yine yanlış yaptığın soru bir sonraki tekrarda öne alınır.',
        child: yanlisSayisi == 0
            ? BosGrafikMesaji(
                metin: filtre.sinif != null
                    ? '${filtre.sinif}. sınıf konularında tekrar bekleyen yanlış sorun yok. Test çözdükçe yanlışların burada toplanır.'
                    : 'Tekrar bekleyen yanlış sorun yok. Test çözdükçe yanlışların burada toplanır.',
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$yanlisSayisi soru tekrar bekliyor', style: context.baslik(18)),
                  const SizedBox(height: 10),
                  for (final e in dersler.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(color: grafikDersRengi(context, e.key), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(dersKisaAdi(e.key), style: TextStyle(color: c.textPrimary))),
                          Text('${e.value} soru', style: TextStyle(fontWeight: FontWeight.w700, color: c.textSecondary)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        ref.read(aktifTestProvider.notifier).tekrarTestiOlustur(adet: adet, sinif: filtre.sinif);
                        _basla();
                      },
                      icon: const Icon(Icons.replay_rounded),
                      label: Text('$adet soruluk tekrar testini başlat'),
                    ),
                  ),
                ],
              ),
      ),
      const SizedBox(height: 10),
      _bilgi('Yanlış yaptığın sorular ayrıca “Yanlışlarım” kart destene eklenir; Kartlar sekmesinde aralıklı tekrarla da çalışabilirsin.'),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => context.go('/flashkart'),
          icon: const Icon(Icons.style_rounded, size: 18),
          label: const Text('Kartlar sekmesine git'),
        ),
      ),
    ];
  }
}
