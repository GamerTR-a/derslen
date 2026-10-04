/// Test, deneme ve yanlış tekrarı durumu.
///
/// * Konu testi: sınıf müfredatındaki bir konudan (9-11) ya da soru
///   havuzundaki ders/konu/alt başlıktan (YKS) seçilen sorular.
/// * Deneme: bir sınıfın tüm derslerinden (ya da tek dersinden) dengeli
///   dağıtılmış, süreli sınav.
/// * Yanlış tekrarı: daha önce yanlış yapılan hazır sorular yeniden sorulur;
///   doğru cevaplanan soru listeden çıkar.
library;

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/algorithms/analiz_motoru.dart' show TestKaydi;
import '../../core/algorithms/soru_uretici.dart';
import '../../core/constants/sinif_mufredati.dart';
import '../../core/constants/soru_havuzu.dart';
import '../../core/storage/analiz_kayitlari.dart';
import '../../core/storage/storage_service.dart';
import '../../core/utils/tarih.dart';
import '../../data/models/soru.dart';
import 'flashkart_provider.dart';
import 'mufredat_provider.dart';
import 'profil_provider.dart';

enum TestTuru { konu, deneme, tekrar }

class TestFiltreState {
  /// Sınıf (9, 10, 11) seçiliyse [konu] bir sınıf konusu kimliğidir; null ise
  /// tüm havuz (YKS) kullanılır ve [konu] havuzdaki konu adıdır.
  final int? sinif;
  final String ders;
  final String konu;
  final String altBaslik;
  final String zorluk; // 'hepsi', 'kolay', 'orta', 'zor'
  final int soruSayisi; // 5, 10, 15, 20

  const TestFiltreState({
    this.sinif,
    this.ders = 'hepsi',
    this.konu = 'hepsi',
    this.altBaslik = 'hepsi',
    this.zorluk = 'hepsi',
    this.soruSayisi = 10,
  });

  TestFiltreState copyWith({
    String? ders,
    String? konu,
    String? altBaslik,
    String? zorluk,
    int? soruSayisi,
  }) {
    return TestFiltreState(
      sinif: sinif,
      ders: ders ?? this.ders,
      konu: konu ?? this.konu,
      altBaslik: altBaslik ?? this.altBaslik,
      zorluk: zorluk ?? this.zorluk,
      soruSayisi: soruSayisi ?? this.soruSayisi,
    );
  }

  /// Filtreye uyan hazır sorular.
  List<Soru> get hazirSorular {
    final s = sinif;
    if (s == null) return filtreliSorular(ders: ders, konu: konu, altBaslik: altBaslik, zorluk: zorluk);
    if (konu != 'hepsi') return konuHazirSorulari(konu, zorluk: zorluk);
    return sinifHazirSorulari(s, ders: ders, zorluk: zorluk);
  }

  /// Filtreye uyan soru şablonları (sayısal konularda sınırsız soru üretir).
  List<SoruSablonu> get sablonlar {
    final s = sinif;
    if (s == null) return filtreliSablonlar(ders: ders, konu: konu, altBaslik: altBaslik, zorluk: zorluk);
    if (konu != 'hepsi') return konuSablonlari(konu, zorluk: zorluk);
    return sinifSablonlari(s, ders: ders, zorluk: zorluk);
  }
}

class AktifTestState {
  final List<Soru> sorular;
  final Map<int, String> cevaplar; // soruIndex -> 'A'/'B'/'C'/'D'/'E'
  final int gecenSaniye;
  final bool tamamlandi;
  final TestTuru tur;
  final String baslik;
  final int? sinif;

  /// Süre sınırı (saniye); null ise süre serbesttir.
  final int? sureSiniri;

  const AktifTestState({
    required this.sorular,
    this.cevaplar = const {},
    this.gecenSaniye = 0,
    this.tamamlandi = false,
    this.tur = TestTuru.konu,
    this.baslik = 'Test',
    this.sinif,
    this.sureSiniri,
  });

