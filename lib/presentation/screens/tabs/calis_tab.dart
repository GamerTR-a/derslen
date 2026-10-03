import 'dart:io';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/ambiyans_service.dart';
import '../../../core/utils/tarih.dart';
import '../../providers/analiz_provider.dart';
import '../../providers/bahce_provider.dart';
import '../../widgets/grafikler.dart';
import '../../providers/mufredat_provider.dart';
import '../../providers/odak_provider.dart';
import '../../providers/ortam_provider.dart';
import '../../widgets/ui_kit.dart';
import '../../cizimler/cizim_widgetlari.dart';
import '../../cizimler/sahne_boyaci.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

const List<String> _dersler = [
  'Genel', 'Matematik', 'Geometri', 'Türkçe', 'Edebiyat', 'Fizik', 'Kimya',
  'Biyoloji', 'Tarih', 'Coğrafya', 'Felsefe', 'Din Kültürü', 'İngilizce',
];

class CalisTab extends ConsumerStatefulWidget {
  const CalisTab({super.key});

  @override
  ConsumerState<CalisTab> createState() => _CalisTabState();
}

class _CalisTabState extends ConsumerState<CalisTab> {
  late final ConfettiController _confetti = ConfettiController(duration: const Duration(seconds: 2));

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _istatistikYukle() async {
    ref.invalidate(analizGirdisiProvider);
    await ref.read(analizGirdisiProvider.future);
  }

