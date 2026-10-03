import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/profil_provider.dart';
import '../../../../core/algorithms/learning_engine.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/ogrenci_profil.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

class OgrenmeMetoduSecici extends ConsumerWidget {
  final OgrenciProfil? profil;

  const OgrenmeMetoduSecici({super.key, required this.profil});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Öğrenme Metodun',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textPrimary),
        ),
        const SizedBox(height: 12),
        ...OgrenmeMetod.values.map((metod) {
          final info = metodBilgi[metod] ?? {};
          final isSelected = profil?.ogrenmeMetod == metod;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? context.colors.primary : context.colors.border,
              ),
            ),
            child: ListTile(
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(profilProvider.notifier).guncelleMetod(metod);
              },
              leading: Icon(Icons.psychology_alt_rounded, size: 26, color: context.colors.primary),
              title: Text(
                info['isim'] ?? '',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.colors.textPrimary),
              ),
              subtitle: Text(
                info['aciklama'] ?? '',
                style: TextStyle(fontSize: 12, color: context.colors.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: isSelected ? Icon(Icons.check_circle_rounded, color: context.colors.primary) : null,
            ),
          );
        }),
      ],
    );
  }
}
