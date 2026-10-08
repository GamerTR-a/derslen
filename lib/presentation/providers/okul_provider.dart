/// Oturumdaki kullanıcının okul durumu ve öğrenciye gelen öğretmen önerileri.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/okul_service.dart';
import '../../data/models/okul_modelleri.dart';
import 'auth_provider.dart';

/// Rol, okul, şube ve veli/çocuk bağlantıları. Sunucuya ulaşılamazsa ya da
/// okul özellikleri kurulu değilse null döner (uygulama okul dışı gibi çalışır).
final okulDurumuProvider = FutureProvider<OkulDurumu?>((ref) async {
  final (userId, status, _) = ref.watch(authProvider.select((a) => (a.userId, a.status, a.rol)));
  if (userId == null || status != AuthStatus.authenticated) return null;
  try {
    return await OkulService.durum();
  } on OkulHatasi {
    return null;
  }
});

/// Öğrenci bir okulun şubesine kayıtlıysa açık topluluk ve herkese açık etüt
/// odaları gizlenir (sunucu da engeller).
final okulModuProvider = Provider<bool>((ref) => ref.watch(okulDurumuProvider).value?.okulOgrencisi ?? false);

/// Öğrencinin şubesine yapılmış güncel öğretmen önerileri.
final ogrenciOnerileriProvider = FutureProvider<List<Oneri>>((ref) async {
  if (!ref.watch(okulModuProvider)) return const [];
  try {
    return await OkulService.onerilerim();
  } on OkulHatasi {
    return const [];
  }
});
