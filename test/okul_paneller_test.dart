import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yks_kocu/core/services/okul_service.dart';
import 'package:yks_kocu/core/storage/storage_service.dart';
import 'package:yks_kocu/core/theme/app_theme.dart';
import 'package:yks_kocu/core/theme/tema_verisi.dart';
import 'package:yks_kocu/core/utils/tarih.dart';
import 'package:yks_kocu/data/models/okul_modelleri.dart';
import 'package:yks_kocu/presentation/providers/okul_provider.dart';
import 'package:yks_kocu/presentation/providers/profil_provider.dart';
import 'package:yks_kocu/presentation/screens/admin/tabs/admin_okullar_tab.dart';
import 'package:yks_kocu/presentation/screens/auth/rol_kodu_screen.dart';
import 'package:yks_kocu/presentation/screens/okul/mudur_paneli.dart';
import 'package:yks_kocu/presentation/screens/okul/ogrenci_detay_screen.dart';
import 'package:yks_kocu/presentation/screens/okul/ogretmen_paneli.dart';
import 'package:yks_kocu/presentation/screens/okul/okulum_screen.dart';
import 'package:yks_kocu/presentation/screens/okul/sube_detay_screen.dart';
import 'package:yks_kocu/presentation/screens/okul/veli_paneli.dart';

/// Sunucunun döndürdüğü biçimde örnek yanıtlar (22_okul_raporlama.sql).
class _SahteSunucu {
  bool rehber = true;
  final List<String> cagrilar = [];
  final Map<String, Map<String, dynamic>?> parametreler = {};

  Map<String, dynamic> _ogrenci(String id, String ad, int dk, int onceki, String risk) => {
        'id': id,
        'ad': ad,
        'dk_7g': dk,
        'dk_onceki_7g': onceki,
        'dk_2onceki_7g': onceki + 120,
        'aktif_gun': dk == 0 ? 0 : 5,
        'plan_blok': 12,
        'plan_tamam': dk == 0 ? 0 : 9,
        'son_aktif': dk == 0 ? null : DateTime.now().subtract(const Duration(days: 1)).toUtc().toIso8601String(),
        'risk': risk,
        'sube': '11-A',
        'sube_id': 's1',
      };

