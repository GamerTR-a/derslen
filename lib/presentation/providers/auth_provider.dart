import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../core/services/auth_service.dart';
import '../../core/storage/storage_service.dart';
import '../../core/storage/synced_storage_service.dart';
import 'profil_provider.dart';

enum AuthStatus {
  /// Açılışta kayıtlı oturum çözülürken (giriş ekranı gösterilmez).
  yukleniyor,
  unauthenticated,
  emailVerificationPending,
  onboardingPending,
  authenticated,
}

class AuthState {
  final AuthStatus status;
  final String? email;
  final String? adSoyad;
  final String? errorMessage;
  final String? userId;

  const AuthState({
    required this.status,
    this.email,
    this.adSoyad,
    this.errorMessage,
    this.userId,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? email,
    String? adSoyad,
    String? errorMessage,
    String? userId,
  }) {
    return AuthState(
      status: status ?? this.status,
      email: email ?? this.email,
      adSoyad: adSoyad ?? this.adSoyad,
      errorMessage: errorMessage ?? this.errorMessage,
      userId: userId ?? this.userId,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final StorageService _storageService;
  StreamSubscription<sb.AuthState>? _authSub;

  /// Eşitleme yerel kopyayı değiştirdiğinde çağrılır (bellekteki durum yenilensin).
  final void Function()? onBulutDegisti;
  DateTime? _sonEsitleme;

  AuthNotifier(this._authService, this._storageService, {this.onBulutDegisti})
      : super(AuthState(status: _kayitliOturumVar() ? AuthStatus.yukleniyor : AuthStatus.unauthenticated)) {
    loadSession();
    _listenToSupabaseAuth();
  }

  static bool _kayitliOturumVar() {
    try {
      return sb.Supabase.instance.client.auth.currentSession != null;
    } catch (_) {
      return false;
    }
  }

  sb.SupabaseClient? get _supabase {
    try {
      return sb.Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Supabase oturumu dışarıdan (token yenileme hatası, başka bir cihazda
  /// çıkış vb.) kapanırsa uygulama durumunu da senkron tutar.
  void _listenToSupabaseAuth() {
    final supabase = _supabase;
    if (supabase == null) return;
    _authSub = supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == sb.AuthChangeEvent.signedOut) {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  /// Uygulama açılışında oturum durumunu yükler.
  /// Kaynak: Supabase yapılandırılmışsa gerçek session (`auth.currentSession`);
  /// Supabase hiç yapılandırılmamışsa (dev/offline build) eski local-flag akışı.
  Future<void> loadSession() async {
    final supabase = _supabase;

    if (supabase != null) {
      final session = supabase.auth.currentSession;
      if (session != null) {
        await _resolveAuthenticatedSession(session);
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
      return;
    }

    // Yerel bayraklarla giriş yalnızca geliştirme derlemesinde (Supabase yokken).
    if (kReleaseMode) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    final savedEmail = await _storageService.getString('user_auth_email');
    final isVerified = await _storageService.getBool('user_email_verified') ?? false;
    final isProfilDone = await _storageService.getMap('ogrenci_profil_data') != null;

    if (savedEmail != null && isVerified) {
      state = AuthState(
        status: isProfilDone ? AuthStatus.authenticated : AuthStatus.onboardingPending,
        email: savedEmail,
      );
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Geçerli bir Supabase session bulunduğunda: kullanıcının bulut verisini
  /// yerel önbelleğe indirir, eski (kullanıcıya bağlanmamış) yerel veriyi bu
  /// hesaba tek seferlik taşır, ardından onboarding durumuna göre state'i belirler.
  Future<void> _resolveAuthenticatedSession(sb.Session session) async {
    final userId = session.user.id;
    final email = session.user.email;

    final synced = SyncedStorageService(local: _storageService, userId: userId);
    var isProfilDone = false;
    try {
      // Profil bu cihazda zaten varsa ağ beklenmez; bulut eşitlemesi arka
      // planda sürer (yalnızca yerelde eksik anahtarları doldurur).
      final yereldeVar = await _storageService.getMap('sd_${userId}_ogrenci_profil_data') != null;
      if (yereldeVar) {
        isProfilDone = true;
        unawaited(_esitle(synced).then((_) => synced.migrateLegacyLocalData()).catchError((_) {}));
      } else {
        await synced.bulutlaEsitle();
        _sonEsitleme = DateTime.now();
        await synced.migrateLegacyLocalData();
        isProfilDone = await synced.getMap('ogrenci_profil_data') != null;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('AuthNotifier: oturum çözülemedi: $e');
    }

    // Beklerken oturum kapandıysa (token yenilenemedi, çıkış yapıldı) eski
    // sonucu yazma.
    if (!mounted) return;
    if (_supabase?.auth.currentSession?.user.id != userId) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    state = AuthState(
      status: isProfilDone ? AuthStatus.authenticated : AuthStatus.onboardingPending,
      email: email,
      userId: userId,
    );
  }

  Future<void> _esitle(SyncedStorageService synced) async {
    _sonEsitleme = DateTime.now();
    final degisti = await synced.bulutlaEsitle();
    if (degisti && mounted && state.userId != null) onBulutDegisti?.call();
  }

  /// Uygulama ön plana döndüğünde çağrılır: başka cihazda yapılan değişiklikleri
  /// alır, gönderilememiş yerel yazmaları yeniden dener. Dakikada en fazla bir kez.
  Future<void> bulutlaEsitle() async {
    final userId = state.userId;
    if (userId == null || state.status != AuthStatus.authenticated) return;
    final son = _sonEsitleme;
    if (son != null && DateTime.now().difference(son) < const Duration(minutes: 1)) return;
    await _esitle(SyncedStorageService(local: _storageService, userId: userId));
  }

  /// 1. E-posta ve Şifre ile Kayıt
  Future<bool> register({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(errorMessage: null);
    final result = await _authService.signUp(email: email, password: password);

    if (result.success) {
      await _storageService.setString('user_auth_email', email);
      final session = _supabase?.auth.currentSession;
      if (session != null) {
        // Doğrulama gerekmeden hesap açıldı: doğrudan profil kurulumuna geç.
        await _storageService.setBool('user_email_verified', true);
        await _resolveAuthenticatedSession(session);
      } else {
        state = AuthState(
          status: result.requiresVerification ? AuthStatus.emailVerificationPending : AuthStatus.onboardingPending,
          email: email,
        );
      }
      return true;
    } else {
      state = state.copyWith(errorMessage: result.message);
      return false;
    }
  }

  /// 2. E-posta Onay Kodunu (OTP) Doğrula
  Future<bool> verifyEmailOtp(String otpCode) async {
    final email = state.email ?? await _storageService.getString('user_auth_email') ?? '';
    state = state.copyWith(errorMessage: null);

    final result = await _authService.verifyOtp(email: email, token: otpCode);

    if (result.success) {
      await _storageService.setBool('user_email_verified', true);

      final session = _supabase?.auth.currentSession;
      if (session != null) {
        await _resolveAuthenticatedSession(session);
      } else {
        state = AuthState(
          status: AuthStatus.onboardingPending,
          email: email,
        );
      }
      return true;
    } else {
      state = state.copyWith(errorMessage: result.message);
      return false;
    }
  }

  /// 3. E-posta ve Şifre ile Giriş
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(errorMessage: null);
    final result = await _authService.signIn(email: email, password: password);

    if (result.success) {
      await _storageService.setString('user_auth_email', email);
      await _storageService.setBool('user_email_verified', true);

      final session = _supabase?.auth.currentSession;
      if (session != null) {
        await _resolveAuthenticatedSession(session);
      } else {
        final isProfilDone = await _storageService.getMap('ogrenci_profil_data') != null;
        state = AuthState(
          status: isProfilDone ? AuthStatus.authenticated : AuthStatus.onboardingPending,
          email: email,
        );
      }
      return true;
    } else if (result.requiresVerification) {
      await _storageService.setString('user_auth_email', email);
      state = AuthState(status: AuthStatus.emailVerificationPending, email: email, errorMessage: result.message);
      return false;
    } else {
      state = state.copyWith(errorMessage: result.message);
      return false;
    }
  }

  /// Kod ekranından "tekrar gönder". Sonuç mesajını döner.
  Future<String> dogrulamaKodunuTekrarGonder() async {
    final email = state.email ?? await _storageService.getString('user_auth_email') ?? '';
    final sonuc = await _authService.dogrulamaKodunuTekrarGonder(email);
    return sonuc.message ?? 'Kod gönderilemedi. Lütfen tekrar dene.';
  }

  /// Kod ekranından giriş ekranına dönüş (yönlendirici bekleyen doğrulama
  /// durumunda başka sayfaya izin vermez).
  void dogrulamadanVazgec() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// 4. Onboarding Tamamlandığında Girişi Tamamla
  void setAuthenticated() {
    state = state.copyWith(status: AuthStatus.authenticated);
  }

  /// Oturumu Kapat
  Future<void> logout() async {
    final userId = state.userId;

    await _authService.signOut();
    await _storageService.remove('user_auth_email');
    await _storageService.remove('user_email_verified');

    // Bu kullanıcıya ait önbelleğe alınmış çalışma verisini (net, plan, flashkart vb.)
    // cihazdan temizle; paylaşılan cihaz senaryosunda bir sonraki kullanıcının
    // önceki kullanıcının verisini görmesini engeller. Uygulama-geneli ayarlar
    // (tema vb.) etkilenmez.
    if (userId != null) {
      await SyncedStorageService(local: _storageService, userId: userId).clearUserData();
    }
    await SecureStorageService.deleteAll();
    await _ozelArkaPlaniSil();

    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Çalış ekranında seçilen kişisel arka plan fotoğrafı cihazda kalmasın
  /// (paylaşılan cihazda bir sonraki kullanıcı görmesin).
  Future<void> _ozelArkaPlaniSil() async {
    try {
      final ortam = await _storageService.getMap(ortamAyarlariAnahtari);
      final yol = ortam?['ozelFotoYolu'] as String?;
      if (yol != null) {
        final dosya = File(yol);
        if (await dosya.exists()) await dosya.delete();
      }
      await _storageService.remove(ortamAyarlariAnahtari);
    } catch (_) {}
  }
}

/// ortam_provider.dart ile aynı anahtar (döngüsel import olmaması için burada).
const String ortamAyarlariAnahtari = 'ortam_ayarlari';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Bulut eşitlemesi yerel kopyayı her değiştirdiğinde artar; senkron depoyu
/// izleyen sağlayıcılar yeniden kurulup veriyi depodan tekrar okur.
final bulutEsitlemeSurumuProvider = StateProvider<int>((ref) => 0);

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final storageService = ref.watch(localStorageServiceProvider);
  return AuthNotifier(
    authService,
    storageService,
    onBulutDegisti: () => ref.read(bulutEsitlemeSurumuProvider.notifier).state++,
  );
});
