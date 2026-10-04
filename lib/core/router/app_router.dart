import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/providers/auth_provider.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/email_verification_screen.dart';
import '../../presentation/screens/onboarding_flow/onboarding_screen.dart';
import '../../presentation/screens/shell_screen.dart';
import '../../presentation/screens/tabs/konu_takibi_tab.dart';
import '../../presentation/screens/tabs/flashkart_tab.dart';
import '../../presentation/screens/tabs/net_takibi_tab.dart';
import '../../presentation/screens/tabs/profil_sos_tab.dart';
import '../../presentation/screens/test/test_olustur_screen.dart';
import '../../presentation/screens/test/test_coz_screen.dart';
import '../../presentation/screens/test/test_sonuc_screen.dart';
import '../../presentation/screens/admin/admin_screen.dart';
import '../../presentation/screens/tickets/create_ticket_screen.dart';
import '../../presentation/screens/tickets/my_tickets_screen.dart';
import '../../presentation/screens/posts/create_post_screen.dart';
import '../../presentation/screens/ayarlar/ayarlar_screen.dart';
import '../../presentation/screens/ayarlar/gizlilik_politikasi_screen.dart';
import '../../presentation/screens/auth/sifremi_unuttum_screen.dart';
import '../../presentation/screens/etut/etut_odalari_screen.dart';
import '../../presentation/screens/etut/etut_odasi_screen.dart';
import '../../presentation/screens/tabs/ana_sayfa_tab.dart';
import '../../presentation/screens/tabs/calis_tab.dart';
import '../../presentation/screens/tabs/bahce_tab.dart';
import '../../presentation/screens/tabs/topluluk_tab.dart';
import '../../presentation/screens/bahce/mini_oyunlar_screen.dart';
import '../../presentation/screens/analiz/analiz_screen.dart';
import '../../presentation/screens/program/ders_programi_screen.dart';
import '../../presentation/screens/mufredat/mufredat_screen.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

/// Sekme dışı alt sayfalar için geri okunu sağlayan ince sarmalayıcı.
class _AltSayfa extends StatelessWidget {
  final Widget child;
  const _AltSayfa({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 48,
        iconTheme: IconThemeData(color: context.colors.textPrimary),
      ),
      body: MediaQuery.removePadding(context: context, removeTop: true, child: child),
    );
  }
}

/// Kayıtlı oturum çözülürken gösterilir; giriş ekranının bir an görünüp
/// kaybolmasını önler.
class _AcilisEkrani extends StatelessWidget {
  const _AcilisEkrani();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'DersNet',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: context.colors.primary, letterSpacing: -0.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: context.colors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

CustomTransitionPage<void> _buildFadePage({required LocalKey key, required Widget child}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      );
    },
  );
}

