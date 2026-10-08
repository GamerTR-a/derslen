/// Bahçe durumu — saksılar, su damlaları, envanter ve yıldız bakiyesi.
///
/// Yıldız bakiyesi ve satın almalar sunucudadır (hile yapılamaz); bitki
/// büyümesi ve su damlaları ise kozmetik olduğu için öğrenci verisiyle
/// birlikte buluta senkronlanan yerel depoda tutulur.
library;

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/bahce_data.dart';
import '../../core/constants/bahce_iklim.dart';
import '../../core/services/supabase_data_service.dart';
import '../../core/storage/storage_service.dart';
import 'profil_provider.dart';

const String _bahceStorageKey = 'bahce_durumu';

String _gunAnahtari(DateTime t) =>
    '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

class Saksi {
  final String? bitkiId;
  final int buyume;
  final String? sonSulama;
  final String? ekimTarihi;

  const Saksi({this.bitkiId, this.buyume = 0, this.sonSulama, this.ekimTarihi});

  bool get bos => bitkiId == null;

  int get asama {
    var a = 0;
    for (var i = 0; i < buyumeEsikleri.length; i++) {
      if (buyume >= buyumeEsikleri[i]) a = i;
    }
    return a;
  }

  bool get olgun => asama == buyumeEsikleri.length - 1;

  bool get bugunSulandi => sonSulama == _gunAnahtari(DateTime.now());

  bool get solgun {
    if (bos) return false;
    final referans = sonSulama ?? ekimTarihi;
    if (referans == null) return false;
    final gun = DateTime.tryParse(referans);
    if (gun == null) return false;
    final bugun = DateTime.now();
    final fark = DateTime(bugun.year, bugun.month, bugun.day).difference(gun).inDays;
    final sinir = bitkiId == 'seed_kaktus' ? solmaGunu * 3 : solmaGunu;
    return fark >= sinir;
  }

  Saksi copyWith({String? bitkiId, int? buyume, String? sonSulama, String? ekimTarihi, bool temizle = false}) {
    if (temizle) return const Saksi();
    return Saksi(
      bitkiId: bitkiId ?? this.bitkiId,
      buyume: buyume ?? this.buyume,
      sonSulama: sonSulama ?? this.sonSulama,
      ekimTarihi: ekimTarihi ?? this.ekimTarihi,
    );
  }

  Map<String, dynamic> toJson() => {
        'bitkiId': bitkiId,
        'buyume': buyume,
        'sonSulama': sonSulama,
        'ekimTarihi': ekimTarihi,
      };

  factory Saksi.fromJson(Map<String, dynamic> j) => Saksi(
        bitkiId: j['bitkiId'] as String?,
        buyume: (j['buyume'] as num?)?.toInt() ?? 0,
        sonSulama: j['sonSulama'] as String?,
        ekimTarihi: j['ekimTarihi'] as String?,
      );
}

class BahceState {
  final List<Saksi> saksilar;
  final int damla;
  final Map<String, int> envanter;
  final List<String> dekorlar;
  /// Seçili iklim bölgesi: olgun bitkiler bu bölgenin ormanına taşınır.
  final String iklim;

  /// Bölge kimliği → o bölgenin ormanındaki bitkiler.
  final Map<String, List<String>> ormanlar;
  final bool hediyeKutusuAcildi;
  final int calismaBirikimDk;
  final String? checkinDamlaTarihi;
  final String? kartDamlaTarihi;
  final int kartDamlaSayisi;

  final int yildiz;
  final bool yildizYukleniyor;

  const BahceState({
    this.saksilar = const [Saksi(), Saksi(), Saksi()],
    this.damla = 5,
    this.envanter = const {},
    this.dekorlar = const [],
    this.iklim = varsayilanIklim,
    this.ormanlar = const {},
    this.hediyeKutusuAcildi = false,
    this.calismaBirikimDk = 0,
    this.checkinDamlaTarihi,
    this.kartDamlaTarihi,
    this.kartDamlaSayisi = 0,
    this.yildiz = 0,
    this.yildizYukleniyor = true,
  });

