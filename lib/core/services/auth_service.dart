import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_auth_service.dart';

class AuthResult {
  final bool success;
  final String? message;
  final String? email;
  final bool requiresVerification;

  const AuthResult({
    required this.success,
    this.message,
    this.email,
    this.requiresVerification = false,
  });
}

class AuthService {
  /// Release derlemesinde Supabase yapılandırılmamışsa (dart-define eksik)
  /// çevrimdışı "sahte başarı" akışı kullanılmaz; kullanıcı doğrulanmadan
  /// uygulamaya giremez.
  static const _yapilandirmaHatasi = AuthResult(
    success: false,
    message: 'Sunucuya bağlanılamıyor. Uygulamayı güncelleyip tekrar dene.',
  );

  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Supabase olmadan yerel geliştirme akışı yalnızca debug/profile derlemede.
  bool get _offlineIzinli => !kReleaseMode;

  String _mapAuthException(dynamic e) {
    if (SupabaseAuthService.agHatasiMi(e as Object)) return SupabaseAuthService.baglantiHatasiMesaji;
    if (e is AuthException) {
      final msg = e.message.toLowerCase();
      if (msg.contains('different from the old')) {
        return 'Yeni şifren eski şifrenden farklı olmalı.';
      } else if (msg.contains('weak') || msg.contains('at least') || msg.contains('should contain')) {
        return 'Şifre yeterince güçlü değil. En az 8 karakter, harf ve rakam kullan.';
      } else if (msg.contains('security purposes')) {
        return 'Çok sık denedin. Bir dakika bekleyip tekrar dene.';
      } else if (msg.contains('invalid login credentials') || msg.contains('invalid_grant')) {
        return 'E-posta adresi veya şifre hatalı. Lütfen bilgilerinizi kontrol edin.';
      } else if (msg.contains('user already registered') || msg.contains('already_exists')) {
        return 'Bu e-posta adresi ile zaten bir hesap oluşturulmuş.';
      } else if (msg.contains('rate limit')) {
        return 'Çok fazla deneme yapıldı. Lütfen biraz bekleyip tekrar deneyin.';
      } else if (msg.contains('expired') || msg.contains('invalid')) {
        return 'Kod hatalı veya süresi dolmuş. Lütfen tekrar deneyin.';
      }
      return 'İşlem gerçekleştirilemedi. Lütfen tekrar deneyin.';
    }
    return 'İşlem gerçekleştirilemedi. Lütfen bağlantınızı kontrol edin.';
  }

