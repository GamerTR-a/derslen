import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yks_kocu/core/algorithms/okul_hesaplari.dart';
import 'package:yks_kocu/core/storage/analiz_kayitlari.dart';
import 'package:yks_kocu/core/storage/storage_service.dart';
import 'package:yks_kocu/core/theme/app_theme.dart';
import 'package:yks_kocu/core/theme/tema_verisi.dart';
import 'package:yks_kocu/core/utils/tarih.dart';
import 'package:yks_kocu/data/models/auth_user.dart';
import 'package:yks_kocu/data/models/okul_modelleri.dart';
import 'package:yks_kocu/data/models/soru.dart';
import 'package:yks_kocu/presentation/providers/auth_provider.dart';
import 'package:yks_kocu/presentation/providers/test_provider.dart';
import 'package:yks_kocu/presentation/screens/auth/karsilama_screen.dart';
import 'package:yks_kocu/presentation/screens/okul/ogrenci_ozet_gorunumu.dart';
import 'package:yks_kocu/presentation/screens/okul/okul_ortak.dart';
import 'package:yks_kocu/presentation/screens/okul/rol_kabugu.dart';

Soru _soru(String id, String ders, String konu, String dogru) => Soru(
      id: id,
      ders: ders,
      konu: konu,
      altBaslik: '',
      zorluk: SoruZorluk.orta,
      soruMetni: 'Soru $id',
      secenekler: const {'A': 'a', 'B': 'b', 'C': 'c', 'D': 'd', 'E': 'e'},
      dogruSecenek: dogru,
      cozumAciklama: '',
    );

/// Son 28 gün; her gün [dk] dakika, [plan] = (blok, tamam).
List<OzetGunu> _gunler(int Function(int geri) dk, {(int, int) Function(int geri)? plan}) {
  final bugun = DateTime(2026, 10, 8);
  return [
    for (var i = 27; i >= 0; i--)
      OzetGunu(
        gun: gunAnahtari(bugun.subtract(Duration(days: i))),
        dk: dk(i),
        planBlok: plan?.call(i).$1 ?? 0,
        planTamam: plan?.call(i).$2 ?? 0,
      ),
  ];
}

