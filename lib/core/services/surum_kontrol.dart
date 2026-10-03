/// Zorunlu güncelleme ve bakım modu (bkz. supabase_migrations/19 `app_config`).
/// Sunucuya ulaşılamazsa uygulama engellenmez.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/theme_extensions.dart';

enum SurumDurumu { uygun, guncellemeGerekli, bakim }

class SurumBilgisi {
  final SurumDurumu durum;
  final String? mesaj;

  const SurumBilgisi(this.durum, [this.mesaj]);

  static const uygun = SurumBilgisi(SurumDurumu.uygun);
}

/// Sunucu yapılandırmasını kurulu derleme numarasıyla karşılaştırır.
SurumBilgisi surumDegerlendir({required int kuruluDerleme, required Map<String, dynamic>? yapilandirma}) {
  if (yapilandirma == null) return SurumBilgisi.uygun;
  final mesaj = (yapilandirma['mesaj'] as String?)?.trim();
  final gecerliMesaj = mesaj == null || mesaj.isEmpty ? null : mesaj;
  if (yapilandirma['bakim'] == true) return SurumBilgisi(SurumDurumu.bakim, gecerliMesaj);
  final minDerleme = (yapilandirma['min_build'] as num?)?.toInt() ?? 0;
  if (kuruluDerleme > 0 && kuruluDerleme < minDerleme) {
    return SurumBilgisi(SurumDurumu.guncellemeGerekli, gecerliMesaj);
  }
  return SurumBilgisi.uygun;
}

final surumBilgisiProvider = FutureProvider<SurumBilgisi>((ref) async {
  try {
    final satir = await Supabase.instance.client
        .from('app_config')
        .select('min_build, bakim, mesaj')
        .eq('id', 1)
        .maybeSingle();
    final bilgi = await PackageInfo.fromPlatform();
    return surumDegerlendir(
      kuruluDerleme: int.tryParse(bilgi.buildNumber) ?? 0,
      yapilandirma: satir,
    );
  } catch (_) {
    return SurumBilgisi.uygun;
  }
});

class SurumEngelEkrani extends ConsumerWidget {
  final SurumBilgisi bilgi;
  const SurumEngelEkrani({super.key, required this.bilgi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final bakim = bilgi.durum == SurumDurumu.bakim;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(bakim ? Icons.build_circle_outlined : Icons.system_update_rounded, size: 64, color: c.primary),
                const SizedBox(height: 20),
                Text(
                  bakim ? 'Kısa bir bakım arası' : 'Güncelleme gerekli',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  bilgi.mesaj ??
                      (bakim
                          ? 'DersNet şu an bakımda. Birazdan tekrar dene.'
                          : 'Bu sürüm artık desteklenmiyor. Devam etmek için uygulamayı mağazadan güncelle.'),
                  style: TextStyle(fontSize: 15, height: 1.4, color: c.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => ref.invalidate(surumBilgisiProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tekrar dene'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
