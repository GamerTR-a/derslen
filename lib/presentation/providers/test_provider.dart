import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/algorithms/analiz_motoru.dart' show TestKaydi;
import '../../core/constants/soru_havuzu.dart';
import '../../core/storage/analiz_kayitlari.dart';
import '../../core/storage/storage_service.dart';
import '../../core/utils/tarih.dart';
import '../../data/models/soru.dart';

class TestFiltreState {
  final String ders;
  final String konu;
  final String altBaslik;
  final String zorluk; // 'hepsi', 'kolay', 'orta', 'zor'
  final int soruSayisi; // 5, 10, 15, 20

  const TestFiltreState({
    this.ders = 'hepsi',
    this.konu = 'hepsi',
    this.altBaslik = 'hepsi',
    this.zorluk = 'hepsi',
    this.soruSayisi = 5,
  });

  TestFiltreState copyWith({
    String? ders,
    String? konu,
    String? altBaslik,
    String? zorluk,
    int? soruSayisi,
  }) {
    return TestFiltreState(
      ders: ders ?? this.ders,
      konu: konu ?? this.konu,
      altBaslik: altBaslik ?? this.altBaslik,
      zorluk: zorluk ?? this.zorluk,
      soruSayisi: soruSayisi ?? this.soruSayisi,
    );
  }
}

class AktifTestState {
  final List<Soru> sorular;
  final Map<int, String> cevaplar; // soruIndex -> 'A'/'B'/'C'/'D'/'E'
  final int gecenSaniye;
  final bool tamamlandi;

  const AktifTestState({
    required this.sorular,
    this.cevaplar = const {},
    this.gecenSaniye = 0,
    this.tamamlandi = false,
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
    );
  }

  int get dogruSayisi {
    var count = 0;
    for (var i = 0; i < sorular.length; i++) {
      if (cevaplar[i] == sorular[i].dogruSecenek) {
        count++;
      }
    }
    return count;
  }

  int get yanlisSayisi {
    var count = 0;
    for (var i = 0; i < sorular.length; i++) {
      if (cevaplar.containsKey(i) && cevaplar[i] != sorular[i].dogruSecenek) {
        count++;
      }
    }
    return count;
  }

  int get bosSayisi => sorular.length - cevaplar.length;

  double get net {
    final raw = dogruSayisi - (yanlisSayisi * 0.25);
    return double.parse(raw.toStringAsFixed(2));
  }
}

class TestFiltreNotifier extends StateNotifier<TestFiltreState> {
  TestFiltreNotifier() : super(const TestFiltreState());

  void dersDegistir(String yeniDers) {
    state = state.copyWith(
      ders: yeniDers,
      konu: 'hepsi',
      altBaslik: 'hepsi',
    );
  }

  void konuDegistir(String yeniKonu) {
    state = state.copyWith(
      konu: yeniKonu,
      altBaslik: 'hepsi',
    );
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

final testFiltreProvider =
    StateNotifierProvider<TestFiltreNotifier, TestFiltreState>((ref) {
  return TestFiltreNotifier();
});

class AktifTestNotifier extends StateNotifier<AktifTestState> {
  AktifTestNotifier() : super(const AktifTestState(sorular: []));

  /// Filtreye uyan sorulardan rastgele bir test hazırlar. Uyan soru yoksa
  /// test boş kalır (çözme ekranı "soru bulunamadı" gösterir).
  void testOlustur(TestFiltreState filtre) {
    final uyanSorular = filtreliSorular(
      ders: filtre.ders,
      konu: filtre.konu,
      altBaslik: filtre.altBaslik,
      zorluk: filtre.zorluk,
    )..shuffle();

    state = AktifTestState(
      sorular: uyanSorular.take(filtre.soruSayisi).toList(),
      cevaplar: {},
      gecenSaniye: 0,
      tamamlandi: false,
    );
  }

  void secenekIsaretle(int soruIndex, String secenek) {
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
}

final aktifTestProvider =
    StateNotifierProvider<AktifTestNotifier, AktifTestState>((ref) {
  return AktifTestNotifier();
});

/// Biten bir testin sonucunu ders bazında analiz geçmişine ekler
/// (Gelişim Analizi › Test performansı). Son 500 kayıt tutulur.
Future<void> testGecmisineEkle(StorageService storage, AktifTestState test) async {
  if (test.sorular.isEmpty) return;
  final bugun = gunAnahtari(DateTime.now());
  final dersler = <String, List<int>>{};
  for (var i = 0; i < test.sorular.length; i++) {
    final soru = test.sorular[i];
    final m = dersler.putIfAbsent(dersAdiNormalize(soru.ders), () => [0, 0, 0]);
    final cevap = test.cevaplar[i];
    if (cevap == null) {
      m[2]++;
    } else if (cevap == soru.dogruSecenek) {
      m[0]++;
    } else {
      m[1]++;
    }
  }
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
