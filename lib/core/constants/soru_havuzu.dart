/// Test oluşturucunun soru havuzu. Sorular DersNet tarafından özgün olarak
/// yazılmıştır; konu başlıkları MEB müfredatı ve YKS kapsamını izler.
library;

import '../../data/models/soru.dart';
import 'soru_havuzu_ek_fen.dart';
import 'soru_havuzu_ek_mat.dart';
import 'soru_havuzu_ek_sosyal.dart';
import 'soru_havuzu_ek_turkce.dart';
import 'soru_havuzu_sayisal.dart';
import 'soru_havuzu_sozel.dart';

/// Havuzdaki tüm sorular (derslerin müfredat sırasıyla).
final List<Soru> soruHavuzu = [
  ...sozelSorular.where((s) => s.ders == 'Türkçe'),
  ...ekTurkceSorular,
  ...sayisalSorular,
  ...ekMatematikSorular,
  ...ekFenSorular,
  ...sozelSorular.where((s) => s.ders != 'Türkçe'),
  ...ekEdebiyatSorular,
  ...ekSosyalSorular,
];

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

/// Filtreye uyan soruları döndürür ('hepsi' o filtreyi devre dışı bırakır).
List<Soru> filtreliSorular({String ders = 'hepsi', String konu = 'hepsi', String altBaslik = 'hepsi', String zorluk = 'hepsi'}) {
  return [
    for (final s in soruHavuzu)
      if ((ders == 'hepsi' || s.ders == ders) &&
          (konu == 'hepsi' || s.konu == konu) &&
          (altBaslik == 'hepsi' || s.altBaslik == altBaslik) &&
          (zorluk == 'hepsi' || s.zorluk.name == zorluk))
        s,
  ];
}
