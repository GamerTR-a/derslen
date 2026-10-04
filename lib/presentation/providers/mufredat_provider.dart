/// Kişisel müfredat: kullanıcının eklediği dersler/konular, gizlediği hazır
/// konular ve (serbest modda) hedef sınav adı/tarihi.
///
/// Profildeki hedef alan `serbest` ise hazır YKS konuları hiç kullanılmaz;
/// müfredat tamamen buradaki derslerden oluşur (üniversite, KPSS, dil sınavı,
/// lise ara sınıfları…). YKS alanlarında ise hazır konuların üstüne ders/konu
/// eklenebilir, istenmeyenler gizlenebilir.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/sinif_mufredati.dart';
import '../../core/constants/yks_data.dart';
import '../../core/storage/storage_service.dart';
import '../../core/utils/tarih.dart';
import 'profil_provider.dart';

const String _mufredatStorageKey = 'mufredat';

/// Serbest müfredat modunun `hedefBolum` değeri.
const String serbestMufredat = 'serbest';

class MufredatState {
  final bool yuklendi;
  final List<Konu> ozelKonular;
  final Set<String> gizliIdler;
  final String? hedefAd;

  /// YYYY-MM-DD
  final String? hedefTarih;

  const MufredatState({
    this.yuklendi = false,
    this.ozelKonular = const [],
    this.gizliIdler = const {},
    this.hedefAd,
    this.hedefTarih,
  });

  /// Kullanıcının eklediği dersler (eklenme sırasıyla).
  List<String> get ozelDersler {
    final l = <String>[];
    for (final k in ozelKonular) {
      if (!l.contains(k.ders)) l.add(k.ders);
    }
    return l;
  }

  /// Hedef sınava kalan gün (tarih yoksa ya da geçtiyse null).
  int? get hedefeKalanGun {
    final t = hedefTarih == null ? null : DateTime.tryParse(hedefTarih!);
    if (t == null) return null;
    final gun = t.difference(sadeceGun(DateTime.now())).inDays;
    return gun < 0 ? null : gun;
  }

  Map<String, dynamic> toJson() => {
        'ozel': [
          for (final k in ozelKonular) {'id': k.id, 'ders': k.ders, 'baslik': k.baslik},
        ],
        'gizli': gizliIdler.toList(),
        'hedefAd': hedefAd,
        'hedefTarih': hedefTarih,
      };

  factory MufredatState.fromJson(Map<String, dynamic> j) => MufredatState(
        yuklendi: true,
        ozelKonular: [
          for (final e in (j['ozel'] as List?) ?? const [])
            if (e is Map && e['id'] is String && e['ders'] is String && e['baslik'] is String)
              Konu(id: e['id'] as String, ders: e['ders'] as String, alan: SinavAlani.TYT, baslik: e['baslik'] as String),
        ],
        gizliIdler: {for (final e in (j['gizli'] as List?) ?? const []) if (e is String) e},
        hedefAd: j['hedefAd'] as String?,
        hedefTarih: j['hedefTarih'] as String?,
      );
}

class MufredatNotifier extends StateNotifier<MufredatState> {
  final StorageService _storage;
  late final Future<void> hazir;
  int _sayac = 0;

  MufredatNotifier(this._storage) : super(const MufredatState()) {
    hazir = _yukle();
  }

  Future<void> _yukle() async {
    try {
      final map = await _storage.getMap(_mufredatStorageKey);
      if (!mounted) return;
      state = map == null ? const MufredatState(yuklendi: true) : MufredatState.fromJson(map);
    } catch (_) {
      if (mounted) state = const MufredatState(yuklendi: true);
    }
  }

  Future<void> _kaydet(MufredatState yeni) async {
    state = yeni;
    await _storage.setMap(_mufredatStorageKey, yeni.toJson());
  }

  MufredatState _kopya({List<Konu>? ozel, Set<String>? gizli, String? hedefAd, String? hedefTarih, bool hedefTemizle = false}) =>
      MufredatState(
        yuklendi: true,
        ozelKonular: ozel ?? state.ozelKonular,
        gizliIdler: gizli ?? state.gizliIdler,
        hedefAd: hedefTemizle ? null : (hedefAd ?? state.hedefAd),
        hedefTarih: hedefTemizle ? null : (hedefTarih ?? state.hedefTarih),
      );

  String _yeniId() => 'ozel-${DateTime.now().microsecondsSinceEpoch}-${_sayac++}';

