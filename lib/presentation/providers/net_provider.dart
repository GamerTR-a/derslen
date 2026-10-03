import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/storage_service.dart';
import '../../core/services/supabase_data_service.dart';
import '../../core/utils/tarih.dart';
import '../../data/models/net_kaydi.dart';
import '../../core/constants/app_constants.dart';
import 'profil_provider.dart';

const String _netKayitlariStorageKey = 'net_kayitlari_listesi';

/// ÖSYM oturumlarındaki soru sayıları (ders başına en fazla girilebilecek soru).
const Map<SinavAlani, Map<String, int>> denemeSoruSayilari = {
  SinavAlani.TYT: {
    'Türkçe': 40,
    'Sosyal Bilimler': 20,
    'Matematik': 40,
    'Fen Bilimleri': 20,
  },
  SinavAlani.AYT: {
    'Matematik': 40,
    'Fizik': 14,
    'Kimya': 13,
    'Biyoloji': 13,
    'Türk Dili ve Edebiyatı': 24,
    'Tarih': 21,
    'Coğrafya': 17,
    'Felsefe Grubu': 12,
    'Din Kültürü': 6,
  },
};

/// Deneme formunda bir dersin satırı.
class DenemeSatiri {
  final String ders;
  final int dogru;
  final int yanlis;
  final int bos;
  const DenemeSatiri(this.ders, this.dogru, this.yanlis, this.bos);
}

/// Aynı gün, aynı alan ve aynı adla girilmiş ders kayıtlarının oluşturduğu deneme.
class DenemeGrubu {
  final String tarih;
  final SinavAlani alan;
  final String ad;
  final List<NetKaydi> dersler;

  const DenemeGrubu({required this.tarih, required this.alan, required this.ad, required this.dersler});

  String get anahtar => denemeAnahtari(tarih, alan, ad);
  double get toplamNet => double.parse(dersler.fold<double>(0, (t, k) => t + k.net).toStringAsFixed(2));
  int get dogru => dersler.fold(0, (t, k) => t + k.dogru);
  int get yanlis => dersler.fold(0, (t, k) => t + k.yanlis);
  int get bos => dersler.fold(0, (t, k) => t + k.bos);
  DateTime get olusturma => dersler.map((k) => k.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);
}

String denemeAnahtari(String tarih, SinavAlani alan, String ad) => '$tarih|${alan.name}|$ad';

/// Uygulamanın verdiği ("TYT Denemesi 3", eski sürümlerde "Deneme 3") adlar;
/// bunlar topluluk karşılaştırmasına gönderilmez.
bool otomatikDenemeAdi(String? ad) => ad == null || RegExp(r'^((TYT|AYT) Denemesi|Deneme|Sınav) \d+$').hasMatch(ad.trim());

class NetNotifier extends StateNotifier<List<NetKaydi>> {
  final StorageService _storageService;

  NetNotifier(this._storageService) : super([]) {
    loadNetKayitlari();
  }

