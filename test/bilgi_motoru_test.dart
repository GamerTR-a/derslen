import 'package:flutter_test/flutter_test.dart';
import 'package:yks_kocu/core/algorithms/asistan_motoru.dart';
import 'package:yks_kocu/core/algorithms/bilgi_motoru.dart';
import 'package:yks_kocu/core/constants/yks_rehber.dart';

void main() {
  test('Arama metni Türkçe harfleri ve büyük harfi sadeleştirir', () {
    expect(aramaMetni('Türev NEDİR?'), 'turev nedir');
    expect(aramaMetni('IŞIK, ağaç; öğüt'), 'isik agac ogut');
  });

  group('Ders soruları kartlardan yanıtlanır', () {
    const beklenen = {
      'Mitoz bölünme nedir?': 'Mitoz',
      'mitoz nedir': 'Mitoz',
      'MITOKONDRI ne işe yarar': 'Mitokondri',
      'Tanzimat Fermanı ne zaman ilan edildi': 'Tanzimat Fermanı',
      'ohm yasası formülü': 'Ohm',
      'diskriminant nedir': 'Diskriminant',
      'Namık Kemal kimdir': 'Namık Kemal',
      'iyonik bağ nedir açıklar mısın': 'İyonik Bağ',
      'kalan teoremi': 'Kalan teoremi',
      'lozan antlaşması': 'Lozan',
    };
    for (final e in beklenen.entries) {
      test(e.key, () {
        final s = bilgiAra(e.key);
        expect(s.yeterli, isTrue, reason: 'kapsama ${s.kapsama}');
        expect(s.enIyi!.baslik, contains(e.value));
        expect(niyetBul(e.key), AsistanNiyet.dersSorusu);
      });
    }
  });

  group('Sınav ve çalışma soruları rehberden yanıtlanır', () {
    const beklenen = {
      'TYT kaç soru?': 'tyt-yapi',
      'AYT kaç dakika sürüyor': 'ayt-yapi',
      'net nasıl hesaplanır': 'net-hesabi',
      'YKS puanı nasıl hesaplanır': 'puan-hesabi',
      'obp nedir': 'puan-hesabi',
      'baraj puanı var mı': 'baraj',
      'pomodoro tekniği nedir': 'pomodoro',
      'paragrafta nasıl hızlanırım': 'paragraf',
      'matematik nasıl çalışılır': 'matematik-calisma',
      'turlama tekniği nedir': 'turlama',
      'günde kaç saat çalışmalıyım': 'gunluk-calisma',
      'deneme analizi nasıl yapılır': 'deneme-analizi',
    };
    for (final e in beklenen.entries) {
      test(e.key, () {
        final s = bilgiAra(e.key);
        expect(s.enIyi?.id, e.value, reason: 'kapsama ${s.kapsama}');
        expect(s.yeterli, isTrue);
        expect(niyetBul(e.key), AsistanNiyet.dersSorusu, reason: e.key);
      });
    }
  });

  test('Notlarda olmayan soru uydurulmaz', () {
    for (final m in ['kuantum dolanıklık nedir', 'merhaba', 'bugün hava nasıl', 'en iyi telefon hangisi']) {
      expect(bilgiAra(m).yeterli, isFalse, reason: m);
    }
    final y = bilgiYaniti(mesaj: 'kuantum dolanıklık nedir', sonuc: bilgiAra('kuantum dolanıklık nedir'));
    expect(y.metin, contains('bulamadım'));
  });

  test('Uygulama komutları bilgi sorusuna dönüşmez', () {
    const beklenen = {
      'Yağmur sesi açar mısın': AsistanNiyet.arkaPlanSesi,
      'Bahçem nasıl, bitkilerim büyüdü mü?': AsistanNiyet.bahce,
      'Hangi konular kaldı?': AsistanNiyet.konuDurumu,
      'Fizikten test çözmek istiyorum': AsistanNiyet.testCoz,
      'Hedefim 90 net, yetişir mi?': AsistanNiyet.hedefNet,
      'Son denememi analiz et': AsistanNiyet.denemeAnalizi,
      'Çok stresliyim, sınav kaygısı nedir': AsistanNiyet.motivasyon,
      'merhaba': AsistanNiyet.yardim,
    };
    for (final e in beklenen.entries) {
      expect(niyetBul(e.key), e.value, reason: e.key);
    }
  });

  test('Bilgi yanıtı kart içeriğini ve ilgili düğmeleri verir', () {
    const soru = 'Mitoz bölünme nedir?';
    final y = bilgiYaniti(mesaj: soru, sonuc: bilgiAra(soru), havuzDersleri: {'Biyoloji'}, bulutAcik: true);
    expect(y.metin, contains('Biyoloji'));
    expect(y.maddeler.join(' '), contains('yavru hücre'));
    expect(y.aksiyonlar.any((a) => a.komut?.tur == AsistanKomutTur.desteAc && a.komut?.deste == 'biyoloji'), isTrue);
    expect(y.aksiyonlar.any((a) => a.komut?.tur == AsistanKomutTur.testBaslat && a.komut?.ders == 'Biyoloji'), isTrue);
    expect(y.aksiyonlar.last.bulutSorusu, soru);
    final bulutsuz = bilgiYaniti(mesaj: soru, sonuc: bilgiAra(soru));
    expect(bulutsuz.aksiyonlar.any((a) => a.bulutSorusu != null), isFalse);
  });

  test('Net hesabı', () {
    expect(mesajdakiDogruYanlis('40 doğru 12 yanlış kaç net eder'), (40, 12));
    expect(mesajdakiDogruYanlis('30d 6y'), (30, 6));
    expect(mesajdakiDogruYanlis('25 doğru kaç net'), (25, 0));
    expect(mesajdakiDogruYanlis('Hedefim 90 net'), isNull);
    expect(mesajdakiDogruYanlis('40 dakika çalıştım'), isNull);
    expect(niyetBul('40 doğru 12 yanlış kaç net'), AsistanNiyet.netHesapla);
    expect(netHesabiYaniti(40, 12).metin, contains('37 net'));
    expect(netHesabiYaniti(28, 6).metin, contains('26.50 net'));
  });

  test('Rehber maddeleri tekil ve dolu', () {
    final idler = <String>{};
    for (final r in yksRehberi) {
      expect(idler.add(r.id), isTrue, reason: r.id);
      expect(r.metin.trim(), isNotEmpty);
      expect(r.maddeler, isNotEmpty, reason: r.id);
      expect(aramaMetni(r.anahtarlar), r.anahtarlar, reason: '${r.id} anahtarları sade yazılmalı');
    }
  });
}