void main() {
  group('Roller ve paneller', () {
    test('sunucu rolü doğru panele çözülür', () {
      expect(KullaniciRolu.coz('teacher'), KullaniciRolu.ogretmen);
      expect(KullaniciRolu.coz('parent'), KullaniciRolu.veli);
      expect(KullaniciRolu.coz('principal'), KullaniciRolu.mudur);
      expect(KullaniciRolu.coz('student'), KullaniciRolu.ogrenci);
      // Uygulama yöneticisi ve topluluk başkanı öğrenci panelini kullanır.
      expect(KullaniciRolu.coz('admin'), KullaniciRolu.ogrenci);
      expect(KullaniciRolu.coz('baskan'), KullaniciRolu.ogrenci);
      expect(KullaniciRolu.coz(null), KullaniciRolu.ogrenci);
      expect(KullaniciRolu.coz('bilinmeyen'), KullaniciRolu.ogrenci);
    });

    test('her panelin ayrı ana rotası vardır', () {
      expect({for (final r in KullaniciRolu.values) r.ev}.length, KullaniciRolu.values.length);
      expect(KullaniciRolu.turden('ogretmen'), KullaniciRolu.ogretmen);
      expect(KullaniciRolu.turden('yok'), isNull);
    });

    test('oturum durumu varsayılan olarak öğrenci panelidir', () {
      const s = AuthState(status: AuthStatus.authenticated);
      expect(s.panel, KullaniciRolu.ogrenci);
      expect(s.copyWith(rol: 'teacher').panel, KullaniciRolu.ogretmen);
      // copyWith rolü korur.
      expect(s.copyWith(rol: 'parent').copyWith(status: AuthStatus.authenticated).rol, 'parent');
    });

    test('okul müdürü uygulama yöneticisi sayılmaz', () {
      final mudur = LiseAuthUser.fromJson({'id': 'u1', 'role': 'principal'});
      expect(mudur.isInstitutionAdmin, isTrue);
      expect(mudur.isAdmin, isFalse);
      expect(LiseAuthUser.fromJson({'id': 'u2', 'role': 'teacher'}).isCoach, isTrue);
    });
  });

  group('Panel yönlendirmesi', () {
    test('öğrenci okul panellerine giremez, kendi ekranlarında kalır', () {
      expect(panelYonlendirmesi(KullaniciRolu.ogrenci, '/ana'), isNull);
      expect(panelYonlendirmesi(KullaniciRolu.ogrenci, '/okulum'), isNull);
      expect(panelYonlendirmesi(KullaniciRolu.ogrenci, '/ogretmen'), '/ana');
      expect(panelYonlendirmesi(KullaniciRolu.ogrenci, '/mudur'), '/ana');
      expect(panelYonlendirmesi(KullaniciRolu.ogrenci, '/okul/ogrenci/abc'), '/ana');
    });

    test('öğretmen yalnızca kendi paneline ve ortak ekranlara girer', () {
      expect(panelYonlendirmesi(KullaniciRolu.ogretmen, '/ogretmen'), isNull);
      expect(panelYonlendirmesi(KullaniciRolu.ogretmen, '/okul/sube/s1'), isNull);
      expect(panelYonlendirmesi(KullaniciRolu.ogretmen, '/okul/ogrenci/o1'), isNull);
      expect(panelYonlendirmesi(KullaniciRolu.ogretmen, '/ayarlar'), isNull);
      expect(panelYonlendirmesi(KullaniciRolu.ogretmen, '/ana'), '/ogretmen');
      expect(panelYonlendirmesi(KullaniciRolu.ogretmen, '/mudur'), '/ogretmen');
      expect(panelYonlendirmesi(KullaniciRolu.ogretmen, '/admin'), '/ogretmen');
    });

    test('veli öğrenci detayına bakabilir ama öğrenci ekranlarına giremez', () {
      expect(panelYonlendirmesi(KullaniciRolu.veli, '/veli'), isNull);
      expect(panelYonlendirmesi(KullaniciRolu.veli, '/flashkart'), '/veli');
      expect(panelYonlendirmesi(KullaniciRolu.veli, '/okulum'), '/veli');
    });

    test('müdür tek tek öğrenci ekranına giremez (yalnızca toplamları görür)', () {
      expect(panelYonlendirmesi(KullaniciRolu.mudur, '/mudur'), isNull);
      expect(panelYonlendirmesi(KullaniciRolu.mudur, '/okul/ogrenci/o1'), '/mudur');
      expect(panelYonlendirmesi(KullaniciRolu.mudur, '/okul/sube/s1'), '/mudur');
      expect(panelYonlendirmesi(KullaniciRolu.mudur, '/gizlilik-politikasi'), isNull);
    });
  });

  group('Kodlar', () {
    test('kod temizlenir, biçimlenir ve türü önekten bulunur', () {
      expect(kodTemizle(' s-abcd-2345 '), 'SABCD2345');
      expect(kodBicimle('sabcd2345'), 'S-ABCD-2345');
      expect(kodBicimle('KISA'), 'KISA');
      expect(kodTuru('S-ABCD-2345'), KullaniciRolu.ogrenci);
      expect(kodTuru('T-ABCD-2345'), KullaniciRolu.ogretmen);
      expect(kodTuru('M-ABCD-2345'), KullaniciRolu.mudur);
      expect(kodTuru('V-ABCD-2345'), KullaniciRolu.veli);
      expect(kodTuru('X-ABCD-2345'), isNull);
      expect(kodTuru('S-ABC'), isNull);
    });

    test('her hata durumu için açıklama vardır', () {
      for (final tur in KullaniciRolu.values) {
        for (final durum in ['gecersiz', 'cok_deneme', 'rol_uyumsuz', 'zaten_uye']) {
          expect(kodHataMetni(durum, tur), isNotEmpty);
        }
      }
      expect(kodHataMetni('cok_deneme', KullaniciRolu.veli), contains('saat'));
    });
  });

  group('Haftalık özet', () {
    test('son 7 gün ve önceki 7 gün ayrı toplanır', () {
      // Son hafta her gün 60 dk, önceki hafta her gün 30 dk.
      final gunler = _gunler((geri) => geri < 7 ? 60 : (geri < 14 ? 30 : 0), plan: (geri) => geri < 7 ? (4, 3) : (0, 0));
      final bu = haftaOzeti(gunler);
      final gecen = haftaOzeti(gunler, geri: 1);
      expect(bu.toplamDk, 420);
      expect(bu.aktifGun, 7);
      expect(bu.planUyumu, 75);
      expect(bu.gunlukOrtalama, 60);
      expect(gecen.toplamDk, 210);
      expect(gecen.planUyumu, isNull);
      expect(haftaOzeti(gunler, geri: 2).toplamDk, 0);
      expect(haftaOzeti(const []).toplamDk, 0);
      expect(haftaOzeti(gunler, geri: 9).gunler, isEmpty);
    });

    test('sunucu ölçümü yoksa öğrencinin kendi kaydı kullanılır', () {
      expect(gunSuresi(const OzetGunu(gun: '2026-10-08', dk: 40, beyanDk: 90)), 40);
      expect(gunSuresi(const OzetGunu(gun: '2026-10-08', dk: 0, beyanDk: 90)), 90);
    });

    test('hafta farkı ve son etkinlik metinleri', () {
      expect(haftaFarkiMetni(120, 120), contains('aynı'));
      expect(haftaFarkiMetni(180, 120), startsWith('+1 sa'));
      expect(haftaFarkiMetni(60, 120), startsWith('-1 sa'));
      final simdi = DateTime(2026, 10, 8, 15);
      expect(sonAktifMetni(null, simdi), 'henüz yok');
      expect(sonAktifMetni(DateTime(2026, 10, 8, 1), simdi), 'bugün');
      expect(sonAktifMetni(DateTime(2026, 10, 7, 23), simdi), 'dün');
      expect(sonAktifMetni(DateTime(2026, 10, 3), simdi), '5 gün önce');
      expect(sonAktifMetni(DateTime(2026, 9, 10), simdi), '4 hafta önce');
    });

    test('risk açıklamaları duruma göre değişir', () {
      const dusus = OgrenciSatiri(id: 'o', ad: 'Ada', dk7g: 40, dkOnceki7g: 90, dk2Onceki7g: 200, risk: RiskDurumu.dusus);
      expect(riskAciklamasi(dusus), contains('3 sa 20 dk'));
      expect(RiskDurumu.coz('pasif').uyari, isTrue);
      expect(RiskDurumu.coz('yeni').uyari, isFalse);
      expect(RiskDurumu.coz(null), RiskDurumu.yok);
    });
  });

  group('Sınıf ormanı', () {
    test('her 5 saatlik ortak çalışma bir ağaçtır', () {
      expect(ormanAgacSayisi(0), 0);
      expect(ormanAgacSayisi(299), 0);
      expect(ormanAgacSayisi(300), 1);
      expect(ormanAgacSayisi(1550), 5);
      expect(ormanAgacSayisi(-5), 0);
      expect(siradakiAgacIlerlemesi(450), closeTo(0.5, 0.001));
      expect(siradakiAgacIlerlemesi(0), 0);
      expect(sinifHaftalikHedefi(20), 6000);
      expect(sinifHaftalikHedefi(0), 300);
    });
  });

  group('Sunucu yanıtlarının çözümü', () {
    test('okul durumu: şubeye kayıtlı öğrenci okul modundadır', () {
      final d = OkulDurumu.fromJson({
        'rol': 'student',
        'ad': 'Ada Yılmaz',
        'uye_rol': 'ogrenci',
        'okul': {'id': 'ok1', 'ad': 'Örnek Lisesi', 'aktif': true},
        'sube': {'id': 's1', 'sinif': '11', 'ad': 'A'},
        'cocuklar': [],
        'veli_sayisi': 1,
      });
      expect(d.okulOgrencisi, isTrue);
      expect(d.sube!.etiket, '11-A');
      expect(d.veliSayisi, 1);
      // Okula bağlı olmayan öğrenci ve öğretmen okul modunda değildir.
      expect(OkulDurumu.fromJson({'rol': 'student'}).okulOgrencisi, isFalse);
      expect(
        OkulDurumu.fromJson({
          'rol': 'teacher',
          'okul': {'id': 'ok1', 'ad': 'Örnek Lisesi'},
          'rehber': true,
        }).okulOgrencisi,
        isFalse,
      );
    });

    test('veli durumu çocukları taşır', () {
      final d = OkulDurumu.fromJson({
        'rol': 'parent',
        'cocuklar': [
          {'id': 'c1', 'ad': 'Ada', 'sinif': '11. Sınıf'},
          {'id': 'c2', 'ad': 'Efe', 'sinif': null},
        ],
      });
      expect(d.panel, KullaniciRolu.veli);
      expect(d.cocuklar.map((c) => c.ad), ['Ada', 'Efe']);
    });

    test('şube özeti ve öğrenci satırı', () {
      final s = SubeOzeti.fromJson({
        'sube': {'id': 's1', 'sinif': '12', 'ad': 'B'},
        'rehber': true,
        'brans': null,
        'ogrenciler': [
          {'id': 'o1', 'ad': 'Ada', 'dk_7g': 300, 'dk_onceki_7g': 420, 'plan_blok': 10, 'plan_tamam': 7, 'risk': 'dusus', 'son_aktif': '2026-10-07T18:00:00Z'},
          {'id': 'o2', 'ad': 'Efe', 'dk_7g': 0, 'dk_onceki_7g': 0, 'risk': 'pasif', 'son_aktif': null},
        ],
      });
      expect(s.sube.etiket, '12-B');
      expect(s.ogrenciler.first.planUyumu, 70);
      expect(s.ogrenciler.first.risk, RiskDurumu.dusus);
      expect(s.ogrenciler.last.planUyumu, isNull);
      expect(s.ogrenciler.last.sonAktif, isNull);
    });

    test('öğrenci özeti: görüşme notları yalnızca rehbere gelir', () {
      final rehber = OgrenciOzeti.fromJson({
        'erisim': 'rehber',
        'ad': 'Ada',
        'gunler': [
          {'gun': '2026-10-08', 'dk': 45, 'beyan_dk': 60, 'plan_blok': 3, 'plan_tamam': 2},
        ],
        'ders_dk': {'Matematik': 120, 'Fizik': 30},
        'netler': [
          {'deneme': 'TYT 3', 'alan': 'TYT', 'net': 68.25, 'tarih': '2026-10-01T10:00:00Z'},
        ],
        'konu': {'tamam': 42, 'zayif': 5, 'gun': '2026-10-08'},
        'testler': [
          {'ders': 'Matematik', 'dogru': 14, 'yanlis': 4, 'bos': 2},
        ],
        'gorusmeler': [
          {'id': 'g1', 'not': 'Program konuşuldu', 'hedef': 'Günde 2 blok', 'tarih': '2026-10-02T09:00:00Z', 'benim': true, 'ogretmen': 'Zeynep Hoca'},
        ],
      });
      expect(rehber.rehberGorunumu, isTrue);
      expect(rehber.gorusmeler, hasLength(1));
      expect(rehber.konuTamam, 42);
      expect(rehber.testler.single.basari, 70);
      expect(enCokCalisilanDers(rehber.dersDk), startsWith('Matematik'));

      final veli = OgrenciOzeti.fromJson({'erisim': 'veli', 'ad': 'Ada', 'gunler': [], 'gorusmeler': null});
      expect(veli.gorusmeler, isNull);
      expect(veli.rehberGorunumu, isFalse);
    });

    test('okul özeti toplamları şubelerden hesaplanır ve rapor ad içermez', () {
      final o = OkulOzeti.fromJson({
        'okul': 'Örnek Lisesi',
        'tarih': '2026-10-08',
        'ogrenci': 50,
        'ogretmen': 4,
        'veli': 12,
        'subeler': [
          {'id': 's1', 'sinif': '11', 'ad': 'A', 'ogrenci': 30, 'aktif_7g': 18, 'ort_dk_7g': 200, 'toplam_dk_7g': 6000, 'risk': 3},
          {'id': 's2', 'sinif': '12', 'ad': 'A', 'ogrenci': 20, 'aktif_7g': 12, 'ort_dk_7g': 150, 'toplam_dk_7g': 3000, 'risk': 1},
        ],
        'haftalar': [
          {'bas': '2026-09-28', 'toplam_dk': 8000, 'aktif': 28},
          {'bas': '2026-10-05', 'toplam_dk': 9000, 'aktif': 30},
        ],
      });
      expect(o.aktif7g, 30);
      expect(o.aktifOrani, 60);
      expect(o.risk, 4);
      expect(o.ortDk7g, 180);
      expect(o.subeler.first.aktifOrani, 60);
      final rapor = okulRaporuMetni(o);
      expect(rapor, contains('Örnek Lisesi'));
      expect(rapor, contains('11-A: 30 öğrenci, %60 aktif'));
      expect(rapor, contains('05 Eki haftası'));
    });

    test('kod sonucu ve veli bağlantısı', () {
      final k = KodSonucu.fromJson({'durum': 'onay_gerekli', 'okul': 'Örnek Lisesi', 'sinif': '11', 'sube': 'A'});
      expect(k.basarili, isFalse);
      expect(k.okul, 'Örnek Lisesi');
      expect(KodSonucu.fromJson({'durum': 'ok'}).basarili, isTrue);
      final b = VeliBaglantisi.fromJson({'id': 'b1', 'durum': 'aktif', 'karsi_ad': 'Ayşe', 'karsi_id': 'v1', 'ben_ogrenci': true});
      expect(b.aktif, isTrue);
      expect(b.karsiId, 'v1');
    });

    test('yönetim özeti öğretmenin görevini ve şubelerini taşır', () {
      final y = YonetimOzeti.fromJson({
        'okul': {'id': 'ok1', 'ad': 'Örnek Lisesi'},
        'subeler': [
          {'id': 's1', 'sinif': '11', 'ad': 'A', 'kod': 'SABCD2345', 'ogrenci_sayisi': 28, 'ogretmenler': ['Zeynep']},
        ],
        'ogretmenler': [
          {'id': 't1', 'ad': 'Zeynep', 'rehber': true, 'brans': null, 'sube_ids': ['s1']},
          {'id': 't2', 'ad': 'Can', 'rehber': false, 'brans': 'Fizik', 'sube_ids': []},
        ],
        'davetler': [
          {'kod': 'TABCD2345', 'rehber': false, 'brans': 'Kimya', 'son_gecerlilik': '2026-10-20T00:00:00Z'},
        ],
      });
      expect(y.okulAd, 'Örnek Lisesi');
      expect(y.ogretmenler.first.gorev, 'Rehber öğretmen');
      expect(y.ogretmenler.last.gorev, 'Fizik');
      expect(y.ogretmenler.first.subeIdleri, {'s1'});
      expect(y.davetler.single.gorev, 'Kimya');
    });
  });

  group('Veli özeti metni', () {
    test('süre, gün, program ve son denemeyi içerir', () {
      final o = OgrenciOzeti(
        erisim: 'veli',
        ad: 'Ada',
        gunler: _gunler((geri) => geri < 7 ? 60 : 30, plan: (geri) => geri < 7 ? (2, 1) : (0, 0)),
        dersDk: const {'Matematik': 300, 'Türkçe': 120},
        netler: const [OzetDenemesi(deneme: 'TYT 3', alan: 'TYT', net: 68.25)],
      );
      final metin = veliOzetMetni(o);
      expect(metin, contains('Ada'));
      expect(metin, contains('7 sa'));
      expect(metin, contains('7 / 7'));
      expect(metin, contains('%50'));
      expect(metin, contains('68.25 net'));
      expect(netMetni(70), '70');
    });
  });

  group('Konu bazlı test kaydı', () {
    test('test sonucu ders ve konuya göre günlük kayda eklenir', () async {
      SharedPreferences.setMockInitialValues({});
      final depo = SharedPrefsStorageService();
      await depo.init();
      final test = AktifTestState(
        sorular: [
          _soru('1', 'Matematik', 'Türev', 'A'),
          _soru('2', 'Matematik', 'Türev', 'B'),
          _soru('3', 'Matematik', 'Limit', 'C'),
          _soru('4', 'Edebiyat', 'Şiir Bilgisi', 'D'),
        ],
        cevaplar: const {0: 'A', 1: 'C', 3: 'D'},
      );
      final gun = DateTime(2026, 10, 8, 20);
      await testKonuKaydinaEkle(depo, test, simdi: gun);
      await testKonuKaydinaEkle(depo, test, simdi: gun);

      final kayit = await depo.getMap(AnalizKayitlari.testKonu);
      final bugun = Map<String, dynamic>.from(kayit!['2026-10-08'] as Map);
      // [doğru, yanlış, boş] — iki kez eklendiği için ikiye katlanır.
      expect(bugun['Matematik>Türev'], [2, 2, 0]);
      expect(bugun['Matematik>Limit'], [0, 0, 2]);
      expect(bugun['Türk Dili ve Edebiyatı>Şiir Bilgisi'], [2, 0, 0]);
    });
  });

  group('Ekranlar', () {
    for (final tema in [AppTheme.light, AppTheme.dark]) {
      final ad = tema.gece ? 'gece' : 'gündüz';

      testWidgets('karşılama ekranı dört paneli gösterir ($ad)', (tester) async {
        tester.view.physicalSize = const Size(360 * 3, 640 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(child: MaterialApp(theme: temaVerisi(tema), home: const KarsilamaScreen())),
        );
        for (final rol in KullaniciRolu.values) {
          expect(find.text(rol.etiket), findsOneWidget);
        }
        expect(find.textContaining('Giriş yap'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('öğrenci özeti bölümleri taşmadan çizilir ($ad)', (tester) async {
        tester.view.physicalSize = const Size(360 * 3, 760 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        final ozet = OgrenciOzeti(
          erisim: 'rehber',
          ad: 'Ada Yılmaz',
          sube: '11-A',
          gunler: _gunler((geri) => (geri * 23) % 140, plan: (geri) => (4, geri % 5)),
          dersDk: const {'Matematik': 320, 'Fizik': 140, 'Türk Dili ve Edebiyatı': 90, 'Genel': 30},
          netler: [
            OzetDenemesi(deneme: 'Türkiye Geneli TYT Denemesi 3 (çok uzun adlı)', alan: 'TYT', net: 71.5, tarih: DateTime(2026, 10, 1)),
          ],
          konuTamam: 42,
          konuZayif: 6,
          testler: const [
            OzetTesti(ders: 'Matematik', dogru: 14, yanlis: 4, bos: 2),
            OzetTesti(ders: 'Fizik', dogru: 3, yanlis: 6, bos: 1),
          ],
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: temaVerisi(tema),
            home: Scaffold(
              body: Builder(
                builder: (context) => ListView(
                  padding: const EdgeInsets.all(20),
                  children: [...haftaBolumu(context, ozet), const SizedBox(height: 14), ...gecmisBolumu(context, ozet)],
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Program uyumu'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(ListView), const Offset(0, -1400));
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
      });

      testWidgets('ortak bileşenler dar ekranda taşmaz ($ad)', (tester) async {
        tester.view.physicalSize = const Size(320 * 3, 640 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: temaVerisi(tema),
            home: Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(20),
                children: const [
                  PanelBasligi('Çok Uzun Adlı Örnek Anadolu Lisesi Müdürlüğü', alt: 'Son 7 günün özeti'),
                  KodKutusu(kod: 'SABCD2345', aciklama: 'Öğrenci katılım kodu'),
                  SizedBox(height: 10),
                  RiskRozeti(RiskDurumu.pasif),
                  RiskRozeti(RiskDurumu.dusus),
                  OranSatiri(etiket: 'Trigonometrik Denklemler ve Eşitsizlikler', deger: '%42', oran: 0.42, alt: 'Matematik · 9 öğrenci · 120 soru'),
                  BilgiKarti(ikon: Icons.info_outline, baslik: 'Bilgi', maddeler: ['Birinci madde', 'İkinci, daha uzun bir madde metni buraya gelir.']),
                  BosDurum(ikon: Icons.inbox_outlined, baslik: 'Boş', aciklama: 'Henüz kayıt yok.'),
                  AnaDugme(etiket: 'Devam'),
                ],
              ),
            ),
          ),
        );
        expect(find.text('S-ABCD-2345'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('panel kabuğu sekmeyi ilk açılışta kurar ve geri tuşu ilk sekmeye döner', (tester) async {
      final kurulan = <String>[];
      PanelSekmesi sekme(String ad) => PanelSekmesi(
            etiket: ad,
            ikon: Icons.circle_outlined,
            seciliIkon: Icons.circle,
            insa: (_) {
              if (!kurulan.contains(ad)) kurulan.add(ad);
              return Center(child: Text('$ad içeriği'));
            },
          );
      await tester.pumpWidget(
        MaterialApp(
          theme: temaVerisi(AppTheme.light),
          home: RolKabugu(sekmeler: [sekme('Bir'), sekme('İki'), sekme('Üç')]),
        ),
      );
      expect(kurulan, ['Bir']);
      await tester.tap(find.text('Üç'));
      await tester.pumpAndSettle();
      expect(kurulan, ['Bir', 'Üç']);
      expect(find.text('Üç içeriği'), findsOneWidget);

      // Geri: uygulamadan çıkmak yerine ilk sekmeye döner.
      final geri = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(geri, isTrue);
      expect(find.text('Bir içeriği'), findsOneWidget);
      expect(kurulan, ['Bir', 'Üç']);
    });
  });
}
