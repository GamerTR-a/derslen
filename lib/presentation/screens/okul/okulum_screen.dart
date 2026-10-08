import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

import '../../../core/algorithms/okul_hesaplari.dart';
import '../../../core/services/okul_service.dart';
import '../../../core/utils/tarih.dart';
import '../../../data/models/okul_modelleri.dart';
import '../../providers/okul_provider.dart';
import '../../providers/plan_provider.dart';
import '../../widgets/ui_kit.dart';
import 'okul_ortak.dart';

final _sinifDurumuProvider = FutureProvider.autoDispose<SinifDurumu?>((ref) async {
  if (!ref.watch(okulModuProvider)) return null;
  try {
    return await OkulService.sinifDurumu();
  } on OkulHatasi {
    return null;
  }
});

final _veliBaglantilariProvider = FutureProvider.autoDispose<List<VeliBaglantisi>?>((ref) async {
  try {
    return await OkulService.veliBaglantilari();
  } on OkulHatasi {
    return null;
  }
});

/// Öğrencinin okul bölümü: şubeye katılma, sınıf ormanı, öğretmen önerileri
/// ve veli bağlantısı. Okul hesabında Topluluk sekmesinin yerini alır.
class OkulumScreen extends ConsumerWidget {
  /// true ise AppBar'sız, sekmenin içine gömülü çizilir.
  final bool gomulu;

  const OkulumScreen({super.key, this.gomulu = false});

  Future<void> _yenile(WidgetRef ref) async {
    ref.invalidate(okulDurumuProvider);
    ref.invalidate(ogrenciOnerileriProvider);
    ref.invalidate(_sinifDurumuProvider);
    ref.invalidate(_veliBaglantilariProvider);
    await ref.read(okulDurumuProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final durum = ref.watch(okulDurumuProvider);
    final okulda = durum.value?.okulOgrencisi ?? false;

    final govde = RefreshIndicator(
      onRefresh: () => _yenile(ref),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20, 12, 20, gomulu ? 120 : 32),
        children: [
          if (gomulu) PanelBasligi('Okulum', alt: durum.value?.okulAd),
          if (durum.isLoading && !durum.hasValue)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
          else if (okulda) ...[
            const _SinifKarti(),
            const SizedBox(height: 18),
            const _OneriListesi(),
          ] else
            _KatilKarti(yenile: () => _yenile(ref)),
          const SizedBox(height: 18),
          const _VeliBolumu(),
          const SizedBox(height: 18),
          const BilgiKarti(
            ikon: Icons.visibility_outlined,
            baslik: 'Öğretmenin ve velin ne görür?',
            maddeler: [
              'Görür: odak sayacıyla ölçülen çalışma süren, program uyumun, konu ilerlemen, girdiğin deneme netleri ve test sonuçların.',
              'Görmez: ruh hâli kayıtların, asistanla sohbetlerin, bahçen, oyunların ve kişisel notların.',
              'Branş öğretmeni yalnızca kendi dersinin verisini görür.',
              'Sınıfında kişi sıralaması yoktur; yalnızca şubenin toplamı gösterilir.',
            ],
          ),
          if (okulda) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () async {
                  final onay = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: ctx.colors.surface,
                      title: const Text('Sınıftan ayrıl'),
                      content: const Text(
                          'Öğretmenlerin çalışma verini artık göremez ve öneri gönderemez. Yeniden katılmak için şube kodunu tekrar girmen gerekir.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ayrıl')),
                      ],
                    ),
                  );
                  if (onay != true) return;
                  try {
                    await OkulService.okuldanAyril();
                    await _yenile(ref);
                  } on OkulHatasi catch (e) {
                    if (context.mounted) okulBildir(context, e.mesaj, hata: true);
                  }
                },
                child: Text('Sınıftan ayrıl', style: TextStyle(color: c.textMuted)),
              ),
            ),
          ],
        ],
      ),
    );

    if (gomulu) return Scaffold(backgroundColor: c.background, body: SafeArea(child: govde));
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: c.textPrimary),
        title: Text('Okulum ve velim', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(top: false, child: govde),
    );
  }
}

// ─── Şubeye katılma ──────────────────────────────────────────────────

class _KatilKarti extends StatefulWidget {
  final Future<void> Function() yenile;
  const _KatilKarti({required this.yenile});

  @override
  State<_KatilKarti> createState() => _KatilKartiState();
}

class _KatilKartiState extends State<_KatilKarti> {
  final _kod = TextEditingController();
  bool _islemde = false;
  String? _hata;

  @override
  void dispose() {
    _kod.dispose();
    super.dispose();
  }

