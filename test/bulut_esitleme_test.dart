import 'package:flutter_test/flutter_test.dart';
import 'package:yks_kocu/core/services/surum_kontrol.dart';
import 'package:yks_kocu/core/storage/storage_service.dart';
import 'package:yks_kocu/core/storage/synced_storage_service.dart';

class _SahteBulut implements BulutDepo {
  final Map<String, BulutKayit> satirlar = {};
  bool cevrimdisi = false;
  int yazmaSayisi = 0;
  DateTime saat = DateTime.utc(2026, 10, 1, 12);

  /// Başka bir cihazın yazması.
  void digerCihazYazdi(String anahtar, Map<String, dynamic> deger) {
    saat = saat.add(const Duration(minutes: 1));
    satirlar[anahtar] = BulutKayit(anahtar, deger, saat);
  }

  void _kontrol() {
    if (cevrimdisi) throw Exception('ağ yok');
  }

  @override
  Future<List<BulutKayit>> hepsi(String userId) async {
    _kontrol();
    return satirlar.values.toList();
  }

  @override
  Future<BulutKayit?> getir(String userId, String anahtar) async {
    _kontrol();
    return satirlar[anahtar];
  }

  @override
  Future<DateTime?> yaz(String userId, String anahtar, Map<String, dynamic> deger) async {
    _kontrol();
    yazmaSayisi++;
    saat = saat.add(const Duration(minutes: 1));
    satirlar[anahtar] = BulutKayit(anahtar, Map<String, dynamic>.from(deger), saat);
    return saat;
  }

  @override
  Future<void> sil(String userId, String anahtar) async {
    _kontrol();
    satirlar.remove(anahtar);
  }
}

void main() {
  late _SahteBulut bulut;
  late SharedPrefsStorageService yerel;
  late SyncedStorageService depo;

  setUp(() {
    bulut = _SahteBulut();
    yerel = SharedPrefsStorageService(); // init edilmeden bellek içi çalışır
    depo = SyncedStorageService(local: yerel, userId: 'u1', bulut: bulut);
  });

  test('Yazma buluta gider; eşitleme değişiklik yoksa yereli değiştirmez', () async {
    await depo.setMap('netler', {'a': 1});
    expect(bulut.satirlar['netler']!.deger, {'a': 1});
    expect(await depo.bulutlaEsitle(), isFalse);
    expect(bulut.yazmaSayisi, 1);
  });

  test('Başka cihazın daha yeni yazması eşitlemede yerele alınır', () async {
    await depo.setMap('netler', {'a': 1});
    bulut.digerCihazYazdi('netler', {'a': 2});

    expect(await depo.bulutlaEsitle(), isTrue);
    expect(await depo.getMap('netler'), {'a': 2});
    // Alınan veri buluta geri yazılmaz.
    expect(bulut.yazmaSayisi, 1);
  });

  test('Çevrimdışı yazma kaybolmaz: bağlantı gelince gönderilir ve bulutu ezmez', () async {
    await depo.setMap('plan', {'gun': 1});
    bulut.cevrimdisi = true;
    await depo.setMap('plan', {'gun': 2});
    expect(bulut.satirlar['plan']!.deger, {'gun': 1});

    bulut.cevrimdisi = false;
    expect(await depo.bulutlaEsitle(), isFalse);
    expect(bulut.satirlar['plan']!.deger, {'gun': 2});
    expect(await depo.getMap('plan'), {'gun': 2});
  });

  test('Gönderilmemiş yerel değişiklik varken bulut daha yeni olsa da yerel korunur', () async {
    await depo.setMap('plan', {'gun': 1});
    bulut.cevrimdisi = true;
    await depo.setMap('plan', {'gun': 5});
    bulut.cevrimdisi = false;
    bulut.digerCihazYazdi('plan', {'gun': 3});

    await depo.bulutlaEsitle();
    expect(await depo.getMap('plan'), {'gun': 5});
    expect(bulut.satirlar['plan']!.deger, {'gun': 5});
  });

  test('Yerelde olmayan anahtarlar buluttan doldurulur', () async {
    bulut.digerCihazYazdi('kartlar', {'k': [1, 2]});
    expect(await depo.bulutlaEsitle(), isTrue);
    expect(await depo.getMap('kartlar'), {'k': [1, 2]});
  });

  test('Zaman damgasız eski yerel kopya farklıysa korunur ve buluta gönderilir', () async {
    // Önceki uygulama sürümü: yalnızca veri yazılı, damga yok.
    await yerel.setMap('sd_u1_konular', {'x': 1});
    bulut.digerCihazYazdi('konular', {'x': 0});

    expect(await depo.bulutlaEsitle(), isFalse);
    expect(await depo.getMap('konular'), {'x': 1});
    expect(bulut.satirlar['konular']!.deger, {'x': 1});

    // Artık damgalı: sonraki uzak yazma alınır.
    bulut.digerCihazYazdi('konular', {'x': 9});
    expect(await depo.bulutlaEsitle(), isTrue);
    expect(await depo.getMap('konular'), {'x': 9});
  });

  test('Zaman damgasız kopya bulutla aynıysa gereksiz yazma yapılmaz', () async {
    await yerel.setMap('sd_u1_konular', {'b': 2, 'a': 1.0});
    bulut.digerCihazYazdi('konular', {'a': 1, 'b': 2});
    expect(await depo.bulutlaEsitle(), isFalse);
    expect(bulut.yazmaSayisi, 0);
  });

  test('Bulut erişilemezken eşitleme sessizce başarısız olur', () async {
    await depo.setMap('netler', {'a': 1});
    bulut.cevrimdisi = true;
    expect(await depo.bulutlaEsitle(), isFalse);
    expect(await depo.getMap('netler'), {'a': 1});
  });

  group('surumDegerlendir', () {
    test('yapılandırma yoksa ya da derleme yeterliyse uygun', () {
      expect(surumDegerlendir(kuruluDerleme: 5, yapilandirma: null).durum, SurumDurumu.uygun);
      expect(surumDegerlendir(kuruluDerleme: 5, yapilandirma: {'min_build': 5, 'bakim': false}).durum, SurumDurumu.uygun);
    });

    test('eski derleme güncellemeye zorlanır', () {
      final b = surumDegerlendir(kuruluDerleme: 4, yapilandirma: {'min_build': 5, 'bakim': false, 'mesaj': ' Güncelle '});
      expect(b.durum, SurumDurumu.guncellemeGerekli);
      expect(b.mesaj, 'Güncelle');
    });

    test('bakım modu sürümden bağımsız engeller; okunamayan derleme numarası engellemez', () {
      expect(surumDegerlendir(kuruluDerleme: 99, yapilandirma: {'min_build': 1, 'bakim': true}).durum, SurumDurumu.bakim);
      expect(surumDegerlendir(kuruluDerleme: 0, yapilandirma: {'min_build': 5, 'bakim': false}).durum, SurumDurumu.uygun);
    });
  });
}
