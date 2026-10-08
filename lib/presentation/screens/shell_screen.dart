import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';
import '../../core/services/secure_screen_service.dart';
import '../providers/bahce_provider.dart';
import '../providers/flashkart_provider.dart';
import '../providers/odak_provider.dart';
import '../providers/okul_provider.dart';
import '../widgets/asistan_widget.dart';

const List<String> _sekmeRotalari = ['/ana', '/calis', '/flashkart', '/bahce', '/topluluk'];

class ShellScreen extends ConsumerWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final i = _sekmeRotalari.indexWhere(location.startsWith);
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);
    final due = ref.watch(desteDueSayilariProvider)['hepsi'] ?? 0;
    final susuz = ref.watch(bahceProvider.select((b) => b.susuzBitki));
    final odak = ref.watch(odakProvider);
    final okulModu = ref.watch(okulModuProvider);
    final bekleyenOneri = ref.watch(ogrenciOnerileriProvider).value?.where((o) => o.durum == null).length ?? 0;

    String? calisRozeti;
    if (odak.aktif && selectedIndex != 1) {
      final sn = odak.gosterilenSaniye;
      calisRozeti = '${sn ~/ 60}:${(sn % 60).toString().padLeft(2, '0')}';
    }

    Widget ikon(IconData i, {String? etiket, bool nokta = false}) {
      if (etiket != null) return Badge(label: Text(etiket), child: Icon(i));
      if (nokta) return Badge(smallSize: 8, child: Icon(i));
      return Icon(i);
    }

    return PopScope(
      // Odak seansı sürerken geri tuşu uygulamayı kapatmaz (sayaç kaybolmasın):
      // uygulama arka plana alınır, seans devam eder.
      canPop: selectedIndex == 0 && !odak.aktif,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (selectedIndex != 0) {
          context.go('/ana');
          return;
        }
        final messenger = ScaffoldMessenger.of(context);
        if (!await SecureScreenService.arkaPlanaAl()) {
          messenger.showSnackBar(const SnackBar(
            content: Text('Odak seansın sürüyor. Çıkmadan önce Çalış sekmesinden seansı bitir ya da vazgeç.'),
          ));
        }
      },
      child: Scaffold(
        backgroundColor: context.colors.background,
        body: Stack(
          children: [
            Positioned.fill(child: child),
            const Positioned.fill(child: AsistanWidget()),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (i) {
            HapticFeedback.selectionClick();
            context.go(_sekmeRotalari[i]);
          },
          backgroundColor: context.colors.surface,
          indicatorColor: context.colors.primary.withValues(alpha: 0.14),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 68,
          destinations: [
            NavigationDestination(
              icon: ikon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: context.colors.primary),
              label: 'Ana Sayfa',
            ),
            NavigationDestination(
              icon: ikon(Icons.timer_outlined, etiket: calisRozeti),
              selectedIcon: Icon(Icons.timer_rounded, color: context.colors.primary),
              label: 'Çalış',
            ),
            NavigationDestination(
              icon: ikon(Icons.style_outlined, etiket: due > 0 ? (due > 99 ? '99+' : '$due') : null),
              selectedIcon: Icon(Icons.style_rounded, color: context.colors.primary),
              label: 'Kartlar',
            ),
            NavigationDestination(
              icon: ikon(Icons.local_florist_outlined, nokta: susuz > 0),
              selectedIcon: Icon(Icons.local_florist_rounded, color: context.colors.primary),
              label: 'Bahçe',
            ),
            if (okulModu)
              NavigationDestination(
                icon: ikon(Icons.school_outlined, etiket: bekleyenOneri > 0 ? '$bekleyenOneri' : null),
                selectedIcon: Icon(Icons.school_rounded, color: context.colors.primary),
                label: 'Okulum',
              )
            else
              NavigationDestination(
                icon: ikon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups_rounded, color: context.colors.primary),
                label: 'Topluluk',
              ),
          ],
        ),
      ),
    );
  }
}