  /// E-posta ve Şifre ile Kayıt Ol (Standart E-posta)
  Future<AuthResult> signUp({
    required String email,
    required String password,
    String? name,
    String? grade,
    String? department,
  }) async {
    if (_supabase == null) {
      if (!_offlineIzinli) return _yapilandirmaHatasi;
      return AuthResult(
        success: true,
        email: email,
        requiresVerification: true,
        message: 'Doğrulama kodu $email adresine gönderildi.',
      );
    }

    try {
      await SupabaseAuthService.register(
        name: name ?? email.split('@').first,
        email: email,
        password: password,
        grade: grade,
        department: department,
      );

      // Sunucuda e-posta onayı kapalıysa kayıt anında oturum açılır.
      return AuthResult(
        success: true,
        email: email,
        requiresVerification: _supabase?.auth.currentSession == null,
        message: 'Kayıt başarılı!',
      );
    } catch (e) {
      return AuthResult(success: false, message: e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// 6 Haneli OTP Kodunu Doğrula
  Future<AuthResult> verifyOtp({
    required String email,
    required String token,
  }) async {
    final supabase = _supabase;
    if (supabase == null) {
      if (!_offlineIzinli) return _yapilandirmaHatasi;
      if (token.length == 6) {
        return AuthResult(
          success: true,
          email: email,
          message: 'E-posta adresiniz başarıyla doğrulandı!',
        );
      }
      return const AuthResult(
        success: false,
        message: 'Lütfen 6 haneli doğrulama kodunu doğru girin.',
      );
    }

    try {
      final res = await supabase.auth
          .verifyOTP(
            email: email,
            token: token,
            type: OtpType.signup,
          )
          .timeout(const Duration(seconds: 15));

      if (res.session != null || res.user != null) {
        return AuthResult(
          success: true,
          email: email,
          message: 'E-posta adresiniz başarıyla doğrulandı!',
        );
      }
      return const AuthResult(
        success: false,
        message: 'Onay kodu hatalı veya süresi dolmuş. Lütfen tekrar deneyin.',
      );
    } catch (e) {
      return AuthResult(success: false, message: _mapAuthException(e));
    }
  }

  /// Şifre ve E-posta ile Giriş Yap (Standart E-posta)
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    if (_supabase == null) {
      if (!_offlineIzinli) return _yapilandirmaHatasi;
      return AuthResult(
        success: true,
        email: email,
        message: 'Giriş başarılı!',
      );
    }

    try {
      await SupabaseAuthService.login(email: email, password: password);

      return AuthResult(
        success: true,
        email: email,
        message: 'Giriş başarılı!',
      );
    } on SupabaseAuthException catch (e) {
      // Hesap var ama e-posta onaylanmamış: yeni kod gönderip kod ekranına al.
      if (e.message.contains('doğrulanmamış')) {
        await dogrulamaKodunuTekrarGonder(email);
        return AuthResult(success: false, email: email, requiresVerification: true, message: e.message);
      }
      return AuthResult(success: false, message: e.message);
    } catch (e) {
      return AuthResult(success: false, message: e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Kayıt doğrulama kodunu yeniden gönderir.
  Future<AuthResult> dogrulamaKodunuTekrarGonder(String email) async {
    final supabase = _supabase;
    if (supabase == null) return _yapilandirmaHatasi;
    try {
      await supabase.auth.resend(type: OtpType.signup, email: email.trim()).timeout(const Duration(seconds: 15));
      return const AuthResult(success: true, message: 'Onay kodu tekrar gönderildi. Spam/gereksiz klasörünü de kontrol et.');
    } catch (e) {
      return AuthResult(success: false, message: _mapAuthException(e));
    }
  }

  /// Şifre sıfırlama kodu gönderir. Hesap var/yok bilgisini ifşa etmemek için
  /// her durumda başarılı döner.
  Future<void> sifreSifirlamaKoduGonder(String email) async {
    try {
      await _supabase?.auth.resetPasswordForEmail(email.trim());
    } catch (_) {}
  }

  /// E-postaya gelen 6 haneli kurtarma koduyla yeni şifreyi belirler, ardından
  /// oturumu kapatır (kullanıcı yeni şifresiyle giriş yapar).
  Future<AuthResult> sifreyiKodlaYenile({
    required String email,
    required String kod,
    required String yeniSifre,
  }) async {
    final supabase = _supabase;
    if (supabase == null) return _yapilandirmaHatasi;
    // Kayıt ve giriş ekranları şifreyi kırparak gönderir; burada da aynısı.
    yeniSifre = yeniSifre.trim();
    if (yeniSifre.length < 8) {
      return const AuthResult(success: false, message: 'Şifren en az 8 karakter olmalı.');
    }
    final eposta = email.trim().toLowerCase();
    try {
      // Kod tek kullanımlıktır. Önceki denemede kod doğrulanıp şifre adımı
      // reddedildiyse (ör. eski şifreyle aynı) kod tekrar sorulmaz.
      final kodDogrulandi = _kurtarmaEposta == eposta && supabase.auth.currentSession != null;
      if (!kodDogrulandi) {
        await supabase.auth.verifyOTP(email: eposta, token: kod.trim(), type: OtpType.recovery);
        _kurtarmaEposta = eposta;
      }
      await supabase.auth.updateUser(UserAttributes(password: yeniSifre));
      _kurtarmaEposta = null;
      // Şifre değişince diğer cihazlardaki oturumlar da kapatılır.
      try {
        await supabase.auth.signOut(scope: SignOutScope.global);
      } catch (_) {}
      await SupabaseAuthService.signOut();
      return const AuthResult(success: true, message: 'Şifren güncellendi. Yeni şifrenle giriş yapabilirsin.');
    } catch (e) {
      return AuthResult(success: false, message: _mapAuthException(e));
    }
  }

  String? _kurtarmaEposta;

  /// Şifre yenileme yarıda bırakılırsa kodla açılan geçici oturumu kapatır
  /// (kullanıcı şifresini belirlemeden girişli kalmasın).
  Future<void> kurtarmaOturumunuKapat() async {
    if (_kurtarmaEposta == null) return;
    _kurtarmaEposta = null;
    await SupabaseAuthService.signOut();
  }

  /// Oturumu Kapat
  Future<void> signOut() async {
    try {
      await SupabaseAuthService.signOut();
    } catch (_) {}
  }
}
