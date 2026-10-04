/// Ders Programım — üç sekmede sade bir düzen:
///  * Günlük: seçili günün saatli blokları, tamamlama, odak seansı başlatma,
///    blok ekleme / düzenleme / silme ve günü başka günlere kopyalama.
///  * Haftalık: haftanın tablosu ve derslere ayrılan süre.
///  * Kişiselleştir: programın nasıl hazırlanacağı (otomatik ya da sabit),
///    programa girecek konuların ders ders seçimi, günler ve saatler.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

import '../../../core/algorithms/ders_programi.dart';
import '../../../core/utils/tarih.dart';
import '../../../data/models/gunluk_checkin.dart';
import '../../../data/models/plan_blok.dart';
import '../../providers/bahce_provider.dart';
import '../../providers/checkin_provider.dart';
import '../../providers/konu_provider.dart';
import '../../providers/mufredat_provider.dart';
import '../../providers/odak_provider.dart';
import '../../providers/plan_provider.dart';
import '../../providers/profil_provider.dart';
import '../../widgets/grafikler.dart';
import '../../widgets/nefes_egzersizi_dialog.dart';
import 'program_duzenleme.dart';

class DersProgramiScreen extends ConsumerStatefulWidget {
  /// Açılışta gösterilecek sekme: 0 Günlük, 1 Haftalık, 2 Kişiselleştir.
  final int baslangicSekmesi;

  const DersProgramiScreen({super.key, this.baslangicSekmesi = 0});

  @override
  ConsumerState<DersProgramiScreen> createState() => _DersProgramiScreenState();
}