  String _format(int saniye) {
    final s = saniye ~/ 3600;
    final d = (saniye % 3600) ~/ 60;
    final sn = saniye % 60;
    final dd = d.toString().padLeft(2, '0');
    final ss = sn.toString().padLeft(2, '0');
    return s > 0 ? '$s:$dd:$ss' : '$dd:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final odak = ref.watch(odakProvider);
    final ortam = ref.watch(ortamProvider);
    final bahce = ref.watch(bahceProvider);

    ref.listen<OdakState>(odakProvider, (onceki, simdi) {
      if (onceki?.sonYildiz == null && simdi.sonYildiz != null) {
        if ((simdi.sonYildiz ?? 0) > 0) _confetti.play();
        HapticFeedback.mediumImpact();
      }
    });

    return Scaffold(
      backgroundColor: context.colors.background,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _istatistikYukle,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _sahne(context, odak, ortam, bahce.yildiz)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                  sliver: SliverList.list(
                    children: [
                      _sureSecici(odak),
                      const SizedBox(height: 14),
                      _dersSecici(odak),
                      const SizedBox(height: 18),
                      _kontroller(odak),
                      const SizedBox(height: 16),
                      _canliPuan(odak),
                      const SizedBox(height: 24),
                      _istatistikler(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: IgnorePointer(
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                numberOfParticles: 30,
                gravity: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sahne(BuildContext context, OdakState odak, OrtamState ortam, int yildiz) {
    final foto = ortam.sahne == OdakSahne.ozel && ortam.ozelFotoYolu != null ? File(ortam.ozelFotoYolu!) : null;
    final ust = MediaQuery.of(context).padding.top;
    final yagmur = ortam.sahne == OdakSahne.orman || ortam.ses == AmbiyansSes.yagmur;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: Container(
        height: 360 + ust,
        color: ortam.sahne.renkler.first,
        child: Stack(
          children: [
            Positioned.fill(
              child: foto != null
                  ? Image.file(
                      foto,
                      fit: BoxFit.cover,
                      color: Colors.black.withValues(alpha: 0.35),
                      colorBlendMode: BlendMode.darken,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    )
                  : HareketliSahne(
                      dongu: const Duration(seconds: 22),
                      boyaci: (t) => OdakSahnesiBoyaci(ortam.sahne.name, t),
                    ),
            ),
            if (yagmur) const Positioned.fill(child: _YagmurEfekti()),
            Padding(
              padding: EdgeInsets.fromLTRB(16, ust + 8, 12, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _camRozet(yildiz),
                      const Spacer(),
                      _camButon(Icons.map_outlined, 'Konularım ve müfredat', () => context.push('/konular')),
                      const SizedBox(width: 8),
                      _camButon(Icons.tune_rounded, 'Manzara ve ses', () => _ortamSayfasi(context)),
                    ],
                  ),
                  const Spacer(),
                  _sayac(odak),
                  const Spacer(),
                  Text(
                    '${ortam.sahne.etiket}  ·  ${ortam.sesEtiketi}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      shadows: const [Shadow(blurRadius: 6, color: Colors.black38)],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sayac(OdakState odak) {
    final c = context.colors;
    final durum = switch (odak.asama) {
      OdakAsama.hazir => odak.serbest ? 'Serbest mod · hazır' : 'Başlamaya hazır',
      OdakAsama.calisiyor => '${odak.ders} · odaklanıyorsun',
      OdakAsama.duraklatildi => 'Duraklatıldı',
      OdakAsama.tamamlandi => 'Seans tamamlandı',
    };
    final gece = c.gece;
    final yaziRenk = gece ? const Color(0xFF111629) : Colors.white;
    return Semantics(
      label: 'Sayaç ${_format(odak.gosterilenSaniye)}, $durum',
      excludeSemantics: true,
      child: SizedBox(
        width: 224,
        height: 224,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (gece) ...[
              const Parilti(renk: Color(0xFFFFC66B), boyut: 250),
              Container(width: 186, height: 186, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF3EEDF))),
              const Positioned(left: 58, top: 62, child: _Krater(18)),
              const Positioned(right: 54, bottom: 58, child: _Krater(26)),
              const Positioned(right: 70, top: 50, child: _Krater(10)),
            ] else
              Container(width: 204, height: 204, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withValues(alpha: 0.16))),
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: odak.ilerleme.clamp(0.0, 1.0),
                strokeWidth: 8,
                strokeCap: StrokeCap.round,
                backgroundColor: gece ? const Color(0xFF2A3363) : Colors.white.withValues(alpha: 0.22),
                color: gece ? const Color(0xFFFFC66B) : Colors.white,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _format(odak.gosterilenSaniye),
                  style: context.baslik(50, color: yaziRenk).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
                const SizedBox(height: 4),
                Text(
                  durum,
                  style: TextStyle(
                    color: gece ? const Color(0xFF3A4474) : Colors.white.withValues(alpha: 0.92),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _camRozet(int yildiz) {
    return Semantics(
      label: 'Yıldız bakiyen: $yildiz',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const YildizIkon(boyut: 16),
            const SizedBox(width: 6),
            Text('$yildiz', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _camButon(IconData ikon, String ipucu, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      tooltip: ipucu,
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.22),
        minimumSize: const Size(44, 44),
      ),
      icon: Icon(ikon, color: Colors.white),
    );
  }

  Widget _sureSecici(OdakState odak) {
    return Row(
      children: [
        for (final dk in odakSureleri) ...[
          Expanded(
            child: HapSecim(
              etiket: dk == 0 ? 'Serbest' : '$dk dk',
              secili: odak.sureDk == dk,
              onTap: odak.aktif ? null : () => ref.read(odakProvider.notifier).sureSec(dk),
            ),
          ),
          if (dk != odakSureleri.last) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _dersSecici(OdakState odak) {
    final ozel = ref.watch(mufredatProvider.select((m) => m.ozelDersler));
    final dersler = ref.watch(serbestModProvider)
        ? ['Genel', ...ozel]
        : [..._dersler, for (final d in ozel) if (!_dersler.contains(d)) d];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dersler.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => HapSecim(
          etiket: dersler[i],
          secili: odak.ders == dersler[i],
          onTap: odak.aktif ? null : () => ref.read(odakProvider.notifier).dersSec(dersler[i]),
        ),
      ),
    );
  }

  Widget _kontroller(OdakState odak) {
    final n = ref.read(odakProvider.notifier);
    final calisiyor = odak.asama == OdakAsama.calisiyor;
    return Row(
      children: [
        if (odak.aktif)
          IconButton.filledTonal(
            onPressed: () => _sifirlaOnay(n),
            tooltip: 'Vazgeç',
            iconSize: 26,
            style: IconButton.styleFrom(minimumSize: const Size(56, 56)),
            icon: const Icon(Icons.close_rounded),
          ),
        if (odak.aktif) const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 58,
            child: FilledButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                calisiyor ? n.duraklat() : n.baslat();
              },
              style: FilledButton.styleFrom(
                backgroundColor: calisiyor ? context.colors.warning : context.colors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              icon: Icon(calisiyor ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 28),
              label: Text(
                calisiyor ? 'Duraklat' : (odak.asama == OdakAsama.duraklatildi ? 'Devam et' : 'Odaklanmaya başla'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
        if (odak.aktif) const SizedBox(width: 12),
        if (odak.aktif)
          IconButton.filledTonal(
            onPressed: () {
              HapticFeedback.mediumImpact();
              n.bitir();
            },
            tooltip: 'Seansı bitir ve kaydet',
            iconSize: 26,
            style: IconButton.styleFrom(minimumSize: const Size(56, 56)),
            icon: Icon(Icons.check_rounded, color: context.colors.success),
          ),
      ],
    );
  }

  void _sifirlaOnay(OdakNotifier n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seanstan vazgeçilsin mi?'),
        content: const Text('Bu seans kaydedilmeyecek. Kaydetmek istersen onay düğmesiyle bitir.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Devam et')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              n.sifirla();
            },
            child: Text('Vazgeç', style: TextStyle(color: context.colors.danger)),
          ),
        ],
      ),
    );
  }

  Widget _canliPuan(OdakState odak) {
    if (odak.asama == OdakAsama.tamamlandi) {
      final y = odak.sonYildiz;
      return YumusakKart(
        renk: context.colors.primarySoft,
        child: Row(
          children: [
            const SaksiliBitki(bitkiId: 'seed_papatya', asama: 1, genislik: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                y == null
                    ? 'Seans kaydediliyor…'
                    : y > 0
                        ? '${odak.sonDakika} dk odaklandın, +$y yıldız kazandın! Bahçendeki bitkiler de büyüdü.'
                        : '${odak.sonDakika} dk odaklandın. Yıldız için en az 25 dk gerekir (günlük tavan 200 yıldız).',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.textPrimary, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }
    return YumusakKart(
      child: Row(
        children: [
          _mini(Icon(Icons.timer_outlined, size: 18, color: context.colors.primary), '${odak.gecenDakika} dk', 'bu seans'),
          _ayrac(),
          _mini(const YildizIkon(boyut: 18), '+${odak.tahminiYildiz}', 'kazanılacak'),
          _ayrac(),
          _mini(Icon(Icons.flag_outlined, size: 18, color: context.colors.accent), odak.tahminiYildiz >= 40 ? 'tavan' : '${odak.sonrakiYildizaDk} dk', 'sonraki +10'),
        ],
      ),
    );
  }

  Widget _mini(Widget ikon, String deger, String alt) {
    return Expanded(
      child: Column(
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [ikon, const SizedBox(width: 5), Text(deger, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.colors.textPrimary))]),
          const SizedBox(height: 2),
          Text(alt, style: TextStyle(fontSize: 12, color: context.colors.textMuted)),
        ],
      ),
    );
  }

  Widget _ayrac() => Container(width: 1, height: 32, color: context.colors.border);

  Widget _istatistikler(BuildContext context) {
    final c = context.colors;
    final hafta = ref.watch(donemAnaliziProvider(7));
    final dagilim = ref.watch(buHaftaDersDagilimiProvider);
    final yukleniyor = hafta == null && ref.watch(analizGirdisiProvider).isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BolumBasligi('Son 7 gün', aksiyon: 'Analiz', onAksiyon: () => context.push('/analiz')),
        YumusakKart(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
          child: hafta == null
              ? SizedBox(
                  height: 150,
                  child: Center(
                    child: yukleniyor
                        ? const CircularProgressIndicator()
                        : Text('Profilini tamamlayınca çalışma grafiğin burada görünür.', style: TextStyle(color: c.textMuted)),
                  ),
                )
              : Column(
                  children: [
                    CalismaCubukGrafigi(gunler: hafta.gunler, dakikalar: hafta.gunlukDk, hedefDk: hafta.hedefDk, yukseklik: 150),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _mini(Icon(Icons.timer_outlined, size: 18, color: c.primary), sureMetni(hafta.toplamDk), 'toplam'),
                        _ayrac(),
                        _mini(Icon(Icons.today_rounded, size: 18, color: c.info), '${hafta.aktifGun}/7', 'aktif gün'),
                        _ayrac(),
                        _mini(const AlevIkon(boyut: 18), '${hafta.seri}', 'gün seri'),
                      ],
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 18),
        const BolumBasligi('Bu hafta ders dağılımı'),
        YumusakKart(
          child: dagilim == null || dagilim.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    dagilim == null && yukleniyor ? 'Yükleniyor…' : 'Bu hafta henüz kayıtlı çalışma yok. Bir ders seçip ilk seansını başlat!',
                    style: TextStyle(color: c.textMuted),
                  ),
                )
              : DersDagilimGrafigi(dagilim: dagilim),
        ),
      ],
    );
  }

  void _ortamSayfasi(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      builder: (_) => const _OrtamSayfasi(),
    );
  }
}

class _OrtamSayfasi extends ConsumerStatefulWidget {
  const _OrtamSayfasi();

  @override
  ConsumerState<_OrtamSayfasi> createState() => _OrtamSayfasiState();
}

class _OrtamSayfasiState extends ConsumerState<_OrtamSayfasi> {
  bool _onizleme = false;
  bool _ekleniyor = false;
  late final OdakNotifier _odak = ref.read(odakProvider.notifier);
  late final OrtamNotifier _ortam = ref.read(ortamProvider.notifier);

  @override
  void dispose() {
    // Seans yokken yapılan önizleme sayfa kapanınca susar.
    if (_onizleme && ref.read(odakProvider).asama != OdakAsama.calisiyor) {
      // ignore: discarded_futures
      AmbiyansService.durdur();
    }
    super.dispose();
  }

  Future<void> _uygula() async {
    _onizleme = true;
    await _odak.sesDegisti(ref.read(ortamProvider), onizleme: true);
  }

  Future<void> _sesSec(AmbiyansSes s) async {
    HapticFeedback.selectionClick();
    await _ortam.sesSec(s);
    await _uygula();
  }

  Future<void> _ozelSec(String yol) async {
    HapticFeedback.selectionClick();
    await _ortam.ozelSesSec(yol);
    await _uygula();
  }

  Future<void> _ozelEkle() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _ekleniyor = true);
    try {
      final sonuc = await _ortam.ozelSesEkle();
      if (sonuc == null) return;
      if (sonuc.isNotEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(sonuc)));
        return;
      }
      await _uygula();
      messenger.showSnackBar(const SnackBar(content: Text('Ses eklendi ve seçildi.')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Ses dosyası eklenemedi. Farklı bir dosya dene.')));
    } finally {
      if (mounted) setState(() => _ekleniyor = false);
    }
  }

  Future<void> _ozelSil(OzelSes o) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ses silinsin mi?'),
        content: Text('“${o.ad}” listeden ve cihazdaki uygulama klasöründen silinecek.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
        ],
      ),
    );
    if (onay != true) return;
    final seciliydi = ref.read(ortamProvider).ozelSesYolu == o.yol;
    await _ortam.ozelSesSil(o.yol);
    if (seciliydi) await AmbiyansService.durdur();
  }

  @override
  Widget build(BuildContext context) {
    final ortam = ref.watch(ortamProvider);
    final c = context.colors;

    Widget kategori(String baslik, AmbiyansKategori k) {
      final sesler = AmbiyansSes.values.where((s) => s.kategori == k && s != AmbiyansSes.ozel).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 8),
            child: Text(baslik, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: c.textMuted)),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in sesler) HapSecim(etiket: s.etiket, secili: ortam.ses == s, onTap: () => _sesSec(s)),
            ],
          ),
        ],
      );
    }

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BolumBasligi('Manzara'),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.1,
                children: [
                  for (final s in OdakSahne.values)
                    Semantics(
                      button: true,
                      selected: ortam.sahne == s,
                      label: s.etiket,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          if (s == OdakSahne.ozel) {
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await _ortam.ozelFotoSec();
                            } catch (_) {
                              messenger.showSnackBar(const SnackBar(content: Text('Fotoğraf yüklenemedi.')));
                            }
                          } else {
                            await _ortam.sahneSec(s);
                          }
                        },
                        child: Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: s.renkler.first,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: ortam.sahne == s ? c.accent : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: Stack(
                            children: [
                              if (s != OdakSahne.ozel) Positioned.fill(child: CustomPaint(painter: OdakSahnesiBoyaci(s.name, 0.3))),
                              if (s == OdakSahne.ozel)
                                const Center(child: Icon(Icons.add_photo_alternate_outlined, color: Colors.white, size: 30)),
                              Positioned(
                                left: 6,
                                right: 6,
                                bottom: 6,
                                child: Text(
                                  s == OdakSahne.ozel ? 'Galeriden seç' : s.etiket,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              const BolumBasligi('Arka plan sesi'),
              HapSecim(etiket: AmbiyansSes.sessiz.etiket, secili: ortam.ses == AmbiyansSes.sessiz, onTap: () => _sesSec(AmbiyansSes.sessiz)),
              kategori('Doğa', AmbiyansKategori.doga),
              kategori('Mekân', AmbiyansKategori.mekan),
              kategori('Gürültü ve odak tonları', AmbiyansKategori.gurultu),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text('Kendi seslerim', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: c.textMuted)),
                  ),
                  Text('${ortam.ozelSesler.length}/$maksOzelSes', style: TextStyle(fontSize: 12, color: c.textMuted)),
                ],
              ),
              const SizedBox(height: 6),
              for (final o in ortam.ozelSesler)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: ortam.ses == AmbiyansSes.ozel && ortam.ozelSesYolu == o.yol ? c.primarySoft : c.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ortam.ses == AmbiyansSes.ozel && ortam.ozelSesYolu == o.yol ? c.primary : c.border),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.music_note_rounded, color: c.primary),
                    title: Text(o.ad, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, color: c.textPrimary)),
                    onTap: () => _ozelSec(o.yol),
                    trailing: IconButton(
                      tooltip: 'Sesi sil',
                      icon: Icon(Icons.delete_outline_rounded, color: c.textMuted),
                      onPressed: () => _ozelSil(o),
                    ),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: _ekleniyor || ortam.ozelSesler.length >= maksOzelSes ? null : _ozelEkle,
                icon: _ekleniyor
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.upload_file_rounded),
                label: const Text('Ses dosyası yükle'),
              ),
              const SizedBox(height: 4),
              Text('MP3, M4A, WAV veya OGG · en fazla ${maksOzelSesBayt ~/ (1024 * 1024)} MB. Dosya yalnızca bu cihazda saklanır.',
                  style: TextStyle(fontSize: 11.5, color: c.textMuted)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.volume_down_rounded, color: c.textMuted),
                  Expanded(
                    child: Slider(
                      value: ortam.sesSeviyesi,
                      min: 0.05,
                      max: 1,
                      label: '%${(ortam.sesSeviyesi * 100).round()}',
                      divisions: 19,
                      onChanged: (v) {
                        _ortam.sesSeviyesiAyarla(v);
                        AmbiyansService.seviyeAyarla(v);
                      },
                    ),
                  ),
                  Icon(Icons.volume_up_rounded, color: c.textMuted),
                ],
              ),
              Text(
                'Seçtiğin sesi hemen dinleyebilirsin. Odak seansı başlayınca çalar, duraklatınca durur. Alfa dalgası kulaklıkla etkilidir.',
                style: TextStyle(fontSize: 12, color: c.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _YagmurEfekti extends StatefulWidget {
  const _YagmurEfekti();

  @override
  State<_YagmurEfekti> createState() => _YagmurEfektiState();
}

class _YagmurEfektiState extends State<_YagmurEfekti> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }
  final List<Offset> _damlalar = List.generate(46, (i) {
    final r = Random(i);
    return Offset(r.nextDouble(), r.nextDouble());
  });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return const SizedBox.shrink();
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(painter: _YagmurPainter(_c, _damlalar)),
      ),
    );
  }
}

class _YagmurPainter extends CustomPainter {
  final Animation<double> anim;
  final List<Offset> damlalar;
  final Paint _p = Paint()
    ..color = Colors.white.withValues(alpha: 0.28)
    ..strokeWidth = 1.4
    ..strokeCap = StrokeCap.round;

  _YagmurPainter(this.anim, this.damlalar) : super(repaint: anim);

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < damlalar.length; i++) {
      final d = damlalar[i];
      final hiz = 0.8 + (i % 5) * 0.15;
      final y = ((d.dy + anim.value * hiz) % 1.0) * size.height;
      final x = d.dx * size.width;
      canvas.drawLine(Offset(x, y), Offset(x - 3, y + 14), _p);
    }
  }

  @override
  bool shouldRepaint(covariant _YagmurPainter old) => false;
}

class _Krater extends StatelessWidget {
  final double boyut;
  const _Krater(this.boyut);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: boyut,
      height: boyut,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE4DCC6)),
    );
  }
}
