/// Storage Service — SharedPreferences wrapper
/// Web projesindeki `src/lib/store.ts` getItem/setItem mantığından port edildi.
library;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show LocalStorage;
import 'dart:convert';

abstract class StorageService {
  Future<void> init();

  // Generic get/set
  Future<T?> get<T>(String key, T Function(Map<String, dynamic>) fromJson);
  Future<void> set<T>(String key, T value, Map<String, dynamic> Function(T) toJson);
  Future<void> remove(String key);
  Future<void> clear();

  // Typed helpers
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
  Future<int?> getInt(String key);
  Future<void> setInt(String key, int value);
  Future<bool?> getBool(String key);
  Future<void> setBool(String key, bool value);
  Future<List<String>?> getStringList(String key);
  Future<void> setStringList(String key, List<String> value);
  Future<Map<String, dynamic>?> getMap(String key);
  Future<void> setMap(String key, Map<String, dynamic> value);
}

class SharedPrefsStorageService implements StorageService {
  SharedPreferences? _prefs;
  final Map<String, dynamic> _memoryCache = {};

  @override
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      // SharedPreferences erişilemezse bellek içi önbelleğe fallback yap
      _prefs = null;
    }
  }

  SharedPreferences? get _instance => _prefs;

  @override
  Future<T?> get<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    try {
      final jsonString = _instance?.getString(key) ?? _memoryCache[key] as String?;
      if (jsonString == null) return null;
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return fromJson(json);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> set<T>(String key, T value, Map<String, dynamic> Function(T) toJson) async {
    final json = toJson(value);
    final jsonString = jsonEncode(json);
    _memoryCache[key] = jsonString;
    await _instance?.setString(key, jsonString);
  }

  @override
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    await _instance?.remove(key);
  }

  @override
  Future<void> clear() async {
    _memoryCache.clear();
    await _instance?.clear();
  }

  @override
  Future<String?> getString(String key) async =>
      _instance?.getString(key) ?? _memoryCache[key] as String?;

  @override
  Future<void> setString(String key, String value) async {
    _memoryCache[key] = value;
    await _instance?.setString(key, value);
  }

  @override
  Future<int?> getInt(String key) async =>
      _instance?.getInt(key) ?? _memoryCache[key] as int?;

  @override
  Future<void> setInt(String key, int value) async {
    _memoryCache[key] = value;
    await _instance?.setInt(key, value);
  }

  @override
  Future<bool?> getBool(String key) async =>
      _instance?.getBool(key) ?? _memoryCache[key] as bool?;

  @override
  Future<void> setBool(String key, bool value) async {
    _memoryCache[key] = value;
    await _instance?.setBool(key, value);
  }

  @override
  Future<List<String>?> getStringList(String key) async =>
      _instance?.getStringList(key) ?? (_memoryCache[key] as List<dynamic>?)?.cast<String>();

  @override
  Future<void> setStringList(String key, List<String> value) async {
    _memoryCache[key] = value;
    await _instance?.setStringList(key, value);
  }

  @override
  Future<Map<String, dynamic>?> getMap(String key) async {
    try {
      final jsonString = _instance?.getString(key) ?? _memoryCache[key] as String?;
      if (jsonString == null) return null;
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> setMap(String key, Map<String, dynamic> value) async {
    final jsonString = jsonEncode(value);
    _memoryCache[key] = jsonString;
    await _instance?.setString(key, jsonString);
  }
}

/// Secure Storage Service — FlutterSecureStorage wrapper
/// Hassas veriler (token, API key) için
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  static Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  static Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  static Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }

  // Supabase credentials
  static const String supabaseUrl = 'supabase_url';
  static const String supabaseAnonKey = 'supabase_anon_key';
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';

  static Future<void> saveSupabaseCredentials(String url, String anonKey) async {
    await write(supabaseUrl, url);
    await write(supabaseAnonKey, anonKey);
  }

  static Future<(String?, String?)> getSupabaseCredentials() async {
    final url = await read(supabaseUrl);
    final key = await read(supabaseAnonKey);
    return (url, key);
  }

  static Future<void> saveAuthTokens(String accessToken, String refreshToken) async {
    await write(SecureStorageService.authToken, accessToken);
    await write(SecureStorageService.refreshToken, refreshToken);
  }

  static Future<(String?, String?)> getAuthTokens() async {
    final access = await read(authToken);
    final refresh = await read(refreshToken);
    return (access, refresh);
  }

  static Future<void> clearAuthTokens() async {
    await delete(authToken);
    await delete(refreshToken);
  }
}

/// Supabase oturum (JWT access/refresh token) kalıcılığı için `flutter_secure_storage`
/// tabanlı [LocalStorage] implementasyonu. Varsayılan `SharedPreferencesLocalStorage`
/// yerine kullanılarak oturum verisinin düz metin SharedPreferences yerine
/// iOS Keychain / Android Keystore'da şifreli tutulması sağlanır.
class SecureSupabaseLocalStorage extends LocalStorage {
  const SecureSupabaseLocalStorage();

  static const _sessionKey = 'supabase_session';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    return SecureStorageService.containsKey(_sessionKey);
  }

  @override
  Future<String?> accessToken() async {
    return SecureStorageService.read(_sessionKey);
  }

  @override
  Future<void> removePersistedSession() async {
    await SecureStorageService.delete(_sessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    await SecureStorageService.write(_sessionKey, persistSessionString);
  }
}