  Future<void> _katil() async {
    final kod = kodTemizle(_kod.text);
    if (kod.length != 9) {
      setState(() => _hata = 'Kod 9 karakterdir (ör. S-ABCD-2345).');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _islemde = true;
      _hata = null;
    });
    try {
      // İlk çağrı yalnızca okul ve şubeyi öğrenir; katılım onaydan sonra yapılır.
      final on = await OkulService.koduKullan(kod, KullaniciRolu.ogrenci);
      if (!mounted) return;
      if (on.durum != 'onay_gerekli') {
        setState(() => _hata = kodHataMetni(on.durum, KullaniciRolu.ogrenci));
        return;
      }
      final onay = await _bilgilendir(on);
      if (onay != true || !mounted) return;
      final sonuc = await OkulService.koduKullan(kod, KullaniciRolu.ogrenci, onay: true);
      if (!mounted) return;
      if (!sonuc.basarili) {
        setState(() => _hata = kodHataMetni(sonuc.durum, KullaniciRolu.ogrenci));
        return;
      }
      okulBildir(context, '${sonuc.sinif}-${sonuc.sube} şubesine katıldın.');
      await widget.yenile();
    } on OkulHatasi catch (e) {
      if (mounted) setState(() => _hata = e.mesaj);
    } finally {
      if (mounted) setState(() => _islemde = false);
    }
  }

  Future<bool?> _bilgilendir(KodSonucu s) {
    return okulSayfasiGoster<bool>(
      context,
      baslik: '${s.okul}',
      insa: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${s.sinif}-${s.sube} şubesine katılıyorsun.',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ctx.colors.textPrimary)),
          const SizedBox(height: 12),
          const BilgiKarti(
            ikon: Icons.visibility_outlined,
            baslik: 'Öğretmenlerin görecek',
            maddeler: [
              'Odak sayacıyla ölçülen çalışma süren ve hangi derse çalıştığın',
              'Program uyumun ve konu ilerlemen',
              'Uygulamaya girdiğin deneme netleri ve test sonuçların',
            ],
          ),
          const SizedBox(height: 10),
          BilgiKarti(
            ikon: Icons.visibility_off_outlined,
            baslik: 'Kimse görmeyecek',
            renk: ctx.colors.success,
            maddeler: const [
              'Ruh hâli kayıtların ve asistanla sohbetlerin',
              'Bahçen, oyunların ve kişisel notların',
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Okul hesabında açık topluluk ve herkese açık etüt odaları kapanır. 18 yaşından küçüksen bu adımı velinin bilgisi ve onayıyla tamamla. İstediğin zaman sınıftan ayrılabilirsin.',
            style: TextStyle(fontSize: 12.5, color: ctx.colors.textMuted, height: 1.45),
          ),
          const SizedBox(height: 14),
          AnaDugme(etiket: 'Kabul ediyorum, katıl', onPressed: () => Navigator.pop(ctx, true)),
          Center(
            child: TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return YumusakKart(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school_rounded, color: c.gece ? c.accent : c.primary),
              const SizedBox(width: 10),
              Expanded(child: Text('Okuluna katıl', style: context.baslik(19))),
            ],
          ),
          const SizedBox(height: 6),
          Text('Okulun DersNet kullanıyorsa öğretmeninden aldığın şube kodunu gir.',
              style: TextStyle(fontSize: 13.5, color: c.textSecondary, height: 1.4)),
          const SizedBox(height: 12),
          TextField(
            controller: _kod,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            enableSuggestions: false,
            maxLength: 14,
            onSubmitted: (_) => _islemde ? null : _katil(),
            style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700, letterSpacing: 1.2),
            decoration: okulGirdisi(context, ipucu: 'S-XXXX-XXXX', ikon: Icons.key_rounded).copyWith(counterText: ''),
          ),
          if (_hata != null) ...[
            const SizedBox(height: 8),
            Text(_hata!, style: TextStyle(color: c.danger, fontWeight: FontWeight.w600, height: 1.35)),
          ],
          const SizedBox(height: 12),
          AnaDugme(etiket: 'Devam', onPressed: _katil, yukleniyor: _islemde),
        ],
      ),
    );
  }
}

// ─── Sınıfım ve sınıf ormanı ─────────────────────────────────────────

