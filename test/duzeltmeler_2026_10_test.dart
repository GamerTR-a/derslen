// 2026-10 düzeltme paketi: odak sayacının kalıcılığı, sınıf müfredatı,
// konu testi / deneme / yanlış tekrarı ve kişisel ders programı.
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yks_kocu/core/algorithms/ders_programi.dart';
import 'package:yks_kocu/core/algorithms/soru_uretici.dart';
import 'package:yks_kocu/core/constants/app_constants.dart';
import 'package:yks_kocu/core/constants/sinif_mufredati.dart';
import 'package:yks_kocu/core/constants/soru_havuzu.dart';
import 'package:yks_kocu/core/storage/storage_service.dart';
import 'package:yks_kocu/core/utils/tarih.dart';
import 'package:yks_kocu/data/models/ogrenci_profil.dart';
import 'package:yks_kocu/data/models/plan_blok.dart';
import 'package:yks_kocu/presentation/providers/flashkart_provider.dart';
import 'package:yks_kocu/presentation/providers/konu_provider.dart';
import 'package:yks_kocu/presentation/providers/mufredat_provider.dart';
import 'package:yks_kocu/presentation/providers/odak_provider.dart';
import 'package:yks_kocu/presentation/providers/plan_provider.dart';
import 'package:yks_kocu/presentation/providers/profil_provider.dart';
import 'package:yks_kocu/presentation/providers/test_provider.dart';