  AktifTestState copyWith({
    List<Soru>? sorular,
    Map<int, String>? cevaplar,
    int? gecenSaniye,
    bool? tamamlandi,
  }) {
    return AktifTestState(
      sorular: sorular ?? this.sorular,
      cevaplar: cevaplar ?? this.cevaplar,
      gecenSaniye: gecenSaniye ?? this.gecenSaniye,
      tamamlandi: tamamlandi ?? this.tamamlandi,
      tur: tur,
      baslik: baslik,
      sinif: sinif,
      sureSiniri: sureSiniri,
    );
  }

  int get dogruSayisi {
    var count = 0;
    for (var i = 0; i < sorular.length; i++) {
      if (cevaplar[i] == sorular[i].dogruSecenek) count++;
    }
    return count;
  }

  int get yanlisSayisi {
    var count = 0;
    for (var i = 0; i < sorular.length; i++) {
      if (cevaplar.containsKey(i) && cevaplar[i] != sorular[i].dogruSecenek) count++;
    }
    return count;
  }

  int get bosSayisi => sorular.length - cevaplar.length;

  double get net {
    final raw = dogruSayisi - (yanlisSayisi * 0.25);
    return double.parse(raw.toStringAsFixed(2));
  }

  /// Kalan süre (saniye); süre sınırı yoksa null.
  int? get kalanSaniye => sureSiniri == null ? null : max(0, sureSiniri! - gecenSaniye);

  /// Ders bazında [doğru, yanlış, boş] sayıları (soru sırasıyla).
  Map<String, List<int>> get dersSonuclari {
    final m = <String, List<int>>{};
    for (var i = 0; i < sorular.length; i++) {
      final l = m.putIfAbsent(dersAdiNormalize(sorular[i].ders), () => [0, 0, 0]);
      final c = cevaplar[i];
      l[c == null ? 2 : (c == sorular[i].dogruSecenek ? 0 : 1)]++;
    }
    return m;
  }
}

class TestFiltreNotifier extends StateNotifier<TestFiltreState> {
  TestFiltreNotifier(int? sinif) : super(TestFiltreState(sinif: sinif));

  void sinifDegistir(int? sinif) {
    state = TestFiltreState(sinif: sinif, zorluk: state.zorluk, soruSayisi: state.soruSayisi);
  }

  void dersDegistir(String yeniDers) {
    state = state.copyWith(ders: yeniDers, konu: 'hepsi', altBaslik: 'hepsi');
  }

  void konuDegistir(String yeniKonu) {
    state = state.copyWith(konu: yeniKonu, altBaslik: 'hepsi');
  }

  void altBaslikDegistir(String yeniAltBaslik) {
    state = state.copyWith(altBaslik: yeniAltBaslik);
  }

  void zorlukDegistir(String yeniZorluk) {
    state = state.copyWith(zorluk: yeniZorluk);
  }

  void soruSayisiDegistir(int yeniSayi) {
    state = state.copyWith(soruSayisi: yeniSayi);
  }
}

/// Test filtresi; başlangıçta öğrencinin sınıfına (9-11) göre kurulur.
final testFiltreProvider = StateNotifierProvider<TestFiltreNotifier, TestFiltreState>((ref) {
  return TestFiltreNotifier(ref.read(sinifProvider));
});

/// Denemede ders başına soru sayısı (genel deneme).
const Map<String, int> denemeDersSoruSayisi = {
  'Türk Dili ve Edebiyatı': 10,
  'Türkçe': 10,
  'Matematik': 10,
  'Geometri': 4,
  'Fizik': 5,
  'Kimya': 5,
  'Biyoloji': 5,
  'Tarih': 5,
  'Coğrafya': 5,
  'Felsefe': 4,
  'Din Kültürü': 3,
};

/// Soru başına ayrılan süre (saniye).
const int denemeSoruSuresi = 90;

class AktifTestNotifier extends StateNotifier<AktifTestState> {
  final Ref _ref;

  AktifTestNotifier(this._ref) : super(const AktifTestState(sorular: []));

