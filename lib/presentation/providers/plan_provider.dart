/// Haftalık ders programı ve günlük plan durumu.
///
/// Program hafta başında (ya da ayarlar değişince) üretilir ve haftalık olarak
/// saklanır; böylece gün içinde check-in veya konu değişince bloklar yer
/// değiştirmez, tamamlanan bloklar kaybolmaz. Bugünün planı, programın bugünkü
/// gününün check-in'e göre uyarlanmış halidir. Her gün için plan uyumu
/// (planlanan/tamamlanan blok ve dakika) analiz grafiklerine kaydedilir.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/algorithms/ders_programi.dart';
import '../../core/storage/analiz_kayitlari.dart';
import '../../core/storage/storage_service.dart';
import '../../core/utils/tarih.dart';
import '../../data/models/gunluk_checkin.dart';
import '../../data/models/plan_blok.dart';
import 'checkin_provider.dart';
import 'konu_provider.dart';
import 'profil_provider.dart';

class ProgramState {
  final bool yuklendi;
  final DersProgramiAyar? ayar;
  final String? haftaAnahtari;

  /// 7 gün (Pazartesi = 0), üretildiği haliyle (check-in uyarlaması yok).
  final List<List<PlanBlok>> hafta;

  /// { 'YYYY-MM-DD': {blokId, ...} }
  final Map<String, Set<String>> tamamlanan;

  const ProgramState({
    this.yuklendi = false,
    this.ayar,
    this.haftaAnahtari,
    this.hafta = const [[], [], [], [], [], [], []],
    this.tamamlanan = const {},
  });

  ProgramState copyWith({
    bool? yuklendi,
    DersProgramiAyar? ayar,
    String? haftaAnahtari,
    List<List<PlanBlok>>? hafta,
    Map<String, Set<String>>? tamamlanan,
  }) =>
      ProgramState(
        yuklendi: yuklendi ?? this.yuklendi,
        ayar: ayar ?? this.ayar,
        haftaAnahtari: haftaAnahtari ?? this.haftaAnahtari,
        hafta: hafta ?? this.hafta,
        tamamlanan: tamamlanan ?? this.tamamlanan,
      );

  DateTime? get haftaBaslangic => haftaAnahtari == null ? null : DateTime.tryParse(haftaAnahtari!);

  String gunAnahtariAt(int gunIndex) =>
      gunAnahtari((haftaBaslangic ?? haftaBaslangici(DateTime.now())).add(Duration(days: gunIndex)));

  /// Bir günün blokları, tamamlanma işaretleriyle.
  List<PlanBlok> gunBloklari(int gunIndex) {
    final anahtar = gunAnahtariAt(gunIndex);
    final biten = tamamlanan[anahtar] ?? const <String>{};
    return [for (final b in hafta[gunIndex]) biten.contains(b.id) ? b.copyWith(tamamlandi: true) : b];
  }

  int gunCalismaDk(int gunIndex) =>
      hafta[gunIndex].where((b) => b.isCalismaBloku).fold(0, (t, b) => t + b.sure);
}

class ProgramNotifier extends StateNotifier<ProgramState> {
  final Ref _ref;
  final StorageService _storage;
  bool _hazirlaniyor = false;

  ProgramNotifier(this._ref, this._storage) : super(const ProgramState());

  static int get bugunIndex => DateTime.now().weekday - 1;

