/// Ders Programım — haftalık saatli ders programı: gün gün bloklar,
/// tamamlama işaretleme, haftalık tablo görünümü, ders dağılımı ve
/// programı kişiselleştirme (gün başına saat/süre, öncelikli/hariç dersler,
/// Pazar deneme sınavı).
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

import '../../../core/algorithms/ders_programi.dart';
import '../../../core/utils/tarih.dart';
import '../../../data/models/plan_blok.dart';
import '../../providers/konu_provider.dart';
import '../../providers/plan_provider.dart';
import '../../providers/profil_provider.dart';
import '../../widgets/grafikler.dart';
import '../../widgets/nefes_egzersizi_dialog.dart';
import '../../widgets/pomodoro_dialog.dart';

class DersProgramiScreen extends ConsumerStatefulWidget {
  const DersProgramiScreen({super.key});

  @override
  ConsumerState<DersProgramiScreen> createState() => _DersProgramiScreenState();
}

class _DersProgramiScreenState extends ConsumerState<DersProgramiScreen> {
  int _seciliGun = DateTime.now().weekday - 1;
  DersProgramiAyar? _taslak;
  final _ayarAnahtari = GlobalKey();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(programProvider.notifier).hazirla());
  }

  int get _bugun => DateTime.now().weekday - 1;

  Future<void> _bildir(String mesaj) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj), behavior: SnackBarBehavior.floating));
  }

  Future<void> _yenile() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Programı yenile'),
        content: const Text(
          'Konu durumuna göre program bugünden itibaren yeniden hazırlanır. Geçmiş günler ve bugün tamamladığın bloklar korunur.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yenile')),
        ],
      ),
    );
    if (onay != true) return;
    final ilk = await ref.read(programProvider.notifier).yenidenOlustur();
    _bildir(ilk > _bugun ? 'Bugün tamamlanan bloğun olduğu için yeni program yarından başlıyor.' : 'Program yenilendi.');
  }

  Future<void> _ayarlariKaydet() async {
    final taslak = _taslak;
    if (taslak == null) return;
    final ilk = await ref.read(programProvider.notifier).ayarKaydet(taslak);
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
      final ayar = _taslak ?? program.ayar!;
      govde = ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        children: [
          _haftaOzeti(context, program),
          const SizedBox(height: 14),
          _gunSecici(context, program),
          const SizedBox(height: 12),
          _gunPlani(context, program),
          const SizedBox(height: 14),
          GrafikKarti(
            baslik: 'Haftalık tablo',
            aciklama: 'Her satır bir gün; renkler dersleri gösterir. Bir güne dokunarak ayrıntısını aç.',
            child: _haftalikTablo(context, program),
          ),
          const SizedBox(height: 14),
          GrafikKarti(
            baslik: 'Bu haftanın ders dağılımı',
            aciklama: 'Programda derslere ayrılan süre',
            child: DersDagilimGrafigi(dagilim: _sirali(programDersDagilimi(program.hafta))),
          ),
          const SizedBox(height: 14),
          KeyedSubtree(key: _ayarAnahtari, child: _ayarlar(context, ayar, profil.hedefBolum)),
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
          IconButton(
            tooltip: 'Program ayarları',
            onPressed: () {
              final ctx = _ayarAnahtari.currentContext;
              if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 350));
            },
            icon: Icon(Icons.tune_rounded, color: c.textSecondary),
          ),
          IconButton(
            tooltip: 'Programı yenile',
            onPressed: program.yuklendi ? _yenile : null,
            icon: Icon(Icons.autorenew_rounded, color: c.textSecondary),
          ),
        ],
      ),
      body: SafeArea(top: false, child: govde),
    );
  }

  Map<String, int> _sirali(Map<String, int> m) => Map.fromEntries(m.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));

  // ─── Özet ───────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: c.feature, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${kisaTarih(bas)} – ${kisaTarih(bit)}',
            style: TextStyle(color: c.onFeature.withValues(alpha: 0.8), fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text('Bu hafta ${sureMetni(planDk)} · $planBlok blok', style: context.baslik(21, color: c.onFeature)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: oran,
              minHeight: 9,
              backgroundColor: c.onFeature.withValues(alpha: 0.18),
              color: c.accent,
            ),
          ),
          const SizedBox(height: 8),
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

  // ─── Gün seçici ─────────────────────────────────────────────────────

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
          height: 84,
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

  // ─── Seçili günün planı ─────────────────────────────────────────────

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

    return GrafikKarti(
      baslik: bugunMu ? 'Bugün · ${gunAdlari[g]}' : gunAdlari[g],
      aciklama: bloklar.isEmpty
          ? null
          : '${kisaTarih(tarih)} · ${bloklar.first.saatFormatli} başlangıç · ${sureMetni(bloklar.where((b) => b.isCalismaBloku).fold(0, (t, b) => t + b.sure))} çalışma',
      child: Column(
        children: [
          if (bloklar.isEmpty)
            BosGrafikMesaji(
              metin: g < _bugun && p.hafta[g].isEmpty
                  ? 'Bu gün program oluşturulmadan önceydi.'
                  : 'Bu gün dinlenme günü. Program ayarlarından bu güne süre ekleyebilirsin.',
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
                      'Bugünkü enerji/stres durumuna göre $cikarilan blok çıkarıldı. Kendini iyi hissedersen check-in\'i güncelleyebilirsin.',
                      style: TextStyle(fontSize: 12.5, color: c.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          for (final b in bloklar) _blokSatiri(context, b, tarih, isaretlenebilir: bugunMu || gecmisMi, bugunMu: bugunMu),
        ],
      ),
    );
  }

  Widget _blokSatiri(BuildContext context, PlanBlok b, DateTime tarih, {required bool isaretlenebilir, required bool bugunMu}) {
    final c = context.colors;
    if (b.isMola) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 46,
              child: Text(b.saatFormatli, style: TextStyle(fontSize: 11.5, color: c.textMuted)),
            ),
            Icon(Icons.coffee_rounded, size: 14, color: c.textMuted),
            const SizedBox(width: 6),
            Text('${b.konu} · ${b.sure} dk', style: TextStyle(fontSize: 12, color: c.textMuted)),
          ],
        ),
      );
    }
    final renk = b.ders == 'Deneme' ? c.info : b.blokRenk;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Text(
              b.saatFormatli,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c.textSecondary),
            ),
          ),
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(color: renk, borderRadius: BorderRadius.circular(2)),
          ),
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
              tooltip: b.isEgzersiz ? 'Nefes egzersizini başlat' : 'Odak zamanlayıcısını başlat',
              icon: Icon(b.isEgzersiz ? Icons.self_improvement_rounded : Icons.play_circle_fill_rounded, color: c.primary, size: 30),
              onPressed: () => _baslat(b),
            ),
          if (isaretlenebilir)
            Checkbox(
              value: b.tamamlandi,
              onChanged: (_) {
                HapticFeedback.lightImpact();
                ref.read(programProvider.notifier).tamamlandiDegistir(b.id, gun: tarih);
              },
            )
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(Icons.schedule_rounded, size: 20, color: c.textMuted),
            ),
        ],
      ),
    );
  }

  void _baslat(PlanBlok b) {
    if (b.isEgzersiz) {
      showDialog(context: context, builder: (_) => const NefesEgzersiziDialog()).then((_) {
        ref.read(programProvider.notifier).tamamlandiIsaretle(b.id);
      });
      return;
    }
    final notifier = ref.read(programProvider.notifier);
    showDialog(
      context: context,
      builder: (_) => PomodoroDialog(
        konuBasligi: '${b.ders ?? ''} - ${b.konu}',
        sureDakika: b.sure,
        ders: b.ders,
        onTamamlandi: (dk) {
          if (dk >= (b.sure * 0.6).round()) notifier.tamamlandiIsaretle(b.id);
        },
      ),
    );
  }

  // ─── Haftalık tablo ─────────────────────────────────────────────────

  Widget _haftalikTablo(BuildContext context, ProgramState p) {
    final c = context.colors;
    final enUzun = max(60, List.generate(7, (g) => p.hafta[g].fold<int>(0, (t, b) => t + b.sure)).reduce(max));
    return Column(
      children: [
        for (var g = 0; g < 7; g++)
          InkWell(
            onTap: () => setState(() => _seciliGun = g),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                      gunKisaAdlari[g],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: g == _seciliGun ? FontWeight.w900 : FontWeight.w700,
                        color: g == _bugun ? c.primary : c.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, k) {
                        final bloklar = p.gunBloklari(g);
                        if (bloklar.isEmpty) {
                          return Text(
                            'dinlenme',
                            style: TextStyle(fontSize: 11.5, color: c.textMuted, fontStyle: FontStyle.italic),
                          );
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

  // ─── Ayarlar ────────────────────────────────────────────────────────

  Widget _ayarlar(BuildContext context, DersProgramiAyar ayar, String hedefBolum) {
    final c = context.colors;
    final dersler = alanDersleri(hedefBolum, ref.watch(konuProvider));
    final degisti = _taslak != null;

    void guncelle(DersProgramiAyar yeni) => setState(() => _taslak = yeni);

    return GrafikKarti(
      baslik: 'Program ayarları',
      aciklama: 'Haftalık toplam ${sureMetni(ayar.haftalikDk)} · ${ayar.aktifGunSayisi} gün',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var g = 0; g < 7; g++) _gunAyariSatiri(context, g, ayar.gunler[g], (yeni) => guncelle(ayar.gunGuncelle(g, yeni))),
          const SizedBox(height: 12),
          Text(
            'Öncelik vermek istediğin dersler',
            style: TextStyle(fontWeight: FontWeight.w800, color: c.textPrimary),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final d in dersler)
                FilterChip(
                  label: Text(dersKisaAdi(d)),
                  selected: ayar.oncelikliDersler.contains(d),
                  onSelected: (s) => guncelle(
                    ayar.copyWith(
                      oncelikliDersler: s ? [...ayar.oncelikliDersler, d] : ayar.oncelikliDersler.where((x) => x != d).toList(),
                      haricDersler: ayar.haricDersler.where((x) => x != d).toList(),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Programa alınmayacak dersler',
            style: TextStyle(fontWeight: FontWeight.w800, color: c.textPrimary),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final d in dersler)
                FilterChip(
                  label: Text(dersKisaAdi(d)),
                  selected: ayar.haricDersler.contains(d),
                  onSelected: (s) {
                    final haric = s ? [...ayar.haricDersler, d] : ayar.haricDersler.where((x) => x != d).toList();
                    if (haric.length >= dersler.length) {
                      _bildir('En az bir ders programda kalmalı.');
                      return;
                    }
                    guncelle(ayar.copyWith(haricDersler: haric, oncelikliDersler: ayar.oncelikliDersler.where((x) => x != d).toList()));
                  },
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (hedefBolum != serbestAlan)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Pazar deneme sınavı',
                style: TextStyle(fontWeight: FontWeight.w700, color: c.textPrimary),
              ),
              subtitle: Text('Pazar günü başa TYT/AYT denemesi eklenir (dönüşümlü).', style: TextStyle(fontSize: 12, color: c.textMuted)),
              value: ayar.pazarDeneme,
              onChanged: (v) => guncelle(ayar.copyWith(pazarDeneme: v)),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: degisti ? _ayarlariKaydet : null,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Kaydet ve programı güncelle', textAlign: TextAlign.center),
            ),
          ),
          if (degisti)
            Center(
              child: TextButton(onPressed: () => setState(() => _taslak = null), child: const Text('Değişiklikleri geri al')),
            ),
        ],
      ),
    );
  }

  Widget _gunAyariSatiri(BuildContext context, int g, GunAyari gun, ValueChanged<GunAyari> degis) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              gunKisaAdlari[g],
              style: TextStyle(fontWeight: FontWeight.w800, color: gun.aktif ? c.textPrimary : c.textMuted),
            ),
          ),
          Switch(
            value: gun.aktif,
            onChanged: (v) => degis(gun.copyWith(aktif: v)),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: gun.aktif
                ? Row(
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          minimumSize: const Size(0, 40),
                        ),
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
                            decoration: BoxDecoration(
                              border: Border.all(color: c.border),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    sureMetni(gun.sureDk),
                                    style: TextStyle(fontWeight: FontWeight.w700, color: c.textPrimary),
                                  ),
                                ),
                                Icon(Icons.expand_more_rounded, size: 18, color: c.textMuted),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Dinlenme günü',
                    style: TextStyle(color: c.textMuted, fontStyle: FontStyle.italic),
                  ),
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
