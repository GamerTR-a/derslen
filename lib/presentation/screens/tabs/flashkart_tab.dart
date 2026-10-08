import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/bahce_provider.dart';
import '../../providers/flashkart_provider.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/ui_kit.dart';
import '../../cizimler/cizim_widgetlari.dart';
import '../../cizimler/sahne_boyaci.dart';
import '../../cizimler/svg_cizimler.dart';
import '../../../core/algorithms/sm2.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/sinif_mufredati.dart';
import '../../../data/models/flash_kart.dart';
import '../../../data/models/kart_durum.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

/// Kartın SM-2 durumuna göre bitki metaforu: (aşama, solgun mu, etiket).
(int, bool, String) kartBitkiDurumu(KartDurum? d) {
  if (d == null || d.tekrarSayisi == 0) return (1, false, 'Yeni filiz');
  if (d.bugunTekrarEdilecek) return (2, true, 'Su bekliyor');
  if (d.aralik >= 21) return (3, false, 'Çiçek açtı');
  return (2, false, 'Büyüyor');
}

class _KartBitkisi extends StatelessWidget {
  final int asama;
  final bool solgun;
  final double boyut;
  const _KartBitkisi(this.asama, this.solgun, {this.boyut = 22});

  @override
  Widget build(BuildContext context) =>
      Cizim(bitkiSvg('seed_kiraz', asama, gece: context.colors.gece, solgun: solgun), width: boyut * 0.8, height: boyut);
}

const List<(String, String)> _desteler = [
  ('hepsi', 'Tümü'),
  (yanlisDeste, 'Yanlışlarım'),
  (ozelDeste, 'Kartlarım'),
  ('turkce', 'Türkçe'),
  ('matematik', 'Matematik'),
  ('geometri', 'Geometri'),
  ('fizik', 'Fizik'),
  ('kimya', 'Kimya'),
  ('biyoloji', 'Biyoloji'),
  ('edebiyat', 'Edebiyat'),
  ('tarih', 'Tarih'),
  ('cografya', 'Coğrafya'),
  ('felsefe', 'Felsefe'),
  ('din', 'Din Kültürü'),
  ('ingilizce', 'İngilizce'),
];

class FlashkartTab extends ConsumerStatefulWidget {
  const FlashkartTab({super.key});

  @override
  ConsumerState<FlashkartTab> createState() => _FlashkartTabState();
}

class _FlashkartTabState extends ConsumerState<FlashkartTab> with SingleTickerProviderStateMixin {
  int _oturumdaTekrar = 0;
  bool _isFlipped = false;
  bool _showHint = false;
  late final AnimationController _ruzgar =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat();

  @override
  void dispose() {
    _ruzgar.dispose();
    super.dispose();
  }