  /// Filtreye uyan sorulardan rastgele bir test hazırlar. Uyan soru yoksa
  /// test boş kalır (çözme ekranı "soru bulunamadı" gösterir).
  void testOlustur(TestFiltreState filtre, {Random? rastgele}) {
    final konu = filtre.sinif != null && filtre.konu != 'hepsi' ? sinifKonusuBul(filtre.konu) : null;
    state = AktifTestState(
      sorular: soruSec(filtre.hazirSorular, filtre.sablonlar, filtre.soruSayisi, rastgele: rastgele),
      baslik: konu?.baslik ??
          (filtre.konu != 'hepsi'
              ? filtre.konu
              : filtre.ders != 'hepsi'
                  ? '${filtre.ders} testi'
                  : 'Karışık test'),
      sinif: filtre.sinif,
    );
  }

  /// Sınıf müfredatındaki tek bir konudan test hazırlar.
  void konuTestiOlustur(String konuId, {int adet = 10, Random? rastgele}) {
    final konu = sinifKonusuBul(konuId);
    if (konu == null) return;
    testOlustur(TestFiltreState(sinif: konu.sinif, ders: konu.ders, konu: konuId, soruSayisi: adet), rastgele: rastgele);
  }

  /// Süreli deneme hazırlar. [sinif] verilirse o sınıfın müfredatından,
  /// verilmezse tüm havuzdan (YKS) seçilir. [ders] verilirse tek derslik
  /// deneme olur. [kisa] soru sayılarını yarıya indirir.
  void denemeOlustur({int? sinif, String? ders, bool kisa = false, Random? rastgele}) {
    final r = rastgele ?? Random();
    final dersler = ders != null
        ? [ders]
        : sinif != null
            ? sinifDersleri(sinif)
            : dersKonuAltBaslikHaritasi.keys.toList();
    final sorular = <Soru>[];
    for (final d in dersler) {
      final taban = ders != null ? 20 : (denemeDersSoruSayisi[d] ?? 5);
      final adet = kisa ? max(2, (taban / 2).round()) : taban;
      final hazir = sinif != null ? sinifHazirSorulari(sinif, ders: d) : filtreliSorular(ders: d);
      final sablon = sinif != null ? sinifSablonlari(sinif, ders: d) : filtreliSablonlar(ders: d);
      sorular.addAll(soruSec(hazir, sablon, adet, rastgele: r));
    }
    state = AktifTestState(
      sorular: sorular,
      tur: TestTuru.deneme,
      baslik: [
        if (sinif != null) '$sinif. Sınıf',
        ?ders,
        kisa ? 'Kısa Deneme' : (ders != null ? 'Denemesi' : 'Genel Deneme'),
      ].join(' '),
      sinif: sinif,
      sureSiniri: sorular.length * denemeSoruSuresi,
    );
  }

  /// Daha önce yanlış yapılan sorulardan tekrar testi hazırlar.
  void tekrarTestiOlustur({int adet = 20, int? sinif, Random? rastgele}) {
    final r = rastgele ?? Random();
    final sorular = yanlisSoruListesi(_ref.read(yanlisSorularProvider), sinif: sinif);
    state = AktifTestState(
      sorular: sorular.take(adet).toList()..shuffle(r),
      tur: TestTuru.tekrar,
      baslik: 'Yanlışlarımın Tekrarı',
      sinif: sinif,
    );
  }

  void secenekIsaretle(int soruIndex, String secenek) {
    if (state.tamamlandi) return;
    final yeniCevaplar = Map<int, String>.from(state.cevaplar);
    if (yeniCevaplar[soruIndex] == secenek) {
      yeniCevaplar.remove(soruIndex); // Aynı şıkka basılırsa seçimi kaldır
    } else {
      yeniCevaplar[soruIndex] = secenek;
    }
    state = state.copyWith(cevaplar: yeniCevaplar);
  }

