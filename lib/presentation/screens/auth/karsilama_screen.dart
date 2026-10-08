import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

import '../../../data/models/okul_modelleri.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/ui_kit.dart';

/// İlk ekran: uygulamayı kimin kullanacağı seçilir. Seçim yalnızca kayıt
/// yolunu belirler; yetki, hesap açıldıktan sonra girilen kodla sunucuda verilir.
class KarsilamaScreen extends ConsumerWidget {
  const KarsilamaScreen({super.key});

  static const List<(KullaniciRolu, IconData, String)> _secenekler = [
    (KullaniciRolu.ogrenci, Icons.school_rounded, 'Programını kur, çalış, ilerlemeni gör'),
    (KullaniciRolu.veli, Icons.family_restroom_rounded, 'Çocuğunun haftalık çalışma özetini gör'),
    (KullaniciRolu.ogretmen, Icons.co_present_rounded, 'Sınıflarının çalışma düzenini takip et'),
    (KullaniciRolu.mudur, Icons.account_balance_rounded, 'Okulunu kur, şube ve öğretmenleri yönet'),
  ];

  Future<void> _sec(BuildContext context, WidgetRef ref, KullaniciRolu rol) async {
    await ref.read(authProvider.notifier).kayitTuruAyarla(rol == KullaniciRolu.ogrenci ? null : rol.tur);
    if (context.mounted) context.push('/register?tur=${rol.tur}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'DersNet',
                      style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: c.primary, letterSpacing: -0.5),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text('Uygulamayı nasıl kullanacaksın?', style: context.baslik(23)),
                  const SizedBox(height: 4),
                  Text('Sana uygun paneli açalım.', style: TextStyle(fontSize: 14, color: c.textSecondary)),
                  const SizedBox(height: 18),
                  for (final (rol, ikon, aciklama) in _secenekler)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Semantics(
                        button: true,
                        label: '${rol.etiket}: $aciklama',
                        child: YumusakKart(
                          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                          onTap: () => _sec(context, ref, rol),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(14)),
                                child: Icon(ikon, color: c.gece ? c.accent : c.primary, size: 26),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(rol.etiket,
                                        style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: c.textPrimary)),
                                    const SizedBox(height: 2),
                                    Text(aciklama, style: TextStyle(fontSize: 13, color: c.textSecondary, height: 1.3)),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: c.textMuted),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.push('/login'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: c.primary,
                        side: BorderSide(color: c.primary),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Zaten hesabım var: Giriş yap', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: TextButton(
                      onPressed: () => context.push('/gizlilik-politikasi'),
                      child: Text('Gizlilik Politikası', style: TextStyle(color: c.textMuted, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