class _DersProgramiScreenState extends ConsumerState<DersProgramiScreen> with SingleTickerProviderStateMixin {
  late final TabController _sekme = TabController(length: 3, vsync: this, initialIndex: widget.baslangicSekmesi.clamp(0, 2));
  int _seciliGun = DateTime.now().weekday - 1;
  DersProgramiAyar? _taslak;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(programProvider.notifier).hazirla());
  }

  @override
  void dispose() {
    _sekme.dispose();
    super.dispose();
  }

  int get _bugun => DateTime.now().weekday - 1;

  void _bildir(String mesaj) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mesaj), behavior: SnackBarBehavior.floating));
  }

  Future<bool> _onay(String baslik, String metin, String evet) async {
    final sonuc = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(baslik),
        content: Text(metin),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(evet)),
        ],
      ),
    );
    return sonuc == true;
  }

  Future<void> _yenile() async {
    final sabit = ref.read(programProvider).ayar?.sabitle == true;
    final onay = await _onay(
      'Program yeniden hazırlansın mı?',
      sabit
          ? 'Sabitlediğin program silinir ve konu durumuna göre bugünden itibaren yeniden hazırlanır. Elle eklediğin bloklar da değişir.'
          : 'Konu durumuna göre program bugünden itibaren yeniden hazırlanır. Elle eklediğin bloklar da değişir; geçmiş günler ve bugün tamamladığın bloklar korunur.',
      'Yeniden hazırla',
    );
    if (!onay) return;
    final ilk = await ref.read(programProvider.notifier).yenidenOlustur();
    _bildir(ilk > _bugun ? 'Bugün tamamlanan bloğun olduğu için yeni program yarından başlıyor.' : 'Program yeniden hazırlandı.');
  }

  Future<void> _ayarlariKaydet() async {
    final taslak = _taslak;
    if (taslak == null) return;
    final ilk = await ref.read(programProvider.notifier).ayarKaydet(taslak);
    if (!mounted) return;
    setState(() => _taslak = null);
    _bildir(
      ilk > _bugun
          ? 'Ayarlar kaydedildi; bugün tamamlanan blok olduğu için değişiklik yarından başlıyor.'
          : 'Ayarlar kaydedildi, programın güncellendi.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final program = ref.watch(programProvider);
    final profil = ref.watch(profilProvider).value;
    final c = context.colors;

    Widget govde;
    if (profil == null || !profil.onboardingTamamlandi) {
      govde = const Padding(
        padding: EdgeInsets.all(20),
        child: BosGrafikMesaji(metin: 'Ders programı için önce profilini (hedef alan, günlük süre, öğrenme metodu) tamamla.'),
      );
    } else if (!program.yuklendi) {
      govde = const Center(
        child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()),
      );
    } else {
      govde = TabBarView(
        controller: _sekme,
        children: [
          _gunlukSekmesi(context, program),
          _haftalikSekmesi(context, program),
          _kisisellestirSekmesi(context, program, profil.hedefBolum),
        ],
      );
    }

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: c.textPrimary),
        title: Text('Ders Programım', style: context.baslik(20)),
        actions: [
          IconButton(
            tooltip: 'Gelişim analizi',
            onPressed: () => context.push('/analiz'),
            icon: Icon(Icons.insights_rounded, color: c.textSecondary),
          ),
        ],
        bottom: TabBar(
          controller: _sekme,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800),
          tabs: const [Tab(text: 'Günlük'), Tab(text: 'Haftalık'), Tab(text: 'Kişiselleştir')],
        ),
      ),
      body: SafeArea(top: false, child: govde),
    );
  }

  // ═══ GÜNLÜK ═════════════════════════════════════════════════════════

  Widget _gunlukSekmesi(BuildContext context, ProgramState p) {
    final bugunMu = _seciliGun == _bugun;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        _haftaOzeti(context, p),
        const SizedBox(height: 12),
        _gunSecici(context, p),
        const SizedBox(height: 12),
        _gunPlani(context, p),
        if (bugunMu) ...[
          const SizedBox(height: 12),
          _checkinKarti(context),
        ],
      ],
    );
  }

  Widget _haftaOzeti(BuildContext context, ProgramState p) {
    final c = context.colors;
    final bas = p.haftaBaslangic ?? haftaBaslangici(DateTime.now());
    final bit = bas.add(const Duration(days: 6));
    var planDk = 0;
    var planBlok = 0;
    var bugunekadarBlok = 0;
    var bitenBlok = 0;
    for (var g = 0; g < 7; g++) {
      final bloklar = p.gunBloklari(g).where((b) => b.isCalismaBloku).toList();
      planDk += bloklar.fold(0, (t, b) => t + b.sure);
      planBlok += bloklar.length;
      if (g <= _bugun) {
        bugunekadarBlok += bloklar.length;
        bitenBlok += bloklar.where((b) => b.tamamlandi).length;
      }
    }
    final oran = bugunekadarBlok == 0 ? 0.0 : bitenBlok / bugunekadarBlok;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.feature, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${kisaTarih(bas)} – ${kisaTarih(bit)}',
                  style: TextStyle(color: c.onFeature.withValues(alpha: 0.8), fontWeight: FontWeight.w700),
                ),
              ),
              if (p.ayar?.sabitle == true)
                Row(
                  children: [
                    Icon(Icons.push_pin_rounded, size: 14, color: c.onFeature.withValues(alpha: 0.85)),
                    const SizedBox(width: 4),
                    Text('Sabit program', style: TextStyle(color: c.onFeature.withValues(alpha: 0.85), fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Bu hafta ${sureMetni(planDk)} · $planBlok blok', style: context.baslik(20, color: c.onFeature)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: oran,
              minHeight: 8,
              backgroundColor: c.onFeature.withValues(alpha: 0.18),
              color: c.accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            bugunekadarBlok == 0
                ? 'Bugüne kadar planlanmış blok yok'
                : 'Bugüne kadar $bitenBlok/$bugunekadarBlok blok tamamlandı (%${(oran * 100).round()})',
            style: TextStyle(color: c.onFeature.withValues(alpha: 0.85), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _gunSecici(BuildContext context, ProgramState p) {
    final bas = p.haftaBaslangic ?? haftaBaslangici(DateTime.now());
    return Row(
      children: [
        for (var g = 0; g < 7; g++) ...[if (g > 0) const SizedBox(width: 5), Expanded(child: _gunCipi(context, p, g, bas))],
      ],
    );
  }

  Widget _gunCipi(BuildContext context, ProgramState p, int g, DateTime bas) {
    final c = context.colors;
    final bloklar = p.gunBloklari(g).where((b) => b.isCalismaBloku).toList();
    final biten = bloklar.where((b) => b.tamamlandi).length;
    final secili = g == _seciliGun;
    final bugun = g == _bugun;
    final dk = bloklar.fold<int>(0, (t, b) => t + b.sure);
    return Semantics(
      button: true,
      selected: secili,
      label: '${gunAdlari[g]}, ${sureMetni(dk)}, ${bloklar.length} bloktan $biten tamamlandı',
      child: InkWell(
        onTap: () => setState(() => _seciliGun = g),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 80,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color: secili ? c.primary : c.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: secili ? c.primary : (bugun ? c.accent : c.border), width: bugun && !secili ? 2 : 1),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  gunKisaAdlari[g],
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: secili ? c.onPrimary : c.textPrimary),
                ),
                Text(
                  '${bas.add(Duration(days: g)).day}',
                  style: TextStyle(fontSize: 12, color: secili ? c.onPrimary.withValues(alpha: 0.85) : c.textMuted),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: bloklar.isEmpty
                      ? Icon(Icons.bedtime_outlined, size: 16, color: secili ? c.onPrimary : c.textMuted)
                      : CircularProgressIndicator(
                          value: biten / bloklar.length,
                          strokeWidth: 3,
                          backgroundColor: (secili ? c.onPrimary : c.border).withValues(alpha: 0.35),
                          color: secili ? c.onPrimary : c.success,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _gunPlani(BuildContext context, ProgramState p) {
    final c = context.colors;
    final g = _seciliGun;
    final bugunMu = g == _bugun;
    final gecmisMi = g < _bugun;
    final tarih = (p.haftaBaslangic ?? haftaBaslangici(DateTime.now())).add(Duration(days: g));
    List<PlanBlok> bloklar;
    var cikarilan = 0;
    if (bugunMu) {
      final plan = ref.watch(bugunPlaniProvider);
      bloklar = plan.bloklar;
      cikarilan = plan.cikarilan;
    } else {
      bloklar = p.gunBloklari(g);
    }
    final calismaDk = bloklar.where((b) => b.isCalismaBloku).fold(0, (t, b) => t + b.sure);

    return GrafikKarti(
      baslik: bugunMu ? 'Bugün · ${gunAdlari[g]}' : gunAdlari[g],
      aciklama: bloklar.isEmpty ? kisaTarih(tarih) : '${kisaTarih(tarih)} · ${bloklar.first.saatFormatli} başlangıç · ${sureMetni(calismaDk)} çalışma',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bloklar.isEmpty)
            BosGrafikMesaji(
              metin: gecmisMi
                  ? 'Bu gün için kayıtlı program yok.'
                  : 'Bu gün boş. “Blok ekle” ile kendi programını kurabilir ya da Kişiselleştir sekmesinden bu güne süre ayırabilirsin.',
            ),
          if (cikarilan > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(Icons.battery_charging_full_rounded, size: 18, color: c.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bugünkü enerji/stres durumuna göre $cikarilan blok çıkarıldı. Kendini iyi hissedersen aşağıdaki durumunu güncelleyebilirsin.',
                      style: TextStyle(fontSize: 12.5, color: c.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          for (final b in bloklar) _blokSatiri(context, b, g, tarih, bugunMu: bugunMu, gecmisMi: gecmisMi),
          if (!gecmisMi) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => _blokEkle(p, g),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Blok ekle'),
                ),
                if (p.hafta[g].isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _gunuKopyala(p, g),
                    icon: const Icon(Icons.copy_all_rounded, size: 18),
                    label: const Text('Günü kopyala'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _blokSatiri(BuildContext context, PlanBlok b, int g, DateTime tarih, {required bool bugunMu, required bool gecmisMi}) {
    final c = context.colors;
    final duzenlenebilir = !gecmisMi && !b.isEgzersiz;
    final menu = !duzenlenebilir
        ? null
        : PopupMenuButton<String>(
            tooltip: 'Bloğu düzenle ya da sil',
            icon: Icon(Icons.more_vert_rounded, size: 20, color: c.textMuted),
            padding: EdgeInsets.zero,
            onSelected: (v) => v == 'sil' ? ref.read(programProvider.notifier).blokSil(g, b.id) : _blokDuzenle(g, b),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'duzenle', child: Text('Düzenle')),
              PopupMenuItem(value: 'sil', child: Text('Sil')),
            ],
          );

    if (b.isMola) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(width: 46, child: Text(b.saatFormatli, style: TextStyle(fontSize: 11.5, color: c.textMuted))),
            Icon(Icons.coffee_rounded, size: 14, color: c.textMuted),
            const SizedBox(width: 6),
            Expanded(child: Text('${b.konu} · ${b.sure} dk', style: TextStyle(fontSize: 12, color: c.textMuted))),
            if (menu != null) SizedBox(height: 32, child: menu),
          ],
        ),
      );
    }
    final renk = b.ders == 'Deneme' ? c.info : b.blokRenk;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Text(b.saatFormatli, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c.textSecondary)),
          ),
          Container(width: 4, height: 44, decoration: BoxDecoration(color: renk, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.konu,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: b.tamamlandi ? c.textMuted : c.textPrimary,
                    decoration: b.tamamlandi ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if ((b.ders ?? '').isNotEmpty && b.ders != 'Psikoloji') dersKisaAdi(b.ders!),
                    b.tipEtiketi,
                    sureMetni(b.sure),
                  ].join(' · '),
                  style: TextStyle(fontSize: 12, color: c.textSecondary),
                ),
              ],
            ),
          ),
          if (bugunMu && !b.tamamlandi)
            IconButton(
              tooltip: b.isEgzersiz
                  ? 'Nefes egzersizini başlat'
                  : b.ders == 'Deneme'
                      ? 'Denemeyi başlat'
                      : 'Odak seansını başlat',
              visualDensity: VisualDensity.compact,
              icon: Icon(b.isEgzersiz ? Icons.self_improvement_rounded : Icons.play_circle_fill_rounded, color: c.primary, size: 30),
              onPressed: () => _baslat(b, tarih),
            ),
          if (bugunMu || gecmisMi)
            Checkbox(
              value: b.tamamlandi,
              visualDensity: VisualDensity.compact,
              onChanged: (_) {
                HapticFeedback.lightImpact();
                ref.read(programProvider.notifier).tamamlandiDegistir(b.id, gun: tarih);
              },
            ),
          ?menu,
        ],
      ),
    );
  }

  Future<void> _baslat(PlanBlok b, DateTime tarih) async {
    final program = ref.read(programProvider.notifier);
    if (b.isEgzersiz) {
      await showDialog(context: context, builder: (_) => const NefesEgzersiziDialog());
      await program.tamamlandiIsaretle(b.id);
      return;
    }
    if (b.ders == 'Deneme' && ref.read(sinifProvider) != null) {
      // 9-11. sınıflarda deneme uygulama içinde çözülür.
      context.push('/test-olustur?bolum=deneme');
      return;
    }
    final basladi = await ref.read(odakProvider.notifier).blokBaslat(
          blokId: b.id,
          blokGun: gunAnahtari(tarih),
          sureDk: b.sure,
          ders: (b.ders ?? '').isEmpty ? 'Genel' : b.ders!,
          baslik: b.konu,
        );
    if (!mounted) return;
    if (!basladi) {
      _bildir('Süren bir odak seansın var. Önce onu bitir ya da vazgeç.');
    }
    context.go('/calis');
  }

  Future<void> _blokEkle(ProgramState p, int g) async {
    final varsayilan = gunSonuDk(p.hafta[g]) ?? p.ayar?.gunler[g].baslangicDk ?? 17 * 60;
    final t = await blokSayfasiGoster(context, gunAdi: gunAdlari[g], varsayilanBaslangicDk: varsayilan);
    if (t == null) return;
    await ref.read(programProvider.notifier).blokEkle(g, ders: t.ders, konu: t.konu, sureDk: t.sureDk, tip: t.tip, baslangicDk: t.baslangicDk);
    _sabitlemeOner();
  }

  Future<void> _blokDuzenle(int g, PlanBlok b) async {
    final t = await blokSayfasiGoster(context, gunAdi: gunAdlari[g], varsayilanBaslangicDk: 17 * 60, mevcut: b);
    if (t == null) return;
    await ref.read(programProvider.notifier).blokGuncelle(g, b.id, ders: t.ders, konu: t.konu, sureDk: t.sureDk, tip: t.tip, baslangicDk: t.baslangicDk);
    _sabitlemeOner();
  }

  /// Elle düzenleme yapıldıktan sonra, program sabit değilse bir kez hatırlatır.
  void _sabitlemeOner() {
    if (!mounted || ref.read(programProvider).ayar?.sabitle == true) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        content: const Text('Blok kaydedildi. Bu düzen her hafta aynen kullanılsın istersen programı sabitle.'),
        action: SnackBarAction(
          label: 'Sabitle',
          onPressed: () => ref.read(programProvider.notifier).sabitle(true),
        ),
      ));
  }

  Future<void> _gunuKopyala(ProgramState p, int kaynak) async {
    final secili = <int>{};
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('${gunAdlari[kaynak]} programını kopyala'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Hangi günlere kopyalansın? Seçtiğin günlerin mevcut blokları silinir.'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (var g = _bugun; g < 7; g++)
                    if (g != kaynak)
                      FilterChip(
                        label: Text(gunKisaAdlari[g]),
                        selected: secili.contains(g),
                        onSelected: (v) => setS(() => v ? secili.add(g) : secili.remove(g)),
                      ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
            TextButton(onPressed: secili.isEmpty ? null : () => Navigator.pop(ctx, true), child: const Text('Kopyala')),
          ],
        ),
      ),
    );
    if (onay != true || secili.isEmpty) return;
    await ref.read(programProvider.notifier).gunuKopyala(kaynak, secili);
    _bildir('${gunAdlari[kaynak]} programı ${secili.length} güne kopyalandı.');
  }

  // ─── Günlük durum (check-in) ────────────────────────────────────────

  Widget _checkinKarti(BuildContext context) {
    final checkin = ref.watch(checkinProvider);
    return GrafikKarti(
      baslik: 'Bugün nasılsın?',
      aciklama: 'Enerjin düşük ya da stresin yüksekse bugünkü plan hafifletilir.',
      child: Column(
        children: [
          _checkinSatiri(context, checkin, 'Enerji', checkin.enerji, (v) => (v, checkin.odak, checkin.stres)),
          _checkinSatiri(context, checkin, 'Odak', checkin.odak, (v) => (checkin.enerji, v, checkin.stres)),
          _checkinSatiri(context, checkin, 'Stres', checkin.stres, (v) => (checkin.enerji, checkin.odak, v)),
        ],
      ),
    );
  }

  Widget _checkinSatiri(BuildContext context, GunlukCheckin checkin, String etiket, int deger, (int, int, int) Function(int) yeni) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 62, child: Text(etiket, style: TextStyle(fontWeight: FontWeight.w700, color: c.textPrimary))),
          for (var puan = 1; puan <= 5; puan++)
            Expanded(
              child: Semantics(
                button: true,
                selected: deger == puan,
                label: '$etiket $puan',
                excludeSemantics: true,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    final (e, o, s) = yeni(puan);
                    final messenger = ScaffoldMessenger.of(context);
                    await ref.read(checkinProvider.notifier).kaydetCheckin(enerji: e, odak: o, stres: s);
                    final kazanilan = await ref.read(bahceProvider.notifier).checkinDamlasi();
                    if (kazanilan > 0) {
                      messenger.showSnackBar(SnackBar(
                        content: Text('Günlük durumunu girdiğin için +$kazanilan su damlası kazandın!'),
                        behavior: SnackBarBehavior.floating,
                      ));
                    }
                  },
                  child: Container(
                    height: 36,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: deger == puan ? c.primary : c.background,
                      shape: BoxShape.circle,
                      border: Border.all(color: deger == puan ? c.primary : c.border),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$puan',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: deger == puan ? c.onPrimary : c.textSecondary),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══ HAFTALIK ═══════════════════════════════════════════════════════

  Widget _haftalikSekmesi(BuildContext context, ProgramState p) {
    final dagilim = programDersDagilimi(p.hafta);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        GrafikKarti(
          baslik: 'Haftalık tablo',
          aciklama: 'Her satır bir gün; renkler dersleri gösterir. Bir güne dokunarak ayrıntısını aç.',
          child: _haftalikTablo(context, p),
        ),
        const SizedBox(height: 14),
        GrafikKarti(
          baslik: 'Bu haftanın ders dağılımı',
          aciklama: 'Programda derslere ayrılan süre',
          child: DersDagilimGrafigi(dagilim: Map.fromEntries(dagilim.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))),
        ),
      ],
    );
  }

  Widget _haftalikTablo(BuildContext context, ProgramState p) {
    final c = context.colors;
    final enUzun = max(60, List.generate(7, (g) => p.hafta[g].fold<int>(0, (t, b) => t + b.sure)).reduce(max));
    return Column(
      children: [
        for (var g = 0; g < 7; g++)
          InkWell(
            onTap: () {
              setState(() => _seciliGun = g);
              _sekme.animateTo(0);
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                      gunKisaAdlari[g],
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: g == _bugun ? c.primary : c.textSecondary),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, k) {
                        final bloklar = p.gunBloklari(g);
                        if (bloklar.isEmpty) {
                          return Text('dinlenme', style: TextStyle(fontSize: 11.5, color: c.textMuted, fontStyle: FontStyle.italic));
                        }
                        return Row(
                          children: [
                            for (final b in bloklar)
                              Tooltip(
                                message: b.isMola ? 'Mola ${b.sure} dk' : '${b.saatFormatli} ${b.ders} · ${b.konu}',
                                child: Container(
                                  width: max(0.0, (k.maxWidth - bloklar.length) * b.sure / enUzun),
                                  height: 22,
                                  margin: const EdgeInsets.only(right: 1),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: b.isMola
                                        ? c.border.withValues(alpha: 0.5)
                                        : (b.ders == 'Deneme' ? c.info : b.blokRenk).withValues(alpha: b.tamamlandi ? 1 : 0.55),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: !b.isMola && k.maxWidth * b.sure / enUzun > 26
                                      ? Text(
                                          dersKisaAdi(b.ders ?? '').characters.take(3).toString(),
                                          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white),
                                        )
                                      : null,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: 58,
                    child: Text(
                      p.gunCalismaDk(g) == 0 ? '' : sureMetni(p.gunCalismaDk(g)),
                      textAlign: TextAlign.end,
                      style: TextStyle(fontSize: 11.5, color: c.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 14, color: c.textMuted),
            const SizedBox(width: 6),
            Expanded(
              child: Text('Koyu renkli bloklar tamamlananlar.', style: TextStyle(fontSize: 11.5, color: c.textMuted)),
            ),
          ],
        ),
      ],
    );
  }

  // ═══ KİŞİSELLEŞTİR ══════════════════════════════════════════════════

  Widget _kisisellestirSekmesi(BuildContext context, ProgramState p, String hedefBolum) {
    final ayar = _taslak ?? p.ayar!;
    final degisti = _taslak != null;
    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, degisti ? 110 : 40),
          children: [
            _hazirlamaKarti(context, p),
            const SizedBox(height: 14),
            _konuKarti(context, p, hedefBolum),
            const SizedBox(height: 14),
            _gunlerKarti(context, ayar),
            const SizedBox(height: 14),
            _derslerKarti(context, ayar, hedefBolum),
          ],
        ),
        if (degisti)
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: Material(
              elevation: 6,
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    TextButton(onPressed: () => setState(() => _taslak = null), child: const Text('Geri al')),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _ayarlariKaydet,
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('Kaydet ve programı güncelle'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 1 — Program nasıl hazırlansın: otomatik ya da sabit.
  Widget _hazirlamaKarti(BuildContext context, ProgramState p) {
    final c = context.colors;
    final sabit = p.ayar?.sabitle == true;

    Widget secenek(bool deger, IconData ikon, String baslik, String aciklama) {
      final secili = sabit == deger;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Semantics(
          button: true,
          selected: secili,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: secili
                ? null
                : () async {
                    await ref.read(programProvider.notifier).sabitle(deger);
                    _bildir(deger
                        ? 'Program sabitlendi: bu haftaki düzenin her hafta aynen kullanılacak.'
                        : 'Program otomatik: her hafta konu durumuna göre yeniden hazırlanacak.');
                  },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: secili ? c.primary.withValues(alpha: 0.10) : c.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: secili ? c.primary : c.border, width: secili ? 2 : 1),
              ),
              child: Row(
                children: [
                  Icon(ikon, color: secili ? c.primary : c.textMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(baslik, style: TextStyle(fontWeight: FontWeight.w800, color: c.textPrimary)),
                        const SizedBox(height: 2),
                        Text(aciklama, style: TextStyle(fontSize: 12.5, color: c.textMuted, height: 1.3)),
                      ],
                    ),
                  ),
                  if (secili) Icon(Icons.check_circle_rounded, color: c.primary),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return GrafikKarti(
      baslik: '1 · Programın nasıl hazırlansın?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          secenek(false, Icons.auto_awesome_rounded, 'Otomatik',
              'Her hafta konu durumuna (bitmemiş ve zayıf konular) göre yeniden hazırlanır. Blok ekleyip çıkarabilirsin; değişikliklerin o hafta için geçerlidir.'),
          secenek(true, Icons.push_pin_rounded, 'Sabit (kendi programım)',
              'Günlük sekmesinde blokları kendin eklediğin ve düzenlediğin program her hafta aynen yinelenir.'),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _yenile,
              icon: const Icon(Icons.autorenew_rounded, size: 18),
              label: const Text('Programı şimdi yeniden hazırla'),
            ),
          ),
        ],
      ),
    );
  }

  /// 2 — Programa girecek konular.
  Widget _konuKarti(BuildContext context, ProgramState p, String hedefBolum) {
    final c = context.colors;
    final tumu = alanKonulari(hedefBolum, ref.watch(konuProvider));
    final secili = programKonulari(hedefBolum, ref.watch(konuProvider), p.ayar!);
    final hepsi = p.ayar!.seciliKonuIdleri.isEmpty || secili.length == tumu.length;
    final dersSayisi = {for (final k in secili) k.ders}.length;

    return GrafikKarti(
      baslik: '2 · Hangi konuları çalışacaksın?',
      aciklama: 'Dersleri ve konuları tek tek seç; program yalnızca seçtiklerinden hazırlansın.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(hepsi ? Icons.select_all_rounded : Icons.checklist_rounded, color: c.gece ? c.accent : c.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hepsi ? 'Müfredatındaki tüm konular (${tumu.length} konu)' : '${secili.length} konu seçili · $dersSayisi ders',
                  style: TextStyle(fontWeight: FontWeight.w700, color: c.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => _konulariSec(p),
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Ders ders, konu konu seç'),
              ),
              if (!hepsi)
                TextButton(
                  onPressed: () async {
                    await ref.read(programProvider.notifier).konulariSec(const []);
                    _bildir('Program yeniden tüm konulardan hazırlandı.');
                  },
                  child: const Text('Tüm konulara dön'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _konulariSec(ProgramState p) async {
    final sonuc = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(builder: (_) => KonuSecimSayfasi(seciliIdler: p.ayar!.seciliKonuIdleri)),
    );
    if (sonuc == null || !mounted) return;
    if (p.ayar!.sabitle && !await _onay('Sabit program değişecek', 'Program seçtiğin konulardan yeniden hazırlanacak ve sabitlediğin düzenin yerini alacak.', 'Devam et')) {
      return;
    }
    final ilk = await ref.read(programProvider.notifier).konulariSec(sonuc);
    if (!mounted) return;
    _sekme.animateTo(0);
    _bildir(
      sonuc.isEmpty
          ? 'Program tüm konulardan hazırlandı.'
          : ilk > _bugun
              ? '${sonuc.length} konuyla program hazırlandı; bugün tamamlanan blok olduğu için yarından başlıyor.'
              : '${sonuc.length} konuyla programın hazırlandı.',
    );
  }

  /// 3 — Günler ve saatler.
  Widget _gunlerKarti(BuildContext context, DersProgramiAyar ayar) {
    void guncelle(DersProgramiAyar yeni) => setState(() => _taslak = yeni);
    return GrafikKarti(
      baslik: '3 · Günlerin ve saatlerin',
      aciklama: 'Haftalık toplam ${sureMetni(ayar.haftalikDk)} · ${ayar.aktifGunSayisi} gün. Süreye molalar dahildir.',
      child: Column(
        children: [
          for (var g = 0; g < 7; g++) _gunAyariSatiri(context, g, ayar.gunler[g], (yeni) => guncelle(ayar.gunGuncelle(g, yeni))),
        ],
      ),
    );
  }

  /// 4 — Ders öncelikleri ve deneme.
  Widget _derslerKarti(BuildContext context, DersProgramiAyar ayar, String hedefBolum) {
    final c = context.colors;
    final dersler = alanDersleri(hedefBolum, ref.watch(konuProvider));
    final sinif = ref.watch(sinifProvider);
    void guncelle(DersProgramiAyar yeni) => setState(() => _taslak = yeni);

    return GrafikKarti(
      baslik: '4 · Ders öncelikleri',
      aciklama: 'Bir derse dokunarak durumunu değiştir: normal → öncelikli → programa alma.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in dersler)
                () {
                  final oncelikli = ayar.oncelikliDersler.contains(d);
                  final haric = ayar.haricDersler.contains(d);
                  return Semantics(
                    button: true,
                    label: '$d: ${oncelikli ? 'öncelikli' : haric ? 'programa alınmıyor' : 'normal'}',
                    excludeSemantics: true,
                    child: ActionChip(
                      avatar: Icon(
                        oncelikli ? Icons.star_rounded : (haric ? Icons.block_rounded : Icons.circle_outlined),
                        size: 18,
                        color: oncelikli ? c.warning : (haric ? c.danger : c.textMuted),
                      ),
                      label: Text(
                        dersKisaAdi(d),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: haric ? c.textMuted : c.textPrimary,
                          decoration: haric ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      onPressed: () {
                        final onc = ayar.oncelikliDersler.where((x) => x != d).toList();
                        final har = ayar.haricDersler.where((x) => x != d).toList();
                        if (!oncelikli && !haric) {
                          onc.add(d);
                        } else if (oncelikli) {
                          if (har.length + 1 >= dersler.length) {
                            _bildir('En az bir ders programda kalmalı.');
                          } else {
                            har.add(d);
                          }
                        }
                        guncelle(ayar.copyWith(oncelikliDersler: onc, haricDersler: har));
                      },
                    ),
                  );
                }(),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              _lejant(Icons.star_rounded, c.warning, 'Öncelikli'),
              _lejant(Icons.circle_outlined, c.textMuted, 'Normal'),
              _lejant(Icons.block_rounded, c.danger, 'Programa alınmıyor'),
            ],
          ),
          if (hedefBolum != serbestAlan) ...[
            const Divider(height: 28),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pazar deneme sınavı', style: TextStyle(fontWeight: FontWeight.w700, color: c.textPrimary)),
                      Text(
                        sinif != null ? 'Pazar günü başa $sinif. sınıf genel denemesi eklenir.' : 'Pazar günü başa TYT/AYT denemesi eklenir (dönüşümlü).',
                        style: TextStyle(fontSize: 12, color: c.textMuted),
                      ),
                    ],
                  ),
                ),
                Switch(value: ayar.pazarDeneme, onChanged: (v) => guncelle(ayar.copyWith(pazarDeneme: v))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _lejant(IconData ikon, Color renk, String metin) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: 15, color: renk),
          const SizedBox(width: 4),
          Text(metin, style: TextStyle(fontSize: 12, color: context.colors.textMuted)),
        ],
      );

  Widget _gunAyariSatiri(BuildContext context, int g, GunAyari gun, ValueChanged<GunAyari> degis) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(gunKisaAdlari[g], style: TextStyle(fontWeight: FontWeight.w800, color: gun.aktif ? c.textPrimary : c.textMuted)),
          ),
          Switch(value: gun.aktif, onChanged: (v) => degis(gun.copyWith(aktif: v))),
          const SizedBox(width: 4),
          Expanded(
            child: gun.aktif
                ? Row(
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10), minimumSize: const Size(0, 40)),
                        onPressed: () async {
                          final secim = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(hour: gun.baslangicDk ~/ 60, minute: gun.baslangicDk % 60),
                            helpText: '${gunAdlari[g]} başlangıç saati',
                          );
                          if (secim != null) degis(gun.copyWith(baslangicDk: secim.hour * 60 + secim.minute));
                        },
                        child: Text(saatMetni(gun.baslangicDk)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _sureSec(context, g, gun, degis),
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(border: Border.all(color: c.border), borderRadius: BorderRadius.circular(10)),
                            child: Row(
                              children: [
                                Expanded(child: Text(sureMetni(gun.sureDk), style: TextStyle(fontWeight: FontWeight.w700, color: c.textPrimary))),
                                Icon(Icons.expand_more_rounded, size: 18, color: c.textMuted),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Text('Dinlenme günü', style: TextStyle(color: c.textMuted, fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }

  Future<void> _sureSec(BuildContext context, int g, GunAyari gun, ValueChanged<GunAyari> degis) async {
    var deger = gun.sureDk.toDouble().clamp(30, 600).toDouble();
    final sonuc = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${gunAdlari[g]} için çalışma süresi', style: ctx.baslik(18)),
                const SizedBox(height: 4),
                Text(
                  'Molalar dahil toplam süre. Blok sayısı öğrenme metoduna göre hesaplanır.',
                  style: TextStyle(fontSize: 12.5, color: ctx.colors.textMuted),
                ),
                const SizedBox(height: 12),
                Center(child: Text(sureMetni(deger.round()), style: ctx.baslik(26))),
                Slider(
                  value: deger,
                  min: 30,
                  max: 600,
                  divisions: 38,
                  label: sureMetni(deger.round()),
                  onChanged: (v) => setS(() => deger = v),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(onPressed: () => Navigator.pop(ctx, deger.round()), child: const Text('Tamam')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (sonuc != null) degis(gun.copyWith(sureDk: sonuc));
  }
}
