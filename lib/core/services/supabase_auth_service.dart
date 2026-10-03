import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/auth_user.dart';

class SupabaseAuthException implements Exception {
  final String message;
  const SupabaseAuthException(this.message);

  @override
  String toString() => message;
}

class SupabaseAuthService {
  static SupabaseClient get _client => Supabase.instance.client;
  static const String _cachedUserKey = 'lisenet_cached_auth_user';

  /// Giriş ekranı, hatalı deneme sayacını yalnızca bu hatada artırır.
  static const String kimlikHatasiMesaji = 'E-posta adresi veya şifre hatalı.';
  static const String baglantiHatasiMesaji = 'Sunucuya ulaşılamadı. İnternet bağlantını kontrol edip tekrar dene.';

  /// Ağ kaynaklı hata mı (bağlantı yok, DNS, zaman aşımı)?
  static bool agHatasiMi(Object e) {
    if (e is TimeoutException || e is AuthRetryableFetchException) return true;
    final m = e.toString();
    return m.contains('SocketException') || m.contains('Failed host lookup') || m.contains('ClientException');
  }

  /// Standard Email Validation (Normal Mail)
  static void _validateStandardEmail(String email) {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) {
      throw const SupabaseAuthException('Lütfen e-posta adresinizi girin.');
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(cleanEmail)) {
      throw const SupabaseAuthException('Geçerli bir e-posta adresi giriniz (örnek: ad@domain.com).');
    }
  }

  /// Password Validation
  static void _validatePassword(String password) {
    if (password.length < 8) {
      throw const SupabaseAuthException('Şifreniz en az 8 karakter olmalıdır.');
    }
  }

  /// Giriş Yap (Login)
  static Future<LiseAuthUser> login({
    required String email,
    required String password,
  }) async {
    try {
      _validateStandardEmail(email);

      final res = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (res.user == null) {
        throw const SupabaseAuthException('E-posta veya şifre hatalı.');
      }

      // Buradan sonra oturum açılmıştır. Profil satırı okunamasa da giriş
      // başarısız sayılmaz; aksi hâlde kullanıcı "hata" görür ama uygulama
      // bir sonraki açılışta girişli gelir.
      LiseAuthUser authUser;
      try {
        var profile = await _client.from('profiles').select().eq('id', res.user!.id).maybeSingle();
        if (profile == null) {
          await _insertProfile(
            userId: res.user!.id,
            name: res.user!.email?.split('@').first ?? 'Kullanıcı',
          );
          profile = await _client.from('profiles').select().eq('id', res.user!.id).single();
        }
        authUser = LiseAuthUser.fromProfileJson(res.user!, profile);
      } catch (_) {
        authUser = LiseAuthUser(
          id: res.user!.id,
          name: res.user!.email?.split('@').first ?? 'Kullanıcı',
          email: res.user!.email ?? email.trim(),
          createdAt: DateTime.now(),
        );
      }

      await cacheAuthUser(authUser);
      return authUser;
    } on SupabaseAuthException {
      rethrow;
    } catch (e) {
      throw SupabaseAuthException(_mapError(e));
    }
  }

  /// Kayıt Ol (Register - Standard Email)
  static Future<LiseAuthUser> register({
    required String name,
    required String email,
    required String password,
    String? grade,
    String? department,
  }) async {
    try {
      _validateStandardEmail(email);
      _validatePassword(password);

      // Profil satırı sunucuda `handle_new_user` tetikleyicisiyle oluşturulur;
      // ad/sınıf/alan bilgisi kullanıcı metadata'sı olarak iletilir.
      final res = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'name': name.trim(),
          'grade': ?grade,
          'department': ?department,
        },
      );

      if (res.user == null) {
        throw const SupabaseAuthException('Kayıt işlemi gerçekleştirilemedi. Lütfen tekrar deneyin.');
      }

      // E-posta onayı açıkken kayıtlı bir adresle tekrar kayıt olunursa sunucu
      // hata vermez, kimliksiz (identities boş) sahte bir kullanıcı döner.
      if (res.session == null && (res.user!.identities?.isEmpty ?? false)) {
        throw const SupabaseAuthException('Bu e-posta adresi ile zaten bir hesap mevcut. Giriş yapmayı dene.');
      }

      if (res.session != null) {
        // Profil satırını tetikleyici zaten oluşturur; bu yazma başarısız olsa
        // bile hesap açılmıştır, kayıt başarısız sayılmamalı.
        try {
          await _insertProfile(
            userId: res.user!.id,
            name: name.trim(),
            grade: grade,
            department: department,
          );
        } catch (_) {}
      }

      final authUser = LiseAuthUser(
        id: res.user!.id,
        name: name.trim(),
        email: email.trim(),
        grade: grade,
        department: department,
        isAdmin: false,
        createdAt: DateTime.now(),
      );

      await cacheAuthUser(authUser);
      return authUser;
    } on SupabaseAuthException {
      rethrow;
    } catch (e) {
      throw SupabaseAuthException(_mapError(e));
    }
  }

  /// Profile Insert Helper
  static Future<void> _insertProfile({
    required String userId,
    required String name,
    String? grade,
    String? department,
  }) async {
    // role/xp gönderilmez: sunucu varsayılanları (student, 0) geçerlidir ve
    // mevcut bir satırda bu alanlar tetikleyiciyle kilitlidir.
    await _client.from('profiles').upsert({
      'id': userId,
      'name': name,
      'grade': grade,
      'department': department != null ? [department] : [],
    });
  }

  /// Hesap Silme (RPC Call)
  static Future<void> deleteAccount() async {
    try {
      await _client.rpc('delete_account');
      await signOut();
    } catch (e) {
      throw SupabaseAuthException(_mapError(e));
    }
  }

  /// Oturumu Kapat
  static Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedUserKey);
    } catch (_) {}
  }

  /// User Önbelleğe Alma
  static Future<void> cacheAuthUser(LiseAuthUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedUserKey, jsonEncode(user.toJson()));
    } catch (_) {}
  }

  /// Önbellekten Kullanıcıyı Getir
  static Future<LiseAuthUser?> getCachedAuthUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString(_cachedUserKey);
      if (userStr != null) {
        return LiseAuthUser.fromJson(jsonDecode(userStr));
      }
    } catch (_) {}
    return null;
  }

  /// Error Mapper
  static String _mapError(dynamic e) {
    if (agHatasiMi(e as Object)) return baglantiHatasiMesaji;
    if (e is AuthException) {
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login credentials') || msg.contains('invalid_grant')) {
        return kimlikHatasiMesaji;
      } else if (msg.contains('user already registered') || msg.contains('already_exists')) {
        return 'Bu e-posta adresi ile zaten bir hesap mevcut.';
      } else if (msg.contains('rate limit') || msg.contains('security purposes')) {
        return 'Çok fazla deneme yapıldı. Lütfen biraz bekleyin.';
      } else if (msg.contains('email not confirmed')) {
        return 'E-posta adresin henüz doğrulanmamış. Gelen kutunu kontrol et.';
      } else if (msg.contains('password')) {
        return 'Şifre yeterince güçlü değil. En az 8 karakter, harf ve rakam kullan.';
      }
      return 'İşlem gerçekleştirilemedi. Lütfen tekrar deneyin.';
    }
    return 'Beklenmeyen bir hata oluştu. Lütfen tekrar dene.';
  }
}