  Future<dynamic> cagir(String fn, Map<String, dynamic>? params) async {
    cagrilar.add(fn);
    parametreler[fn] = params;
    final bugun = DateTime.now();
    switch (fn) {
      case 'ogretmen_siniflarim':
        return {
          'rehber': rehber,
          'brans': rehber ? null : 'Matematik',
          'okul': 'Örnek Anadolu Lisesi',
          'siniflar': [
            {'sube_id': 's1', 'sinif': '11', 'ad': 'A', 'ogrenci_sayisi': 28, 'aktif_7g': 19, 'ort_dk_7g': 245, 'risk_sayisi': 3},
            {'sube_id': 's2', 'sinif': '12', 'ad': 'FEN-1', 'ogrenci_sayisi': 24, 'aktif_7g': 20, 'ort_dk_7g': 410, 'risk_sayisi': 0},
          ],
        };
      case 'sube_ozeti':
        return {
          'sube': {'id': 's1', 'sinif': '11', 'ad': 'A'},
          'rehber': rehber,
          'brans': rehber ? null : 'Matematik',
          'ogrenciler': [
            _ogrenci('o1', 'Efe Uzunsoyadlıoğlu Karadenizli', 0, 0, rehber ? 'pasif' : 'yok'),
            _ogrenci('o2', 'Ada Yılmaz', 95, 240, rehber ? 'dusus' : 'yok'),
            _ogrenci('o3', 'Can Demir', 380, 300, 'yok'),
          ],
        };
      case 'ogretmen_uyarilari':
        return [_ogrenci('o1', 'Efe Uzunsoyadlıoğlu Karadenizli', 0, 0, 'pasif'), _ogrenci('o2', 'Ada Yılmaz', 95, 240, 'dusus')];
      case 'sube_konu_ozeti':
        return [
          {'ders': 'Matematik', 'konu': 'Trigonometrik Denklemler ve Eşitsizlikler', 'dogru': 40, 'yanlis': 70, 'bos': 10, 'ogrenci': 9},
          {'ders': 'Fizik', 'konu': 'Atışlar', 'dogru': 60, 'yanlis': 30, 'bos': 5, 'ogrenci': 6},
        ];
      case 'ogrenci_ozeti':
        return {
          'erisim': rehber ? 'rehber' : 'veli',
          'brans': null,
          'ad': 'Ada Yılmaz',
          'sinif': '11. Sınıf',
          'sube': '11-A',
          'okul': 'Örnek Anadolu Lisesi',
          'gunler': [
            for (var i = 27; i >= 0; i--)
              {
                'gun': gunAnahtari(bugun.subtract(Duration(days: i))),
                'dk': (i * 31) % 150,
                'beyan_dk': 20,
                'plan_blok': 4,
                'plan_tamam': i % 4,
              },
          ],
          'ders_dk': {'Matematik': 420, 'Fizik': 200, 'Türkçe': 150},
          'netler': [
            {'deneme': 'TYT Deneme 3', 'alan': 'TYT', 'net': 72.5, 'tarih': '2026-10-01T10:00:00Z'},
            {'deneme': 'AYT Deneme 1', 'alan': 'AYT', 'net': 41.0, 'tarih': '2026-09-20T10:00:00Z'},
          ],
          'konu': {'tamam': 58, 'zayif': 7, 'gun': '2026-10-08'},
          'testler': [
            {'ders': 'Matematik', 'dogru': 30, 'yanlis': 12, 'bos': 3},
          ],
          'gorusmeler': rehber
              ? [
                  {'id': 'g1', 'not': 'Haftalık program birlikte gözden geçirildi.', 'hedef': 'Günde iki blok matematik', 'tarih': '2026-10-02T09:00:00Z', 'benim': true, 'ogretmen': 'Zeynep Kaya'},
                ]
              : null,
        };
      case 'ogretmen_onerilerim':
        return [
          {'id': 'n1', 'sube_id': 's1', 'sube': '11-A', 'ders': 'Matematik', 'konu': 'Türev: zincir kuralı tekrarı', 'not': 'Çarşamba dersinden önce.', 'sure_dk': 45, 'created_at': '2026-10-06T08:00:00Z', 'ogrenci_sayisi': 28, 'eklendi': 14, 'tamamlandi': 6},
        ];
      case 'onerilerim':
        return [
          {'id': 'n1', 'ders': 'Matematik', 'konu': 'Türev: zincir kuralı tekrarı', 'not': 'Çarşamba dersinden önce.', 'sure_dk': 45, 'created_at': '2026-10-06T08:00:00Z', 'durum': null, 'ogretmen': 'Zeynep Kaya'},
          {'id': 'n2', 'ders': 'Fizik', 'konu': 'Atışlar', 'not': null, 'sure_dk': 30, 'created_at': '2026-10-05T08:00:00Z', 'durum': 'eklendi', 'ogretmen': 'Can Öz'},
          {'id': 'n3', 'ders': 'Kimya', 'konu': 'Mol kavramı', 'not': null, 'sure_dk': 30, 'created_at': '2026-10-04T08:00:00Z', 'durum': 'tamamlandi', 'ogretmen': 'Elif Ak'},
        ];
      case 'sinif_durumum':
        return {'okul': 'Örnek Anadolu Lisesi', 'sube': '11-A', 'uye': 28, 'calisan': 4, 'hafta_dk': 5200, 'toplam_dk': 9150, 'benim_hafta_dk': 310, 'katilan': 19};
      case 'veli_baglantilarim':
        return [
          {'id': 'b1', 'durum': 'aktif', 'kod': null, 'ben_ogrenci': true, 'karsi_id': 'v1', 'karsi_ad': 'Ayşe Yılmaz'},
          {'id': 'b2', 'durum': 'bekliyor', 'kod': 'VABCD2345', 'ben_ogrenci': true, 'karsi_id': null, 'karsi_ad': 'Veli', 'son_gecerlilik': '2026-10-15T00:00:00Z'},
        ];
      case 'okul_ozeti':
        return {
          'okul': 'Örnek Anadolu Lisesi',
          'tarih': '2026-10-08',
          'ogrenci': 52,
          'ogretmen': 5,
          'veli': 17,
          'subeler': [
            {'id': 's1', 'sinif': '11', 'ad': 'A', 'ogrenci': 28, 'aktif_7g': 19, 'ort_dk_7g': 245, 'toplam_dk_7g': 6860, 'risk': 3, 'plan_blok': 300, 'plan_tamam': 190},
            {'id': 's2', 'sinif': '12', 'ad': 'FEN-1', 'ogrenci': 24, 'aktif_7g': 20, 'ort_dk_7g': 410, 'toplam_dk_7g': 9840, 'risk': 0, 'plan_blok': 280, 'plan_tamam': 230},
          ],
          'haftalar': [
            for (var i = 7; i >= 0; i--)
              {'bas': gunAnahtari(haftaBaslangici(bugun).subtract(Duration(days: 7 * i))), 'toplam_dk': 4000 + (7 - i) * 1800, 'aktif': 20 + (7 - i)},
          ],
        };
      case 'okul_yonetim_ozeti':
        return {
          'okul': {'id': 'ok1', 'ad': 'Örnek Anadolu Lisesi', 'il': 'İzmir', 'ilce': 'Bornova'},
          'subeler': [
            {'id': 's1', 'sinif': '11', 'ad': 'A', 'kod': 'SABCD2345', 'ogrenci_sayisi': 28, 'ogretmenler': ['Zeynep Kaya', 'Can Öz']},
            {'id': 's2', 'sinif': '12', 'ad': 'FEN-1', 'kod': 'SWXYZ6789', 'ogrenci_sayisi': 0, 'ogretmenler': []},
          ],
          'ogretmenler': [
            {'id': 't1', 'ad': 'Zeynep Kaya', 'rehber': true, 'brans': null, 'sube_ids': ['s1']},
            {'id': 't2', 'ad': 'Can Öz', 'rehber': false, 'brans': 'Fizik', 'sube_ids': []},
          ],
          'davetler': [
            {'kod': 'TABCD2345', 'rehber': false, 'brans': 'Kimya', 'son_gecerlilik': '2026-10-20T00:00:00Z'},
          ],
        };
      case 'admin_okullar':
        return [
          {'id': 'ok1', 'ad': 'Örnek Anadolu Lisesi', 'il': 'İzmir', 'ilce': 'Bornova', 'aktif': true, 'ogrenci': 52, 'ogretmen': 5, 'mudurler': ['Mehmet Aydın'], 'bekleyen_kod': null},
          {'id': 'ok2', 'ad': 'Yeni Kurs Merkezi', 'il': 'Ankara', 'ilce': '', 'aktif': false, 'ogrenci': 0, 'ogretmen': 0, 'mudurler': [], 'bekleyen_kod': 'MABCD2345'},
        ];
      case 'okul_kodu_kullan':
        return {'durum': 'gecersiz'};
      default:
        return null;
    }
  }
}

