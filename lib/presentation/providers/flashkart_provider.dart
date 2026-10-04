import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/algorithms/sm2.dart';
import '../../core/constants/flashkart_data.dart';
import '../../core/constants/sinif_mufredati.dart';
import '../../core/storage/storage_service.dart';
import '../../data/models/kart_durum.dart';
import '../../data/models/soru.dart';
import 'mufredat_provider.dart';
import 'profil_provider.dart';

/// Bir sınıfın (9-11) müfredat konularına bağlı hazır kartların kimlikleri.
Set<String> sinifKartIdleri(int sinif) => _sinifKartIdleri.putIfAbsent(sinif, () {
      final konular = sinifKonulari(sinif);
      return {
        for (final k in flashKartlar)
          if (konular.any((t) => t.kartEslesir(k.id, k.ders, k.unite))) k.id,
      };
    });

final Map<int, Set<String>> _sinifKartIdleri = {};

const String _flashkartStorageKey = 'flashkart_durumlari';
const String _ozelKartlarStorageKey = 'flashkart_ozel_kartlar';
const String _bilemedimStorageKey = 'flashkart_bilemedim';
const String _yeniSayacStorageKey = 'flashkart_yeni_sayac';

/// Hazır destelerden bir günde tanıtılacak en fazla yeni kart. Kullanıcının
/// kendi kartları ve Yanlışlarım bu sınıra tabi değildir.
const int gunlukYeniKartSiniri = 25;

String _bugunAnahtari() => DateTime.now().toIso8601String().split('T')[0];

/// Hiç değerlendirilmemiş kart mı?
bool yeniKartMi(KartDurum d) => d.tekrarSayisi == 0 && !d.updatedAt.isAfter(d.createdAt);

/// Kullanıcının kendi eklediği kartların destesi.
const String ozelDeste = 'ozel';

/// Test yanlışlarından otomatik oluşturulan kartların destesi.
const String yanlisDeste = 'yanlislar';

class FlashkartState {
  final List<KartDurum> durumlar;
  final List<FlashKart> ozelKartlar;
  final String seciliDers; // 'hepsi' veya deste kimliği

  /// "Bilemedim" denilen kartlar. "Yanlışlarım" destesinde, testten gelen
  /// yanlış kartlarla birlikte listelenir; "Kolaydı" denince çıkar.
  final Set<String> bilemedimIdleri;

  /// Bugün tanıtılan hazır (yeni) kart sayısı ve ait olduğu gün.
  final int bugunYeniSayisi;
  final String yeniSayacTarihi;

  /// Sınıf süzgeci (9, 10, 11): yalnızca o sınıfın konularına ait hazır
  /// kartlar gösterilir. null ise tüm hazır kartlar. Kullanıcının kendi
  /// kartları ve testten gelen yanlışlar her zaman görünür.
  final int? sinif;

  const FlashkartState({
    required this.durumlar,
    this.ozelKartlar = const [],
    this.sinif,
    this.seciliDers = 'hepsi',
    this.bilemedimIdleri = const {},
    this.bugunYeniSayisi = 0,
    this.yeniSayacTarihi = '',
  });

  /// Bugün daha kaç hazır yeni kart tanıtılabilir.
  int get kalanYeniKart =>
      yeniSayacTarihi == _bugunAnahtari() ? max(0, gunlukYeniKartSiniri - bugunYeniSayisi) : gunlukYeniKartSiniri;

  List<FlashKart> get tumKartlar {
    final s = sinif;
    if (s == null) return [...flashKartlar, ...ozelKartlar];
    final idler = sinifKartIdleri(s);
    return [
      for (final k in flashKartlar)
        if (idler.contains(k.id)) k,
      ...ozelKartlar,
    ];
  }

  /// Kart "Yanlışlarım" destesinde mi (testten gelen yanlış ya da bilinemeyen kart)?
  bool yanlislardaMi(FlashKart k) => k.ders == yanlisDeste || bilemedimIdleri.contains(k.id);

  /// Bir destenin tüm kartları (tekrar zamanı gelmemiş olanlar dahil).
  List<FlashKart> desteKartlari(String deste) {
    if (deste == 'hepsi') return tumKartlar;
    if (deste == yanlisDeste) return tumKartlar.where(yanlislardaMi).toList();
    return tumKartlar.where((k) => k.ders == deste).toList();
  }

  FlashkartState copyWith({
    List<KartDurum>? durumlar,
    List<FlashKart>? ozelKartlar,
    String? seciliDers,
    Set<String>? bilemedimIdleri,
    int? bugunYeniSayisi,
    String? yeniSayacTarihi,
    int? sinif,
    bool sinifTemizle = false,
  }) {
    return FlashkartState(
      durumlar: durumlar ?? this.durumlar,
      ozelKartlar: ozelKartlar ?? this.ozelKartlar,
      sinif: sinifTemizle ? null : (sinif ?? this.sinif),
      seciliDers: seciliDers ?? this.seciliDers,
      bilemedimIdleri: bilemedimIdleri ?? this.bilemedimIdleri,
      bugunYeniSayisi: bugunYeniSayisi ?? this.bugunYeniSayisi,
      yeniSayacTarihi: yeniSayacTarihi ?? this.yeniSayacTarihi,
    );
  }
}

