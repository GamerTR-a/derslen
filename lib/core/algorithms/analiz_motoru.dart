/// Gelişim Analizi Motoru — günlük kayıtlardan dönem özetleri, trendler,
/// tablolar ve otomatik içgörüler üretir. Flutter'a bağımlı değildir; tüm
/// girdiler parametre olarak verilir (test edilebilirlik için).
library;

import 'dart:math';

import '../../data/models/konu.dart';
import '../../data/models/net_kaydi.dart';
import '../../data/models/ogrenci_profil.dart';
import '../constants/app_constants.dart';
import '../utils/tarih.dart';
import 'ders_programi.dart' show alanDersleri, alanKonulari, serbestAlan;

/// Uygulama içi testlerden tek bir dersin sonucu.
class TestKaydi {
  final String tarih;
  final String ders;
  final int dogru;
  final int yanlis;
  final int bos;
  final int saniye;

  const TestKaydi({
    required this.tarih,
    required this.ders,
    required this.dogru,
    required this.yanlis,
    required this.bos,
    this.saniye = 0,
  });

  int get toplam => dogru + yanlis + bos;
  double get net => dogru - yanlis * 0.25;

  Map<String, dynamic> toJson() => {'t': tarih, 'd': ders, 'do': dogru, 'y': yanlis, 'b': bos, 's': saniye};

  factory TestKaydi.fromJson(Map<String, dynamic> j) => TestKaydi(
        tarih: j['t'] as String? ?? '',
        ders: j['d'] as String? ?? 'Genel',
        dogru: (j['do'] as num?)?.toInt() ?? 0,
        yanlis: (j['y'] as num?)?.toInt() ?? 0,
        bos: (j['b'] as num?)?.toInt() ?? 0,
        saniye: (j['s'] as num?)?.toInt() ?? 0,
      );
}

class AnalizGirdisi {
  final Map<String, int> calismaGunluk;
  final Map<String, Map<String, int>> calismaDers;
  final Map<String, List<int>> planUyum;
  final Map<String, List<int>> checkinLog;
  final Map<String, List<int>> konuLog;
  final List<TestKaydi> testler;
  final List<NetKaydi> netler;
  final List<Konu> konular;
  final OgrenciProfil profil;
  final int bekleyenKart;
  final int toplamKartTekrari;
  final DateTime bugun;

  const AnalizGirdisi({
    this.calismaGunluk = const {},
    this.calismaDers = const {},
    this.planUyum = const {},
    this.checkinLog = const {},
    this.konuLog = const {},
    this.testler = const [],
    this.netler = const [],
    this.konular = const [],
    required this.profil,
    this.bekleyenKart = 0,
    this.toplamKartTekrari = 0,
    required this.bugun,
  });
}

class DenemeNoktasi {
  final DateTime tarih;
  final String ad;
  final double net;
  const DenemeNoktasi(this.tarih, this.ad, this.net);
}

class NetTrendi {
  final List<DenemeNoktasi> noktalar;

  /// Son (en fazla 8) denemeye göre deneme başına ortalama net değişimi.
  final double egim;

  /// 3'lü hareketli ortalama (noktalarla aynı uzunlukta).
  final List<double> hareketliOrtalama;

  const NetTrendi(this.noktalar, this.egim, this.hareketliOrtalama);

  bool get bos => noktalar.isEmpty;
  double? get son => noktalar.isEmpty ? null : noktalar.last.net;
  double? get degisim => noktalar.length < 2 ? null : noktalar.last.net - noktalar[noktalar.length - 2].net;
  double get enIyi => noktalar.fold<double>(0, (m, e) => max(m, e.net));

  /// Bu eğimle [denemeSonra] deneme sonraki tahmini net (0'ın altına inmez).
  double tahmin(int denemeSonra) => max(0, (son ?? 0) + egim * denemeSonra);
}

class DersNetSatiri {
  final String ders;
  final SinavAlani alan;
  final int denemeSayisi;
  final double son;
  final double ortalama;
  final double enIyi;

  /// Son 3 denemenin ortalaması − önceki 3'ün ortalaması (yetersizse null).
  final double? degisim;
  final double dogruluk;

