/// Akıllı StorageService provider'ı — kullanıcı oturum açıksa Supabase ile
/// senkronize (SyncedStorageService), değilse ham yerel depo döner.
///
/// `authProvider`'ı izler; `localStorageServiceProvider`'a ise sadece bu dosya
/// ve `auth_provider.dart` bağımlıdır (tersi yok), böylece döngüsel bağımlılık
/// oluşmaz: authProvider → localStorageServiceProvider, storageServiceProvider
/// → (localStorageServiceProvider + authProvider).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/profil_provider.dart' show localStorageServiceProvider;
import 'storage_service.dart';
import 'synced_storage_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  final local = ref.watch(localStorageServiceProvider);
  final userId = ref.watch(authProvider).userId;
  ref.watch(bulutEsitlemeSurumuProvider);

  if (userId == null) return local;
  return SyncedStorageService(local: local, userId: userId);
});