class _SinifKarti extends ConsumerWidget {
  const _SinifKarti();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final okul = ref.watch(okulDurumuProvider).value;
    final s = ref.watch(_sinifDurumuProvider).value;
    final sube = s?.sube ?? okul?.sube?.etiket ?? '';
    final agac = ormanAgacSayisi(s?.toplamDk ?? 0);
    final hedef = sinifHaftalikHedefi(s?.uye ?? 1);
    final haftaOrani = s == null ? 0.0 : (s.haftaDk / hedef).clamp(0, 1).toDouble();
    const gosterilen = 18;

    return YumusakKart(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(12)),
                child: Text(sube, style: context.baslik(19, color: c.gece ? c.accent : c.primary)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(okul?.okulAd ?? s?.okul ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w700, color: c.textPrimary)),
              ),
            ],
          ),
          if (s == null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text('Sınıf verisi şu an yüklenemedi. Aşağı çekerek yenile.', style: TextStyle(color: c.textMuted)),
            )
          else ...[
            const SizedBox(height: 16),
            Text('Sınıf ormanı', style: context.baslik(17)),
            const SizedBox(height: 4),
            Text(
              agac == 0
                  ? 'Sınıfça her 5 saatlik çalışma bir ağaç diker. İlk ağaç için birlikte çalışmaya başlayın.'
                  : 'Sınıfın birlikte $agac ağaç dikti (toplam ${sureMetni(s.toplamDk)}).',
              style: TextStyle(fontSize: 13, color: c.textSecondary, height: 1.4),
            ),
            if (agac > 0) ...[
              const SizedBox(height: 10),
              Semantics(
                label: '$agac ağaç',
                child: Wrap(
                  spacing: 2,
                  runSpacing: 2,
                  children: [
                    for (var i = 0; i < (agac > gosterilen ? gosterilen : agac); i++)
                      Icon(i.isEven ? Icons.park_rounded : Icons.forest_rounded, size: 24, color: c.success),
                    if (agac > gosterilen)
                      Padding(
                        padding: const EdgeInsets.only(left: 6, top: 3),
                        child: Text('+${agac - gosterilen}',
                            style: TextStyle(fontWeight: FontWeight.w800, color: c.textSecondary)),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            OranSatiri(
              etiket: 'Sıradaki ağaç',
              deger: '%${(siradakiAgacIlerlemesi(s.toplamDk) * 100).round()}',
              oran: siradakiAgacIlerlemesi(s.toplamDk),
              renk: c.success,
            ),
            OranSatiri(
              etiket: 'Bu haftanın sınıf hedefi',
              deger: '%${(haftaOrani * 100).round()}',
              oran: haftaOrani,
              alt:
                  '${sureMetni(s.haftaDk)} / ${sureMetni(hedef)} · senin katkın ${sureMetni(s.benimHaftaDk)} · ${s.katilan} / ${s.uye} kişi katıldı',
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.circle, size: 10, color: s.calisan > 0 ? c.success : c.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.calisan == 0 ? 'Şu an sınıfından çalışan yok. İlk sen başla.' : 'Şu an sınıfından ${s.calisan} kişi çalışıyor.',
                    style: TextStyle(fontSize: 13.5, color: c.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(onPressed: () => context.go('/calis'), child: const Text('Çalış')),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Öğretmen önerileri ──────────────────────────────────────────────

class _OneriListesi extends ConsumerWidget {
  const _OneriListesi();

  Future<void> _programaEkle(BuildContext context, WidgetRef ref, Oneri o) async {
    try {
      await ref
          .read(programProvider.notifier)
          .blokEkle(DateTime.now().weekday - 1, ders: o.ders, konu: o.konu, sureDk: o.sureDk);
      await OkulService.oneriIsaretle(o.id, 'eklendi');
      ref.invalidate(ogrenciOnerileriProvider);
      if (context.mounted) okulBildir(context, 'Bugünkü programına eklendi.');
    } on OkulHatasi catch (e) {
      if (context.mounted) okulBildir(context, e.mesaj, hata: true);
    }
  }

  Future<void> _tamamla(BuildContext context, WidgetRef ref, Oneri o) async {
    try {
      await OkulService.oneriIsaretle(o.id, 'tamamlandi');
      ref.invalidate(ogrenciOnerileriProvider);
    } on OkulHatasi catch (e) {
      if (context.mounted) okulBildir(context, e.mesaj, hata: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final oneriler = ref.watch(ogrenciOnerileriProvider).value ?? const <Oneri>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BolumBasligi('Öğretmen önerileri'),
        if (oneriler.isEmpty)
          Text('Şu an bekleyen öneri yok. Öğretmenin bir çalışma önerdiğinde burada görürsün.',
              style: TextStyle(fontSize: 13.5, color: c.textMuted, height: 1.4))
        else
          for (final o in oneriler)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: YumusakKart(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [o.ders, '${o.sureDk} dk', if (o.ogretmen != null) o.ogretmen!].join('  ·  '),
                      style: TextStyle(fontSize: 12, color: c.textMuted, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(o.konu, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: c.textPrimary)),
                    if (o.not != null && o.not!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(o.not!, style: TextStyle(fontSize: 13, color: c.textSecondary, height: 1.35)),
                    ],
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: switch (o.durum) {
                        'tamamlandi' => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 18, color: c.success),
                              const SizedBox(width: 6),
                              Text('Tamamlandı', style: TextStyle(fontWeight: FontWeight.w700, color: c.textSecondary)),
                            ],
                          ),
                        'eklendi' => TextButton.icon(
                            onPressed: () => _tamamla(context, ref, o),
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Tamamladım'),
                          ),
                        _ => TextButton.icon(
                            onPressed: () => _programaEkle(context, ref, o),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Programıma ekle'),
                          ),
                      },
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

// ─── Veli bağlantısı ─────────────────────────────────────────────────

class _VeliBolumu extends ConsumerStatefulWidget {
  const _VeliBolumu();

  @override
  ConsumerState<_VeliBolumu> createState() => _VeliBolumuState();
}

class _VeliBolumuState extends ConsumerState<_VeliBolumu> {
  bool _islemde = false;

  Future<void> _calistir(Future<void> Function() islem) async {
    setState(() => _islemde = true);
    try {
      await islem();
      ref.invalidate(_veliBaglantilariProvider);
      ref.invalidate(okulDurumuProvider);
    } on OkulHatasi catch (e) {
      if (mounted) okulBildir(context, e.mesaj, hata: true);
    } finally {
      if (mounted) setState(() => _islemde = false);
    }
  }

  Future<void> _kodUret() => _calistir(() async {
        final kod = await OkulService.veliKoduUret();
        if (mounted && kod == 'limit') okulBildir(context, 'En fazla 3 veli bağlanabilir.', hata: true);
      });

  Future<void> _kaldir(VeliBaglantisi b) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.colors.surface,
        title: const Text('Veli bağlantısını kaldır'),
        content: Text('${b.karsiAd} çalışma özetini artık göremeyecek.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kaldır')),
        ],
      ),
    );
    if (onay == true) await _calistir(() => OkulService.veliBaglantisiniBitir(b.id));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final veri = ref.watch(_veliBaglantilariProvider);
    final baglantilar = (veri.value ?? const <VeliBaglantisi>[]).where((b) => b.benOgrenci).toList();
    final aktifler = baglantilar.where((b) => b.aktif).toList();
    final bekleyen = baglantilar.where((b) => !b.aktif && b.kod != null).firstOrNull;

    return YumusakKart(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.family_restroom_rounded, color: c.gece ? c.accent : c.primary),
              const SizedBox(width: 10),
              Expanded(child: Text('Velim', style: context.baslik(19))),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Velin haftalık çalışma özetini kendi telefonundan görebilir. Bir kod üret ve velinle paylaş; kod 7 gün geçerlidir.',
            style: TextStyle(fontSize: 13.5, color: c.textSecondary, height: 1.4),
          ),
          if (veri.hasValue && veri.value == null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('Veli bağlantısı şu an kullanılamıyor. İnternetini kontrol et ya da daha sonra dene.',
                  style: TextStyle(fontSize: 12.5, color: c.textMuted)),
            ),
          for (final b in aktifler)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.verified_user_outlined, color: c.success),
              title: Text(b.karsiAd, style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700)),
              subtitle: Text('Özetini görebiliyor', style: TextStyle(color: c.textMuted, fontSize: 12.5)),
              trailing: IconButton(
                tooltip: 'Bağlantıyı kaldır',
                onPressed: _islemde ? null : () => _kaldir(b),
                icon: Icon(Icons.link_off_rounded, color: c.textMuted),
              ),
            ),
          if (bekleyen != null) ...[
            const SizedBox(height: 12),
            KodKutusu(
              kod: bekleyen.kod!,
              aciklama: bekleyen.sonGecerlilik == null
                  ? 'Veli kodu'
                  : 'Veli kodu · ${kisaTarih(bekleyen.sonGecerlilik!)} tarihine kadar geçerli',
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _islemde || (veri.hasValue && veri.value == null) ? null : _kodUret,
              icon: const Icon(Icons.vpn_key_outlined, size: 18),
              label: Text(bekleyen == null ? 'Veli kodu üret' : 'Yeni kod üret'),
            ),
          ),
        ],
      ),
    );
  }
}
