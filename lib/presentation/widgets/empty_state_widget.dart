import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';
import '../cizimler/cizim_widgetlari.dart';
import '../providers/ortam_provider.dart';

/// Boş durum: kullanıcının asistan karakteri, başlık ve açıklama.
/// [icon] yalnızca ruh halini seçmek için kullanılır ('🌸'/'🎉' → gururlu).
class EmptyStateWidget extends ConsumerWidget {
  final String icon;
  final String baslik;
  final String aciklama;
  final String? butonMetni;
  final VoidCallback? onButonPressed;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.baslik,
    required this.aciklama,
    this.butonMetni,
    this.onButonPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final karakter = ref.watch(ortamProvider.select((o) => o.asistan.name));
    final basari = icon == '🌸' || icon == '🎉';
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Maskot(karakter: karakter, ruh: basari ? MaskotRuh.gururlu : MaskotRuh.dusunceli, boyut: 110, zipla: basari),
            const SizedBox(height: 16),
            Text(baslik, style: context.baslik(20), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              aciklama,
              style: TextStyle(fontSize: 13.5, color: context.colors.textMuted, height: 1.45),
              textAlign: TextAlign.center,
            ),
            if (butonMetni != null && onButonPressed != null) ...[
              const SizedBox(height: 22),
              FilledButton(onPressed: onButonPressed, child: Text(butonMetni!)),
            ],
          ],
        ),
      ),
    );
  }
}