  void _nextCard(Sm2Kalite kalite, String kartId) {
    HapticFeedback.lightImpact();
    final ilkKez = kalite == Sm2Kalite.tekrarSifirla && !ref.read(flashkartProvider).bilemedimIdleri.contains(kartId);
    if (ilkKez) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Kart “Yanlışlarım” destesine de eklendi. “Kolaydı” dediğinde oradan çıkar.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ));
    }
    ref.read(flashkartProvider.notifier).kartOylele(kartId, kalite);
    ref.read(bahceProvider.notifier).kartDamlasi();
    setState(() {
      _isFlipped = false;
      _showHint = false;
      _oturumdaTekrar++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final flashkartState = ref.watch(flashkartProvider);
    final kartlar = ref.watch(bugunCalisilacakKartlarProvider);
    final dueSayilari = ref.watch(desteDueSayilariProvider);
    final damla = ref.watch(bahceProvider.select((b) => b.damla));
    final durumlar = {for (final d in flashkartState.durumlar) d.id: d};

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, kisit) {
            final dar = kisit.maxHeight < _rahatYukseklik;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text('Kartlar', style: context.baslik(28)),
                            ),
                            IconButton(
                              tooltip: 'Destedeki tüm kartlar',
                              onPressed: () => _desteListesi(context, flashkartState.seciliDers),
                              icon: Icon(Icons.format_list_bulleted_rounded, color: context.colors.textSecondary),
                            ),
                            SayacRozeti(ikon: const _KartBitkisi(2, true, boyut: 17), deger: '${dueSayilari['hepsi'] ?? 0}', renk: context.colors.warning, semantik: '${dueSayilari['hepsi'] ?? 0} kart tekrar bekliyor'),
                            const SizedBox(width: 8),
                            SayacRozeti(ikon: const DamlaIkon(boyut: 15), deger: '$damla', renk: context.colors.water, semantik: '$damla su damlası'),
                          ],
                        ),
                      ),
                      if (!dar)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(context.colors.gece
                                ? 'Işıklı ipteki desteyi seç; tekrar ettikçe kartların çiçek açar.'
                                : 'İpteki desteyi seç. Tekrar ettikçe kartların çiçek açar, bahçen için su kazanırsın.',
                                style: TextStyle(fontSize: 13, color: context.colors.textMuted)),
                          ),
                        ),
                      _sinifSuzgeci(flashkartState.sinif),
                      _askiIpi(flashkartState.seciliDers, dueSayilari),
                    ],
                  ),
                ),
                // Kart kalan alanı doldurur; ekran kısaysa küçülmek yerine sayfa kayar.
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: _enAzKartAlani),
                      child: kartlar.isEmpty
                          ? _buildTamamlandiWidget(flashkartState.seciliDers)
                          : _buildKartWidget(kartlar.first, durumlar[kartlar.first.id], _oturumdaTekrar, kartlar.length),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Bu yükseklikten kısa ekranlarda açıklama satırı gizlenir.
  static const double _rahatYukseklik = 760;

  /// Kart + ilerleme çubuğu + düğmeler için ayrılan en küçük yükseklik.
  static const double _enAzKartAlani = 400;

  /// Hazır kartları sınıfa göre süzer (9-11: o sınıfın Maarif konuları).
  Widget _sinifSuzgeci(int? secili) {
    void sec(int? s) {
      HapticFeedback.selectionClick();
      setState(() {
        _oturumdaTekrar = 0;
        _isFlipped = false;
        _showHint = false;
      });
      ref.read(flashkartProvider.notifier).sinifSec(s);
    }

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        children: [
          FilledButton.tonalIcon(
            onPressed: () => _kartEkleSayfasi(context),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Kart ekle', style: TextStyle(fontWeight: FontWeight.w800)),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
          const SizedBox(width: 8),
          HapSecim(etiket: 'Tüm kartlar', secili: secili == null, onTap: () => sec(null)),
          for (final s in mufredatliSiniflar) ...[
            const SizedBox(width: 8),
            HapSecim(etiket: '$s. sınıf', secili: secili == s, onTap: () => sec(s)),
          ],
        ],
      ),
    );
  }

  Widget _askiIpi(String secili, Map<String, int> due) {
    final c = context.colors;
    final hareketsiz = MediaQuery.of(context).disableAnimations;
    const genislik = 104.0;
    return SizedBox(
      height: 168,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 6,
            height: 40,
            child: HareketliSahne(dongu: const Duration(seconds: 6), boyaci: (t) => AskiIpiBoyaci(c.gece, t)),
          ),
          ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _desteler.length,
            itemBuilder: (_, i) {
              final (id, ad) = _desteler[i];
              final sayi = due[id] ?? 0;
              final seciliMi = secili == id;
              final renk = id == 'hepsi' ? c.primary : (dersRengi(id));
              return SizedBox(
                width: genislik + 8,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: AnimatedBuilder(
                      animation: _ruzgar,
                      builder: (_, child) {
                        final aci = hareketsiz ? 0.0 : sin(_ruzgar.value * 2 * pi + i * 0.9) * (seciliMi ? 0.02 : 0.06);
                        return Transform.rotate(angle: aci + (c.gece ? (i.isEven ? 0.03 : -0.025) : 0), alignment: Alignment.topCenter, child: child);
                      },
                      child: Column(
                        children: [
                          c.gece
                              ? Container(width: 6, height: 18, decoration: BoxDecoration(color: c.textMuted, borderRadius: BorderRadius.circular(2)))
                              : Container(
                                  width: 10,
                                  height: 22,
                                  decoration: BoxDecoration(color: const Color(0xFFD4A373), borderRadius: BorderRadius.circular(3)),
                                ),
                          Semantics(
                            button: true,
                            selected: seciliMi,
                            label: '$ad destesi, $sayi kart tekrar bekliyor',
                            excludeSemantics: true,
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _oturumdaTekrar = 0;
                                  _isFlipped = false;
                                  _showHint = false;
                                });
                                ref.read(flashkartProvider.notifier).dersSec(id);
                              },
                              child: c.gece
                                  ? _polaroid(ad, sayi, renk, seciliMi, genislik - 10)
                                  : _desteKarti(ad, sayi, renk, seciliMi, genislik - 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _desteKarti(String ad, int sayi, Color renk, bool secili, double w) {
    final c = context.colors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: w,
      height: 108,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: secili ? renk : c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: renk.withValues(alpha: secili ? 1 : 0.35), width: 1.5),
        boxShadow: [BoxShadow(color: renk.withValues(alpha: secili ? 0.32 : 0.08), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _KartBitkisi(sayi > 0 ? 2 : 3, sayi > 0, boyut: 30),
          const Spacer(),
          Text(ad,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: secili ? c.onPrimary : c.textPrimary)),
          Text(sayi > 0 ? '$sayi tekrar' : 'hepsi tamam',
              style: TextStyle(fontSize: 11.5, color: secili ? c.onPrimary.withValues(alpha: 0.8) : c.textMuted)),
        ],
      ),
    );
  }

  Widget _polaroid(String ad, int sayi, Color renk, bool secili, double w) {
    final c = context.colors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: w,
      padding: const EdgeInsets.fromLTRB(7, 7, 7, 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EEDF),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: secili ? c.accent : Colors.transparent, width: 2),
        boxShadow: [
          BoxShadow(color: secili ? c.accent.withValues(alpha: 0.45) : Colors.black.withValues(alpha: 0.4), blurRadius: secili ? 16 : 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 60,
            width: double.infinity,
            decoration: BoxDecoration(color: Color.lerp(const Color(0xFF1B2240), renk, 0.18), borderRadius: BorderRadius.circular(3)),
            alignment: Alignment.center,
            child: sayi > 0
                ? Text('$sayi', style: context.baslik(26, color: c.accent))
                : const _KartBitkisi(3, false, boyut: 38),
          ),
          const SizedBox(height: 6),
          Text(ad, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF111629))),
        ],
      ),
    );
  }

  Widget _buildKartWidget(FlashKart kart, KartDurum? durum, int yapilan, int kalan) {
    final (asama, solgun, bitkiEtiket) = kartBitkiDurumu(durum);
    return Column(
      children: [
        Row(
          children: [
            Text('$kalan kaldı', style: TextStyle(fontWeight: FontWeight.w700, color: context.colors.textMuted)),
            const SizedBox(width: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: yapilan / (yapilan + kalan),
                  minHeight: 6,
                  backgroundColor: context.colors.border,
                  color: context.colors.success,
                ),
              ),
            ),
            const SizedBox(width: 10),
            _KartBitkisi(asama, solgun, boyut: 20),
            const SizedBox(width: 4),
            Text(bitkiEtiket, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: context.colors.textSecondary)),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isFlipped = !_isFlipped),
            onLongPress: kart.ders == ozelDeste || kart.ders == yanlisDeste ? () => _kartSilOnay(kart) : null,
            child: _CevrilenKart(
              key: ValueKey(kart.id),
              cevrildi: _isFlipped,
              on: _buildOnYuz(kart),
              arka: _buildArkaYuz(kart),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (!_isFlipped)
          Column(
            children: [
              if (kart.ipucu != null && kart.ipucu!.isNotEmpty)
                TextButton.icon(
                  onPressed: () => setState(() => _showHint = !_showHint),
                  icon: Icon(Icons.lightbulb_outline, color: context.colors.warning, size: 20),
                  label: Text(
                    _showHint ? 'İpucu: ${kart.ipucu}' : 'İpucu göster',
                    style: TextStyle(color: context.colors.warning, fontWeight: FontWeight.bold),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => setState(() => _isFlipped = true),
                  style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text('Cevabı göster', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(child: _buildRatingButton(label: 'Bilemedim', subText: 'Yanlışlarım\'a', color: context.colors.danger, kalite: Sm2Kalite.tekrarSifirla, kartId: kart.id)),
              const SizedBox(width: 8),
              Expanded(child: _buildRatingButton(label: 'Zorlandım', subText: 'kısa ara', color: context.colors.warning, kalite: Sm2Kalite.orta, kartId: kart.id)),
              const SizedBox(width: 8),
              Expanded(child: _buildRatingButton(label: 'Kolaydı', subText: 'uzun ara', color: context.colors.success, kalite: Sm2Kalite.cokKolay, kartId: kart.id)),
            ],
          ),
      ],
    );
  }

  Widget _kartKabugu({required Key key, required Color kenar, required Widget child}) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: kenar.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [BoxShadow(color: kenar.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: child,
    );
  }

  Widget _buildOnYuz(FlashKart kart) {
    return _kartKabugu(
      key: ValueKey('on_${kart.id}'),
      kenar: kart.renk,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: kart.renk.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Text('${kart.dersEtiketi} • ${kart.unite}',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: kart.renk, fontSize: 12.5, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  kart.on,
                  style: TextStyle(
                    fontSize: kart.on.length > 80 ? 17 : 26,
                    fontWeight: kart.on.length > 80 ? FontWeight.w600 : FontWeight.w900,
                    color: context.colors.textPrimary,
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Text('Çevirmek için dokun', style: TextStyle(fontSize: 12, color: context.colors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildArkaYuz(FlashKart kart) {
    return _kartKabugu(
      key: ValueKey('arka_${kart.id}'),
      kenar: context.colors.success,
      child: Column(
        children: [
          Text('Cevap', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.colors.success)),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  kart.arka,
                  style: TextStyle(fontSize: 16.5, color: context.colors.textPrimary, height: 1.5, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Text('Ne kadar iyi hatırladın?', style: TextStyle(fontSize: 12, color: context.colors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildRatingButton({
    required String label,
    required String subText,
    required Color color,
    required Sm2Kalite kalite,
    required String kartId,
  }) {
    return SizedBox(
      height: 58,
      child: FilledButton(
        onPressed: () => _nextCard(kalite, kartId),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: context.colors.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            Text(subText, style: TextStyle(fontSize: 11, color: context.colors.onPrimary.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }

  Widget _buildTamamlandiWidget(String deste) {
    final toplam = ref.read(flashkartProvider).desteKartlari(deste).length;
    if (toplam == 0) {
      return EmptyStateWidget(
        icon: deste == yanlisDeste ? '🎯' : '✍️',
        baslik: deste == yanlisDeste ? 'Henüz yanlış kartın yok' : 'Henüz kendi kartın yok',
        aciklama: deste == yanlisDeste
            ? 'Test çözdüğünde yanlış yaptığın sorular ve “Bilemedim” dediğin kartlar buraya otomatik düşer.'
            : '“Kart ekle” ile formül, tarih veya kavram kartı oluştur.',
      );
    }
    if (ref.read(yeniKartSiniriDolduProvider)) {
      return EmptyStateWidget(
        icon: '🌱',
        baslik: 'Bugünlük yeni kartlar tamam',
        aciklama: 'Her gün en fazla $gunlukYeniKartSiniri hazır yeni kart tanıtılır; böylece tekrarların birikmez. Yarın yeni tohumlar gelecek.',
        butonMetni: 'Kartları listele',
        onButonPressed: () => _desteListesi(context, deste),
      );
    }
    return EmptyStateWidget(
      icon: '🌸',
      baslik: 'Bu destedeki tüm kartlar çiçek açtı!',
      aciklama: _oturumdaTekrar > 0
          ? 'Bugün $_oturumdaTekrar kart tekrar ettin. Destede $toplam kart var; tekrar zamanı gelenler solmaya başladığında burada görünür.'
          : 'Destede $toplam kart var; tekrar zamanı gelenler solmaya başladığında burada görünür.',
      butonMetni: 'Kartları listele',
      onButonPressed: () => _desteListesi(context, deste),
    );
  }

  void _kartSilOnay(FlashKart kart) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kart silinsin mi?'),
        content: Text(kart.on, maxLines: 3, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(flashkartProvider.notifier).ozelKartSil(kart.id);
              setState(() => _isFlipped = false);
            },
            child: Text('Sil', style: TextStyle(color: context.colors.danger)),
          ),
        ],
      ),
    );
  }

  void _kartEkleSayfasi(BuildContext context) {
    final on = TextEditingController();
    final arka = TextEditingController();
    final ipucu = TextEditingController();
    final konu = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.colors.surface,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: StatefulBuilder(
          builder: (ctx, setSheet) {
            final gecerli = on.text.trim().isNotEmpty && arka.text.trim().isNotEmpty;
            InputDecoration dekor(String etiket, String ipucuMetni) => InputDecoration(
                  labelText: etiket,
                  hintText: ipucuMetni,
                  filled: true,
                  fillColor: context.colors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                );
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BolumBasligi('Yeni kart'),
                TextField(
                  controller: on,
                  autofocus: true,
                  maxLength: 300,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setSheet(() {}),
                  decoration: dekor('Ön yüz', 'Örn: Newton\'un 2. yasası'),
                ),
                TextField(
                  controller: arka,
                  maxLength: 600,
                  maxLines: 3,
                  minLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setSheet(() {}),
                  decoration: dekor('Arka yüz', 'Örn: F = m · a'),
                ),
                TextField(
                  controller: ipucu,
                  maxLength: 120,
                  decoration: dekor('İpucu (isteğe bağlı)', ''),
                ),
                TextField(
                  controller: konu,
                  maxLength: 40,
                  textCapitalization: TextCapitalization.words,
                  decoration: dekor('Ders / konu etiketi (isteğe bağlı)', 'Örn: Fizik • Kuvvet'),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: !gecerli
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            Navigator.pop(ctx);
                            await ref.read(flashkartProvider.notifier).ozelKartEkle(on: on.text, arka: arka.text, ipucu: ipucu.text, konu: konu.text);
                            messenger.showSnackBar(const SnackBar(
                              content: Text('Kart “Kartlarım” destesine eklendi'),
                              behavior: SnackBarBehavior.floating,
                            ));
                          },
                    style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ).whenComplete(() {
      on.dispose();
      arka.dispose();
      ipucu.dispose();
      konu.dispose();
    });
  }

  void _desteListesi(BuildContext context, String deste) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.colors.surface,
      builder: (_) => _DesteListesi(deste: deste),
    );
  }
}


/// Y ekseninde dönen (3B hissi veren) kart çevirme animasyonu.
class _CevrilenKart extends StatelessWidget {
  final bool cevrildi;
  final Widget on;
  final Widget arka;

  const _CevrilenKart({super.key, required this.cevrildi, required this.on, required this.arka});

  @override
  Widget build(BuildContext context) {
    final sure = MediaQuery.of(context).disableAnimations ? Duration.zero : const Duration(milliseconds: 460);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: cevrildi ? pi : 0),
      duration: sure,
      curve: Curves.easeInOutCubic,
      builder: (_, aci, _) {
        final arkaGorunur = aci > pi / 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(aci),
          child: arkaGorunur
              ? Transform(alignment: Alignment.center, transform: Matrix4.rotationY(pi), child: arka)
              : on,
        );
      },
    );
  }
}

/// Bir destedeki tüm kartlar: tekrar durumu, "Yanlışlarım" rozeti ve
/// kart başına işlemler (şimdi tekrar et, Yanlışlarım'dan çıkar, sil).
class _DesteListesi extends ConsumerWidget {
  final String deste;
  const _DesteListesi({required this.deste});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(flashkartProvider);
    final c = context.colors;
    final durumlar = {for (final d in state.durumlar) d.id: d};
    final kartlar = state.desteKartlari(deste)
      ..sort((a, b) {
        final da = durumlar[a.id]?.sonrakiTekrar ?? '';
        final db = durumlar[b.id]?.sonrakiTekrar ?? '';
        return da.compareTo(db);
      });
    final ad = _desteler.firstWhere((d) => d.$1 == deste, orElse: () => (deste, dersEtiketleri[deste] ?? deste)).$2;
    final n = ref.read(flashkartProvider.notifier);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, kaydirma) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text('$ad · ${kartlar.length} kart', style: context.baslik(20)),
          ),
          if (deste == yanlisDeste)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('Testteki yanlışların ve “Bilemedim” dediğin kartlar. “Kolaydı” dediğin kart listeden çıkar.',
                  style: TextStyle(fontSize: 12.5, color: c.textMuted)),
            ),
          Expanded(
            child: kartlar.isEmpty
                ? Center(child: Text('Bu destede kart yok.', style: TextStyle(color: c.textMuted)))
                : ListView.separated(
                    controller: kaydirma,
                    padding: const EdgeInsets.fromLTRB(16, 4, 8, 24),
                    itemCount: kartlar.length,
                    separatorBuilder: (_, _) => Divider(height: 1, color: c.border),
                    itemBuilder: (_, i) {
                      final k = kartlar[i];
                      final d = durumlar[k.id];
                      final bilemedim = state.bilemedimIdleri.contains(k.id);
                      final islemler = [
                        if (d != null && yeniKartMi(d)) ('simdi', 'Şimdi çalış')
                        else if (d != null && !d.bugunTekrarEdilecek) ('simdi', 'Bugün tekrar et'),
                        if (deste == yanlisDeste || bilemedim) ('cikar', "Yanlışlarım'dan çıkar"),
                        if (k.ders == ozelDeste) ('sil', 'Kartı sil'),
                      ];
                      return ListTile(
                        contentPadding: const EdgeInsets.only(left: 4),
                        leading: Container(width: 5, height: 40, decoration: BoxDecoration(color: k.renk, borderRadius: BorderRadius.circular(3))),
                        title: Text(k.on, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, color: c.textPrimary)),
                        subtitle: Wrap(
                          spacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(k.dersEtiketi == k.ders ? k.unite : '${k.dersEtiketi} • ${k.unite}',
                                style: TextStyle(fontSize: 12, color: c.textMuted)),
                            Text(d == null || yeniKartMi(d) ? 'Yeni' : d.durumEtiketi,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: d == null || yeniKartMi(d) ? c.info : (d.bugunTekrarEdilecek ? c.warning : c.success))),
                            if (bilemedim) Text('· Bilemedim', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.danger)),
                          ],
                        ),
                        onTap: () => _onizle(context, k.on, k.arka),
                        trailing: islemler.isEmpty
                            ? null
                            : PopupMenuButton<String>(
                                tooltip: 'Kart işlemleri',
                                onSelected: (secim) async {
                                  switch (secim) {
                                    case 'simdi':
                                      await n.bugunTekrarla(k.id);
                                    case 'cikar':
                                      await n.yanlislardanCikar(k.id);
                                    case 'sil':
                                      await n.ozelKartSil(k.id);
                                  }
                                },
                                itemBuilder: (_) => [for (final (id, ad) in islemler) PopupMenuItem(value: id, child: Text(ad))],
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _onizle(BuildContext context, String on, String arka) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(on, style: ctx.baslik(18)),
        content: SingleChildScrollView(child: Text(arka, style: TextStyle(color: ctx.colors.textSecondary, height: 1.45))),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Kapat'))],
      ),
    );
  }
}
