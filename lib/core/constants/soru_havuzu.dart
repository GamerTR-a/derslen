/// Test oluşturucunun soru havuzu. Sorular DersNet tarafından özgün olarak
/// yazılmıştır; konu başlıkları MEB müfredatını (9-11. sınıflarda Türkiye
/// Yüzyılı Maarif Modeli) ve YKS kapsamını izler. Sayısal konularda hazır
/// soruların yanında [soruSablonlari] ile her seferinde yeni soru üretilir.
library;

import 'dart:math';

import '../../data/models/soru.dart';
import '../algorithms/soru_uretici.dart';
import 'sinif_mufredati.dart';
import 'soru_havuzu_ek_fen.dart';
import 'soru_havuzu_ek_mat.dart';
import 'soru_havuzu_ek_sosyal.dart';
import 'soru_havuzu_ek_turkce.dart';
import 'soru_havuzu_sayisal.dart';
import 'soru_havuzu_sinif_fen.dart';
import 'soru_havuzu_sinif_mat.dart';
import 'soru_havuzu_sinif_sozel.dart';
import 'soru_havuzu_sozel.dart';
import 'soru_sablonlari_fen.dart';
import 'soru_sablonlari_mat.dart';

/// Havuzdaki tüm sorular (derslerin müfredat sırasıyla). Sınıf müfredatı için
/// yazılan sorular sonda durur.
final List<Soru> soruHavuzu = [
  ...sozelSorular.where((s) => s.ders == 'Türkçe'),
  ...ekTurkceSorular,
  ...sayisalSorular,
  ...ekMatematikSorular,
  ...ekFenSorular,
  ...sozelSorular.where((s) => s.ders != 'Türkçe'),
  ...ekEdebiyatSorular,
  ...ekSosyalSorular,
  ...sinifMatSorulari,
  ...sinifFenSorulari,
  ...sinifSozelSorulari,
];

/// Soru üreten şablonlar (sayısal konular).
final List<SoruSablonu> soruSablonlari = [...matematikSablonlari, ...fenSablonlari];

/// Ders → konu → alt başlık haritası (test oluşturma filtreleri için).
final Map<String, Map<String, List<String>>> dersKonuAltBaslikHaritasi = () {
  final result = <String, Map<String, List<String>>>{};
  for (final soru in soruHavuzu) {
    final konular = result.putIfAbsent(soru.ders, () => {});
    final altlar = konular.putIfAbsent(soru.konu, () => []);
    if (!altlar.contains(soru.altBaslik)) altlar.add(soru.altBaslik);
  }
  return result;
}();

bool _zorlukUyar(SoruZorluk z, String zorluk) => zorluk == 'hepsi' || z.name == zorluk;

/// Filtreye uyan soruları döndürür ('hepsi' o filtreyi devre dışı bırakır).
List<Soru> filtreliSorular({String ders = 'hepsi', String konu = 'hepsi', String altBaslik = 'hepsi', String zorluk = 'hepsi'}) {
  return [
    for (final s in soruHavuzu)
      if ((ders == 'hepsi' || s.ders == ders) &&
          (konu == 'hepsi' || s.konu == konu) &&
          (altBaslik == 'hepsi' || s.altBaslik == altBaslik) &&
          _zorlukUyar(s.zorluk, zorluk))
        s,
  ];
}

/// Filtreye uyan soru şablonları (havuzdaki ders/konu adlarıyla).
List<SoruSablonu> filtreliSablonlar({String ders = 'hepsi', String konu = 'hepsi', String altBaslik = 'hepsi', String zorluk = 'hepsi'}) {
  return [
    for (final s in soruSablonlari)
      if ((ders == 'hepsi' || s.ders == ders) &&
          (konu == 'hepsi' || s.konu == konu) &&
          (altBaslik == 'hepsi' || s.alt == altBaslik) &&
          _zorlukUyar(s.zorluk, zorluk))
        s,
  ];
}

// ─── Sınıf müfredatı (9-11) ile eşleme ──────────────────────────────────