  /// Programı yükler; bu hafta için program yoksa üretir. Profil hazır
  /// değilse (onboarding bitmemiş) hiçbir şey yapmaz.
  Future<void> hazirla() async {
    final profil = _ref.read(profilProvider).value;
    if (profil == null || !profil.onboardingTamamlandi || _hazirlaniyor) return;
    final buHafta = gunAnahtari(haftaBaslangici(DateTime.now()));
    if (state.yuklendi && state.haftaAnahtari == buHafta) return;

    _hazirlaniyor = true;
    try {
      final ayarMap = await _storage.getMap(AnalizKayitlari.programAyar);
      final ayar = ayarMap == null ? DersProgramiAyar.varsayilan(profil) : DersProgramiAyar.fromJson(ayarMap, profil);

      final tamMap = await _storage.getMap(AnalizKayitlari.planTamamlanan) ?? {};
      final tamamlanan = {
        for (final e in tamMap.entries) e.key: ((e.value as List?) ?? const []).cast<String>().toSet(),
      };

      final kayit = await _storage.getMap(AnalizKayitlari.haftalikProgram);
      List<List<PlanBlok>>? hafta;
      if (kayit != null && kayit['hafta'] == buHafta) hafta = _coz(kayit['gunler']);

      if (!mounted) return;
      state = ProgramState(
        yuklendi: true,
        ayar: ayar,
        haftaAnahtari: buHafta,
        hafta: hafta ?? const [[], [], [], [], [], [], []],
        tamamlanan: tamamlanan,
      );
      // Yeni haftada geçmiş günler için plan üretilmez (öğrenci o günlerin
      // planını görmediği için uyum hesabını bozmasın).
      if (hafta == null) await _olustur(ilkGun: bugunIndex);
      await uyumuKaydet();
    } finally {
      _hazirlaniyor = false;
    }
  }

  List<List<PlanBlok>>? _coz(dynamic ham) {
    if (ham is! List || ham.length != 7) return null;
    try {
      return [
        for (final gun in ham)
          [for (final b in (gun as List)) PlanBlok.fromJson(Map<String, dynamic>.from(b as Map))],
      ];
    } catch (_) {
      return null;
    }
  }

  Future<void> _olustur({required int ilkGun}) async {
    await _ref.read(konuProvider.notifier).hazir;
    final profil = _ref.read(profilProvider).value;
    final ayar = state.ayar;
    if (profil == null || ayar == null || !mounted) return;
    final bas = state.haftaBaslangic ?? haftaBaslangici(DateTime.now());
    final yeni = haftalikProgramOlustur(
      profil: profil,
      konular: _ref.read(konuProvider),
      ayar: ayar,
      haftaBaslangic: bas,
      ilkGun: ilkGun,
    );
    final hafta = [for (var i = 0; i < 7; i++) i < ilkGun ? state.hafta[i] : yeni[i]];
    state = state.copyWith(hafta: hafta);
    await _storage.setMap(AnalizKayitlari.haftalikProgram, {
      'hafta': state.haftaAnahtari,
      'olusturma': DateTime.now().toIso8601String(),
      'gunler': [
        for (final gun in hafta) [for (final b in gun) b.toJson()],
      ],
    });
  }

  /// Programı bugünden itibaren yeniden üretir. Bugün tamamlanmış blok varsa
  /// bugünkü plan korunur, değişiklik yarından başlar. Dönüş: değişikliğin
  /// başladığı gün indeksi.
  Future<int> yenidenOlustur() async {
    if (!state.yuklendi) await hazirla();
    final bugun = bugunIndex;
    final bugunBiten = state.tamamlanan[gunAnahtari(DateTime.now())]?.isNotEmpty ?? false;
    final ilkGun = bugunBiten ? bugun + 1 : bugun;
    if (ilkGun <= 6) await _olustur(ilkGun: ilkGun);
    await uyumuKaydet();
    return ilkGun;
  }

  Future<int> ayarKaydet(DersProgramiAyar ayar) async {
    await _storage.setMap(AnalizKayitlari.programAyar, ayar.toJson());
    state = state.copyWith(ayar: ayar);
    return yenidenOlustur();
  }

  Future<void> tamamlandiDegistir(String blokId, {DateTime? gun}) async {
    final anahtar = gunAnahtari(gun ?? DateTime.now());
    final set = {...?state.tamamlanan[anahtar]};
    if (!set.remove(blokId)) set.add(blokId);
    await _tamamlananiYaz(anahtar, set);
  }

  Future<void> tamamlandiIsaretle(String blokId, {DateTime? gun}) async {
    final anahtar = gunAnahtari(gun ?? DateTime.now());
    final set = {...?state.tamamlanan[anahtar]};
    if (!set.add(blokId)) return;
    await _tamamlananiYaz(anahtar, set);
  }