  void saniyeArtir() {
    if (!state.tamamlandi) {
      state = state.copyWith(gecenSaniye: state.gecenSaniye + 1);
    }
  }

  void testiBitir() {
    state = state.copyWith(tamamlandi: true);
  }

  /// Testi bitirir ve sonucu kaydeder: analiz geçmişi, yanlış soru listesi,
  /// (denemeyse) deneme geçmişi ve "Yanlışlarım" kart destesi. "Yanlışlarım"
  /// destesine eklenen kart sayısını döner.
  Future<int> bitirVeKaydet() async {
    if (state.tamamlandi || state.sorular.isEmpty) return 0;
    testiBitir();
    final test = state;
    final storage = _ref.read(storageServiceProvider);
    await testGecmisineEkle(storage, test);
    await _ref.read(yanlisSorularProvider.notifier).testSonucunuIsle(test);
    if (test.tur == TestTuru.deneme) {
      await denemeGecmisineEkle(storage, test);
      _ref.invalidate(denemeGecmisiProvider);
    }
    final yanlislar = [
      for (var i = 0; i < test.sorular.length; i++)
        if (test.cevaplar.containsKey(i) && test.cevaplar[i] != test.sorular[i].dogruSecenek) test.sorular[i],
    ];
    return _ref.read(flashkartProvider.notifier).yanlislardanKartEkle(yanlislar);
  }
}

final aktifTestProvider = StateNotifierProvider<AktifTestNotifier, AktifTestState>((ref) {
  return AktifTestNotifier(ref);
});

// ─── Yanlış yapılan sorular (tekrar sistemi) ────────────────────────────

/// Yanlış yapılan soruları, en çok yanlış yapılan önce gelecek şekilde
/// döndürür. [sinif] verilirse yalnızca o sınıfın konularındaki sorular.
List<Soru> yanlisSoruListesi(Map<String, int> yanlislar, {int? sinif}) {
  final izinli = sinif == null ? null : {for (final s in sinifHazirSorulari(sinif)) s.id};
  final adaylar = <(Soru, int)>[];
  for (final e in yanlislar.entries) {
    final s = soruBul(e.key);
    if (s != null && (izinli == null || izinli.contains(s.id))) adaylar.add((s, e.value));
  }
  adaylar.sort((a, b) => b.$2.compareTo(a.$2));
  return [for (final a in adaylar) a.$1];
}

/// Yanlış yapılan hazır sorular: { soruId: yanlış sayısı }. Üretilmiş sorular
/// (her seferinde farklı sayılarla geldiği için) burada tutulmaz; onlar
/// "Yanlışlarım" kart destesine eklenir.
class YanlisSorularNotifier extends StateNotifier<Map<String, int>> {
  final StorageService _storage;
  late final Future<void> hazir;

  YanlisSorularNotifier(this._storage) : super(const {}) {
    hazir = _yukle();
  }

  Future<void> _yukle() async {
    try {
      final m = await _storage.getMap(AnalizKayitlari.testYanlislar) ?? {};
      if (!mounted) return;
      state = {
        for (final e in m.entries)
          if (e.value is num && soruBul(e.key) != null) e.key: (e.value as num).toInt(),
      };
    } catch (_) {}
  }

  /// Yanlış cevaplanan sorular listeye eklenir (sayacı artar), doğru
  /// cevaplananlar listeden çıkar. Boş bırakılanlar değişmez.
  Future<void> testSonucunuIsle(AktifTestState test) async {
    await hazir;
    final yeni = {...state};
    for (var i = 0; i < test.sorular.length; i++) {
      final s = test.sorular[i];
      final c = test.cevaplar[i];
      if (c == null || uretilmisSoruMu(s)) continue;
      if (c == s.dogruSecenek) {
        yeni.remove(s.id);
      } else {
        yeni[s.id] = (yeni[s.id] ?? 0) + 1;
      }
    }
    if (mounted) state = yeni;
    await _storage.setMap(AnalizKayitlari.testYanlislar, yeni);
  }

