import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';
import '../../../providers/rozet_provider.dart';
import '../../../../data/models/rozet.dart';

class RozetlerCard extends ConsumerWidget {
  const RozetlerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final kazanilanlar = ref.watch(rozetProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded, size: 18, color: colors.warning),
              const SizedBox(width: 6),
              Text(
                'Rozetlerim',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
              ),
              const SizedBox(width: 6),
              Text(
                '${kazanilanlar.length}/${rozetKatalogu.length}',
                style: TextStyle(fontSize: 13, color: colors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: rozetKatalogu.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final rozet = rozetKatalogu[index];
                final acik = kazanilanlar.contains(rozet.id);
                return _RozetKutusu(rozet: rozet, acik: acik);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RozetKutusu extends StatelessWidget {
  final Rozet rozet;
  final bool acik;

  const _RozetKutusu({required this.rozet, required this.acik});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final renk = acik ? colors.warning : colors.textMuted;

    return Tooltip(
      message: '${rozet.baslik}\n${rozet.aciklama}',
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: renk.withValues(alpha: acik ? 0.15 : 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: renk.withValues(alpha: acik ? 0.6 : 0.25), width: 1.5),
              ),
              child: Icon(rozet.icon, color: renk, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              rozet.baslik,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: acik ? colors.textPrimary : colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