  Future<void> loadNetKayitlari() async {
    try {
      final list = await _storageService.getMap(_netKayitlariStorageKey);
      if (list != null && list['items'] is List) {
        final items = (list['items'] as List)
            .map((e) => NetKaydi.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        state = items;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('NetNotifier: net kayıtları yüklenemedi: $e');
    }
  }

  /// Ad verilmemiş denemeler için "TYT Denemesi 3" gibi, o alandaki
  /// denemeler arasında benzersiz bir ad üretir.
  String otomatikAd(SinavAlani alan, {bool serbest = false}) {
    final mevcut = state.where((k) => k.alan == alan).map((k) => '${k.tarih}|${k.denemeAdi ?? ''}').toSet().length;
    var n = mevcut + 1;
    final adlar = state.map((k) => k.denemeAdi).toSet();
    String ad(int i) => serbest ? 'Sınav $i' : '${alan.name} Denemesi $i';
    while (adlar.contains(ad(n))) {
      n++;
    }
    return ad(n);
  }

  /// Bir denemenin tüm ders sonuçlarını tek seferde kaydeder. Hepsi aynı
  /// tarih ve adla saklandığı için analizde tek bir deneme noktası olur.
  Future<void> denemeEkle({
    required SinavAlani alan,
    required DateTime tarih,
    required List<DenemeSatiri> satirlar,
    String? denemeAdi,
    bool serbest = false,
  }) async {
    if (satirlar.isEmpty) return;
    final now = DateTime.now();
    final kullaniciAdi = denemeAdi?.trim() ?? '';
    final ad = kullaniciAdi.isEmpty ? otomatikAd(alan, serbest: serbest) : kullaniciAdi;
    final gun = gunAnahtari(tarih);

    final yeniler = [
      for (var i = 0; i < satirlar.length; i++)
        NetKaydi(
          id: 'net-${now.microsecondsSinceEpoch}-$i',
          tarih: gun,
          alan: alan,
          ders: satirlar[i].ders,
          dogru: satirlar[i].dogru,
          yanlis: satirlar[i].yanlis,
          bos: satirlar[i].bos,
          denemeAdi: ad,
          createdAt: now,
        ),
    ];
    state = [...yeniler, ...state];
    await _saveNetKayitlari();

    // Kullanıcı gerçek bir deneme adı (yayın) yazdıysa topluluk karşılaştırması
    // için anonim olarak sunucuya da gönderilir. Bağlantı yoksa sessizce
    // yutulur; yerel kayıt zaten yapıldı.
    if (kullaniciAdi.isNotEmpty && !serbest) {
      for (final s in satirlar) {
        unawaited(SupabaseDataService.submitExamResult(
          denemeAdi: kullaniciAdi,
          alan: alan.name,
          ders: s.ders,
          dogru: s.dogru,
          yanlis: s.yanlis,
          bos: s.bos,
        ));
      }
    }
  }

  Future<void> netSil(String id) async {
    state = state.where((k) => k.id != id).toList();
    await _saveNetKayitlari();
  }

  /// Bir denemenin tüm ders kayıtlarını siler.
  Future<void> denemeSil(String anahtar) async {
    state = state.where((k) => denemeAnahtari(k.tarih, k.alan, k.denemeAdi ?? '') != anahtar).toList();
    await _saveNetKayitlari();
  }

  Future<void> _saveNetKayitlari() async {
    final mapList = state.map((k) => k.toJson()).toList();
    await _storageService.setMap(_netKayitlariStorageKey, {'items': mapList});
  }
}

final netProvider = StateNotifierProvider<NetNotifier, List<NetKaydi>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return NetNotifier(storage);
});

/// Kayıtların denemelere göre gruplanmış hali (en yeni deneme başta).
final denemeGruplariProvider = Provider<List<DenemeGrubu>>((ref) {
  final kayitlar = ref.watch(netProvider);
  final gruplar = <String, List<NetKaydi>>{};
  for (final k in kayitlar) {
    gruplar.putIfAbsent(denemeAnahtari(k.tarih, k.alan, k.denemeAdi ?? ''), () => []).add(k);
  }
  final liste = [
    for (final l in gruplar.values)
      DenemeGrubu(tarih: l.first.tarih, alan: l.first.alan, ad: l.first.denemeAdi ?? l.first.tarih, dersler: l),
  ];
  liste.sort((a, b) {
    final c = b.tarih.compareTo(a.tarih);
    return c != 0 ? c : b.olusturma.compareTo(a.olusturma);
  });
  return liste;
});

/// Ders bazında ortalama netler ("TYT Matematik" gibi alan önekli anahtarlarla;
/// TYT ve AYT'deki aynı adlı dersler karışmaz).
final dersNetOrtalamalariProvider = Provider<Map<String, double>>((ref) {
  final tumNetler = ref.watch(netProvider);
  final map = <String, List<double>>{};

  for (final n in tumNetler) {
    map.putIfAbsent('${n.alan.name} ${n.ders}', () => []).add(n.net);
  }

  final result = <String, double>{};
  map.forEach((ders, netler) {
    if (netler.isNotEmpty) {
      final ort = netler.reduce((a, b) => a + b) / netler.length;
      result[ders] = double.parse(ort.toStringAsFixed(2));
    }
  });

  return result;
});
