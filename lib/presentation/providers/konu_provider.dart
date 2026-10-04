import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/sinif_mufredati.dart';
import '../../core/constants/yks_data.dart';
import '../../core/storage/analiz_kayitlari.dart';
import '../../core/storage/storage_service.dart';
import '../../core/utils/tarih.dart';
import '../../core/constants/app_constants.dart';
import 'mufredat_provider.dart';
import 'profil_provider.dart';

const String _konularStorageKey = 'konular_user_state';

/// Profile göre hazır (uygulamanın sunduğu) müfredat: serbest modda boş, 9-11.
/// sınıflarda o sınıfın Maarif Modeli konuları, diğerlerinde YKS konuları.
List<Konu> hazirMufredat(String? hedefBolum, String? sinifSeviyesi) {
  if (hedefBolum == serbestMufredat) return const [];
  final sinif = araSinif(sinifSeviyesi);
  if (sinif != null) return [for (final k in sinifKonulari(sinif)) k.konu];
  return tumKonular;
}

/// Kullanıcının geçerli müfredatı: gizlenmemiş hazır konular (sınıfa göre
/// Maarif ya da YKS) + kullanıcının eklediği konular; tamamlandı/zayıf
/// işaretleriyle.
class KonuNotifier extends StateNotifier<List<Konu>> {
  final StorageService _storageService;
  final Ref _ref;
  Map<String, dynamic> _durum = {};

  /// Kayıtlı konu durumları ve kişisel müfredat yüklenince tamamlanır. Konu
  /// durumuna göre hesap yapanlar (ör. ders programı) önce bunu bekler.
  late final Future<void> hazir;

  KonuNotifier(this._storageService, this._ref) : super(tumKonular) {
    hazir = _yukle();
  }

  Future<void> _yukle() async {
    try {
      _durum = await _storageService.getMap(_konularStorageKey) ?? {};
    } catch (e) {
      if (kDebugMode) debugPrint('KonuNotifier: konu durumu yüklenemedi: $e');
    }
    await _ref.read(mufredatProvider.notifier).hazir;
    yenidenKur();
  }

  /// Müfredat ya da hedef alan değişince konu listesini yeniden kurar.
  void yenidenKur() {
    if (!mounted) return;
    final m = _ref.read(mufredatProvider);
    final profil = _ref.read(profilProvider).value;
    final temel = [
      for (final k in hazirMufredat(profil?.hedefBolum, profil?.sinifSeviyesi))
        if (!m.gizliIdler.contains(k.id)) k,
      ...m.ozelKonular,
    ];
    state = [
      for (final k in temel)
        if (_durum[k.id] case final Map d)
          k.copyWith(tamamlandi: d['tamamlandi'] == true, zayif: d['zayif'] == true)
        else
          k,
    ];
  }

  Future<void> toggleTamamlandi(String id) async {
    state = state.map((k) {
      if (k.id == id) {
        return k.copyWith(tamamlandi: !k.tamamlandi);
      }
      return k;
    }).toList();
    await _saveState();
  }

  Future<void> toggleZayif(String id) async {
    state = state.map((k) {
      if (k.id == id) {
        return k.copyWith(zayif: !k.zayif);
      }
      return k;
    }).toList();
    await _saveState();
  }

  Future<void> _saveState() async {
    // Gizlenen ya da başka modda görünmeyen konuların durumu korunur.
    final gorunen = {for (final k in state) k.id};
    _durum = {
      for (final e in _durum.entries)
        if (!gorunen.contains(e.key)) e.key: e.value,
      for (final k in state)
        if (k.tamamlandi || k.zayif) k.id: {'tamamlandi': k.tamamlandi, 'zayif': k.zayif},
    };
    await _storageService.setMap(_konularStorageKey, _durum);

    // Konu ilerleme grafiği için günlük anlık görüntü: {tarih: [tamamlanan, zayıf]}
    final log = await _storageService.getMap(AnalizKayitlari.konuIlerleme) ?? {};
    log[gunAnahtari(DateTime.now())] = [
      state.where((k) => k.tamamlandi).length,
      state.where((k) => k.zayif).length,
    ];
    await _storageService.setMap(AnalizKayitlari.konuIlerleme, eskiKayitlariBudanmis(log));
  }
}

final konuProvider = StateNotifierProvider<KonuNotifier, List<Konu>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final n = KonuNotifier(storage, ref);
  ref.listen(mufredatProvider, (_, _) => n.yenidenKur());
  ref.listen(profilProvider.select((p) => (p.value?.hedefBolum, p.value?.sinifSeviyesi)), (_, _) => n.yenidenKur());
  return n;
});

/// Öğrencinin (gizlemeden önceki) hazır müfredatı.
final hazirMufredatProvider = Provider<List<Konu>>((ref) {
  final p = ref.watch(profilProvider.select((p) => (p.value?.hedefBolum, p.value?.sinifSeviyesi)));
  return hazirMufredat(p.$1, p.$2);
});

// Helper provider: Sinav alanına göre hazır (YKS) konular
final konularByAlanProvider = Provider.family<List<Konu>, SinavAlani>((ref, alan) {
  final tumu = ref.watch(konuProvider);
  return tumu.where((k) => k.alan == alan && !k.ozel).toList();
});