  const DersNetSatiri({
    required this.ders,
    required this.alan,
    required this.denemeSayisi,
    required this.son,
    required this.ortalama,
    required this.enIyi,
    required this.degisim,
    required this.dogruluk,
  });
}

class KonuDersDurumu {
  final String ders;
  final int toplam;
  final int tamamlanan;
  final int zayif;
  const KonuDersDurumu(this.ders, this.toplam, this.tamamlanan, this.zayif);
  double get oran => toplam == 0 ? 0 : tamamlanan / toplam;
}

class TestDersOzeti {
  final String ders;
  final int soru;
  final int dogru;
  final int yanlis;
  const TestDersOzeti(this.ders, this.soru, this.dogru, this.yanlis);
  double get dogruluk => soru == 0 ? 0 : dogru / soru;
}

enum IcgoruTuru { olumlu, uyari, bilgi }

class Icgoru {
  final IcgoruTuru tur;
  final String metin;
  const Icgoru(this.tur, this.metin);
}

class DonemAnalizi {
  final int gunSayisi;
  final List<String> gunler;
  final List<int> gunlukDk;
  final int toplamDk;
  final int oncekiDonemDk;
  final int aktifGun;
  final int hedefDk;
  final int hedefeUlasilanGun;
  final int seri;
  final int enUzunSeri;
  final Map<String, int> dersDagilimi;
  final List<int> planlananBlok;
  final List<int> tamamlananBlok;
  final List<int> planlananDk;
  final List<int> tamamlananDk;
  final NetTrendi tyt;
  final NetTrendi ayt;
  final List<DersNetSatiri> dersNetTablosu;
  final List<KonuDersDurumu> konuDurumu;
  final List<int?> konuTamamlananSerisi;
  final List<List<int>?> checkinSerisi;
  final List<TestDersOzeti> testOzeti;
  final List<List<int>> isiHaritasi;
  final List<Icgoru> icgoruler;
  final int bekleyenKart;

  const DonemAnalizi({
    required this.gunSayisi,
    required this.gunler,
    required this.gunlukDk,
    required this.toplamDk,
    required this.oncekiDonemDk,
    required this.aktifGun,
    required this.hedefDk,
    required this.hedefeUlasilanGun,
    required this.seri,
    required this.enUzunSeri,
    required this.dersDagilimi,
    required this.planlananBlok,
    required this.tamamlananBlok,
    required this.planlananDk,
    required this.tamamlananDk,
    required this.tyt,
    required this.ayt,
    required this.dersNetTablosu,
    required this.konuDurumu,
    required this.konuTamamlananSerisi,
    required this.checkinSerisi,
    required this.testOzeti,
    required this.isiHaritasi,
    required this.icgoruler,
    required this.bekleyenKart,
  });

  double get gunlukOrtalamaDk => gunSayisi == 0 ? 0 : toplamDk / gunSayisi;

  /// Plan uyumu (0..1); plan verisi yoksa null.
  double? get planUyumu {
    final p = planlananBlok.fold<int>(0, (a, b) => a + b);
    if (p == 0) return null;
    return tamamlananBlok.fold<int>(0, (a, b) => a + b) / p;
  }

  /// Önceki eşit döneme göre çalışma süresi değişimi (%); karşılaştırma yoksa null.
  double? get calismaDegisimYuzde => oncekiDonemDk == 0 ? null : (toplamDk - oncekiDonemDk) / oncekiDonemDk * 100;

  int get toplamKonu => konuDurumu.fold(0, (a, b) => a + b.toplam);
  int get tamamlananKonu => konuDurumu.fold(0, (a, b) => a + b.tamamlanan);
  int get zayifKonu => konuDurumu.fold(0, (a, b) => a + b.zayif);
  double get konuOrani => toplamKonu == 0 ? 0 : tamamlananKonu / toplamKonu;
}

/// Bugünden (dahil) geriye kesintisiz çalışılan gün sayısı. Bugün henüz
/// çalışılmadıysa seri dünden itibaren sayılır (gün bitmeden sıfırlanmaz).
int calismaSerisi(Map<String, int> log, DateTime bugun) {
  var gun = sadeceGun(bugun);
  if ((log[gunAnahtari(gun)] ?? 0) <= 0) gun = gun.subtract(const Duration(days: 1));
  var seri = 0;
  while ((log[gunAnahtari(gun)] ?? 0) > 0) {
    seri++;
    gun = gun.subtract(const Duration(days: 1));
  }
  return seri;
}