  int get ekiliBitki => saksilar.where((s) => !s.bos).length;
  int get susuzBitki => saksilar.where((s) => !s.bos && !s.bugunSulandi).length;
  bool get solgunVar => saksilar.any((s) => s.solgun);

  /// Tüm bölgelerdeki bitkiler.
  List<String> get orman => [for (final l in ormanlar.values) ...l];
  List<String> bolgeOrmani(String id) => ormanlar[id] ?? const [];
  List<String> get aktifOrman => bolgeOrmani(iklim);
  bool iklimiSever(String? bitkiId) => bitkiId != null && iklimBul(iklim).sevenler.contains(bitkiId);

  BahceState copyWith({
    List<Saksi>? saksilar,
    int? damla,
    Map<String, int>? envanter,
    List<String>? dekorlar,
    String? iklim,
    Map<String, List<String>>? ormanlar,
    bool? hediyeKutusuAcildi,
    int? calismaBirikimDk,
    String? checkinDamlaTarihi,
    String? kartDamlaTarihi,
    int? kartDamlaSayisi,
    int? yildiz,
    bool? yildizYukleniyor,
  }) {
    return BahceState(
      saksilar: saksilar ?? this.saksilar,
      damla: damla ?? this.damla,
      envanter: envanter ?? this.envanter,
      dekorlar: dekorlar ?? this.dekorlar,
      iklim: iklim ?? this.iklim,
      ormanlar: ormanlar ?? this.ormanlar,
      hediyeKutusuAcildi: hediyeKutusuAcildi ?? this.hediyeKutusuAcildi,
      calismaBirikimDk: calismaBirikimDk ?? this.calismaBirikimDk,
      checkinDamlaTarihi: checkinDamlaTarihi ?? this.checkinDamlaTarihi,
      kartDamlaTarihi: kartDamlaTarihi ?? this.kartDamlaTarihi,
      kartDamlaSayisi: kartDamlaSayisi ?? this.kartDamlaSayisi,
      yildiz: yildiz ?? this.yildiz,
      yildizYukleniyor: yildizYukleniyor ?? this.yildizYukleniyor,
    );
  }

  Map<String, dynamic> toJson() => {
        'saksilar': saksilar.map((s) => s.toJson()).toList(),
        'damla': damla,
        'envanter': envanter,
        'dekorlar': dekorlar,
        'iklim': iklim,
        'ormanlar': ormanlar,
        // Bölgeleri tanımayan eski sürümler için düz liste.
        'orman': orman,
        'hediyeKutusuAcildi': hediyeKutusuAcildi,
        'calismaBirikimDk': calismaBirikimDk,
        'checkinDamlaTarihi': checkinDamlaTarihi,
        'kartDamlaTarihi': kartDamlaTarihi,
        'kartDamlaSayisi': kartDamlaSayisi,
      };

  factory BahceState.fromJson(Map<String, dynamic> j) {
    final saksilar = (j['saksilar'] as List?)
            ?.map((e) => Saksi.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        const [Saksi(), Saksi(), Saksi()];
    final eski = (j['orman'] as List?)?.cast<String>() ?? const <String>[];
    final ormanlar = (j['ormanlar'] as Map?)?.map((k, v) => MapEntry(k as String, (v as List).cast<String>())) ??
        {if (eski.isNotEmpty) varsayilanIklim: eski};
    return BahceState(
      saksilar: saksilar,
      damla: (j['damla'] as num?)?.toInt() ?? 5,
      envanter: (j['envanter'] as Map?)?.map((k, v) => MapEntry(k as String, (v as num).toInt())) ?? const {},
      dekorlar: (j['dekorlar'] as List?)?.cast<String>() ?? const [],
      iklim: iklimBul(j['iklim'] as String?).id,
      ormanlar: ormanlar,
      hediyeKutusuAcildi: j['hediyeKutusuAcildi'] as bool? ?? false,
      calismaBirikimDk: (j['calismaBirikimDk'] as num?)?.toInt() ?? 0,
      checkinDamlaTarihi: j['checkinDamlaTarihi'] as String?,
      kartDamlaTarihi: j['kartDamlaTarihi'] as String?,
      kartDamlaSayisi: (j['kartDamlaSayisi'] as num?)?.toInt() ?? 0,
    );
  }
}

class BahceNotifier extends StateNotifier<BahceState> {
  final StorageService _storage;
  final Random _rng = Random.secure();
  late final Future<void> _yuklendi;