  Future<void> temizle() async {
    state = const {};
    await _storage.setMap(AnalizKayitlari.testYanlislar, const {});
  }
}

final yanlisSorularProvider = StateNotifierProvider<YanlisSorularNotifier, Map<String, int>>((ref) {
  return YanlisSorularNotifier(ref.watch(storageServiceProvider));
});

// ─── Geçmiş kayıtları ───────────────────────────────────────────────────

/// Uygulama içinde çözülen bir denemenin özeti.
class DenemeKaydi {
  final String tarih;
  final String baslik;
  final int? sinif;
  final int dogru;
  final int yanlis;
  final int bos;
  final int saniye;

  const DenemeKaydi({
    required this.tarih,
    required this.baslik,
    this.sinif,
    required this.dogru,
    required this.yanlis,
    required this.bos,
    this.saniye = 0,
  });

  int get toplam => dogru + yanlis + bos;
  double get net => dogru - yanlis * 0.25;
  double get basari => toplam == 0 ? 0 : dogru / toplam;

  Map<String, dynamic> toJson() => {'t': tarih, 'b': baslik, 's': sinif, 'd': dogru, 'y': yanlis, 'bos': bos, 'sn': saniye};

  factory DenemeKaydi.fromJson(Map<String, dynamic> j) => DenemeKaydi(
        tarih: j['t'] as String? ?? '',
        baslik: j['b'] as String? ?? 'Deneme',
        sinif: (j['s'] as num?)?.toInt(),
        dogru: ((j['d'] as num?) ?? 0).toInt(),
        yanlis: ((j['y'] as num?) ?? 0).toInt(),
        bos: ((j['bos'] as num?) ?? 0).toInt(),
        saniye: ((j['sn'] as num?) ?? 0).toInt(),
      );
}

Future<void> denemeGecmisineEkle(StorageService storage, AktifTestState test) async {
  final map = await storage.getMap(AnalizKayitlari.denemeGecmisi) ?? {};
  final items = List<dynamic>.from((map['items'] as List?) ?? const []);
  items.add(DenemeKaydi(
    tarih: gunAnahtari(DateTime.now()),
    baslik: test.baslik,
    sinif: test.sinif,
    dogru: test.dogruSayisi,
    yanlis: test.yanlisSayisi,
    bos: test.bosSayisi,
    saniye: test.gecenSaniye,
  ).toJson());
  if (items.length > 60) items.removeRange(0, items.length - 60);
  await storage.setMap(AnalizKayitlari.denemeGecmisi, {'items': items});
}

/// Uygulama içi denemeler (eskiden yeniye).
final denemeGecmisiProvider = FutureProvider<List<DenemeKaydi>>((ref) async {
  final map = await ref.watch(storageServiceProvider).getMap(AnalizKayitlari.denemeGecmisi);
  return [
    for (final e in (map?['items'] as List?) ?? const [])
      if (e is Map) DenemeKaydi.fromJson(Map<String, dynamic>.from(e)),
  ];
});

/// Biten bir testin sonucunu ders bazında analiz geçmişine ekler
/// (Gelişim Analizi › Test performansı). Son 500 kayıt tutulur.
Future<void> testGecmisineEkle(StorageService storage, AktifTestState test) async {
  if (test.sorular.isEmpty) return;
  final bugun = gunAnahtari(DateTime.now());
  final dersler = test.dersSonuclari;
  final map = await storage.getMap(AnalizKayitlari.testGecmisi) ?? {};
  final items = List<dynamic>.from((map['items'] as List?) ?? const []);
  final saniyePay = test.gecenSaniye ~/ dersler.length;
  for (final e in dersler.entries) {
    items.add(TestKaydi(
      tarih: bugun,
      ders: e.key,
      dogru: e.value[0],
      yanlis: e.value[1],
      bos: e.value[2],
      saniye: saniyePay,
    ).toJson());
  }
  if (items.length > 500) items.removeRange(0, items.length - 500);
  await storage.setMap(AnalizKayitlari.testGecmisi, {'items': items});
}
