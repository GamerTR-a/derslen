/// Synced Storage Service — kullanıcıya özel, Supabase ile senkronize StorageService.
///
/// Yerel önbellek (SharedPrefsStorageService) birincil okuma kaynağıdır (hızlı, offline
/// çalışır); her yazma aynı zamanda `public.student_data` tablosuna upsert edilir.
/// Anahtarlar `sd_<userId>_<key>` olarak isim alanına ayrılır ki aynı cihazda birden
/// fazla hesap kullanıldığında veriler karışmasın.
///
/// Çakışma kuralı: her anahtar için sunucudaki son `updated_at` yerelde tutulur.
/// Buluta ulaşamayan yazmalar "kirli" işaretlenir ve bir sonraki eşitlemede
/// yeniden gönderilir. Eşitlemede bulut daha yeniyse ve yerelde gönderilmemiş
/// değişiklik yoksa yerel kopya güncellenir; kirli anahtarda yerel kazanır.
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'storage_service.dart';

/// `student_data` tablosundaki bir satır.
class BulutKayit {
  final String anahtar;
  final Map<String, dynamic> deger;
  final DateTime? guncelleme;

  const BulutKayit(this.anahtar, this.deger, this.guncelleme);
}

/// `student_data` erişimi. Yöntemler ağ/sunucu hatasında istisna fırlatır.
abstract class BulutDepo {
  Future<List<BulutKayit>> hepsi(String userId);
  Future<BulutKayit?> getir(String userId, String anahtar);

  /// Satırı yazar ve sunucunun kaydettiği `updated_at` değerini döner.
  Future<DateTime?> yaz(String userId, String anahtar, Map<String, dynamic> deger);
  Future<void> sil(String userId, String anahtar);
}

class SupabaseBulutDepo implements BulutDepo {
  const SupabaseBulutDepo();

  SupabaseClient get _db => Supabase.instance.client;

  static BulutKayit _satir(Map<String, dynamic> r) => BulutKayit(
        r['data_key'] as String,
        Map<String, dynamic>.from(r['data_value'] as Map),
        DateTime.tryParse(r['updated_at'] as String? ?? ''),
      );

  @override
  Future<List<BulutKayit>> hepsi(String userId) async {
    final rows = await _db.from('student_data').select('data_key, data_value, updated_at').eq('user_id', userId);
    return [for (final r in rows as List) _satir(Map<String, dynamic>.from(r as Map))];
  }

  @override
  Future<BulutKayit?> getir(String userId, String anahtar) async {
    final row = await _db
        .from('student_data')
        .select('data_key, data_value, updated_at')
        .eq('user_id', userId)
        .eq('data_key', anahtar)
        .maybeSingle();
    return row == null ? null : _satir(row);
  }

