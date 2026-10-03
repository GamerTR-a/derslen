import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/analiz_kayitlari.dart';
import '../../core/storage/storage_service.dart';
import '../../data/models/gunluk_checkin.dart';
import 'profil_provider.dart';

const String _checkinStorageKeyPrefix = 'checkin_';

class CheckinNotifier extends StateNotifier<GunlukCheckin> {
  final StorageService _storageService;

  CheckinNotifier(this._storageService) : super(_defaultCheckin()) {
    loadBugunkuCheckin();
  }

  static String get _bugunKey {
    final now = DateTime.now();
    return '$_checkinStorageKeyPrefix${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static GunlukCheckin _defaultCheckin() {
    final now = DateTime.now();
    final bugun = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return GunlukCheckin(
      tarih: bugun,
      enerji: 3,
      odak: 3,
      stres: 2,
      createdAt: now,
    );
  }

  Future<void> loadBugunkuCheckin() async {
    try {
      final map = await _storageService.getMap(_bugunKey);
      if (map != null) {
        state = GunlukCheckin.fromJson(map);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('CheckinNotifier: günlük check-in yüklenemedi: $e');
    }
  }

  Future<void> kaydetCheckin({
    required int enerji,
    required int odak,
    required int stres,
  }) async {
    final now = DateTime.now();
    final bugun = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final guncel = GunlukCheckin(
      tarih: bugun,
      enerji: enerji.clamp(1, 5),
      odak: odak.clamp(1, 5),
      stres: stres.clamp(1, 5),
      createdAt: now,
    );

    state = guncel;
    await _storageService.setMap(_bugunKey, guncel.toJson());

    // Analiz grafikleri için tüm günler tek kayıtta: {tarih: [enerji, odak, stres]}
    final log = await _storageService.getMap(AnalizKayitlari.checkin) ?? {};
    log[bugun] = [guncel.enerji, guncel.odak, guncel.stres];
    await _storageService.setMap(AnalizKayitlari.checkin, eskiKayitlariBudanmis(log));
  }
}

final checkinProvider =
    StateNotifierProvider<CheckinNotifier, GunlukCheckin>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return CheckinNotifier(storage);
});
