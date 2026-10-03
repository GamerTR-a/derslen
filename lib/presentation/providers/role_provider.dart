/// Giriş yapan kullanıcının sunucu tarafındaki rolünü (`profiles.role`) getirir.
/// `authProvider`'daki `userId` değiştiğinde (giriş/çıkış) otomatik yeniden hesaplanır.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_provider.dart';

final currentUserRoleProvider = FutureProvider<String?>((ref) async {
  final userId = ref.watch(authProvider).userId;
  if (userId == null) return null;

  try {
    final row = await Supabase.instance.client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();
    return row?['role'] as String?;
  } catch (e) {
    return null;
  }
});

class CurrentUserProfile {
  final String name;
  final String? email;
  final String? role;

  const CurrentUserProfile({required this.name, this.email, this.role});
}

/// Giriş yapan kullanıcının (koç/admin) ad ve e-posta bilgisini getirir.
/// Profil ekranlarında hardcoded/mock ad-soyad göstermek yerine kullanılır.
final currentUserProfileProvider = FutureProvider<CurrentUserProfile?>((ref) async {
  final authState = ref.watch(authProvider);
  final userId = authState.userId;
  if (userId == null) return null;

  try {
    final row = await Supabase.instance.client
        .from('profiles')
        .select('name, role')
        .eq('id', userId)
        .maybeSingle();
    return CurrentUserProfile(
      name: (row?['name'] as String?) ?? authState.email?.split('@').first ?? 'Kullanıcı',
      email: authState.email,
      role: row?['role'] as String?,
    );
  } catch (e) {
    return CurrentUserProfile(name: authState.email?.split('@').first ?? 'Kullanıcı', email: authState.email);
  }
});