int enUzunSeri(Map<String, int> log) {
  final gunler = log.entries.where((e) => e.value > 0).map((e) => DateTime.tryParse(e.key)).whereType<DateTime>().toList()
    ..sort();
  var enUzun = 0;
  var mevcut = 0;
  DateTime? onceki;
  for (final g in gunler) {
    mevcut = (onceki != null && g.difference(onceki).inDays == 1) ? mevcut + 1 : 1;
    enUzun = max(enUzun, mevcut);
    onceki = g;
  }
  return enUzun;
}

/// Aynı gün girilen aynı denemenin ders kayıtlarını toplam nete çevirir.
///
/// [ortalama] true ise (serbest müfredat: 100 üzerinden ders puanları) toplam
/// yerine derslerin ortalaması alınır.
List<DenemeNoktasi> denemeNoktalari(List<NetKaydi> kayitlar, SinavAlani alan, {bool ortalama = false}) {
  final map = <String, (DateTime, String, double, int)>{};
  for (final k in kayitlar.where((k) => k.alan == alan)) {
    final anahtar = '${k.tarih}|${k.denemeAdi ?? ''}';
    final onceki = map[anahtar];
    map[anahtar] = (
      onceki?.$1 ?? (DateTime.tryParse(k.tarih) ?? k.createdAt),
      k.denemeAdi ?? k.tarih,
      (onceki?.$3 ?? 0) + k.net,
      (onceki?.$4 ?? 0) + 1,
    );
  }
  final liste = map.values.toList()..sort((a, b) => a.$1.compareTo(b.$1));
  return [
    for (final e in liste) DenemeNoktasi(e.$1, e.$2, double.parse((ortalama ? e.$3 / e.$4 : e.$3).toStringAsFixed(2))),
  ];
}

/// En küçük kareler eğimi (x = 0..n-1).
double dogrusalEgim(List<double> y) {
  final n = y.length;
  if (n < 2) return 0;
  final xOrt = (n - 1) / 2;
  final yOrt = y.reduce((a, b) => a + b) / n;
  var pay = 0.0;
  var payda = 0.0;
  for (var i = 0; i < n; i++) {
    pay += (i - xOrt) * (y[i] - yOrt);
    payda += (i - xOrt) * (i - xOrt);
  }
  return payda == 0 ? 0 : pay / payda;
}

NetTrendi netTrendi(List<NetKaydi> kayitlar, SinavAlani alan, {bool ortalama = false}) {
  final noktalar = denemeNoktalari(kayitlar, alan, ortalama: ortalama);
  final netler = noktalar.map((e) => e.net).toList();
  final son8 = netler.length > 8 ? netler.sublist(netler.length - 8) : netler;
  final ho = <double>[
    for (var i = 0; i < netler.length; i++)
      netler.sublist(max(0, i - 2), i + 1).reduce((a, b) => a + b) / (i - max(0, i - 2) + 1),
  ];
  return NetTrendi(noktalar, dogrusalEgim(son8), ho);
}

List<DersNetSatiri> dersNetTablosu(List<NetKaydi> kayitlar) {
  final gruplar = <(SinavAlani, String), List<NetKaydi>>{};
  for (final k in kayitlar) {
    gruplar.putIfAbsent((k.alan, k.ders), () => []).add(k);
  }
  final satirlar = <DersNetSatiri>[];
  for (final e in gruplar.entries) {
    final l = e.value..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final netler = l.map((k) => k.net).toList();
    double ort(List<double> x) => x.isEmpty ? 0 : x.reduce((a, b) => a + b) / x.length;
    double? degisim;
    if (netler.length >= 2) {
      final yarim = min(3, netler.length ~/ 2);
      final son = netler.sublist(netler.length - yarim);
      final onceki = netler.sublist(netler.length - 2 * yarim, netler.length - yarim);
      degisim = ort(son) - ort(onceki);
    }
    final soru = l.fold<int>(0, (a, k) => a + k.toplamSoru);
    final dogru = l.fold<int>(0, (a, k) => a + k.dogru);
    satirlar.add(DersNetSatiri(
      ders: e.key.$2,
      alan: e.key.$1,
      denemeSayisi: l.length,
      son: netler.last,
      ortalama: ort(netler),
      enIyi: netler.reduce(max),
      degisim: degisim,
      dogruluk: soru == 0 ? 0 : dogru / soru,
    ));
  }
  satirlar.sort((a, b) {
    final c = a.alan.index.compareTo(b.alan.index);
    return c != 0 ? c : b.ortalama.compareTo(a.ortalama);
  });
  return satirlar;
}

