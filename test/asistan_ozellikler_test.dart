import 'package:flutter_test/flutter_test.dart';
import 'package:yks_kocu/core/algorithms/analiz_motoru.dart';
import 'package:yks_kocu/core/algorithms/asistan_motoru.dart';
import 'package:yks_kocu/core/constants/app_constants.dart';
import 'package:yks_kocu/core/constants/yks_data.dart';
import 'package:yks_kocu/data/models/net_kaydi.dart';
import 'package:yks_kocu/data/models/ogrenci_profil.dart';

void main() {
  test('Mesajlar doğru uygulama özelliğine yönlendirilir', () {
    const beklenen = {
      'Matematikten test çözmek istiyorum': AsistanNiyet.testCoz,
      'Kartlarımı tekrar edeyim': AsistanNiyet.kartTekrar,
      'Yanlışlarım destesinde ne var?': AsistanNiyet.kartTekrar,
      'Odak seansı başlat': AsistanNiyet.odakBaslat,
      'Yağmur sesi açar mısın': AsistanNiyet.arkaPlanSesi,
      'Bahçem nasıl, bitkilerim büyüdü mü?': AsistanNiyet.bahce,
      'Biraz mola vermek istiyorum': AsistanNiyet.mola,
      'Etüt odamda kaçıncıyım?': AsistanNiyet.etutOdasi,
      'Hedefim 90 net, yetişir mi?': AsistanNiyet.hedefNet,
      'Deneme ekle': AsistanNiyet.denemeEkle,
      'Son denememi analiz et': AsistanNiyet.denemeAnalizi,
      'Hangi konular kaldı?': AsistanNiyet.konuDurumu,
      'Zayıf derslerim neler?': AsistanNiyet.zayifDersler,
      'Programımı iyileştir': AsistanNiyet.programIyilestir,
      'Bugün ne çalışayım, programım?': AsistanNiyet.programIncele,
      'Çok stresliyim': AsistanNiyet.motivasyon,
    };
    for (final e in beklenen.entries) {
      expect(niyetBul(e.key), e.value, reason: e.key);
    }
  });

  test('Hedef net tahmini mesajdaki hedefi kullanır', () {
    final bugun = DateTime.now();
    final netler = [
      for (var i = 0; i < 5; i++)
        NetKaydi(
          id: 'n$i',
          tarih: bugun.subtract(Duration(days: 25 - i * 5)).toIso8601String().split('T')[0],
          alan: SinavAlani.TYT,
          ders: 'Türkçe',
          dogru: 60 + i * 2,
          denemeAdi: 'D$i',
          createdAt: bugun.subtract(Duration(days: 25 - i * 5)),
        ),
    ];
    expect(mesajdakiHedefNet('Hedefim 90 net'), 90);
    final y = hedefNetYaniti(netler: netler, mesaj: 'Hedefim 90 net, yetişir mi?', kalanGun: 70);
    expect(y.metin, contains('90'));
    expect(y.maddeler.join(' '), contains('70 gün'));
  });

  test('Test önerisi zayıf dersten başlatma düğmesi verir', () {
    final y = testOnerisiYaniti(
      zayifSira: ['Fizik', 'Matematik'],
      havuzSayilari: {'Fizik': 22, 'Matematik': 34, 'Türkçe': 20},
      testler: const [TestKaydi(tarih: '2099-01-01', ders: 'Türkçe', dogru: 2, yanlis: 6, bos: 2)],
      mesaj: 'test çözmek istiyorum',
    );
    final komutlar = y.aksiyonlar.where((a) => a.komut != null).toList();
    expect(komutlar.first.komut!.tur, AsistanKomutTur.testBaslat);
    expect(komutlar.first.komut!.ders, 'Fizik');
    final istenen = testOnerisiYaniti(zayifSira: ['Fizik'], havuzSayilari: {'Fizik': 22, 'Türkçe': 20}, testler: const [], mesaj: 'türkçe testi');
    expect(istenen.aksiyonlar.first.komut!.ders, 'Türkçe');
  });

  test('Kart yanıtı önce Yanlışlarım destesini önerir', () {
    final y = kartTekrarYaniti(
      bekleyen: {'hepsi': 12, 'yanlislar': 3, 'fizik': 5, 'tarih': 4},
      desteAdlari: dersEtiketleri,
      yanlisToplam: 7,
      kalanYeniKart: 10,
    );
    expect(y.metin, contains('12'));
    expect(y.aksiyonlar.first.komut!.deste, 'yanlislar');
    expect(y.maddeler.join(' '), contains('Fizik: 5'));
  });

  test('Konu durumu en geride kalan dersi ve odak düğmesini verir', () {
    const profil = OgrenciProfil(hedefBolum: 'sayisal', onboardingTamamlandi: true);
    final y = konuDurumuYaniti(konular: tumKonular, profil: profil);
    expect(y.maddeler, isNotEmpty);
    expect(y.aksiyonlar.any((a) => a.komut?.tur == AsistanKomutTur.odakBaslat), isTrue);
  });
}