Future<(ProviderContainer, SharedPrefsStorageService)> _kapsayici({String? sinif, SharedPrefsStorageService? depo}) async {
  final d = depo ?? SharedPrefsStorageService();
  if (depo == null) {
    SharedPreferences.setMockInitialValues({});
    await d.init();
  }
  final c = ProviderContainer(overrides: [
    storageServiceProvider.overrideWithValue(d),
    localStorageServiceProvider.overrideWithValue(d),
  ]);
  await c.read(profilProvider.notifier).kaydetProfil(
        hedefBolum: 'sayisal',
        gunlukSaat: 3,
        ogrenmeMetod: OgrenmeMetod.dengeli,
        sinifSeviyesi: sinif,
      );
  await c.read(konuProvider.notifier).hazir;
  return (c, d);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Odak sayacı kapanınca kaybolmaz', () {
    test('çalışan seans cihaza yazılır ve yeniden açılışta kaldığı yerden sürer', () async {
      final (c1, depo) = await _kapsayici();
      final n1 = c1.read(odakProvider.notifier);
      await n1.hazir;
      n1.sureSec(50);
      n1.dersSec('Fizik');
      await n1.baslat();
      expect(c1.read(odakProvider).asama, OdakAsama.calisiyor);
      final kayit = await depo.getMap(odakSeansAnahtari);
      expect(kayit?['asama'], 'calisiyor');
      expect(kayit?['sureDk'], 50);
      c1.dispose(); // uygulama kapandı

      // 12 dakika önce başlamış gibi düzenle ve "yeniden aç".
      await depo.setMap(odakSeansAnahtari, {
        ...kayit!,
        'bas': DateTime.now().subtract(const Duration(minutes: 12)).toIso8601String(),
      });
      final (c2, _) = await _kapsayici(depo: depo);
      await c2.read(odakProvider.notifier).hazir;
      final s = c2.read(odakProvider);
      expect(s.asama, OdakAsama.calisiyor);
      expect(s.ders, 'Fizik');
      expect(s.sureDk, 50);
      expect(s.gecenDakika, inInclusiveRange(12, 13));
      c2.dispose();
    });

    test('uygulama kapalıyken süresi dolan seans tam süresiyle kaydedilir', () async {
      final (c0, depo) = await _kapsayici();
      c0.dispose();
      await depo.setMap(odakSeansAnahtari, {
        'sureDk': 25,
        'ders': 'Kimya',
        'asama': 'calisiyor',
        'oncesi': 0,
        'bas': DateTime.now().subtract(const Duration(minutes: 40)).toIso8601String(),
      });
      final (c, _) = await _kapsayici(depo: depo);
      await c.read(odakProvider.notifier).hazir;
      final s = c.read(odakProvider);
      expect(s.asama, OdakAsama.tamamlandi);
      expect(s.sonDakika, 25);
      expect(c.read(profilProvider).value?.toplamCalismaDk, 25);
      expect(await depo.getMap(odakSeansAnahtari), isNull);
      c.dispose();
    });

    test('duraklatılan seans duraklatılmış olarak geri gelir; vazgeçilince kayıt silinir', () async {
      final (c0, depo) = await _kapsayici();
      c0.dispose();
      await depo.setMap(odakSeansAnahtari, {'sureDk': 25, 'ders': 'Genel', 'asama': 'duraklatildi', 'oncesi': 420, 'bas': null});
      final (c, _) = await _kapsayici(depo: depo);
      final n = c.read(odakProvider.notifier);
      await n.hazir;
      expect(c.read(odakProvider).asama, OdakAsama.duraklatildi);
      expect(c.read(odakProvider).gecenSaniye, 420);
      n.sifirla();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(c.read(odakProvider).aktif, isFalse);
      expect(await depo.getMap(odakSeansAnahtari), isNull);
      c.dispose();
    });

    test('program bloğundan başlatılan seans, süren seans varken ikinci kez başlamaz', () async {
      final (c, _) = await _kapsayici();
      final n = c.read(odakProvider.notifier);
      expect(await n.blokBaslat(blokId: 'b1', blokGun: '2026-10-05', sureDk: 30, ders: 'Tarih', baslik: 'Lale Devri'), isTrue);
      expect(c.read(odakProvider).sureDk, 30);
      expect(c.read(odakProvider).baslik, 'Lale Devri');
      expect(await n.blokBaslat(blokId: 'b2', blokGun: '2026-10-05', sureDk: 20, ders: 'Fizik', baslik: 'Optik'), isFalse);
      expect(c.read(odakProvider).blokId, 'b1');
      n.sifirla();
      c.dispose();
    });
  });

  group('Sınıfa göre müfredat', () {
    test('9. sınıf öğrencisinin konuları Maarif müfredatından, 12. sınıfınki YKS konularından gelir', () async {
      final (c, _) = await _kapsayici(sinif: '9. Sınıf');
      expect(c.read(sinifProvider), 9);
      final konular = c.read(konuProvider);
      expect(konular, isNotEmpty);
      expect(konular.every((k) => k.id.startsWith('s9-')), isTrue);
      expect({for (final k in konular) k.ders}, containsAll(['Matematik', 'Fizik', 'Kimya', 'Biyoloji', 'Tarih', 'Coğrafya']));

      await c
          .read(profilProvider.notifier)
          .kaydetProfil(hedefBolum: 'sayisal', gunlukSaat: 3, ogrenmeMetod: OgrenmeMetod.dengeli, sinifSeviyesi: '12. Sınıf');
      expect(c.read(sinifProvider), isNull);
      expect(c.read(konuProvider).any((k) => k.id.startsWith('tyt-')), isTrue);
      expect(c.read(konuProvider).any((k) => k.id.startsWith('s9-')), isFalse);
      c.dispose();
    });

    test('ara sınıfta Pazar bloğu sınıf denemesidir ve geri sayım kendi YKS yılına göredir', () async {
      const profil = OgrenciProfil(hedefBolum: 'sayisal', gunlukSaat: 3, onboardingTamamlandi: true, sinifSeviyesi: '10. Sınıf');
      final konular = [for (final k in sinifKonulari(10)) k.konu];
      final hafta = haftalikProgramOlustur(
        profil: profil,
        konular: konular,
        ayar: DersProgramiAyar.varsayilan(profil),
        haftaBaslangic: haftaBaslangici(DateTime.now()),
      );
      expect(hafta[6].first.konu, '10. Sınıf Genel Denemesi');
      expect(
        hafta.expand((g) => g).where((b) => b.isCalismaBloku && b.ders != 'Deneme').map((b) => b.ders).toSet(),
        containsAll(['Matematik', 'Fizik', 'Felsefe']),
      );

      final (c, _) = await _kapsayici(sinif: '10. Sınıf');
      final (ad, gun) = c.read(hedefGeriSayimProvider)!;
      expect(ad, 'YKS');
      expect(gun, greaterThan(yksKalanGun() + 700));
      c.dispose();
    });

    test('kartlar öğrencinin sınıfına göre süzülür', () async {
      final (c, _) = await _kapsayici(sinif: '11. Sınıf');
      final s = c.read(flashkartProvider);
      expect(s.sinif, 11);
      final idler = sinifKartIdleri(11);
      expect(idler.length, greaterThan(80));
      expect(s.tumKartlar.every((k) => idler.contains(k.id)), isTrue);
      c.read(flashkartProvider.notifier).sinifSec(null);
      expect(c.read(flashkartProvider).tumKartlar.length, greaterThan(s.tumKartlar.length));
      c.dispose();
    });
  });

  group('Konu testi, deneme ve yanlış tekrarı', () {
    test('konu testi seçilen konunun sorularından oluşur', () async {
      final (c, _) = await _kapsayici(sinif: '9. Sınıf');
      final n = c.read(aktifTestProvider.notifier);
      n.konuTestiOlustur('s9-fiz-10', rastgele: Random(1));
      final test = c.read(aktifTestProvider);
      expect(test.sorular, isNotEmpty);
      expect(test.baslik, 'Bernoulli İlkesi');
      expect(test.sorular.every((s) => s.ders == 'Fizik' && s.konu == 'Bernoulli İlkesi'), isTrue);

      // Sayısal konuda hazır soru az olsa da istenen sayıda soru gelir.
      n.konuTestiOlustur('s9-mat-05', adet: 15, rastgele: Random(2));
      expect(c.read(aktifTestProvider).sorular.length, 15);
      c.dispose();
    });

    test('sınıf denemesi tüm derslerden dengeli ve sürelidir', () async {
      final (c, _) = await _kapsayici(sinif: '10. Sınıf');
      final n = c.read(aktifTestProvider.notifier);
      n.denemeOlustur(sinif: 10, rastgele: Random(3));
      final deneme = c.read(aktifTestProvider);
      expect(deneme.tur, TestTuru.deneme);
      expect(deneme.baslik, '10. Sınıf Genel Deneme');
      expect(deneme.sorular.length, greaterThanOrEqualTo(45));
      expect(deneme.sureSiniri, deneme.sorular.length * denemeSoruSuresi);
      expect(deneme.sorular.map((s) => s.soruMetni).toSet().length, deneme.sorular.length);
      // Her soru 10. sınıf müfredatındaki bir konuya aittir.
      final onuncuSinif = sinifKonulari(10);
      for (final s in deneme.sorular) {
        final uretilen = uretilmisSoruMu(s);
        expect(
          uretilen || onuncuSinif.any((k) => k.soruEslesir(s.ders, s.konu, s.altBaslik)),
          isTrue,
          reason: '${s.id} 10. sınıf konusu değil',
        );
      }

      n.denemeOlustur(sinif: 10, ders: 'Kimya', rastgele: Random(4));
      expect(c.read(aktifTestProvider).sorular.length, 20);
      expect(c.read(aktifTestProvider).sorular.every((s) => s.ders == 'Kimya'), isTrue);
      c.dispose();
    });

    test('yanlış yapılan soru tekrar listesine girer, doğru yapılınca çıkar; deneme geçmişe yazılır', () async {
      final (c, depo) = await _kapsayici(sinif: '9. Sınıf');
      final n = c.read(aktifTestProvider.notifier);
      await c.read(yanlisSorularProvider.notifier).hazir;
      await c.read(flashkartProvider.notifier).loadStates();

      n.testOlustur(const TestFiltreState(sinif: 9, ders: 'Tarih', soruSayisi: 5), rastgele: Random(5));
      var test = c.read(aktifTestProvider);
      expect(test.sorular.length, 5);
      expect(test.sorular.any(uretilmisSoruMu), isFalse);
      // İlk iki soruyu yanlış, üçüncüyü doğru işaretle; kalanlar boş.
      for (var i = 0; i < 2; i++) {
        final dogru = test.sorular[i].dogruSecenek;
        n.secenekIsaretle(i, test.sorular[i].secenekler.keys.firstWhere((k) => k != dogru));
      }
      n.secenekIsaretle(2, test.sorular[2].dogruSecenek);
      final eklenenKart = await n.bitirVeKaydet();
      expect(eklenenKart, 2);
      test = c.read(aktifTestProvider);
      expect(test.tamamlandi, isTrue);
      expect(test.net, 0.5);
      final yanlisIdler = {test.sorular[0].id, test.sorular[1].id};
      expect(c.read(yanlisSorularProvider).keys.toSet(), yanlisIdler);

      // Tekrar testi yalnızca bu sorulardan oluşur; doğru cevaplanan listeden çıkar.
      n.tekrarTestiOlustur(sinif: 9, rastgele: Random(6));
      final tekrar = c.read(aktifTestProvider);
      expect(tekrar.tur, TestTuru.tekrar);
      expect(tekrar.sorular.map((s) => s.id).toSet(), yanlisIdler);
      n.secenekIsaretle(0, tekrar.sorular[0].dogruSecenek);
      await n.bitirVeKaydet();
      expect(c.read(yanlisSorularProvider).keys.toSet(), {tekrar.sorular[1].id});

      // Deneme sonucu deneme geçmişine eklenir.
      n.denemeOlustur(sinif: 9, kisa: true, rastgele: Random(7));
      n.secenekIsaretle(0, c.read(aktifTestProvider).sorular[0].dogruSecenek);
      await n.bitirVeKaydet();
      final gecmis = await c.read(denemeGecmisiProvider.future);
      expect(gecmis.length, 1);
      expect(gecmis.single.sinif, 9);
      expect(gecmis.single.dogru, 1);
      expect((await depo.getMap('test_gecmisi'))?['items'], isNotEmpty);
      c.dispose();
    });

    test('tüm havuz filtresinde sayısal konuya şablon soruları eklenir', () {
      const filtre = TestFiltreState(ders: 'Kimya', konu: 'Mol Kavramı', soruSayisi: 20);
      final secki = soruSec(filtre.hazirSorular, filtre.sablonlar, 20, rastgele: Random(8));
      expect(secki.length, 20);
      expect(secki.every((s) => s.ders == 'Kimya' && s.konu == 'Mol Kavramı'), isTrue);
      expect(secki.where(uretilmisSoruMu), isNotEmpty);
    });
  });

  group('Kişisel ders programı', () {
    const profil = OgrenciProfil(hedefBolum: 'sayisal', gunlukSaat: 3, onboardingTamamlandi: true, sinifSeviyesi: '9. Sınıf');

    test('program yalnızca öğrencinin seçtiği konulardan kurulur', () {
      final konular = [for (final k in sinifKonulari(9)) k.konu];
      const secim = ['s9-mat-05', 's9-mat-06', 's9-fiz-07', 's9-kim-05'];
      final ayar = DersProgramiAyar.varsayilan(profil).copyWith(seciliKonuIdleri: secim, pazarDeneme: false);
      expect(programKonulari('sayisal', konular, ayar).map((k) => k.id).toList(), secim);

      final hafta = haftalikProgramOlustur(profil: profil, konular: konular, ayar: ayar, haftaBaslangic: haftaBaslangici(DateTime.now()));
      final bloklar = hafta.expand((g) => g).where((b) => b.isCalismaBloku).toList();
      expect(bloklar, isNotEmpty);
      expect(bloklar.map((b) => b.ders).toSet(), {'Matematik', 'Fizik', 'Kimya'});
      final izinli = {for (final id in secim) sinifKonusuBul(id)!.baslik};
      expect(bloklar.every((b) => izinli.contains(b.konu)), isTrue);

      // Ayar JSON gidiş-dönüşünde seçim ve sabitleme korunur.
      final geri = DersProgramiAyar.fromJson(ayar.copyWith(sabitle: true).toJson(), profil);
      expect(geri.seciliKonuIdleri, secim);
      expect(geri.sabitle, isTrue);
    });

    test('elle blok eklenir, düzenlenir, kopyalanır ve silinir', () async {
      final (c, _) = await _kapsayici(sinif: '9. Sınıf');
      final n = c.read(programProvider.notifier);
      await n.hazirla();
      expect(c.read(programProvider).yuklendi, isTrue);
      const gun = 6; // Pazar her zaman bugün ya da ileridedir.
      await n.gunuTemizle(gun);
      expect(c.read(programProvider).hafta[gun], isEmpty);

      await n.blokEkle(gun, ders: 'Fizik', konu: 'Vektörler', sureDk: 40, baslangicDk: 18 * 60);
      await n.blokEkle(gun, ders: 'Kimya', konu: 'Lewis Yapısı ve Molekül Polarlığı', sureDk: 30, tip: PlanBlokTip.soru, baslangicDk: 16 * 60);
      // Saat verilmezse blok günün sonuna eklenir.
      await n.blokEkle(gun, ders: 'Tarih', konu: 'Tarih genel tekrar', sureDk: 25, tip: PlanBlokTip.tekrar);
      var bloklar = c.read(programProvider).hafta[gun];
      expect(bloklar.map((b) => b.saat).toList(), ['16:00', '18:00', '18:40']);
      expect(bloklar.map((b) => b.ders).toList(), ['Kimya', 'Fizik', 'Tarih']);
      expect(c.read(programProvider).gunCalismaDk(gun), 95);

      final fizik = bloklar[1];
      await n.tamamlandiIsaretle(fizik.id, gun: DateTime.parse(c.read(programProvider).gunAnahtariAt(gun)));
      await n.blokGuncelle(gun, fizik.id, ders: 'Fizik', konu: 'Bernoulli İlkesi', sureDk: 50, tip: PlanBlokTip.calisma, baslangicDk: 15 * 60);
      bloklar = c.read(programProvider).gunBloklari(gun);
      expect(bloklar.first.konu, 'Bernoulli İlkesi');
      expect(bloklar.first.sure, 50);
      expect(bloklar.first.tamamlandi, isTrue, reason: 'düzenlenen bloğun tamamlanma işareti korunmalı');

      await n.gunuKopyala(gun, [5]);
      final kopya = c.read(programProvider).gunBloklari(5);
      expect(kopya.map((b) => b.konu).toList(), bloklar.map((b) => b.konu).toList());
      expect(kopya.any((b) => b.tamamlandi), isFalse);
      expect(kopya.every((b) => b.id.startsWith(c.read(programProvider).gunAnahtariAt(5))), isTrue);

      await n.blokSil(gun, bloklar.first.id);
      expect(c.read(programProvider).hafta[gun].length, 2);
      c.dispose();
    });

    test('sabitlenen program yeni haftada aynen yinelenir', () async {
      final (c1, depo) = await _kapsayici(sinif: '9. Sınıf');
      final n1 = c1.read(programProvider.notifier);
      await n1.hazirla();
      for (var g = 0; g < 7; g++) {
        await n1.gunuTemizle(g);
      }
      await n1.blokEkle(2, ders: 'Biyoloji', konu: 'Biyoçeşitlilik', sureDk: 45, baslangicDk: 17 * 60);
      await n1.sabitle(true);
      expect(c1.read(programProvider).ayar?.sabitle, isTrue);
      c1.dispose();

      // Kayıtlı haftayı "geçen hafta" yap; yeni haftada şablon kullanılmalı.
      final kayit = (await depo.getMap('haftalik_program'))!;
      await depo.setMap('haftalik_program', {...kayit, 'hafta': '2020-01-06'});
      final (c2, _) = await _kapsayici(sinif: '9. Sınıf', depo: depo);
      await c2.read(programProvider.notifier).hazirla();
      final p = c2.read(programProvider);
      expect(p.haftaAnahtari, gunAnahtari(haftaBaslangici(DateTime.now())));
      expect(p.hafta.expand((g) => g).length, 1);
      final blok = p.hafta[2].single;
      expect(blok.konu, 'Biyoçeşitlilik');
      expect(blok.saat, '17:00');
      expect(blok.id.startsWith(p.gunAnahtariAt(2)), isTrue);

      // Sabitleme kaldırılınca program yeniden otomatik üretilebilir.
      await c2.read(programProvider.notifier).sabitle(false);
      await c2.read(programProvider.notifier).yenidenOlustur();
      expect(c2.read(programProvider).hafta.expand((g) => g).where((b) => b.isCalismaBloku), isNotEmpty);
      c2.dispose();
    });

    test('şablondan hafta kurulurken kimlikler yeni tarihe taşınır', () {
      final eski = [
        for (var g = 0; g < 7; g++)
          g == 1 ? [elleBlok(gunAnahtar: '2026-01-06', ders: 'Kimya', konu: 'Mol Kavramı', sureDk: 30, baslangicDk: 600)] : <PlanBlok>[],
      ];
      final yeni = sablondanHafta(eski, DateTime(2026, 10, 5));
      expect(yeni[1].single.id.startsWith('2026-10-06-'), isTrue);
      expect(yeni[1].single.konu, 'Mol Kavramı');
      expect(gunSonuDk(yeni[1]), 630);
    });
  });
}
