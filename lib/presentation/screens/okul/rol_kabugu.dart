import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

import '../../../core/services/okul_service.dart';
import '../../../core/services/supabase_auth_service.dart';
import '../../../core/storage/storage_service.dart';
import '../../../data/models/okul_modelleri.dart';
import '../../providers/auth_provider.dart';
import '../../providers/okul_provider.dart';
import '../../providers/profil_provider.dart';
import '../../widgets/ui_kit.dart';
import 'okul_ortak.dart';

class PanelSekmesi {
  final String etiket;
  final IconData ikon;
  final IconData seciliIkon;
  final WidgetBuilder insa;

  const PanelSekmesi({required this.etiket, required this.ikon, required this.seciliIkon, required this.insa});
}

/// Öğretmen, veli ve müdür panellerinin ortak kabuğu: alt gezinme çubuğu ve
/// sekmeler. Sekme ilk açıldığında kurulur, sonra durumu korunur.
class RolKabugu extends StatefulWidget {
  final List<PanelSekmesi> sekmeler;

  const RolKabugu({super.key, required this.sekmeler});

  @override
  State<RolKabugu> createState() => _RolKabuguState();
}

class _RolKabuguState extends State<RolKabugu> {
  int _secili = 0;
  final Set<int> _acilan = {0};

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PopScope(
      canPop: _secili == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _secili = 0);
      },
      child: Scaffold(
        backgroundColor: c.background,
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _secili,
            children: [
              for (var i = 0; i < widget.sekmeler.length; i++)
                _acilan.contains(i) ? Builder(builder: widget.sekmeler[i].insa) : const SizedBox.shrink(),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _secili,
          onDestinationSelected: (i) {
            HapticFeedback.selectionClick();
            setState(() {
              _secili = i;
              _acilan.add(i);
            });
          },
          backgroundColor: c.surface,
          indicatorColor: c.primary.withValues(alpha: 0.14),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 68,
          destinations: [
            for (final s in widget.sekmeler)
              NavigationDestination(
                icon: Icon(s.ikon),
                selectedIcon: Icon(s.seciliIkon, color: c.primary),
                label: s.etiket,
              ),
          ],
        ),
      ),
    );
  }
}

/// Öğretmen, veli ve müdür için hesap sekmesi: ad, okul, ayarlar, çıkış.
class RolProfilSekmesi extends ConsumerWidget {
  /// Role özel ek bölümler (ör. velinin çocuk bağlantıları).
  final List<Widget> ekBolumler;

  const RolProfilSekmesi({super.key, this.ekBolumler = const []});

