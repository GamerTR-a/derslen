import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../widgets/profil_duzenle_dialog.dart';
import '../../../../data/models/ogrenci_profil.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

class ProfilBilgiCard extends StatelessWidget {
  final OgrenciProfil? profil;

  const ProfilBilgiCard({super.key, required this.profil});

  Widget _statBox(BuildContext context, {required String title, required String value, required Color color}) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 11, color: context.colors.textMuted)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final saat = (profil?.toplamCalismaDk ?? 0) ~/ 60;
    final dk = (profil?.toplamCalismaDk ?? 0) % 60;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colors.border),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: context.colors.primary.withValues(alpha: 0.12),
                child: Icon(Icons.psychology_alt_rounded, size: 30, color: context.colors.primary),
              ),
              title: Text(
                'Hedef: ${profil?.hedefBolumEtiketi ?? 'Sayısal'}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textPrimary),
              ),
              subtitle: Text(profil?.hedefUniversite ?? 'Hedef üniversite henüz eklenmedi', style: TextStyle(fontSize: 13, color: context.colors.textMuted)),
              trailing: IconButton(
                icon: Icon(Icons.edit_outlined, color: context.colors.primary),
                tooltip: 'Profili Düzenle',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  showDialog(context: context, builder: (_) => const ProfilDuzenleDialog());
                },
              ),
            ),
            Divider(color: context.colors.border, height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statBox(context, title: 'Günlük Hedef', value: '${profil?.gunlukSaat ?? 0} Saat', color: context.colors.primary),
                _statBox(context, title: 'Toplam Çalışma', value: '$saat s $dk dk', color: context.colors.success),
                _statBox(context, title: 'Streak', value: '${profil?.streak ?? 0} Gün', color: context.colors.warning),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