  static String _temiz(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Yeni ders ekler. [konular] boşsa ders "Genel konular" başlığıyla açılır
  /// (programa girebilmesi için en az bir konusu olmalı). Aynı adlı ders
  /// varsa konular ona eklenir.
  Future<void> dersEkle(String ders, [List<String> konular = const []]) async {
    await hazir;
    final ad = _temiz(ders);
    if (ad.isEmpty) return;
    final mevcut = state.ozelKonular.where((k) => k.ders == ad).map((k) => k.baslik.toLowerCase()).toSet();
    final basliklar = [
      for (final b in konular.map(_temiz))
        if (b.isNotEmpty && mevcut.add(b.toLowerCase())) b,
    ];
    if (basliklar.isEmpty && mevcut.isEmpty) basliklar.add('Genel konular');
    if (basliklar.isEmpty) return;
    await _kaydet(_kopya(ozel: [
      ...state.ozelKonular,
      for (final b in basliklar) Konu(id: _yeniId(), ders: ad, alan: SinavAlani.TYT, baslik: b),
    ]));
  }

  Future<void> konuEkle(String ders, String baslik) => dersEkle(ders, [baslik]);

  Future<void> konuSil(String id) async {
    await _kaydet(_kopya(ozel: state.ozelKonular.where((k) => k.id != id).toList()));
  }

  /// Kullanıcının eklediği dersi tüm konularıyla siler.
  Future<void> dersSil(String ders) async {
    await _kaydet(_kopya(ozel: state.ozelKonular.where((k) => k.ders != ders).toList()));
  }

  /// Hazır bir konuyu müfredattan çıkarır / geri ekler.
  Future<void> konuGizle(String id, bool gizle) async {
    final g = {...state.gizliIdler};
    gizle ? g.add(id) : g.remove(id);
    await _kaydet(_kopya(gizli: g));
  }

  /// Verilen hazır konuları topluca müfredattan çıkarır / geri ekler.
  Future<void> konulariGizle(Iterable<String> idler, bool gizle) async {
    final g = {...state.gizliIdler};
    gizle ? g.addAll(idler) : g.removeAll(idler);
    await _kaydet(_kopya(gizli: g));
  }

  /// Hazır bir dersin (ör. AYT Fizik) tüm konularını çıkarır / geri ekler.
  Future<void> hazirDersGizle(SinavAlani alan, String ders, bool gizle) async {
    final idler = tumKonular.where((k) => k.alan == alan && k.ders == ders).map((k) => k.id);
    final g = {...state.gizliIdler};
    gizle ? g.addAll(idler) : g.removeAll(idler);
    await _kaydet(_kopya(gizli: g));
  }

  Future<void> hedefAyarla({required String? ad, required DateTime? tarih}) async {
    await hazir;
    final temiz = ad == null ? '' : _temiz(ad);
    if (temiz.isEmpty && tarih == null) {
      await _kaydet(_kopya(hedefTemizle: true));
      return;
    }
    await _kaydet(MufredatState(
      yuklendi: true,
      ozelKonular: state.ozelKonular,
      gizliIdler: state.gizliIdler,
      hedefAd: temiz.isEmpty ? null : temiz,
      hedefTarih: tarih == null ? null : gunAnahtari(tarih),
    ));
  }
}

final mufredatProvider = StateNotifierProvider<MufredatNotifier, MufredatState>((ref) {
  return MufredatNotifier(ref.watch(storageServiceProvider));
});

/// Kullanıcı serbest müfredat modunda mı (YKS dışı: üniversite vb.)?
final serbestModProvider = Provider<bool>((ref) {
  return ref.watch(profilProvider.select((p) => p.value?.hedefBolum)) == serbestMufredat;
});

/// Hazır Maarif müfredatıyla çalışan lise ara sınıfı (9, 10, 11); 12. sınıf,
/// mezun ve serbest müfredat için null.
final sinifProvider = Provider<int?>((ref) {
  if (ref.watch(serbestModProvider)) return null;
  return araSinif(ref.watch(profilProvider.select((p) => p.value?.sinifSeviyesi)));
});

/// Ana sayfadaki geri sayım: (sınav adı, kalan gün). Serbest modda hedef
/// tarihi girilmediyse null. Ara sınıflarda öğrencinin gireceği YKS'ye
/// (12. sınıfın sonundaki) kalan gün gösterilir.
final hedefGeriSayimProvider = Provider<(String, int)?>((ref) {
  if (!ref.watch(serbestModProvider)) {
    final sinif = ref.watch(sinifProvider);
    if (sinif == null) return ('YKS', yksKalanGun());
    final simdi = DateTime.now();
    final ilk = sonrakiYksTarihi(simdi);
    // Eylül-Haziran arası öğretim yılı: sıradaki YKS, şu anki 12'lerin sınavıdır.
    final hedef = DateTime(ilk.year + (12 - sinif), ilk.month, ilk.day, ilk.hour);
    return ('YKS', hedef.difference(sadeceGun(simdi)).inDays);
  }
  final m = ref.watch(mufredatProvider);
  final gun = m.hedefeKalanGun;
  if (gun == null) return null;
  return (m.hedefAd ?? 'Sınav', gun);
});