  Future<void> _adDuzenle(BuildContext context, WidgetRef ref, String mevcut) async {
    final ad = TextEditingController(text: mevcut);
    final yeni = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.colors.surface,
        title: const Text('Ad Soyad'),
        content: TextField(
          controller: ad,
          autofocus: true,
          maxLength: 60,
          textCapitalization: TextCapitalization.words,
          style: TextStyle(color: ctx.colors.textPrimary),
          decoration: const InputDecoration(counterText: ''),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(ctx, ad.text.trim()), child: const Text('Kaydet')),
        ],
      ),
    );
    if (yeni == null || yeni.length < 3 || yeni == mevcut) return;
    try {
      await OkulService.adGuncelle(yeni);
      ref.invalidate(okulDurumuProvider);
    } on OkulHatasi catch (e) {
      if (context.mounted) okulBildir(context, e.mesaj, hata: true);
    }
  }

  Future<void> _okuldanAyril(BuildContext context, WidgetRef ref) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.colors.surface,
        title: const Text('Okuldan ayrıl'),
        content: const Text(
            'Şubelerine ve öğrencilerine erişimin sona erer; hesabın öğrenci hesabına döner. Yeniden katılmak için müdürden yeni bir kod alman gerekir.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ayrıl')),
        ],
      ),
    );
    if (onay != true) return;
    try {
      await OkulService.okuldanAyril();
      await ref.read(authProvider.notifier).rolTamamlandi();
    } on OkulHatasi catch (e) {
      if (context.mounted) okulBildir(context, e.mesaj, hata: true);
    }
  }

  void _hesabiSil(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.colors.surface,
        title: const Text('Hesabı sil?'),
        content: const Text('Hesabın ve hesabına bağlı tüm veriler kalıcı olarak silinir. Bu işlem geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await SupabaseAuthService.deleteAccount();
              } catch (e) {
                if (context.mounted) {
                  okulBildir(context, 'Hesap silinemedi: ${e.toString().replaceAll('Exception: ', '')}', hata: true);
                }
                return;
              }
              await ref.read(storageServiceProvider).clear();
              await SecureStorageService.deleteAll();
              await ref.read(authProvider.notifier).logout();
            },
            child: Text('Hesabımı sil', style: TextStyle(color: ctx.colors.danger)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final auth = ref.watch(authProvider);
    final durum = ref.watch(okulDurumuProvider).value;
    final ad = (durum?.ad.isNotEmpty ?? false) ? durum!.ad : (auth.email?.split('@').first ?? '');
    final gorev = switch (auth.panel) {
      KullaniciRolu.ogretmen => (durum?.rehber ?? false) ? 'Rehber öğretmen' : '${durum?.brans ?? 'Branş'} öğretmeni',
      KullaniciRolu.mudur => 'Okul müdürü',
      KullaniciRolu.veli => 'Veli',
      KullaniciRolu.ogrenci => 'Öğrenci',
    };

    Widget satir(IconData ikon, String etiket, VoidCallback onTap, {Color? renk}) => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: Icon(ikon, color: renk ?? c.textSecondary),
          title: Text(etiket, style: TextStyle(color: renk ?? c.textPrimary, fontWeight: FontWeight.w600)),
          trailing: Icon(Icons.chevron_right_rounded, color: c.textMuted),
          onTap: onTap,
        );

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(okulDurumuProvider.future),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          const PanelBasligi('Hesap'),
          YumusakKart(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: c.primarySoft,
                  child: ad.isEmpty
                      ? Icon(Icons.person_rounded, color: c.primary)
                      : Text(ad.characters.first.toUpperCase(),
                          style: context.baslik(22, color: c.gece ? c.accent : c.primary)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ad.isEmpty ? 'Adını ekle' : ad,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: context.baslik(19)),
                      const SizedBox(height: 2),
                      Text(
                        [gorev, if (durum?.okulAd != null) durum!.okulAd!].join('  ·  '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: c.textSecondary),
                      ),
                      if (auth.email != null)
                        Text(auth.email!,
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: c.textMuted)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Adı düzenle',
                  onPressed: () => _adDuzenle(context, ref, durum?.ad ?? ''),
                  icon: Icon(Icons.edit_outlined, color: c.textSecondary),
                ),
              ],
            ),
          ),
          ...ekBolumler,
          const SizedBox(height: 16),
          YumusakKart(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              children: [
                satir(Icons.settings_outlined, 'Ayarlar', () => context.push('/ayarlar')),
                satir(Icons.support_agent_rounded, 'Destek talebi', () => context.push('/create-ticket')),
                satir(Icons.privacy_tip_outlined, 'Gizlilik Politikası', () => context.push('/gizlilik-politikasi')),
                if (auth.panel == KullaniciRolu.ogretmen)
                  satir(Icons.exit_to_app_rounded, 'Okuldan ayrıl', () => _okuldanAyril(context, ref)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.read(authProvider.notifier).logout();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: c.primary,
                side: BorderSide(color: c.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Çıkış Yap'),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () => _hesabiSil(context, ref),
              icon: Icon(Icons.delete_forever_rounded, color: c.danger, size: 18),
              label: Text('Hesabımı ve verilerimi sil', style: TextStyle(color: c.danger, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}