/// Son 12 haftanın (pazartesiden başlayan) günlük dakikaları; gelecekteki günler -1.
List<List<int>> isiHaritasi(Map<String, int> log, DateTime bugun, {int hafta = 12}) {
  final buHafta = haftaBaslangici(bugun);
  final bas = buHafta.subtract(Duration(days: 7 * (hafta - 1)));
  final bugunGun = sadeceGun(bugun);
  return [
    for (var h = 0; h < hafta; h++)
      [
        for (var g = 0; g < 7; g++)
          () {
            final t = bas.add(Duration(days: h * 7 + g));
            return t.isAfter(bugunGun) ? -1 : (log[gunAnahtari(t)] ?? 0);
          }(),
      ],
  ];
}

DonemAnalizi donemAnalizi(AnalizGirdisi g, int gunSayisi) {
  final gunler = sonGunler(gunSayisi, g.bugun);
  final gunlukDk = [for (final k in gunler) g.calismaGunluk[k] ?? 0];
  final toplamDk = gunlukDk.fold<int>(0, (a, b) => a + b);
  final oncekiGunler = sonGunler(gunSayisi, g.bugun.subtract(Duration(days: gunSayisi)));
  final oncekiDk = oncekiGunler.fold<int>(0, (a, k) => a + (g.calismaGunluk[k] ?? 0));
  final hedefDk = g.profil.gunlukSaat * 60;

  final dersDagilimi = <String, int>{};
  for (final k in gunler) {
    g.calismaDers[k]?.forEach((ders, dk) => dersDagilimi[ders] = (dersDagilimi[ders] ?? 0) + dk);
  }
  final siraliDers = Map.fromEntries(dersDagilimi.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));

  List<int> planSutun(int i) => [for (final k in gunler) (g.planUyum[k] != null && g.planUyum[k]!.length > i) ? g.planUyum[k]![i] : 0];

  final konuDurumu = <KonuDersDurumu>[];
  final ilgili = alanKonulari(g.profil.hedefBolum, g.konular);
  for (final d in alanDersleri(g.profil.hedefBolum, ilgili)) {
    final l = ilgili.where((k) => k.ders == d).toList();
    konuDurumu.add(KonuDersDurumu(d, l.length, l.where((k) => k.tamamlandi).length, l.where((k) => k.zayif).length));
  }

  // Konu tamamlama serisi: kayıt olmayan günler önceki değerle doldurulur.
  int? sonDeger;
  final oncekiKayitlar = g.konuLog.keys.where((k) => k.compareTo(gunler.first) < 0).toList()..sort();
  if (oncekiKayitlar.isNotEmpty) sonDeger = g.konuLog[oncekiKayitlar.last]!.first;
  final konuSerisi = <int?>[];
  for (final k in gunler) {
    final v = g.konuLog[k];
    if (v != null && v.isNotEmpty) sonDeger = v.first;
    konuSerisi.add(sonDeger);
  }

  final testMap = <String, List<int>>{};
  for (final t in g.testler.where((t) => t.tarih.compareTo(gunler.first) >= 0)) {
    final m = testMap.putIfAbsent(t.ders, () => [0, 0, 0]);
    m[0] += t.toplam;
    m[1] += t.dogru;
    m[2] += t.yanlis;
  }
  final testOzeti = [for (final e in testMap.entries) TestDersOzeti(e.key, e.value[0], e.value[1], e.value[2])]
    ..sort((a, b) => b.soru.compareTo(a.soru));

  final analiz = DonemAnalizi(
    gunSayisi: gunSayisi,
    gunler: gunler,
    gunlukDk: gunlukDk,
    toplamDk: toplamDk,
    oncekiDonemDk: oncekiDk,
    aktifGun: gunlukDk.where((d) => d > 0).length,
    hedefDk: hedefDk,
    hedefeUlasilanGun: hedefDk == 0 ? 0 : gunlukDk.where((d) => d >= hedefDk).length,
    seri: calismaSerisi(g.calismaGunluk, g.bugun),
    enUzunSeri: enUzunSeri(g.calismaGunluk),
    dersDagilimi: siraliDers,
    planlananBlok: planSutun(0),
    tamamlananBlok: planSutun(1),
    planlananDk: planSutun(2),
    tamamlananDk: planSutun(3),
    tyt: netTrendi(g.netler, SinavAlani.TYT, ortalama: g.profil.hedefBolum == serbestAlan),
    ayt: netTrendi(g.netler, SinavAlani.AYT),
    dersNetTablosu: dersNetTablosu(g.netler),
    konuDurumu: konuDurumu,
    konuTamamlananSerisi: konuSerisi,
    checkinSerisi: [for (final k in gunler) g.checkinLog[k]],
    testOzeti: testOzeti,
    isiHaritasi: isiHaritasi(g.calismaGunluk, g.bugun),
    icgoruler: <Icgoru>[],
    bekleyenKart: g.bekleyenKart,
  );
  analiz.icgoruler.addAll(icgoruUret(analiz, g));
  return analiz;
}

