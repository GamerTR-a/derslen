import 'package:flutter_test/flutter_test.dart';
import 'package:yks_kocu/core/algorithms/analiz_motoru.dart';
import 'package:yks_kocu/core/algorithms/ders_programi.dart';
import 'package:yks_kocu/core/constants/app_constants.dart';
import 'package:yks_kocu/core/constants/yks_data.dart';
import 'package:yks_kocu/core/utils/tarih.dart';
import 'package:yks_kocu/data/models/gunluk_checkin.dart';
import 'package:yks_kocu/data/models/net_kaydi.dart';
import 'package:yks_kocu/data/models/ogrenci_profil.dart';

void main() {
  const profil = OgrenciProfil(
    hedefBolum: 'sayisal',
    gunlukSaat: 3,
    ogrenmeMetod: OgrenmeMetod.dengeli,
    onboardingTamamlandi: true,
  );
  final pazartesi = DateTime(2026, 9, 28);

  group('Haftalık ders programı', () {
    test('Molalar dahil blok sayısı doğru hesaplanır', () {
      // 25 dk bloklar; 2 blokta bir 5 dk, 4 blokta bir 15 dk mola → 180 dk'ya 6 blok sığar.
      expect(gunBlokSayisi(180, OgrenmeMetod.dengeli), 6);
      expect(gunBlokSayisi(20, OgrenmeMetod.dengeli), 0);
      // 50 dk blok + 10 dk mola → 180 dk'ya 3 blok.
      expect(gunBlokSayisi(180, OgrenmeMetod.derinlemeci), 3);
    });

    test('Program 7 gün üretir; saatler artan, kimlikler benzersiz, alan dışı ders yok', () {
      final ayar = DersProgramiAyar.varsayilan(profil);
      final hafta = haftalikProgramOlustur(profil: profil, konular: tumKonular, ayar: ayar, haftaBaslangic: pazartesi);

      expect(hafta.length, 7);
      final tumBloklar = hafta.expand((g) => g).toList();
      expect(tumBloklar.map((b) => b.id).toSet().length, tumBloklar.length);
      expect(tumBloklar.where((b) => b.isCalismaBloku).isNotEmpty, isTrue);

      // Sayısal öğrenciye AYT Tarih/Edebiyat konuları planlanmaz.
      expect(tumBloklar.any((b) => b.ders == 'Tarih' || b.ders == 'Türk Dili ve Edebiyatı'), isFalse);

      for (final gun in hafta) {
        final saatler = gun.map((b) => b.saatFormatli).toList();
        final sirali = [...saatler]..sort();
        expect(saatler, sirali);
      }
      // Hafta içi başlangıç saati 17:00.
      expect(hafta[0].first.saatFormatli, '17:00');
    });

    test('Aynı ders bir günde art arda gelmez ve konular günlere yayılır', () {
      final ayar = DersProgramiAyar.varsayilan(profil);
      final hafta = haftalikProgramOlustur(profil: profil, konular: tumKonular, ayar: ayar, haftaBaslangic: pazartesi);
      for (final gun in hafta) {
        final dersler = gun.where((b) => b.isCalismaBloku && b.ders != 'Deneme').map((b) => b.ders).toList();
        for (var i = 1; i < dersler.length; i++) {
          expect(dersler[i], isNot(dersler[i - 1]), reason: 'art arda aynı ders: $dersler');
        }
      }
      // Pazartesi ve Salı aynı konu listesini tekrar etmez.
      final pzt = hafta[0].where((b) => b.isCalismaBloku).map((b) => b.konu).toSet();
      final sal = hafta[1].where((b) => b.isCalismaBloku).map((b) => b.konu).toSet();
      expect(pzt.intersection(sal).length, lessThan(pzt.length));
    });

    test('Zayıf ve bitmemiş konu önce, soru çözme bloğu olarak planlanır', () {
      final konular = [
        for (final k in tumKonular) k.id == 'tyt-mat-5' ? k.copyWith(zayif: true) : k,
      ];
      final hafta = haftalikProgramOlustur(
        profil: profil,
        konular: konular,
        ayar: DersProgramiAyar.varsayilan(profil),
        haftaBaslangic: pazartesi,
      );
      final ilkMatematik = hafta.expand((g) => g).firstWhere((b) => b.ders == 'Matematik');
      expect(ilkMatematik.konu, 'Basit Eşitsizlikler');
      expect(ilkMatematik.tip, PlanBlokTip.soru);
    });

    test('Hariç dersler planlanmaz, öncelikli ders daha fazla blok alır', () {
      final temel = DersProgramiAyar.varsayilan(profil);
      int fizikBlok(DersProgramiAyar a) => haftalikProgramOlustur(
            profil: profil,
            konular: tumKonular,
            ayar: a,
            haftaBaslangic: pazartesi,
          ).expand((g) => g).where((b) => b.ders == 'Fizik').length;

      expect(fizikBlok(temel.copyWith(haricDersler: ['Fizik'])), 0);
      expect(fizikBlok(temel.copyWith(oncelikliDersler: ['Fizik'])), greaterThan(fizikBlok(temel)));
    });

    test('Pazar deneme bloğu eklenir; kapalı günler ve geçmiş günler boş kalır', () {
      final ayar = DersProgramiAyar.varsayilan(profil).gunGuncelle(2, const GunAyari(aktif: false, baslangicDk: 1020, sureDk: 180));
      final hafta = haftalikProgramOlustur(
        profil: profil,
        konular: tumKonular,
        ayar: ayar,
        haftaBaslangic: pazartesi,
        ilkGun: 1,
      );
      expect(hafta[0], isEmpty); // ilkGun'den önce
      expect(hafta[2], isEmpty); // kapalı gün
      expect(hafta[6].first.ders, 'Deneme');
    });

    test('Ayarlar JSON ile kayıpsız saklanır', () {
      final ayar = DersProgramiAyar.varsayilan(profil).copyWith(oncelikliDersler: ['Kimya'], pazarDeneme: false);
      final geri = DersProgramiAyar.fromJson(ayar.toJson(), profil);
      expect(geri.haftalikDk, ayar.haftalikDk);
      expect(geri.oncelikliDersler, ['Kimya']);
      expect(geri.pazarDeneme, isFalse);
    });

    test('Check-in uyarlaması: yüksek stres nefes bloğu ekler ve yükü azaltır', () {
      final gun = haftalikProgramOlustur(
        profil: profil,
        konular: tumKonular,
        ayar: DersProgramiAyar.varsayilan(profil),
        haftaBaslangic: pazartesi,
      )[0];
      final iyi = gunlukPlaniUyarla(gun, GunlukCheckin(tarih: '', enerji: 5, odak: 5, stres: 1, createdAt: DateTime.now()), 'g');
      expect(iyi.cikarilan, 0);
      expect(iyi.bloklar.where((b) => b.isCalismaBloku).length, gun.where((b) => b.isCalismaBloku).length);

      final zor = gunlukPlaniUyarla(gun, GunlukCheckin(tarih: '', enerji: 1, odak: 2, stres: 5, createdAt: DateTime.now()), 'g');
      expect(zor.bloklar.first.tip, PlanBlokTip.egzersiz);
      expect(zor.cikarilan, greaterThan(0));
      expect(zor.bloklar.last.isMola, isFalse);
    });
  });

  group('Analiz motoru', () {
    final bugun = DateTime(2026, 10, 1);
    String gun(int oncesi) => gunAnahtari(bugun.subtract(Duration(days: oncesi)));

    test('Çalışma serisi bugün çalışılmamışsa dünden sayılır', () {
      final log = {gun(1): 30, gun(2): 45, gun(4): 20};
      expect(calismaSerisi(log, bugun), 2);
      expect(calismaSerisi({...log, gun(0): 10}, bugun), 3);
      expect(enUzunSeri({...log, gun(0): 10}), 3);
    });

    test('Doğrusal eğim ve net trendi', () {
      expect(dogrusalEgim([10, 12, 14]), closeTo(2, 1e-9));
      final netler = [
        for (var i = 0; i < 4; i++)
          NetKaydi(
            id: 'n$i',
            tarih: gun(10 - i),
            alan: SinavAlani.TYT,
            ders: 'Matematik',
            dogru: 10 + i * 2,
            denemeAdi: 'D$i',
            createdAt: bugun.subtract(Duration(days: 10 - i)),
          ),
      ];
      final trend = netTrendi(netler, SinavAlani.TYT);
      expect(trend.noktalar.length, 4);
      expect(trend.egim, closeTo(2, 1e-9));
      expect(trend.tahmin(5), closeTo(26, 1e-9));
      final tablo = dersNetTablosu(netler);
      expect(tablo.single.son, 16);
      expect(tablo.single.degisim, closeTo(4, 1e-9));
    });

    test('Dönem analizi: toplamlar, plan uyumu, ders dağılımı ve içgörüler', () {
      final girdi = AnalizGirdisi(
        profil: profil,
        bugun: bugun,
        konular: tumKonular,
        calismaGunluk: {gun(0): 60, gun(1): 120, gun(2): 200, gun(9): 100},
        calismaDers: {
          gun(0): {'Matematik': 60},
          gun(1): {'Fizik': 120},
        },
        planUyum: {
          gun(0): [4, 2, 100, 50],
          gun(1): [4, 4, 100, 100],
        },
        checkinLog: {gun(0): [4, 3, 2]},
      );
      final a = donemAnalizi(girdi, 7);
      expect(a.gunler.length, 7);
      expect(a.gunler.last, gun(0));
      expect(a.toplamDk, 380);
      expect(a.oncekiDonemDk, 100);
      expect(a.aktifGun, 3);
      expect(a.planUyumu, closeTo(0.75, 1e-9));
      expect(a.dersDagilimi.keys.first, 'Fizik');
      expect(a.seri, 3);
      expect(a.isiHaritasi.length, 12);
      expect(a.icgoruler, isNotEmpty);
      // Sayısal öğrencinin konu durumu yalnızca alan dersleri içerir.
      expect(a.konuDurumu.any((k) => k.ders == 'Tarih'), isFalse);
    });
  });
}