class FlashkartNotifier extends StateNotifier<FlashkartState> {
  final StorageService _storageService;

  FlashkartNotifier(this._storageService, {int? sinif})
      : super(FlashkartState(
          durumlar: flashKartlar.map((k) => KartDurum.yeniKart(k.id)).toList(),
          sinif: sinif,
        )) {
    loadStates();
  }

  Future<void> loadStates() async {
    try {
      final ozelMap = await _storageService.getMap(_ozelKartlarStorageKey);
      final ozel = (ozelMap?['items'] as List?)
              ?.map((e) => FlashKart.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          <FlashKart>[];

      final map = await _storageService.getMap(_flashkartStorageKey) ?? {};
      final list = [...flashKartlar, ...ozel].map((k) {
        if (map.containsKey(k.id)) {
          return KartDurum.fromJson(Map<String, dynamic>.from(map[k.id] as Map));
        }
        return KartDurum.yeniKart(k.id);
      }).toList();
      final bilemedimMap = await _storageService.getMap(_bilemedimStorageKey);
      final mevcutIdler = list.map((d) => d.id).toSet();
      final bilemedim = {
        for (final id in ((bilemedimMap?['items'] as List?) ?? const []))
          if (id is String && mevcutIdler.contains(id)) id,
      };
      final sayac = await _storageService.getMap(_yeniSayacStorageKey);
      if (mounted) {
        state = state.copyWith(
          durumlar: list,
          ozelKartlar: ozel,
          bilemedimIdleri: bilemedim,
          bugunYeniSayisi: (sayac?['n'] as num?)?.toInt() ?? 0,
          yeniSayacTarihi: sayac?['t'] as String? ?? '',
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('FlashkartNotifier: durum yüklenemedi: $e');
    }
  }

  void dersSec(String ders) {
    state = state.copyWith(seciliDers: ders);
  }

  /// Sınıf süzgecini değiştirir (null: tüm kartlar).
  void sinifSec(int? sinif) {
    if (sinif == state.sinif) return;
    state = state.copyWith(sinif: sinif, sinifTemizle: sinif == null);
  }

  Future<void> kartOylele(String kartId, Sm2Kalite kalite) async {
    final onceki = state.durumlar.where((d) => d.id == kartId).firstOrNull;
    final hazirYeni = onceki != null && yeniKartMi(onceki) && !state.ozelKartlar.any((k) => k.id == kartId);
    if (hazirYeni) {
      final bugun = _bugunAnahtari();
      final n = state.yeniSayacTarihi == bugun ? state.bugunYeniSayisi + 1 : 1;
      state = state.copyWith(bugunYeniSayisi: n, yeniSayacTarihi: bugun);
      await _storageService.setMap(_yeniSayacStorageKey, {'t': bugun, 'n': n});
    }
    final guncelDurumlar = state.durumlar.map((d) {
      if (d.id == kartId) {
        return sm2Guncelle(d, kalite);
      }
      return d;
    }).toList();

    final bilemedim = {...state.bilemedimIdleri};
    final degisti = switch (kalite) {
      Sm2Kalite.tekrarSifirla => bilemedim.add(kartId),
      Sm2Kalite.cokKolay || Sm2Kalite.kolay => bilemedim.remove(kartId),
      _ => false,
    };
    state = state.copyWith(durumlar: guncelDurumlar, bilemedimIdleri: bilemedim);
    await _saveStates();
    if (degisti) await _saveBilemedim();
  }

  /// Kartı "Yanlışlarım" listesinden çıkarır (testten gelen kartlar silinir).
  Future<void> yanlislardanCikar(String kartId) async {
    if (state.ozelKartlar.any((k) => k.id == kartId && k.ders == yanlisDeste)) {
      await ozelKartSil(kartId);
      return;
    }
    state = state.copyWith(bilemedimIdleri: {...state.bilemedimIdleri}..remove(kartId));
    await _saveBilemedim();
  }

  /// Kartın tekrar zamanını bugüne çeker (listeden "şimdi tekrar et").
  Future<void> bugunTekrarla(String kartId) async {
    final bugun = DateTime.now().toIso8601String().split('T')[0];
    state = state.copyWith(
      durumlar: [
        for (final d in state.durumlar) d.id == kartId ? d.copyWith(sonrakiTekrar: bugun, updatedAt: DateTime.now()) : d,
      ],
    );
    await _saveStates();
  }

  Future<void> _saveBilemedim() async {
    await _storageService.setMap(_bilemedimStorageKey, {'items': state.bilemedimIdleri.toList()});
  }

  Future<void> ozelKartEkle({required String on, required String arka, String? ipucu, String? konu}) async {
    final kart = FlashKart(
      id: 'ozel-${DateTime.now().microsecondsSinceEpoch}',
      ders: ozelDeste,
      unite: (konu == null || konu.trim().isEmpty) ? 'Kendi kartım' : konu.trim(),
      on: on.trim(),
      arka: arka.trim(),
      ipucu: (ipucu == null || ipucu.trim().isEmpty) ? null : ipucu.trim(),
    );
    await _kartlariEkle([kart]);
  }

  Future<void> ozelKartSil(String kartId) async {
    final bilemedimdi = state.bilemedimIdleri.contains(kartId);
    state = state.copyWith(
      ozelKartlar: state.ozelKartlar.where((k) => k.id != kartId).toList(),
      durumlar: state.durumlar.where((d) => d.id != kartId).toList(),
      bilemedimIdleri: {...state.bilemedimIdleri}..remove(kartId),
    );
    await _saveOzel();
    await _saveStates();
    if (bilemedimdi) await _saveBilemedim();
  }

  /// Testte yanlış yapılan soruları "Yanlışlarım" destesine kart olarak ekler.
  /// Aynı soru ikinci kez eklenmez; eklenen kart sayısını döner.
  Future<int> yanlislardanKartEkle(List<Soru> yanlislar) async {
    final mevcut = state.ozelKartlar.map((k) => k.id).toSet();
    final yeni = <FlashKart>[];
    for (final s in yanlislar) {
      final id = 'yanlis-${s.id}';
      if (mevcut.contains(id)) continue;
      final dogruMetin = s.secenekler[s.dogruSecenek] ?? '';
      yeni.add(FlashKart(
        id: id,
        ders: yanlisDeste,
        unite: '${s.ders} • ${s.konu}',
        on: s.soruMetni,
        arka: 'Doğru cevap: ${s.dogruSecenek}) $dogruMetin\n\n${s.cozumAciklama}',
        ipucu: s.altBaslik,
      ));
    }
    if (yeni.isNotEmpty) await _kartlariEkle(yeni);
    return yeni.length;
  }

  Future<void> _kartlariEkle(List<FlashKart> kartlar) async {
    state = state.copyWith(
      ozelKartlar: [...state.ozelKartlar, ...kartlar],
      durumlar: [...state.durumlar, ...kartlar.map((k) => KartDurum.yeniKart(k.id))],
    );
    await _saveOzel();
    await _saveStates();
  }

  Future<void> _saveOzel() async {
    await _storageService.setMap(_ozelKartlarStorageKey, {
      'items': state.ozelKartlar.map((k) => k.toJson()).toList(),
    });
  }

  Future<void> _saveStates() async {
    final saveMap = <String, dynamic>{};
    for (final d in state.durumlar) {
      saveMap[d.id] = d.toJson();
    }
    await _storageService.setMap(_flashkartStorageKey, saveMap);
  }
}

final flashkartProvider =
    StateNotifierProvider<FlashkartNotifier, FlashkartState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final n = FlashkartNotifier(storage, sinif: ref.read(sinifProvider));
  // Profilde sınıf değişince kartlar da o sınıfa göre süzülür.
  ref.listen(sinifProvider, (_, sinif) => n.sinifSec(sinif));
  return n;
});

/// Bir destede bugün çalışılacak kartlar: tekrar zamanı gelenler, kullanıcı
/// kartları ve günlük sınır kadar hazır yeni kart (önce tekrarlar).
List<FlashKart> _bugunkuKartlar(FlashkartState state, String deste) {
  final durum = {for (final d in state.durumlar) d.id: d};
  final ozelIdler = {for (final k in state.ozelKartlar) k.id};
  final tekrar = <FlashKart>[];
  final yeni = <FlashKart>[];
  for (final k in state.desteKartlari(deste)) {
    final d = durum[k.id];
    if (d == null || !d.bugunTekrarEdilecek) continue;
    if (yeniKartMi(d) && !ozelIdler.contains(k.id)) {
      yeni.add(k);
    } else {
      tekrar.add(k);
    }
  }
  return [...tekrar, ...yeni.take(state.kalanYeniKart)];
}

/// Filtrelenmiş ve bugün çalışılacak flashkartlar provider'ı
final bugunCalisilacakKartlarProvider = Provider<List<FlashKart>>((ref) {
  final state = ref.watch(flashkartProvider);
  return _bugunkuKartlar(state, state.seciliDers);
});

/// Deste bazında bugün tekrarı gelen kart sayıları ('hepsi' dahil).
final desteDueSayilariProvider = Provider<Map<String, int>>((ref) {
  final state = ref.watch(flashkartProvider);
  final desteler = {'hepsi', yanlisDeste, ...state.tumKartlar.map((k) => k.ders)};
  return {for (final d in desteler) d: _bugunkuKartlar(state, d).length};
});

/// Seçili destede, bugünkü yeni kart sınırı yüzünden bekleyen hazır kart var mı?
final yeniKartSiniriDolduProvider = Provider<bool>((ref) {
  final state = ref.watch(flashkartProvider);
  if (state.kalanYeniKart > 0) return false;
  final durum = {for (final d in state.durumlar) d.id: d};
  final ozelIdler = {for (final k in state.ozelKartlar) k.id};
  return state.desteKartlari(state.seciliDers).any((k) {
    final d = durum[k.id];
    return d != null && yeniKartMi(d) && !ozelIdler.contains(k.id);
  });
});