/// Verilerden kısa, uygulanabilir yorumlar üretir (en önemlisi başta).
List<Icgoru> icgoruUret(DonemAnalizi a, AnalizGirdisi g) {
  final l = <Icgoru>[];
  final donemAdi = a.gunSayisi <= 7 ? 'bu hafta' : 'son ${a.gunSayisi} günde';

  if (a.toplamDk == 0) {
    l.add(Icgoru(IcgoruTuru.uyari, '${donemAdi[0].toUpperCase()}${donemAdi.substring(1)} kayıtlı çalışma yok. Çalış sekmesinden bir odak oturumu başlatınca grafiklerin dolmaya başlar.'));
  } else {
    final degisim = a.calismaDegisimYuzde;
    if (degisim != null && degisim >= 10) {
      l.add(Icgoru(IcgoruTuru.olumlu, 'Çalışma süren önceki döneme göre %${degisim.round()} arttı. Harika gidiyorsun!'));
    } else if (degisim != null && degisim <= -15) {
      l.add(Icgoru(IcgoruTuru.uyari, 'Çalışma süren önceki döneme göre %${degisim.abs().round()} azaldı. Programındaki süreleri gerçekçi tutmak düzenini korumana yardım eder.'));
    }
    if (a.hedefDk > 0) {
      final oran = a.gunlukOrtalamaDk / a.hedefDk;
      if (oran < 0.6) {
        l.add(Icgoru(IcgoruTuru.uyari, 'Günlük ortalaman ${sureMetni(a.gunlukOrtalamaDk.round())}; hedefin ${sureMetni(a.hedefDk)}. Hedefe ulaştığın gün sayısı: ${a.hedefeUlasilanGun}/${a.gunSayisi}.'));
      } else if (oran >= 1) {
        l.add(Icgoru(IcgoruTuru.olumlu, 'Günlük ortalaman (${sureMetni(a.gunlukOrtalamaDk.round())}) hedefinin üstünde.'));
      }
    }
  }

  final uyum = a.planUyumu;
  if (uyum != null) {
    if (uyum >= 0.8) {
      l.add(Icgoru(IcgoruTuru.olumlu, 'Programına %${(uyum * 100).round()} uydun; disiplinin netlerine yansıyacak.'));
    } else if (uyum < 0.5) {
      l.add(Icgoru(IcgoruTuru.uyari, 'Plan uyumun %${(uyum * 100).round()}. Programım ekranından günlük süreyi biraz azaltıp daha ulaşılabilir bir plan kurabilirsin.'));
    }
  }

  if (a.tyt.noktalar.length >= 3) {
    final e = a.tyt.egim;
    if (e >= 0.5) {
      if (g.profil.hedefBolum == serbestAlan) {
        l.add(Icgoru(IcgoruTuru.olumlu, 'Sınav puanların yükseliyor (sınav başına ortalama +${e.toStringAsFixed(1)}).'));
      } else {
        l.add(Icgoru(IcgoruTuru.olumlu, 'TYT netin deneme başına ortalama +${e.toStringAsFixed(1)} artıyor. Bu hızla 5 deneme sonra ≈${a.tyt.tahmin(5).toStringAsFixed(0)} net.'));
      }
    } else if (e <= -0.5) {
      if (g.profil.hedefBolum == serbestAlan) {
        l.add(Icgoru(IcgoruTuru.uyari, 'Son sınavlarda puanın düşüş eğiliminde (${e.toStringAsFixed(1)}/sınav). Zayıf konularını işaretleyip programa ekle.'));
      } else {
        l.add(Icgoru(IcgoruTuru.uyari, 'Son TYT denemelerinde netin düşüş eğiliminde (${e.toStringAsFixed(1)}/deneme). Yanlış yaptığın konuları zayıf olarak işaretleyip programa ekle.'));
      }
    }
  }

  final dusenler = a.dersNetTablosu.where((s) => s.degisim != null && s.degisim! <= -1).toList();
  if (dusenler.isNotEmpty) {
    final s = dusenler.reduce((x, y) => x.degisim! < y.degisim! ? x : y);
    l.add(Icgoru(IcgoruTuru.uyari, '${g.profil.hedefBolum == serbestAlan ? '' : '${s.alan.name} '}${s.ders} sonucun son sınavlarda ${s.degisim!.toStringAsFixed(1)} düştü.'));
  }
  final yukselenler = a.dersNetTablosu.where((s) => s.degisim != null && s.degisim! >= 1).toList();
  if (yukselenler.isNotEmpty) {
    final s = yukselenler.reduce((x, y) => x.degisim! > y.degisim! ? x : y);
    l.add(Icgoru(IcgoruTuru.olumlu, '${g.profil.hedefBolum == serbestAlan ? '' : '${s.alan.name} '}${s.ders} sonucun son sınavlarda +${s.degisim!.toStringAsFixed(1)} yükseldi.'));
  }

  if (a.dersDagilimi.length >= 2 && a.toplamDk >= 120) {
    final enCok = a.dersDagilimi.entries.first;
    final pay = enCok.value / a.toplamDk;
    if (pay >= 0.5) {
      l.add(Icgoru(IcgoruTuru.bilgi, 'Sürenin %${(pay * 100).round()}\'i ${enCok.key} dersine gitti. Diğer derslerle dengelemek unutmayı azaltır.'));
    }
  }

  final zayifDers = a.konuDurumu.where((k) => k.zayif > 0).toList()..sort((x, y) => y.zayif.compareTo(x.zayif));
  if (zayifDers.isNotEmpty) {
    l.add(Icgoru(IcgoruTuru.bilgi, 'En çok zayıf konu ${zayifDers.first.ders} dersinde (${zayifDers.first.zayif}). Programın bu konulara soru çözme blokları ayırıyor.'));
  }

  // Check-in ile çalışma süresi ilişkisi.
  final yuksek = <int>[];
  final dusuk = <int>[];
  for (var i = 0; i < a.gunler.length; i++) {
    final c = a.checkinSerisi[i];
    if (c == null || c.isEmpty) continue;
    if (c[0] >= 4) yuksek.add(a.gunlukDk[i]);
    if (c[0] <= 2) dusuk.add(a.gunlukDk[i]);
  }
  if (yuksek.length >= 2 && dusuk.length >= 2) {
    final y = yuksek.reduce((p, q) => p + q) / yuksek.length;
    final d = dusuk.reduce((p, q) => p + q) / dusuk.length;
    if (y > d * 1.3) {
      l.add(Icgoru(IcgoruTuru.bilgi, 'Enerjinin yüksek olduğu günlerde ortalama ${sureMetni(y.round())}, düşük olduğu günlerde ${sureMetni(d.round())} çalışıyorsun. Uyku ve mola düzeni fark yaratıyor.'));
    }
  }

  if (a.bekleyenKart >= 15) {
    l.add(Icgoru(IcgoruTuru.uyari, '${a.bekleyenKart} tekrar kartın bekliyor. Kartlar sekmesinde kısa bir tekrar unutmayı önler.'));
  }

  if (a.seri >= 3) {
    l.add(Icgoru(IcgoruTuru.olumlu, '${a.seri} gündür aralıksız çalışıyorsun. En uzun serin: ${a.enUzunSeri} gün.'));
  }
  return l;
}