void main() {
  late _SahteSunucu sunucu;
  late SharedPrefsStorageService depo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    depo = SharedPrefsStorageService();
    await depo.init();
    sunucu = _SahteSunucu();
    OkulService.sahteCagri = sunucu.cagir;
  });

  tearDown(() => OkulService.sahteCagri = null);

  Future<void> ac(WidgetTester tester, AppTheme tema, Widget ekran, {OkulDurumu? durum, Size boyut = const Size(360, 720)}) async {
    tester.view.physicalSize = boyut * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(depo),
          localStorageServiceProvider.overrideWithValue(depo),
          okulDurumuProvider.overrideWith((ref) async => durum),
        ],
        child: MaterialApp(theme: temaVerisi(tema), home: ekran),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// Sayfayı sonuna kadar kaydırıp her adımda taşma hatası olmadığını denetler.
  Future<void> kaydir(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      final liste = find.byType(Scrollable);
      if (liste.evaluate().isEmpty) return;
      await tester.drag(liste.first, const Offset(0, -500), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    }
  }

  for (final tema in [AppTheme.light, AppTheme.dark]) {
    final ad = tema.gece ? 'gece' : 'gündüz';

    testWidgets('öğretmen paneli: sınıflar, uyarılar, öneriler ($ad)', (tester) async {
      await ac(tester, tema, const OgretmenPaneli(),
          durum: const OkulDurumu(rol: 'teacher', ad: 'Zeynep Kaya', okulAd: 'Örnek Anadolu Lisesi', rehber: true));
      expect(find.text('Sınıflarım'), findsWidgets);
      expect(find.text('11-A'), findsOneWidget);
      expect(find.text('3 uyarı'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await kaydir(tester);

      await tester.tap(find.text('Uyarılar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('2 öğrenci ilgini bekliyor'), findsOneWidget);
      expect(find.text('14 gündür çalışma yok'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Öneriler'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Türev: zincir kuralı tekrarı'), findsOneWidget);
      expect(find.text('14 / 28'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Öneri formu açılır ve taşmaz.
      await tester.tap(find.text('Yeni öneri'));
      await tester.pumpAndSettle();
      expect(find.text('Şubeye öneri gönder'), findsOneWidget);
      expect(tester.takeException(), isNull);
      Navigator.of(tester.element(find.text('Şubeye öneri gönder'))).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hesap'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Zeynep Kaya'), findsOneWidget);
      expect(find.text('Çıkış Yap'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('branş öğretmeni uyarı listesini görmez ($ad)', (tester) async {
      sunucu.rehber = false;
      await ac(tester, tema, const OgretmenPaneli(), durum: const OkulDurumu(rol: 'teacher', ad: 'Can Öz', brans: 'Matematik'));
      expect(find.textContaining('yalnızca Matematik'), findsOneWidget);
      await tester.tap(find.text('Uyarılar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Uyarılar rehber öğretmene gösterilir'), findsOneWidget);
      expect(sunucu.cagrilar, isNot(contains('ogretmen_uyarilari')));
      expect(tester.takeException(), isNull);
    });

    testWidgets('şube detayı: öğrenciler ve konular ($ad)', (tester) async {
      await ac(tester, tema, const SubeDetayScreen(subeId: 's1', etiket: '11-A'));
      expect(find.text('Ada Yılmaz'), findsOneWidget);
      expect(find.text('2 / 3'), findsOneWidget); // bu hafta çalışan
      expect(find.text('Çalışma süresi düşüyor'), findsOneWidget);
      expect(sunucu.parametreler['sube_ozeti'], {'p_sube_id': 's1'});
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Konular'));
      await tester.pumpAndSettle();
      expect(find.text('Trigonometrik Denklemler ve Eşitsizlikler'), findsOneWidget);
      expect(find.text('%33'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('öğrenci detayı: rehber görüşme notlarını görür ($ad)', (tester) async {
      await ac(tester, tema, const OgrenciDetayScreen(ogrenciId: 'o2', ad: 'Ada Yılmaz'));
      expect(find.text('Program uyumu'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await kaydir(tester);
      await tester.dragUntilVisible(find.text('Görüşme notları'), find.byType(Scrollable).first, const Offset(0, -300));
      expect(find.text('Haftalık program birlikte gözden geçirildi.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('veli paneli: özet ve geçmiş ($ad)', (tester) async {
      sunucu.rehber = false;
      await ac(
        tester,
        tema,
        const VeliPaneli(),
        durum: const OkulDurumu(rol: 'parent', ad: 'Ayşe Yılmaz', cocuklar: [
          Cocuk(id: 'o2', ad: 'Ada Yılmaz', sinif: '11. Sınıf'),
          Cocuk(id: 'o4', ad: 'Efe Yılmaz'),
        ]),
      );
      expect(find.text('Ada Yılmaz'), findsWidgets);
      expect(find.text('Çalışılan gün'), findsOneWidget);
      // Veliye görüşme notu gelmez.
      expect(find.text('Görüşme notları'), findsNothing);
      expect(tester.takeException(), isNull);
      await kaydir(tester);
      expect(find.text('Haftalık özet'), findsWidgets);

      await tester.tap(find.text('Geçmiş'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Son 4 hafta'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await kaydir(tester);

      await tester.tap(find.text('Hesap'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Bağlı öğrenciler'), findsOneWidget);
      expect(find.text('Efe Yılmaz'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('veli paneli: bağlı öğrenci yoksa kod ister ($ad)', (tester) async {
      await ac(tester, tema, const VeliPaneli(), durum: const OkulDurumu(rol: 'parent', ad: 'Ayşe'));
      expect(find.text('Henüz bağlı bir öğrenci yok'), findsOneWidget);
      expect(find.text('Veli kodu gir'), findsOneWidget);
      expect(sunucu.cagrilar, isNot(contains('ogrenci_ozeti')));
      expect(tester.takeException(), isNull);
    });

    testWidgets('müdür paneli: özet, yönetim, rapor ($ad)', (tester) async {
      await ac(tester, tema, const MudurPaneli(), durum: const OkulDurumu(rol: 'principal', ad: 'Mehmet Aydın', okulAd: 'Örnek Anadolu Lisesi'));
      expect(find.text('39 / 52'), findsOneWidget);
      expect(find.text('%75 aktif'), findsOneWidget);
      // Müdür panelinde öğrenci adı bulunmaz.
      expect(find.textContaining('Ada Yılmaz'), findsNothing);
      expect(tester.takeException(), isNull);
      await kaydir(tester);

      await tester.tap(find.text('Yönetim'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('S-ABCD-2345'), findsOneWidget);
      expect(find.text('Atanmış öğretmen yok'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await kaydir(tester);
      expect(find.text('T-ABCD-2345'), findsOneWidget);

      await tester.tap(find.text('Rapor'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('DersNet çalışma raporu'), findsOneWidget);
      await tester.dragUntilVisible(find.text('Raporu kopyala'), find.byType(Scrollable).first, const Offset(0, -300));
      expect(tester.takeException(), isNull);
    });

    testWidgets('öğrenci: okul bölümü sınıf ormanı, öneriler ve veli kodu ($ad)', (tester) async {
      await ac(
        tester,
        tema,
        const OkulumScreen(),
        durum: const OkulDurumu(
          rol: 'student',
          ad: 'Ada',
          okulId: 'ok1',
          okulAd: 'Örnek Anadolu Lisesi',
          sube: SubeBilgisi(id: 's1', sinif: '11', ad: 'A'),
        ),
      );
      expect(find.text('Sınıf ormanı'), findsOneWidget);
      expect(find.textContaining('30 ağaç'), findsOneWidget); // 9150 dk / 300
      expect(find.textContaining('4 kişi çalışıyor'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.dragUntilVisible(find.text('Programıma ekle'), find.byType(Scrollable).first, const Offset(0, -250));
      expect(find.text('Tamamladım'), findsOneWidget);
      expect(find.text('Tamamlandı'), findsOneWidget);
      await tester.dragUntilVisible(find.text('V-ABCD-2345'), find.byType(Scrollable).first, const Offset(0, -250));
      expect(find.text('Ayşe Yılmaz'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await kaydir(tester);
      // Kişi sıralaması yoktur: yalnızca şube toplamı ve kendi katkısı.
      expect(find.textContaining('sıralama'), findsOneWidget); // bilgilendirme metni
    });

    testWidgets('öğrenci: okula bağlı değilse şube kodu ister ($ad)', (tester) async {
      await ac(tester, tema, const OkulumScreen(), durum: const OkulDurumu(rol: 'student', ad: 'Ada'));
      expect(find.text('Okuluna katıl'), findsOneWidget);
      expect(find.text('Sınıf ormanı'), findsNothing);
      expect(sunucu.cagrilar, isNot(contains('sinif_durumum')));

      await tester.enterText(find.byType(TextField).first, 's-abcd-2345');
      await tester.tap(find.text('Devam'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // İlk çağrı onaysızdır; sunucu geçersiz dediği için katılım yapılmaz.
      expect(sunucu.parametreler['okul_kodu_kullan'], {'p_kod': 'SABCD2345', 'p_tur': 'ogrenci', 'p_onay': false});
      expect(find.textContaining('Kod geçersiz'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('yönetici: okullar sekmesi ($ad)', (tester) async {
      await ac(tester, tema, const Scaffold(body: AdminOkullarTab()));
      expect(find.text('Örnek Anadolu Lisesi'), findsOneWidget);
      expect(find.text('M-ABCD-2345'), findsOneWidget);
      expect(find.text('Durduruldu'), findsOneWidget);
      expect(find.text('Müdür henüz katılmadı'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('kod ekranı: eksik bilgiyle sunucuya gitmez ($ad)', (tester) async {
      await ac(tester, tema, const RolKoduScreen(), boyut: const Size(360, 640));
      expect(find.text('Veli paneli'), findsOneWidget);
      await tester.tap(find.text('Öğretmen'));
      await tester.pump();
      expect(find.text('Öğretmen paneli'), findsOneWidget);

      await tester.ensureVisible(find.text('Paneli aç'));
      await tester.tap(find.text('Paneli aç'));
      await tester.pump();
      expect(find.text('Adını ve soyadını yaz.'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'Zeynep Kaya');
      await tester.enterText(find.byType(TextField).at(1), 'S-ABCD-2345');
      await tester.ensureVisible(find.text('Paneli aç'));
      await tester.tap(find.text('Paneli aç'));
      await tester.pump();
      // Şube kodu öğretmen/veli/müdür kodu olarak kullanılamaz.
      expect(find.textContaining('Bu bir şube kodu'), findsOneWidget);
      expect(sunucu.cagrilar, isNot(contains('okul_kodu_kullan')));
      expect(tester.takeException(), isNull);
    });
  }

  test('servis: sunucu fonksiyonu kurulu değilse anlaşılır hata verir', () async {
    OkulService.sahteCagri = (fn, params) async => throw const OkulHatasi('Okul özellikleri sunucuda henüz etkinleştirilmedi.', kurulmamis: true);
    await expectLater(
      OkulService.siniflarim(),
      throwsA(isA<OkulHatasi>().having((e) => e.kurulmamis, 'kurulmamis', isTrue)),
    );
    // Rol sorgusu bu durumda profil satırına düşer; o da yoksa hata yutulmaz.
    OkulService.sahteCagri = (fn, params) async => {'rol': 'teacher'};
    expect(await OkulService.rol(), 'teacher');
  });
}