class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Ref ref) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      notifyListeners();
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _AuthRefreshListenable(ref);

  return GoRouter(
    refreshListenable: refreshListenable,
    initialLocation: '/ana',
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: context.colors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, color: context.colors.primary, size: 64),
              const SizedBox(height: 16),
              Text(
                'Sayfa Bulunamadı veya Yönlendirme Hatası',
                style: TextStyle(color: context.colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                state.error?.message ?? 'İstenen sayfa yüklenirken bir sorun oluştu.',
                style: TextStyle(color: context.colors.textMuted, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/ana'),
                icon: Icon(Icons.home_rounded),
                label: Text('Ana Sayfaya Dön'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final status = authState.status;
      final loc = state.matchedLocation;

      final isAuthRoute = loc == '/login' ||
          loc == '/register' ||
          loc == '/verify-email' ||
          loc == '/sifremi-unuttum';

      // Gizlilik politikası her oturum durumunda erişilebilir olmalı (mağaza gereksinimi).
      if (loc == '/gizlilik-politikasi') return null;

      if (status == AuthStatus.yukleniyor) {
        return loc == '/acilis' ? null : '/acilis';
      }

      if (status == AuthStatus.unauthenticated) {
        if (!isAuthRoute) return '/login';
        return null;
      }

      if (status == AuthStatus.emailVerificationPending) {
        if (loc != '/verify-email') return '/verify-email';
        return null;
      }

      if (status == AuthStatus.onboardingPending) {
        if (loc != '/onboarding') return '/onboarding';
        return null;
      }

      if (status == AuthStatus.authenticated) {
        if (isAuthRoute || loc == '/onboarding' || loc == '/acilis') return '/ana';
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/acilis',
        builder: (context, state) => const _AcilisEkrani(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      GoRoute(
        path: '/sifremi-unuttum',
        builder: (context, state) => const SifremiUnuttumScreen(),
      ),
      GoRoute(
        path: '/gizlilik-politikasi',
        builder: (context, state) => const GizlilikPolitikasiScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminScreen(),
      ),
      GoRoute(
        path: '/create-ticket',
        builder: (context, state) => const CreateTicketScreen(),
      ),
      GoRoute(
        path: '/my-tickets',
        builder: (context, state) => const MyTicketsScreen(),
      ),
      GoRoute(
        path: '/create-post',
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '/ayarlar',
        builder: (context, state) => const AyarlarScreen(),
      ),
      GoRoute(
        path: '/study-rooms',
        builder: (context, state) => const EtutOdalariScreen(),
      ),
      GoRoute(
        path: '/etut-odasi/:id',
        builder: (context, state) => EtutOdasiScreen(
          odaId: int.tryParse(state.pathParameters['id'] ?? '') ?? 1,
          odaAdi: state.extra as String? ?? 'Etüt Odası',
        ),
      ),
      GoRoute(
        // Eski "günlük plan" bağlantıları Programım ekranının Günlük sekmesine gider.
        path: '/plan',
        builder: (context, state) => const DersProgramiScreen(),
      ),
      GoRoute(
        path: '/program',
        builder: (context, state) => DersProgramiScreen(
          baslangicSekmesi: int.tryParse(state.uri.queryParameters['sekme'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: '/mufredat',
        builder: (context, state) => const MufredatScreen(),
      ),
      GoRoute(
        path: '/analiz',
        builder: (context, state) => const AnalizScreen(),
      ),
      GoRoute(
        path: '/konular',
        builder: (context, state) => const _AltSayfa(child: KonuTakibiTab()),
      ),
      GoRoute(
        path: '/netler',
        builder: (context, state) => const _AltSayfa(child: NetTakibiTab()),
      ),
      GoRoute(
        path: '/profil',
        builder: (context, state) => const _AltSayfa(child: ProfilSosTab()),
      ),
      GoRoute(
        path: '/mini-oyunlar',
        builder: (context, state) => const MiniOyunlarScreen(),
      ),
      GoRoute(
        path: '/test-olustur',
        builder: (context, state) => TestOlusturScreen(baslangicBolumu: state.uri.queryParameters['bolum']),
      ),
      GoRoute(
        path: '/test-coz',
        builder: (context, state) => const TestCozScreen(),
      ),
      GoRoute(
        path: '/test-sonuc',
        builder: (context, state) => const TestSonucScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/ana',
            pageBuilder: (context, state) => _buildFadePage(key: state.pageKey, child: const AnaSayfaTab()),
          ),
          GoRoute(
            path: '/calis',
            pageBuilder: (context, state) => _buildFadePage(key: state.pageKey, child: const CalisTab()),
          ),
          GoRoute(
            path: '/flashkart',
            pageBuilder: (context, state) => _buildFadePage(key: state.pageKey, child: const FlashkartTab()),
          ),
          GoRoute(
            path: '/bahce',
            pageBuilder: (context, state) => _buildFadePage(key: state.pageKey, child: const BahceTab()),
          ),
          GoRoute(
            path: '/topluluk',
            pageBuilder: (context, state) => _buildFadePage(key: state.pageKey, child: const ToplulukTab()),
          ),
        ],
      ),
    ],
  );
});
