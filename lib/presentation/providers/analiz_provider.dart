/// Gelişim analizi sağlayıcıları — günlük kayıtları okuyup seçili dönem için
/// [DonemAnalizi] üretir. Çalışma, plan, check-in, konu veya net verisi
/// değişince otomatik yeniden hesaplanır.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/algorithms/analiz_motoru.dart';
import '../../core/storage/analiz_kayitlari.dart';
import '../../core/storage/storage_service.dart';
import '../../core/utils/tarih.dart';
import '../../data/models/konu.dart';
import '../../data/models/net_kaydi.dart';
import '../../data/models/ogrenci_profil.dart';
import 'checkin_provider.dart';
import 'flashkart_provider.dart';
import 'konu_provider.dart';
import 'net_provider.dart';
import 'plan_provider.dart';
import 'profil_provider.dart';

/// Analiz ekranında seçili dönem (gün): 7, 30 veya 90.
final analizDonemiProvider = StateProvider<int>((ref) => 7);

Map<String, int> _intHarita(Map<String, dynamic>? m) =>
    {for (final e in (m ?? const {}).entries) e.key: ((e.value as num?) ?? 0).toInt()};

Map<String, List<int>> _listeHarita(Map<String, dynamic>? m) => {
      for (final e in (m ?? const {}).entries)
        if (e.value is List) e.key: [for (final v in e.value as List) (v as num).toInt()],
    };

final analizGirdisiProvider = FutureProvider<AnalizGirdisi?>((ref) async {
  final storage = ref.watch(storageServiceProvider);
  final profil = ref.watch(profilProvider).value;
  final netler = ref.watch(netProvider);
  final konular = ref.watch(konuProvider);
  final kartlar = ref.watch(flashkartProvider);
  ref.watch(checkinProvider);
  ref.watch(programProvider.select((p) => p.tamamlanan));
  return analizGirdisiHazirla(storage: storage, profil: profil, netler: netler, konular: konular, kartlar: kartlar);
});

/// Kayıtları okuyup analiz girdisini hazırlar. Sağlayıcı dışında (ör. koç
/// asistanı) o anki verilerle doğrudan çağrılabilir; `analizGirdisiProvider
/// .future` beklemek, bağımlılıklar değişirken dinleyicisiz kalabildiği için
/// kullanılmaz.
Future<AnalizGirdisi?> analizGirdisiHazirla({
  required StorageService storage,
  required OgrenciProfil? profil,
  required List<NetKaydi> netler,
  required List<Konu> konular,
  required FlashkartState kartlar,
}) async {
  if (profil == null || !profil.onboardingTamamlandi) return null;

  final kayitlar = await Future.wait([
    storage.getMap(AnalizKayitlari.calismaGunluk),
    storage.getMap(AnalizKayitlari.calismaDers),
    storage.getMap(AnalizKayitlari.planUyum),
    storage.getMap(AnalizKayitlari.checkin),
    storage.getMap(AnalizKayitlari.konuIlerleme),
    storage.getMap(AnalizKayitlari.testGecmisi),
  ]);

  final dersLog = <String, Map<String, int>>{
    for (final e in (kayitlar[1] ?? const {}).entries)
      if (e.value is Map) e.key: _intHarita(Map<String, dynamic>.from(e.value as Map)),
  };
  final testler = [
    for (final t in ((kayitlar[5]?['items'] as List?) ?? const []))
      if (t is Map) TestKaydi.fromJson(Map<String, dynamic>.from(t)),
  ];

  return AnalizGirdisi(
    calismaGunluk: _intHarita(kayitlar[0]),
    calismaDers: dersLog,
    planUyum: _listeHarita(kayitlar[2]),
    checkinLog: _listeHarita(kayitlar[3]),
    konuLog: _listeHarita(kayitlar[4]),
    testler: testler,
    netler: netler,
    konular: konular,
    profil: profil,
    bekleyenKart: kartlar.durumlar.where((d) => d.bugunTekrarEdilecek && !yeniKartMi(d)).length,
    toplamKartTekrari: kartlar.durumlar.fold(0, (t, d) => t + d.tekrarSayisi),
    bugun: DateTime.now(),
  );
}

/// Seçili dönemin analizi (veri yüklenirken önceki sonuç korunur).
final donemAnaliziProvider = Provider.family<DonemAnalizi?, int>((ref, gun) {
  final girdi = ref.watch(analizGirdisiProvider).valueOrNull;
  if (girdi == null) return null;
  return donemAnalizi(girdi, gun);
});

/// Bu haftanın (pazartesiden bugüne) derslere göre çalışma dakikaları,
/// çoktan aza sıralı. Odak zamanlayıcısı ve program blokları buraya yazar.
final buHaftaDersDagilimiProvider = Provider<Map<String, int>?>((ref) {
  final g = ref.watch(analizGirdisiProvider).valueOrNull;
  if (g == null) return null;
  final bas = haftaBaslangici(g.bugun);
  final m = <String, int>{};
  for (var i = 0; i < g.bugun.weekday; i++) {
    g.calismaDers[gunAnahtari(bas.add(Duration(days: i)))]?.forEach((d, dk) => m[d] = (m[d] ?? 0) + dk);
  }
  m.removeWhere((_, dk) => dk <= 0);
  return Map.fromEntries(m.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
});