  @override
  Future<DateTime?> yaz(String userId, String anahtar, Map<String, dynamic> deger) async {
    final row = await _db
        .from('student_data')
        .upsert({
          'user_id': userId,
          'data_key': anahtar,
          'data_value': deger,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .select('updated_at')
        .single();
    return DateTime.tryParse(row['updated_at'] as String? ?? '');
  }

  @override
  Future<void> sil(String userId, String anahtar) async {
    await _db.from('student_data').delete().eq('user_id', userId).eq('data_key', anahtar);
  }
}

class SyncedStorageService implements StorageService {
  SyncedStorageService({
    required StorageService local,
    required String userId,
    BulutDepo bulut = const SupabaseBulutDepo(),
  })  : _local = local,
        _userId = userId,
        _bulut = bulut;

  final StorageService _local;
  final String _userId;
  final BulutDepo _bulut;

  static const List<String> _legacyFixedKeys = [
    'ogrenci_profil_data',
    'flashkart_durumlari',
    'net_kayitlari_listesi',
    'konular_user_state',
  ];

  String _namespaced(String key) => 'sd_${_userId}_$key';
  String _zamanAnahtari(String key) => '${_namespaced(key)}__at';
  String get _kirliAnahtari => 'sd_${_userId}___kirli';

  Future<Set<String>> _kirliler() async => (await _local.getStringList(_kirliAnahtari) ?? const []).toSet();

  Future<void> _kirliIsaretle(String key, bool kirli) async {
    final k = await _kirliler();
    if (kirli ? k.add(key) : k.remove(key)) {
      await _local.setStringList(_kirliAnahtari, k.toList());
    }
  }

  Future<void> _zamanYaz(String key, DateTime? zaman) async {
    if (zaman != null) await _local.setString(_zamanAnahtari(key), zaman.toUtc().toIso8601String());
  }

  /// Yazmayı buluta gönderir. Başarısız olursa anahtar kirli kalır ve
  /// [bulutlaEsitle] sırasında yeniden denenir.
  Future<void> _pushToCloud(String key, Map<String, dynamic> value) async {
    await _kirliIsaretle(key, true);
    try {
      final zaman = await _bulut.yaz(_userId, key, value);
      await _zamanYaz(key, zaman);
      // Gönderim sürerken anahtar yeniden yazıldıysa kirli kalır.
      final guncel = await _local.getMap(_namespaced(key));
      if (guncel != null && _esit(guncel, value)) await _kirliIsaretle(key, false);
    } catch (e) {
      if (kDebugMode) debugPrint('SyncedStorageService: bulut senkronizasyonu başarısız ($key): $e');
    }
  }

  Future<Map<String, dynamic>?> _pullFromCloud(String key) async {
    try {
      final kayit = await _bulut.getir(_userId, key);
      if (kayit == null) return null;
      await _zamanYaz(key, kayit.guncelleme);
      return kayit.deger;
    } catch (e) {
      if (kDebugMode) debugPrint('SyncedStorageService: bulut okuma başarısız ($key): $e');
      return null;
    }
  }

  /// Yereli bulutla eşitler: eksik anahtarları doldurur, bulutta daha yeni
  /// olanları alır, gönderilememiş yerel değişiklikleri yeniden gönderir.
  /// Yerel kopya değiştiyse true döner (bellekteki durum yeniden yüklenmeli).
  Future<bool> bulutlaEsitle() async {
    var yerelDegisti = false;
    try {
      final kayitlar = await _bulut.hepsi(_userId);
      final kirli = await _kirliler();

      for (final kayit in kayitlar) {
        final key = kayit.anahtar;
        if (kirli.contains(key)) continue;
        final yerel = await _local.getMap(_namespaced(key));

        if (yerel == null) {
          await _local.setMap(_namespaced(key), kayit.deger);
          await _zamanYaz(key, kayit.guncelleme);
          yerelDegisti = true;
          continue;
        }

        final yerelZaman = DateTime.tryParse(await _local.getString(_zamanAnahtari(key)) ?? '');
        if (yerelZaman == null) {
          // Zaman damgası tutulmayan eski sürümden kalan kopya: hangisinin yeni
          // olduğu bilinemez; gönderilmemiş değişiklik kaybolmasın diye yerel kazanır.
          if (_esit(yerel, kayit.deger)) {
            await _zamanYaz(key, kayit.guncelleme);
          } else {
            await _kirliIsaretle(key, true);
          }
        } else if (kayit.guncelleme != null && kayit.guncelleme!.isAfter(yerelZaman)) {
          await _local.setMap(_namespaced(key), kayit.deger);
          await _zamanYaz(key, kayit.guncelleme);
          yerelDegisti = true;
        }
      }

      for (final key in await _kirliler()) {
        final yerel = await _local.getMap(_namespaced(key));
        if (yerel == null) {
          await _kirliIsaretle(key, false);
        } else {
          await _pushToCloud(key, yerel);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('SyncedStorageService: bulutlaEsitle başarısız: $e');
    }
    return yerelDegisti;
  }

  /// Kullanıcıya-özel isim alanı olmadan önce yazılmış eski (legacy) yerel
  /// verileri, bu kullanıcının hesabına tek seferlik taşır.
  Future<void> migrateLegacyLocalData() async {
    final migratedFlagKey = 'migrated_v1_$_userId';
    final alreadyMigrated = await _local.getBool(migratedFlagKey) ?? false;
    if (alreadyMigrated) return;

    final keysToCheck = <String>{..._legacyFixedKeys};
    try {
      final prefs = await SharedPreferences.getInstance();
      keysToCheck.addAll(prefs.getKeys().where((k) => k.startsWith('checkin_')));
    } catch (e) {
      if (kDebugMode) debugPrint('SyncedStorageService: legacy anahtar taraması başarısız: $e');
    }

    for (final legacyKey in keysToCheck) {
      final legacyValue = await _local.getMap(legacyKey);
      if (legacyValue == null) continue;

      final cloudValue = await _pullFromCloud(legacyKey);
      if (cloudValue == null) {
        await _local.setMap(_namespaced(legacyKey), legacyValue);
        await _pushToCloud(legacyKey, legacyValue);
      }
      await _local.remove(legacyKey);
    }

    await _local.setBool(migratedFlagKey, true);
  }

  @override
  Future<void> init() => _local.init();

  @override
  Future<T?> get<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    final map = await getMap(key);
    if (map == null) return null;
    return fromJson(map);
  }

  @override
  Future<void> set<T>(String key, T value, Map<String, dynamic> Function(T) toJson) =>
      setMap(key, toJson(value));

  @override
  Future<void> remove(String key) async {
    await _local.remove(_namespaced(key));
    await _local.remove(_zamanAnahtari(key));
    await _kirliIsaretle(key, false);
    try {
      await _bulut.sil(_userId, key);
    } catch (e) {
      if (kDebugMode) debugPrint('SyncedStorageService: bulut silme başarısız ($key): $e');
    }
  }

  @override
  Future<void> clear() => _local.clear();

  /// Yalnızca bu kullanıcıya ait namespaced anahtarları (`sd_<userId>_*` ve
  /// migrasyon bayrağını) yerelden temizler. Uygulama genelindeki ayarları
  /// (tema, yazı boyutu gibi paylaşılan/kullanıcıdan bağımsız tercihleri)
  /// etkilemez — normal "çıkış yap" akışında `clear()` yerine bu kullanılır.
  Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefix = 'sd_${_userId}_';
      final keysToRemove = prefs.getKeys().where(
            (k) => k.startsWith(prefix) || k == 'migrated_v1_$_userId',
          );
      for (final key in keysToRemove.toList()) {
        await prefs.remove(key);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('SyncedStorageService: clearUserData başarısız: $e');
    }
  }

  // Skaler yardımcılar (getString/getInt/getBool/getStringList) şu an hiçbir
  // provider tarafından bulut senkronlu depoda kullanılmıyor (hepsi getMap/setMap
  // ile çalışıyor) — bunlar sadece yerel önbelleğe, isim alanı ayrılmış olarak
  // delege edilir; bulut senkronu gerekmiyor.
  @override
  Future<String?> getString(String key) => _local.getString(_namespaced(key));

  @override
  Future<void> setString(String key, String value) => _local.setString(_namespaced(key), value);

  @override
  Future<int?> getInt(String key) => _local.getInt(_namespaced(key));

  @override
  Future<void> setInt(String key, int value) => _local.setInt(_namespaced(key), value);

  @override
  Future<bool?> getBool(String key) => _local.getBool(_namespaced(key));

  @override
  Future<void> setBool(String key, bool value) => _local.setBool(_namespaced(key), value);

  @override
  Future<List<String>?> getStringList(String key) => _local.getStringList(_namespaced(key));

  @override
  Future<void> setStringList(String key, List<String> value) =>
      _local.setStringList(_namespaced(key), value);

  @override
  Future<Map<String, dynamic>?> getMap(String key) async {
    final local = await _local.getMap(_namespaced(key));
    if (local != null) return local;

    final cloud = await _pullFromCloud(key);
    if (cloud != null) {
      await _local.setMap(_namespaced(key), cloud);
    }
    return cloud;
  }

  @override
  Future<void> setMap(String key, Map<String, dynamic> value) async {
    await _local.setMap(_namespaced(key), value);
    await _pushToCloud(key, value);
  }
}

/// JSON değerleri için derin eşitlik (JSONB anahtar sırasını korumaz).
bool _esit(Object? a, Object? b) {
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      if (!b.containsKey(k) || !_esit(a[k], b[k])) return false;
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_esit(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}