  BahceNotifier(this._storage) : super(const BahceState()) {
    _yuklendi = _yukle();
    yildizYenile();
  }

  Future<void> _yukle() async {
    try {
      final map = await _storage.getMap(_bahceStorageKey);
      if (map != null && mounted) {
        state = BahceState.fromJson(map).copyWith(
          yildiz: state.yildiz,
          yildizYukleniyor: state.yildizYukleniyor,
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('BahceNotifier: yüklenemedi: $e');
    }
  }

  Future<void> _kaydet() => _storage.setMap(_bahceStorageKey, state.toJson());

  Future<void> yildizYenile() async {
    final bakiye = await SupabaseDataService.getWalletBalance();
    if (!mounted) return;
    state = state.copyWith(yildiz: bakiye, yildizYukleniyor: false);
  }

  void yildizEkle(int miktar) {
    if (miktar <= 0) return;
    state = state.copyWith(yildiz: state.yildiz + miktar);
  }

  /// Onboarding sonundaki sürpriz kutu: rastgele bir tohumu ilk saksıya eker.
  /// Kutu daha önce açıldıysa null döner.
  Future<String?> hediyeKutusuAc() async {
    await _yuklendi;
    if (state.hediyeKutusuAcildi) return null;
    final tohum = hediyeTohumlari[_rng.nextInt(hediyeTohumlari.length)];
    final saksilar = [...state.saksilar];
    final bosIndex = saksilar.indexWhere((s) => s.bos);
    final bugun = _gunAnahtari(DateTime.now());
    if (bosIndex >= 0) {
      saksilar[bosIndex] = Saksi(bitkiId: tohum, ekimTarihi: bugun, sonSulama: bugun);
      state = state.copyWith(saksilar: saksilar, hediyeKutusuAcildi: true);
    } else {
      final env = {...state.envanter};
      env[tohum] = (env[tohum] ?? 0) + 1;
      state = state.copyWith(envanter: env, hediyeKutusuAcildi: true);
    }
    await _kaydet();
    return tohum;
  }

  /// Sonuç: null = başarılı, aksi halde kullanıcıya gösterilecek hata.
  Future<String?> sula(int index) async {
    final saksi = state.saksilar[index];
    if (saksi.bos) return 'Bu saksı boş.';
    if (saksi.bugunSulandi) return 'Bugün zaten suladın';
    if (state.damla <= 0) return 'Su damlan kalmadı. Kart tekrarı ve check-in ile damla kazan.';
    final saksilar = [...state.saksilar];
    saksilar[index] = saksi.copyWith(
      buyume: saksi.olgun ? saksi.buyume : saksi.buyume + 1 + (state.iklimiSever(saksi.bitkiId) ? iklimSulamaBonusu : 0),
      sonSulama: _gunAnahtari(DateTime.now()),
    );
    state = state.copyWith(saksilar: saksilar, damla: state.damla - 1);
    await _kaydet();
    return null;
  }

  Future<String?> ek(int index, String tohumId) async {
    if (!state.saksilar[index].bos) return 'Bu saksı dolu.';
    final adet = state.envanter[tohumId] ?? 0;
    if (adet <= 0) return 'Bu tohumdan kalmadı.';
    final env = {...state.envanter};
    if (adet == 1) {
      env.remove(tohumId);
    } else {
      env[tohumId] = adet - 1;
    }
    final bugun = _gunAnahtari(DateTime.now());
    final saksilar = [...state.saksilar];
    saksilar[index] = Saksi(bitkiId: tohumId, ekimTarihi: bugun, sonSulama: bugun);
    state = state.copyWith(saksilar: saksilar, envanter: env);
    await _kaydet();
    return null;
  }

  /// Olgun bitkiyi seçili bölgenin ormanına taşır, saksıyı boşaltır.
  Future<void> hasatEt(int index) async {
    final saksi = state.saksilar[index];
    if (!saksi.olgun || saksi.bitkiId == null) return;
    final saksilar = [...state.saksilar];
    saksilar[index] = const Saksi();
    state = state.copyWith(
      saksilar: saksilar,
      ormanlar: {...state.ormanlar, state.iklim: [...state.aktifOrman, saksi.bitkiId!]},
    );
    await _kaydet();
  }

  Future<void> iklimSec(String id) async {
    await _yuklendi;
    final bolge = iklimBul(id).id;
    if (bolge != id || state.iklim == id) return;
    state = state.copyWith(iklim: id);
    await _kaydet();
  }

  /// Her 25 dakikalık odak, ekili tüm bitkilere +1 büyüme verir.
  Future<void> calismaIleBuyut(int dakika) async {
    if (dakika <= 0) return;
    await _yuklendi;
    final toplam = state.calismaBirikimDk + dakika;
    final puan = toplam ~/ 25;
    final saksilar = puan == 0
        ? state.saksilar
        : state.saksilar
            .map((s) => s.bos || s.olgun ? s : s.copyWith(buyume: s.buyume + puan))
            .toList();
    state = state.copyWith(saksilar: saksilar, calismaBirikimDk: toplam % 25);
    await _kaydet();
  }

  /// Günlük check-in için damla (günde bir kez). Kazanılan damla sayısını döner.
  Future<int> checkinDamlasi() async {
    await _yuklendi;
    final bugun = _gunAnahtari(DateTime.now());
    if (state.checkinDamlaTarihi == bugun) return 0;
    state = state.copyWith(damla: state.damla + gunlukCheckinDamla, checkinDamlaTarihi: bugun);
    await _kaydet();
    return gunlukCheckinDamla;
  }

  /// Her kart tekrarı 1 damla (günlük tavanlı). Kazanılan damlayı döner.
  Future<int> kartDamlasi() async {
    await _yuklendi;
    final bugun = _gunAnahtari(DateTime.now());
    final sayi = state.kartDamlaTarihi == bugun ? state.kartDamlaSayisi : 0;
    if (sayi >= gunlukKartDamlaTavani) return 0;
    state = state.copyWith(damla: state.damla + 1, kartDamlaTarihi: bugun, kartDamlaSayisi: sayi + 1);
    await _kaydet();
    return 1;
  }

  /// Sonuç: null = başarılı, aksi halde hata mesajı.
  Future<String?> satinAl(BahceUrunu urun) async {
    if (urun.tip == BahceUrunTip.dekor && state.dekorlar.contains(urun.id)) {
      return 'Bu dekor zaten bahçende.';
    }
    if (urun.tip == BahceUrunTip.saksi && state.saksilar.length >= maksSaksiSayisi) {
      return 'Bahçen en fazla $maksSaksiSayisi saksı alabilir.';
    }
    if (state.yildiz < urun.fiyat) return 'Yeterli yıldızın yok. Çalış sekmesinden yıldız kazan';

    final purchaseId = 'p${DateTime.now().millisecondsSinceEpoch}${_rng.nextInt(1 << 30)}';
    final int yeniBakiye;
    try {
      yeniBakiye = await SupabaseDataService.buyGardenItem(itemId: urun.id, purchaseId: purchaseId);
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }

    switch (urun.tip) {
      case BahceUrunTip.tohum:
        final env = {...state.envanter};
        env[urun.id] = (env[urun.id] ?? 0) + 1;
        state = state.copyWith(envanter: env, yildiz: yeniBakiye);
      case BahceUrunTip.dekor:
        state = state.copyWith(dekorlar: [...state.dekorlar, urun.id], yildiz: yeniBakiye);
      case BahceUrunTip.saksi:
        state = state.copyWith(saksilar: [...state.saksilar, const Saksi()], yildiz: yeniBakiye);
    }
    await _kaydet();
    return null;
  }
}

final bahceProvider = StateNotifierProvider<BahceNotifier, BahceState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return BahceNotifier(storage);
});
