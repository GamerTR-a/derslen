/// Rozet/Başarım durumu — streak, deneme, konu ve flashkart verilerini izleyip
/// yeni kazanılan rozetleri hesaplar, `student_data` üzerinden buluta senkronlar
/// ve kazanıldığında XP ödülünü `profiles.xp`'ye ekler.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/supabase_data_service.dart';
import '../../data/models/rozet.dart';
import 'profil_provider.dart';
import 'net_provider.dart';
import 'konu_provider.dart';
import 'flashkart_provider.dart';

const String _kazanilanRozetlerKey = 'kazanilan_rozetler';

class RozetNotifier extends StateNotifier<List<String>> {
  final Ref _ref;

  RozetNotifier(this._ref) : super([]) {
    _load();
  }

  Future<void> _load() async {
    final storage = _ref.read(storageServiceProvider);
    final map = await storage.getMap(_kazanilanRozetlerKey);
    final kazanilanlar = (map?['ids'] as List?)?.cast<String>() ?? <String>[];
    state = kazanilanlar;
    await _degerlendir();
  }

  /// Mevcut ilerleme verilerine göre yeni kazanılmış rozet var mı kontrol eder.
  Future<void> _degerlendir() async {
    final profil = _ref.read(profilProvider).value;
    if (profil == null || !profil.onboardingTamamlandi) return;

    final denemeSayisi = _ref.read(netProvider).length;
    final tamamlananKonuSayisi = _ref.read(konuProvider).where((k) => k.tamamlandi).length;
    final toplamFlashkartTekrari = _ref
        .read(flashkartProvider)
        .durumlar
        .fold<int>(0, (toplam, d) => toplam + d.tekrarSayisi);

    final veri = RozetIlerlemeVerisi(
      streak: profil.streak,
      denemeSayisi: denemeSayisi,
      tamamlananKonuSayisi: tamamlananKonuSayisi,
      toplamFlashkartTekrari: toplamFlashkartTekrari,
    );

    final yeniKazanilanlar = <String>[];
    for (final rozet in rozetKatalogu) {
      if (!state.contains(rozet.id) && rozet.kazanildiMi(veri)) {
        yeniKazanilanlar.add(rozet.id);
      }
    }

    if (yeniKazanilanlar.isEmpty) return;

    final guncelListe = [...state, ...yeniKazanilanlar];
    state = guncelListe;

    final storage = _ref.read(storageServiceProvider);
    await storage.setMap(_kazanilanRozetlerKey, {'ids': guncelListe});

    for (final id in yeniKazanilanlar) {
      await SupabaseDataService.awardBadgeXp(id);
    }
  }

  /// Bir kullanıcı eylemi (net eklendi, konu tamamlandı vb.) sonrası çağrılır.
  Future<void> yenidenDegerlendir() => _degerlendir();
}

final rozetProvider = StateNotifierProvider<RozetNotifier, List<String>>((ref) {
  final notifier = RozetNotifier(ref);
  // Bağımlı veriler değiştiğinde yeniden değerlendirme tetiklenir.
  ref.listen(netProvider, (_, _) => notifier.yenidenDegerlendir());
  ref.listen(konuProvider, (_, _) => notifier.yenidenDegerlendir());
  ref.listen(flashkartProvider, (_, _) => notifier.yenidenDegerlendir());
  ref.listen(profilProvider, (_, _) => notifier.yenidenDegerlendir());
  return notifier;
});