  Future<void> _tamamlananiYaz(String anahtar, Set<String> set) async {
    final yeni = {...state.tamamlanan, anahtar: set};
    final sinir = DateTime.now().subtract(const Duration(days: 21));
    yeni.removeWhere((k, _) => (DateTime.tryParse(k) ?? DateTime.now()).isBefore(sinir));
    state = state.copyWith(tamamlanan: yeni);
    await _storage.setMap(AnalizKayitlari.planTamamlanan, {
      for (final e in yeni.entries) e.key: e.value.toList(),
    });
    await uyumuKaydet();
  }

  /// Bu haftanın bugüne kadarki günleri için plan uyumunu analiz kaydına yazar.
  Future<void> uyumuKaydet() async {
    if (!state.yuklendi) return;
    final log = await _storage.getMap(AnalizKayitlari.planUyum) ?? {};
    final checkinLog = await _storage.getMap(AnalizKayitlari.checkin) ?? {};
    final bugun = bugunIndex;
    var degisti = false;
    for (var g = 0; g <= bugun; g++) {
      final anahtar = state.gunAnahtariAt(g);
      var bloklar = state.gunBloklari(g);
      if (bloklar.isEmpty) continue;
      final c = g == bugun ? _ref.read(checkinProvider) : _checkinOku(checkinLog[anahtar], anahtar);
      if (c != null) bloklar = gunlukPlaniUyarla(bloklar, c, anahtar).bloklar;
      final calisma = bloklar.where((b) => b.isCalismaBloku).toList();
      final biten = calisma.where((b) => b.tamamlandi).toList();
      final deger = [
        calisma.length,
        biten.length,
        calisma.fold<int>(0, (t, b) => t + b.sure),
        biten.fold<int>(0, (t, b) => t + b.sure),
      ];
      final onceki = (log[anahtar] as List?)?.cast<num>().map((e) => e.toInt()).toList();
      if (onceki == null || onceki.join(',') != deger.join(',')) {
        log[anahtar] = deger;
        degisti = true;
      }
    }
    if (degisti) await _storage.setMap(AnalizKayitlari.planUyum, eskiKayitlariBudanmis(log));
  }

  GunlukCheckin? _checkinOku(dynamic ham, String anahtar) {
    if (ham is! List || ham.length < 3) return null;
    return GunlukCheckin(
      tarih: anahtar,
      enerji: (ham[0] as num).toInt(),
      odak: (ham[1] as num).toInt(),
      stres: (ham[2] as num).toInt(),
      createdAt: DateTime.now(),
    );
  }
}

final programProvider = StateNotifierProvider<ProgramNotifier, ProgramState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final notifier = ProgramNotifier(ref, storage);
  ref.listen(profilProvider, (_, _) => unawaited(notifier.hazirla()), fireImmediately: true);
  ref.listen(checkinProvider, (_, _) => unawaited(notifier.uyumuKaydet()));
  return notifier;
});

/// Bugünün planı: programın bugünkü günü, check-in'e göre uyarlanmış.
final bugunPlaniProvider = Provider<({List<PlanBlok> bloklar, int cikarilan})>((ref) {
  final program = ref.watch(programProvider);
  final checkin = ref.watch(checkinProvider);
  final bugun = DateTime.now();
  if (program.yuklendi && program.haftaAnahtari != gunAnahtari(haftaBaslangici(bugun))) {
    // Hafta değişti (uygulama açıkken gece yarısı geçti): yeni programı üret.
    Future.microtask(() => ref.read(programProvider.notifier).hazirla());
  }
  final index = bugun.weekday - 1;
  return gunlukPlaniUyarla(program.gunBloklari(index), checkin, gunAnahtari(bugun));
});

/// Geriye dönük uyumluluk: bugünkü plan blokları.
final gunlukPlanProvider = Provider<List<PlanBlok>>((ref) => ref.watch(bugunPlaniProvider).bloklar);
