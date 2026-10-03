import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/tarih.dart';
import '../../providers/profil_provider.dart';
import '../../providers/bahce_provider.dart';
import '../../providers/checkin_provider.dart';
import '../../providers/plan_provider.dart';
import '../../widgets/pomodoro_dialog.dart';
import '../../widgets/nefes_egzersizi_dialog.dart';
import '../../widgets/empty_state_widget.dart';
import '../../../data/models/plan_blok.dart';
import '../../../core/constants/app_constants.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

class GunlukPlanTab extends ConsumerWidget {
  const GunlukPlanTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilState = ref.watch(profilProvider);
    final checkin = ref.watch(checkinProvider);
    final planBloklar = ref.watch(gunlukPlanProvider);
    final program = ref.watch(programProvider);

    final profil = profilState.value;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.read(checkinProvider.notifier).loadBugunkuCheckin();
          },
          child: CustomScrollView(
            slivers: [
              // Üst Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Merhaba, ${profil?.hedefBolumEtiketi ?? ''} Öğrencisi',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: context.colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _InfoChip(
                                      icon: Icons.psychology_alt_rounded,
                                      label: profil?.ogrenmeMetodEtiketi ?? '',
                                      color: context.colors.primary,
                                    ),
                                    _InfoChip(
                                      icon: Icons.local_fire_department_rounded,
                                      label: '${profil?.streak ?? 0} Gün Seri',
                                      color: context.colors.warning,
                                    ),
                                    _InfoChip(
                                      icon: Icons.event_available_rounded,
                                      label: '${_yksKalanGun()} Gün Kaldı',
                                      color: context.colors.danger,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => const NefesEgzersiziDialog(),
                              );
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: context.colors.success.withValues(alpha: 0.1),
                              padding: const EdgeInsets.all(10),
                            ),
                            icon: Icon(Icons.self_improvement_rounded, color: context.colors.success),
                            tooltip: 'Nefes Egzersizi',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Günlük Check-in Kartı
                      _buildCheckinCard(context, ref, checkin),
                    ],
                  ),
                ),
              ),

              // Günlük Çalışma Zaman Çizelgesi Başlığı
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _SectionHeader(icon: Icons.today_rounded, label: 'Bugünkü Ders Planın'),
                      Text(
                        '${planBloklar.where((b) => b.tamamlandi).length}/${planBloklar.length} Blok',
                        style: TextStyle(fontSize: 14, color: context.colors.primary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              // Blok Listesi
              if (planBloklar.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyStateWidget(
                    icon: '📅',
                    baslik: program.yuklendi ? 'Bugün dinlenme günü' : 'Programın hazırlanıyor',
                    aciklama: program.yuklendi
                        ? 'Bugüne çalışma süresi eklemek için Programım ekranından ayarlarını düzenleyebilirsin.'
                        : 'Haftalık ders programın oluşturuluyor...',
                    butonMetni: program.yuklendi ? 'Programım' : null,
                    onButonPressed: program.yuklendi ? () => context.push('/program') : null,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final blok = planBloklar[index];
                        return _buildPlanBlokItem(context, ref, blok);
                      },
                      childCount: planBloklar.length,
                    ),
                  ),
                ),

              // 7 Günlük Haftalık Plan Önizlemesi
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const _SectionHeader(icon: Icons.calendar_view_week_rounded, label: 'Bu Haftanın Programı'),
                          TextButton(
                            onPressed: () => context.push('/program'),
                            child: const Text('Düzenle'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 92,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 7,
                          itemBuilder: (context, index) {
                            final bugunMu = index == DateTime.now().weekday - 1;
                            final bloklar = program.gunBloklari(index).where((b) => b.isCalismaBloku).toList();
                            final biten = bloklar.where((b) => b.tamamlandi).length;
                            final dk = bloklar.fold<int>(0, (t, b) => t + b.sure);
                            return InkWell(
                              onTap: () => context.push('/program'),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: 84,
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: bugunMu
                                      ? context.colors.primary.withValues(alpha: 0.1)
                                      : context.colors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: bugunMu ? context.colors.primary : context.colors.border,
                                    width: bugunMu ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      gunKisaAdlari[index],
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: bugunMu ? context.colors.primary : context.colors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      bloklar.isEmpty ? 'dinlenme' : sureMetni(dk),
                                      style: TextStyle(fontSize: 11, color: context.colors.textSecondary),
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: bloklar.isEmpty ? 0 : biten / bloklar.length,
                                        minHeight: 5,
                                        backgroundColor: context.colors.border,
                                        color: context.colors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckinCard(BuildContext context, WidgetRef ref, checkin) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionHeader(icon: Icons.bolt_rounded, label: 'Bugünkü Durumun'),
              Text(
                'Ort: ${checkin.ortalama.toStringAsFixed(1)}/5',
                style: TextStyle(fontSize: 12, color: context.colors.textSecondary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildRatingChip(context, ref, 'Enerji', checkin.enerji, checkin.enerjiEmoji, (val) {
                ref.read(checkinProvider.notifier).kaydetCheckin(
                      enerji: val,
                      odak: checkin.odak,
                      stres: checkin.stres,
                    );
                _checkinDamlasi(context, ref);
              }),
              _buildRatingChip(context, ref, 'Odak', checkin.odak, checkin.odakEmoji, (val) {
                ref.read(checkinProvider.notifier).kaydetCheckin(
                      enerji: checkin.enerji,
                      odak: val,
                      stres: checkin.stres,
                    );
                _checkinDamlasi(context, ref);
              }),
              _buildRatingChip(context, ref, 'Stres', checkin.stres, checkin.stresEmoji, (val) {
                ref.read(checkinProvider.notifier).kaydetCheckin(
                      enerji: checkin.enerji,
                      odak: checkin.odak,
                      stres: val,
                    );
                _checkinDamlasi(context, ref);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingChip(BuildContext context, WidgetRef ref, String label, int value,
      String emoji, Function(int) onSelected) {
    return Column(
      children: [
        Text('$label $emoji', style: TextStyle(fontSize: 12, color: context.colors.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(
          children: List.generate(5, (i) {
            final score = i + 1;
            final isSelected = value == score;
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onSelected(score);
              },
              child: Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isSelected ? context.colors.primary : context.colors.background,
                  shape: BoxShape.circle,
                  border: Border.all(color: isSelected ? context.colors.primary : context.colors.border),
                ),
                child: Center(
                  child: Text(
                    '$score',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : context.colors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPlanBlokItem(BuildContext context, WidgetRef ref, PlanBlok blok) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: blok.tamamlandi
            ? context.colors.surface.withValues(alpha: 0.6)
            : context.colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: blok.tamamlandi
              ? context.colors.border
              : context.colors.primary.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: IconButton(
          iconSize: 28,
          tooltip: blok.tamamlandi ? 'Tamamlanmadı olarak işaretle' : 'Tamamlandı olarak işaretle',
          onPressed: () {
            HapticFeedback.lightImpact();
            ref.read(programProvider.notifier).tamamlandiDegistir(blok.id);
          },
          icon: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: blok.tamamlandi
                  ? context.colors.success
                  : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: blok.tamamlandi
                    ? context.colors.success
                    : context.colors.textMuted,
                width: 2,
              ),
            ),
            child: blok.tamamlandi
                ? Icon(Icons.check, size: 18, color: context.colors.onPrimary)
                : null,
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: blok.blokRenk.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(blok.tipIconData, size: 15, color: blok.blokRenk),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                blok.konu,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: blok.tamamlandi ? context.colors.textMuted : context.colors.textPrimary,
                  decoration: blok.tamamlandi ? TextDecoration.lineThrough : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 36, top: 2),
          child: Row(
            children: [
              if (blok.ders != null && blok.ders!.isNotEmpty) ...[
                Text(
                  blok.ders!,
                  style: TextStyle(fontSize: 12, color: context.colors.primary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text('•', style: TextStyle(color: context.colors.textMuted)),
                const SizedBox(width: 8),
              ],
              Text(
                '${blok.sure} dk • ${blok.saatFormatli}',
                style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
              ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            blok.isEgzersiz
                ? Icons.self_improvement
                : Icons.play_circle_fill_rounded,
            color: context.colors.primary,
            size: 32,
          ),
          tooltip: blok.isEgzersiz ? 'Nefes egzersizini başlat' : 'Pomodoro zamanlayıcısını başlat',
          onPressed: () {
            if (blok.isEgzersiz) {
              showDialog(
                context: context,
                builder: (_) => const NefesEgzersiziDialog(),
              );
            } else {
              final notifier = ref.read(programProvider.notifier);
              showDialog(
                context: context,
                builder: (_) => PomodoroDialog(
                  konuBasligi: '${blok.ders ?? ''} - ${blok.konu}',
                  sureDakika: blok.sure,
                  ders: blok.ders,
                  onTamamlandi: (dk) {
                    if (dk >= (blok.sure * 0.6).round()) notifier.tamamlandiIsaretle(blok.id);
                  },
                ),
              );
            }
          },
        ),
      ),
    );
  }

  /// Günün ilk check-in'i bahçe için su damlası kazandırır.
  Future<void> _checkinDamlasi(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final kazanilan = await ref.read(bahceProvider.notifier).checkinDamlasi();
    if (kazanilan > 0) {
      messenger.showSnackBar(SnackBar(
        content: Text('Günlük check-in için +$kazanilan su damlası kazandın!'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  /// YKS sınavına kalan gün sayısı (app_constants.dart'taki yksDate'ten türetilir).
  int _yksKalanGun() {
    return yksKalanGun();
  }
}

/// Bölüm başlığı: emoji yerine tutarlı Material ikon + metin.
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: context.colors.textPrimary),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textPrimary),
        ),
      ],
    );
  }
}

/// Küçük bilgi rozeti (öğrenme metodu, streak vb.) — tutarlı ikon + renk düzeni.
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