final Map<String, List<Soru>> _konuSorulari = () {
  final m = <String, List<Soru>>{for (final k in sinifMufredati) k.id: <Soru>[]};
  for (final s in soruHavuzu) {
    for (final k in sinifMufredati) {
      if (k.soruEslesir(s.ders, s.konu, s.altBaslik)) m[k.id]!.add(s);
    }
  }
  return m;
}();

final Map<String, List<SoruSablonu>> _konuSablonlari = () {
  final m = <String, List<SoruSablonu>>{for (final k in sinifMufredati) k.id: <SoruSablonu>[]};
  for (final s in soruSablonlari) {
    for (final id in s.konuIdleri) {
      m[id]?.add(s);
    }
  }
  return m;
}();

/// Bir sınıf konusunun havuzdaki hazır soruları.
List<Soru> konuHazirSorulari(String konuId, {String zorluk = 'hepsi'}) =>
    [for (final s in _konuSorulari[konuId] ?? const <Soru>[]) if (_zorlukUyar(s.zorluk, zorluk)) s];

/// Bir sınıf konusu için soru üreten şablonlar.
List<SoruSablonu> konuSablonlari(String konuId, {String zorluk = 'hepsi'}) =>
    [for (final s in _konuSablonlari[konuId] ?? const <SoruSablonu>[]) if (_zorlukUyar(s.zorluk, zorluk)) s];

/// Bir sınıfın (isteğe bağlı olarak tek dersinin) hazır soruları, tekrarsız.
List<Soru> sinifHazirSorulari(int sinif, {String ders = 'hepsi', String zorluk = 'hepsi'}) {
  final gorulen = <String>{};
  return [
    for (final k in sinifMufredati)
      if (k.sinif == sinif && (ders == 'hepsi' || k.ders == ders))
        for (final s in konuHazirSorulari(k.id, zorluk: zorluk))
          if (gorulen.add(s.id)) s,
  ];
}

/// Bir sınıfın (isteğe bağlı olarak tek dersinin) soru şablonları, tekrarsız.
List<SoruSablonu> sinifSablonlari(int sinif, {String ders = 'hepsi', String zorluk = 'hepsi'}) {
  final gorulen = <String>{};
  return [
    for (final k in sinifMufredati)
      if (k.sinif == sinif && (ders == 'hepsi' || k.ders == ders))
        for (final s in konuSablonlari(k.id, zorluk: zorluk))
          if (gorulen.add(s.id)) s,
  ];
}

/// Hazır sorulardan ve şablonlardan [adet] soruluk karışık bir seçki yapar.
/// Şablon varsa soruların yaklaşık üçte biri üretilir; hazır soru yetmezse
/// eksik kalan kısım da üretilerek tamamlanır.
List<Soru> soruSec(List<Soru> hazir, List<SoruSablonu> sablonlar, int adet, {Random? rastgele}) {
  final r = rastgele ?? Random();
  final karisik = [...hazir]..shuffle(r);
  final uretilecek = sablonlar.isEmpty ? 0 : max(adet - karisik.length, min(adet ~/ 3, adet));
  final secilen = karisik.take(max(0, adet - uretilecek)).toList();
  if (uretilecek > 0) {
    final sira = [...sablonlar]..shuffle(r);
    final metinler = {for (final s in secilen) s.soruMetni};
    var i = 0, deneme = 0;
    while (secilen.length < adet && deneme < adet * 12) {
      deneme++;
      final soru = sira[i % sira.length].uret(r.nextInt(1 << 30));
      i++;
      if (metinler.add(soru.soruMetni)) secilen.add(soru);
    }
    secilen.shuffle(r);
  }
  return secilen;
}

/// Kimliğinden hazır soruyu bulur (üretilmiş sorular kimlikle bulunamaz).
Soru? soruBul(String id) => _idHaritasi[id];

final Map<String, Soru> _idHaritasi = {for (final s in soruHavuzu) s.id: s};
