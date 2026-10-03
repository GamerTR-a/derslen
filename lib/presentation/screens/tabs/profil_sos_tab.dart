import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/profil_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/role_provider.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/services/supabase_auth_service.dart';
import 'widgets/profil_sos_cards.dart';
import 'widgets/profil_bilgi_card.dart';
import 'widgets/ogrenme_metodu_secici.dart';
import 'widgets/rozetler_card.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

class ProfilSosTab extends ConsumerWidget {
  const ProfilSosTab({super.key});

  void _hesapSilOnay(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hesabı ve Tüm Verileri Sil?', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          'Hesabınız ve cihazda saklanan tüm çalışma verileriniz (netler, planlar, kart durumları) kalıcı olarak silinecektir. Bu işlem geri alınamaz.',
          style: TextStyle(color: context.colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: TextStyle(color: context.colors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();

              final messenger = ScaffoldMessenger.of(context);
              final dangerColor = context.colors.danger;
              try {
                // Sunucu tarafında hesabı ve tüm ilişkili verileri kalıcı olarak sil
                // (auth.users satırı silinince profiles/netler/planlar CASCADE ile silinir).
                await SupabaseAuthService.deleteAccount();
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Hesap silinemedi: ${e.toString().replaceAll('Exception: ', '')}'),
                    backgroundColor: dangerColor,
                  ),
                );
                return;
              }

              final storage = ref.read(storageServiceProvider);
              await storage.clear();
              await SecureStorageService.deleteAll();
              ref.read(authProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: context.colors.danger),
            child: Text('Hesabımı ve Verilerimi Sil', style: TextStyle(color: context.colors.onPrimary)),
          ),
        ],
      ),
    );
  }

  void _profilSifirlaOnay(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Profil Sıfırlama Onayı', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          'Profil bilgilerinizi ve hedeflerinizi sıfırlayarak baştan başlamak istiyor musunuz?',
          style: TextStyle(color: context.colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Vazgeç', style: TextStyle(color: context.colors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();
              ref.read(profilProvider.notifier).profilSifirla();
              ref.read(authProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: context.colors.warning),
            child: Text('Sıfırla', style: TextStyle(color: context.colors.onPrimary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilAsync = ref.watch(profilProvider);
    final profil = profilAsync.value;
    final isAdmin = ref.watch(currentUserRoleProvider).value == 'admin';

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profilim',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: context.colors.textPrimary),
              ),
              const SizedBox(height: 20),
              ProfilBilgiCard(profil: profil),
              const SizedBox(height: 16),
              const RozetlerCard(),
              const SizedBox(height: 28),
              OgrenmeMetoduSecici(profil: profil),
              const SizedBox(height: 32),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          ref.read(authProvider.notifier).logout();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.colors.primary,
                          side: BorderSide(color: context.colors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: Icon(Icons.logout_rounded, size: 18),
                        label: Text('Çıkış Yap'),
                      ),
                      const SizedBox(width: 16),
                      TextButton.icon(
                        onPressed: () => _profilSifirlaOnay(context, ref),
                        icon: Icon(Icons.restart_alt_rounded, color: context.colors.textMuted, size: 18),
                        label: Text('Profili Sıfırla', style: TextStyle(color: context.colors.textMuted)),
                      ),
                    ],
                  ),
                  if (isAdmin)
                    TextButton.icon(
                      onPressed: () => context.push('/admin'),
                      icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                      label: const Text('Admin paneli'),
                    ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => _hesapSilOnay(context, ref),
                    icon: Icon(Icons.delete_forever_rounded, color: context.colors.danger, size: 18),
                    label: Text(
                      'Hesabımı ve Tüm Verilerimi Sil (KVKK / App Store)',
                      style: TextStyle(color: context.colors.danger, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const YasalBilgilendirmeCard(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
