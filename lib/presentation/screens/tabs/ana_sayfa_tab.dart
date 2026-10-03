import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/algorithms/ders_programi.dart' show alanKonulari;
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/tarih.dart';
import '../../../data/models/konu.dart';
import '../../../data/models/plan_blok.dart';
import '../../providers/analiz_provider.dart';
import '../../providers/bahce_provider.dart';
import '../../providers/konu_provider.dart';
import '../../providers/mufredat_provider.dart';
import '../../providers/net_provider.dart';
import '../../providers/plan_provider.dart';
import '../../providers/profil_provider.dart';
import '../../providers/role_provider.dart';
import '../../widgets/grafikler.dart';
import '../../widgets/ilham_bandi.dart';
import '../../widgets/ui_kit.dart';
import '../../cizimler/cizim_widgetlari.dart';
import '../../cizimler/sahne_boyaci.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

class AnaSayfaTab extends ConsumerWidget {
  const AnaSayfaTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(profilProvider).value;
    final kullanici = ref.watch(currentUserProfileProvider).value;
    final bahce = ref.watch(bahceProvider);
    final hafta = ref.watch(donemAnaliziProvider(7));
    final ad = kullanici?.name.split(' ').first ?? '';
    final geriSayim = ref.watch(hedefGeriSayimProvider);
    final hedefMetni = profil?.hedefUniversite?.isNotEmpty == true ? profil!.hedefUniversite! : (profil?.hedefBolumEtiketi ?? '');

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(bahceProvider.notifier).yildizYenile();
            await ref.read(netProvider.notifier).loadNetKayitlari();
            ref.invalidate(analizGirdisiProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ad.isEmpty ? _selam() : '${_selam()}, $ad',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.baslik(27)),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (hedefMetni.isNotEmpty) hedefMetni,
                            if (geriSayim != null) '${geriSayim.$1}: ${geriSayim.$2} gün',
                          ].join('  ·  '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13.5, color: context.colors.textSecondary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Ayarlar',
                    onPressed: () => context.push('/ayarlar'),
                    icon: Icon(Icons.settings_outlined, color: context.colors.textSecondary),
                  ),
                  InkWell(
                    onTap: () => context.push('/profil'),
                    customBorder: const CircleBorder(),
                    child: Semantics(
                      label: 'Profil ve destek',
                      button: true,
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: context.colors.primarySoft,
                        child: ad.isEmpty
                            ? Icon(Icons.person_rounded, color: context.colors.primary)
                            : Text(ad.characters.first.toUpperCase(), style: context.baslik(19, color: context.colors.gece ? context.colors.accent : context.colors.primary)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const IlhamBandi(),
              const SizedBox(height: 14),
              Row(
                children: [
                  _ozet(context, const YildizIkon(boyut: 22), '${bahce.yildiz}', 'yıldız', () => context.go('/bahce')),
                  const SizedBox(width: 10),
                  _ozet(
                    context,
                    Icon(Icons.timer_outlined, size: 22, color: context.colors.primary),
                    sureMetni(hafta?.toplamDk ?? 0),
                    'bu hafta',
                    () => context.push('/analiz'),
                  ),
                  const SizedBox(width: 10),
                  _ozet(context, const AlevIkon(boyut: 22), '${hafta?.seri ?? profil?.streak ?? 0}', context.colors.gece ? 'gece seri' : 'gün seri', null),
                ],
              ),
              const SizedBox(height: 20),
              const _BugunKarti(),
              const SizedBox(height: 12),
              const _SiradakiBloklar(),
              const SizedBox(height: 20),
              BolumBasligi('Bu haftanın gidişatı', aksiyon: 'Analiz', onAksiyon: () => context.push('/analiz')),
              const _HaftaGidisati(),
              const _KocNotlari(),
              const SizedBox(height: 20),
              BolumBasligi('Konu ilerlemen', aksiyon: 'Tümü', onAksiyon: () => context.push('/konular')),
              _KonuIlerleme(hedefBolum: profil?.hedefBolum ?? 'sayisal'),
              const SizedBox(height: 20),
              BolumBasligi('Sınav gelişimi', aksiyon: 'Sonuçlar', onAksiyon: () => context.push('/netler')),
              const _NetGrafigi(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _hizli(context, Icons.edit_note_rounded, 'Test çöz', () => context.push('/test-olustur'))),
                  const SizedBox(width: 8),
                  Expanded(child: _hizli(context, Icons.add_chart_rounded, 'Deneme', () => context.push('/netler'))),
                  const SizedBox(width: 8),
                  Expanded(child: _hizli(context, Icons.calendar_month_rounded, 'Program', () => context.push('/program'))),
                  const SizedBox(width: 8),
                  Expanded(child: _hizli(context, Icons.insights_rounded, 'Analiz', () => context.push('/analiz'))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _selam() {
    final h = DateTime.now().hour;
    if (h < 5) return 'İyi geceler';
    if (h < 12) return 'Günaydın';
    if (h < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }

  Widget _ozet(BuildContext context, Widget ikon, String deger, String etiket, VoidCallback? onTap) {
    return Expanded(
      child: YumusakKart(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Column(
          children: [
            ikon,
            const SizedBox(height: 6),
            FittedBox(
              child: Text(deger, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: context.colors.textPrimary)),
            ),
            Text(etiket, style: TextStyle(fontSize: 11.5, color: context.colors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _hizli(BuildContext context, IconData ikon, String etiket, VoidCallback onTap) {
    return YumusakKart(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          Icon(ikon, size: 24, color: context.colors.gece ? context.colors.accent : context.colors.primary),
          const SizedBox(height: 6),
          Text(etiket, maxLines: 1, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: context.colors.textPrimary)),
        ],
      ),
    );
  }
}

class _BugunKarti extends ConsumerWidget {
  const _BugunKarti();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bloklar = ref.watch(gunlukPlanProvider).where((b) => !b.isMola).toList();
    final biten = bloklar.where((b) => b.tamamlandi).length;
    final siradaki = bloklar.where((b) => !b.tamamlandi).firstOrNull;
    final oran = bloklar.isEmpty ? 0.0 : biten / bloklar.length;

    final c = context.colors;
    final sirada = siradaki == null
        ? (bloklar.isEmpty ? 'Bugün dinlenme günü ya da programın hazırlanıyor.' : 'Bugünün tüm blokları tamam!')
        : 'Sırada ${siradaki.saatFormatli}: ${siradaki.konu} (${siradaki.sure} dk)';

    if (c.gece) {
      return YumusakKart(
        onTap: () => context.push('/plan'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Bugünün takımyıldızı', style: context.baslik(19))),
                Text('$biten / ${bloklar.length} blok', style: TextStyle(color: c.accent, fontWeight: FontWeight.w800, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Semantics(
              label: '${bloklar.length} plan bloğundan $biten tanesi tamamlandı',
              child: SizedBox(
                height: 86,
                width: double.infinity,
                child: HareketliSahne(
                  dongu: const Duration(seconds: 8),
                  boyaci: (t) => TakimyildizBoyaci(
                    toplam: bloklar.length,
                    biten: biten,
                    t: t,
                    yanik: c.accent,
                    sirada: c.primary,
                    sonuk: c.border,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(sirada, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, color: c.textSecondary)),
          ],
        ),
      );
    }

    return YumusakKart(
      onTap: () => context.push('/plan'),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: oran),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, _) => CircularProgressIndicator(
                      value: v,
                      strokeWidth: 7,
                      strokeCap: StrokeCap.round,
                      backgroundColor: c.border,
                      color: c.success,
                    ),
                  ),
                ),
                Text('$biten/${bloklar.length}', style: TextStyle(fontWeight: FontWeight.w800, color: c.textPrimary)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bugünkü planın', style: context.baslik(18)),
                const SizedBox(height: 4),
                Text(sirada, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, color: c.textSecondary, height: 1.35)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: c.textMuted),
        ],
      ),
    );
  }
}

/// Programdan bugünün sıradaki (tamamlanmamış) blokları — saatli zaman çizelgesi.
class _SiradakiBloklar extends ConsumerWidget {
  const _SiradakiBloklar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final kalan = ref.watch(gunlukPlanProvider).where((b) => b.isCalismaBloku && !b.tamamlandi).take(3).toList();
    if (kalan.isEmpty) return const SizedBox.shrink();
    return YumusakKart(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      onTap: () => context.push('/program'),
      child: Column(
        children: [
          for (final PlanBlok b in kalan)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(width: 46, child: Text(b.saatFormatli, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: c.textSecondary))),
                  Container(
                    width: 4,
                    height: 30,
                    decoration: BoxDecoration(color: b.ders == 'Deneme' ? c.info : b.blokRenk, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.konu, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, color: c.textPrimary)),
                        Text('${dersKisaAdi(b.ders ?? '')} · ${b.tipEtiketi} · ${b.sure} dk', style: TextStyle(fontSize: 11.5, color: c.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => context.push('/program'),
              icon: const Icon(Icons.calendar_month_rounded, size: 18),
              label: const Text('Haftalık programım'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Son 7 günün çalışma çubukları + hedef çizgisi ve hafta özeti.
class _HaftaGidisati extends ConsumerWidget {
  const _HaftaGidisati();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final a = ref.watch(donemAnaliziProvider(7));
    if (a == null) {
      return const YumusakKart(child: SizedBox(height: 120, child: Center(child: CircularProgressIndicator())));
    }
    final degisim = a.calismaDegisimYuzde;
    final uyum = a.planUyumu;

    Widget istatistik(String deger, String etiket, {Color? renk}) => Expanded(
          child: Column(
            children: [
              Text(deger, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: renk ?? c.textPrimary)),
              const SizedBox(height: 2),
              Text(etiket, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: c.textMuted)),
            ],
          ),
        );

    return YumusakKart(
      onTap: () => context.push('/analiz'),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      child: Column(
        children: [
          CalismaCubukGrafigi(gunler: a.gunler, dakikalar: a.gunlukDk, hedefDk: a.hedefDk, yukseklik: 140),
          const SizedBox(height: 12),
          Row(
            children: [
              istatistik('${a.aktifGun}/7', 'aktif gün'),
              istatistik(uyum == null ? '—' : '%${(uyum * 100).round()}', 'plan uyumu',
                  renk: uyum == null ? null : (uyum >= 0.7 ? c.success : (uyum >= 0.4 ? c.warning : c.danger))),
              istatistik(
                degisim == null ? '—' : '${degisim >= 0 ? '+' : ''}${degisim.round()}%',
                'geçen haftaya göre',
                renk: degisim == null ? null : (degisim >= 0 ? c.success : c.danger),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Analiz motorunun ürettiği en önemli iki içgörü.
class _KocNotlari extends ConsumerWidget {
  const _KocNotlari();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(donemAnaliziProvider(30));
    final notlar = a?.icgoruler.take(2).toList() ?? const [];
    if (notlar.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: YumusakKart(
        onTap: () => context.push('/analiz'),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
        child: Column(children: [for (final n in notlar) IcgoruSatiri(icgoru: n)]),
      ),
    );
  }
}

class _KonuIlerleme extends ConsumerWidget {
  final String hedefBolum;

  const _KonuIlerleme({required this.hedefBolum});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final konular = alanKonulari(hedefBolum, ref.watch(konuProvider));
    // Hazır dersler alanıyla ("TYT Matematik"), eklenen dersler yalnız adıyla.
    final gruplar = <(String, String), List<Konu>>{};
    for (final k in konular) {
      gruplar.putIfAbsent((k.ozel ? '' : k.alan.name, k.ders), () => []).add(k);
    }
    final secilen = gruplar.entries.toList();
    if (secilen.isEmpty) {
      return YumusakKart(
        onTap: () => context.push('/mufredat'),
        child: Row(
          children: [
            Icon(Icons.playlist_add_rounded, size: 30, color: context.colors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Müfredatında ders yok. Ders ve konularını ekle; programın ve ilerlemen buna göre oluşsun.',
                  style: TextStyle(color: context.colors.textSecondary, height: 1.35)),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: secilen.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final e = secilen[i];
          final toplam = e.value.length;
          final biten = e.value.where((k) => k.tamamlandi).length;
          final zayif = e.value.where((k) => k.zayif).length;
          final oran = toplam == 0 ? 0.0 : biten / toplam;
          final renk = dersRengi(e.key.$2);
          return SizedBox(
            width: 112,
            child: YumusakKart(
              onTap: () => context.push('/konular'),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: oran,
                            strokeWidth: 6,
                            strokeCap: StrokeCap.round,
                            backgroundColor: renk.withValues(alpha: 0.15),
                            color: renk,
                          ),
                        ),
                        Text('%${(oran * 100).round()}',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: context.colors.textPrimary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${e.key.$1} ${dersKisaAdi(e.key.$2)}'.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.colors.textPrimary),
                  ),
                  Text(zayif > 0 ? '$zayif zayıf konu' : '$biten/$toplam konu',
                      style: TextStyle(fontSize: 11, color: zayif > 0 ? context.colors.warning : context.colors.textMuted)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NetGrafigi extends ConsumerWidget {
  const _NetGrafigi();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(donemAnaliziProvider(7));
    final serbest = ref.watch(serbestModProvider);
    if (a == null) return const SizedBox.shrink();
    final tyt = a.tyt;

    if (tyt.bos && a.ayt.bos) {
      return YumusakKart(
        onTap: () => context.push('/netler'),
        child: Row(
          children: [
            Icon(Icons.show_chart_rounded, size: 32, color: context.colors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(serbest ? 'İlk sınav sonucunu ekle; puan gelişimin burada çizilsin.' : 'İlk denemeni ekle; TYT ve AYT net gelişimin burada çizilsin.',
                  style: TextStyle(color: context.colors.textSecondary, height: 1.35)),
            ),
          ],
        ),
      );
    }

    final egilim = tyt.noktalar.length >= 3
        ? '${serbest ? 'Sınav' : 'TYT'} eğilimin ${serbest ? 'sınav' : 'deneme'} başına ${tyt.egim >= 0 ? '+' : ''}${tyt.egim.toStringAsFixed(1)} ${serbest ? 'puan' : 'net'} · en iyi ${tyt.enIyi.toStringAsFixed(1)}'
        : 'Eğilim için en az 3 ${serbest ? 'sınav' : 'deneme'} gerekli.';

    return YumusakKart(
      onTap: () => context.push('/analiz'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NetGelisimGrafigi(tyt: tyt, ayt: a.ayt, yukseklik: 160, serbest: serbest),
          const SizedBox(height: 8),
          Text(egilim, style: TextStyle(fontSize: 12, color: context.colors.textMuted)),
        ],
      ),
    );
  }
}
