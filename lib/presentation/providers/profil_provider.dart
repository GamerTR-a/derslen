import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/storage_service.dart';
import '../../core/storage/storage_provider.dart';
import '../../data/models/ogrenci_profil.dart';
import '../../core/constants/app_constants.dart';
import '../../core/algorithms/analiz_motoru.dart' show calismaSerisi;
import '../../core/storage/analiz_kayitlari.dart';
import '../../core/utils/tarih.dart';

export '../../core/storage/storage_provider.dart' show storageServiceProvider;

const String _profilStorageKey = 'ogrenci_profil_data';
const String _calismaLoguStorageKey = AnalizKayitlari.calismaGunluk;

/// Ham, kullanıcıdan bağımsız yerel depo. `main.dart`'ta önceden init edilip
/// override edilir. Auth akışı (auth_provider.dart) bunu kullanır; buluta
/// senkronize öğrenci verisi için akıllı `storageServiceProvider`'ı
/// (core/storage/storage_provider.dart) kullanın.
final localStorageServiceProvider = Provider<StorageService>((ref) {
  return SharedPrefsStorageService();
});

class ProfilNotifier extends StateNotifier<AsyncValue<OgrenciProfil>> {
  final StorageService _storageService;

  /// Açılıştaki yükleme sürerken profil kaydedildiyse yükleme sonucu onu ezmez.
  bool _yerelDegisti = false;

  ProfilNotifier(this._storageService) : super(const AsyncValue.loading()) {
    loadProfil();
  }

  Future<void> loadProfil() async {
    state = const AsyncValue.loading();
    try {
      final map = await _storageService.getMap(_profilStorageKey);
      if (_yerelDegisti) return;
      if (map != null) {
        final profil = OgrenciProfil.fromJson(map);
        state = AsyncValue.data(profil);
        await seriyiDogrula();
      } else {
        // Profil bulunamadı, varsayılan boş (onboarding yapılmamış) profil
        state = const AsyncValue.data(OgrenciProfil(onboardingTamamlandi: false));
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> kaydetProfil({
    required String hedefBolum,
    required int gunlukSaat,
    required OgrenmeMetod ogrenmeMetod,
    String? hedefUniversite,
    int? hedefPuan,
    String? sinifSeviyesi,
  }) async {
    _yerelDegisti = true;
    final mevcut = state.value ?? const OgrenciProfil();
    final guncelProfil = mevcut.copyWith(
      sinifSeviyesi: sinifSeviyesi ?? mevcut.sinifSeviyesi,
      hedefBolum: hedefBolum,
      gunlukSaat: gunlukSaat,
      ogrenmeMetod: ogrenmeMetod,
      hedefUniversite: hedefUniversite,
      hedefPuan: hedefPuan ?? mevcut.hedefPuan,
      onboardingTamamlandi: true,
      sonAktifGun: DateTime.now().toIso8601String().split('T')[0],
    );

    state = AsyncValue.data(guncelProfil);
    await _storageService.setMap(_profilStorageKey, guncelProfil.toJson());
  }

  Future<void> guncelleMetod(OgrenmeMetod yeniMetod) async {
    if (state.value == null) return;
    final guncel = state.value!.copyWith(ogrenmeMetod: yeniMetod);
    state = AsyncValue.data(guncel);
    await _storageService.setMap(_profilStorageKey, guncel.toJson());
  }

  /// Tamamlanan bir çalışmayı kaydeder: toplam süre, günlük kırılım, ders
  /// bazlı kırılım (analiz grafikleri için) ve çalışma serisi güncellenir.
  Future<void> calismaSuresiEkle(int dakika, {String? ders}) async {
    if (state.value == null || dakika <= 0) return;
    final bugun = DateTime.now();
    final anahtar = gunAnahtari(bugun);

    final log = await _storageService.getMap(_calismaLoguStorageKey) ?? {};
    log[anahtar] = ((log[anahtar] as num?) ?? 0).toInt() + dakika;
    await _storageService.setMap(_calismaLoguStorageKey, eskiKayitlariBudanmis(log));

    final dersAdi = dersAdiNormalize(ders ?? 'Genel');
    final dersLog = await _storageService.getMap(AnalizKayitlari.calismaDers) ?? {};
    final gunluk = Map<String, dynamic>.from((dersLog[anahtar] as Map?) ?? const {});
    gunluk[dersAdi] = ((gunluk[dersAdi] as num?) ?? 0).toInt() + dakika;
    dersLog[anahtar] = gunluk;
    await _storageService.setMap(AnalizKayitlari.calismaDers, eskiKayitlariBudanmis(dersLog));

    final gunlukLog = {for (final e in log.entries) e.key: ((e.value as num?) ?? 0).toInt()};
    final guncel = state.value!.copyWith(
      toplamCalismaDk: state.value!.toplamCalismaDk + dakika,
      streak: calismaSerisi(gunlukLog, bugun),
      sonAktifGun: anahtar,
    );
    state = AsyncValue.data(guncel);
    await _storageService.setMap(_profilStorageKey, guncel.toJson());
  }

  /// Uygulama açılışında seriyi kayıttan yeniden hesaplar (dün çalışılmadıysa
  /// sıfırlanır). Profilde kayıtlı değer yalnızca önbellektir.
  Future<void> seriyiDogrula() async {
    final profil = state.value;
    if (profil == null || !profil.onboardingTamamlandi) return;
    final log = await _storageService.getMap(_calismaLoguStorageKey) ?? {};
    final seri = calismaSerisi({for (final e in log.entries) e.key: ((e.value as num?) ?? 0).toInt()}, DateTime.now());
    if (seri != profil.streak) {
      final guncel = profil.copyWith(streak: seri);
      state = AsyncValue.data(guncel);
      await _storageService.setMap(_profilStorageKey, guncel.toJson());
    }
  }

  /// Son [gunSayisi] günün günlük çalışma dakikası kaydını döndürür (tarih -> dakika).
  Future<Map<String, int>> calismaGunlukLog(int gunSayisi) async {
    final log = await _storageService.getMap(_calismaLoguStorageKey) ?? {};
    final result = <String, int>{};
    final bugun = DateTime.now();
    for (var i = gunSayisi - 1; i >= 0; i--) {
      final gun = bugun.subtract(Duration(days: i));
      final anahtar = '${gun.year}-${gun.month.toString().padLeft(2, '0')}-${gun.day.toString().padLeft(2, '0')}';
      result[anahtar] = ((log[anahtar] as num?) ?? 0).toInt();
    }
    return result;
  }

  Future<void> profilSifirla() async {
    await _storageService.remove(_profilStorageKey);
    state = const AsyncValue.data(OgrenciProfil(onboardingTamamlandi: false));
  }
}

final profilProvider =
    StateNotifierProvider<ProfilNotifier, AsyncValue<OgrenciProfil>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ProfilNotifier(storage);
});
