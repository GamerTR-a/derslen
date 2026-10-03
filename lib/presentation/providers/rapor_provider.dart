/// Haftalık/aylık ilerleme raporu için yardımcı provider'lar.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profil_provider.dart';

/// Rapor kartında seçili periyot (gün sayısı: 7 veya 30).
final raporPeriyotProvider = StateProvider<int>((ref) => 7);

/// Son [gunSayisi] günün günlük çalışma dakikası kaydı (tarih -> dakika).
final calismaGunlukLogProvider = FutureProvider.family<Map<String, int>, int>((ref, gunSayisi) async {
  final notifier = ref.watch(profilProvider.notifier);
  return notifier.calismaGunlukLog(gunSayisi);
});
