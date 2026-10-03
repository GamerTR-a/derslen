import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yks_kocu/core/algorithms/analiz_motoru.dart';
import 'package:yks_kocu/core/algorithms/ders_programi.dart';
import 'package:yks_kocu/core/constants/app_constants.dart';
import 'package:yks_kocu/core/constants/yks_data.dart';
import 'package:yks_kocu/core/storage/storage_service.dart';
import 'package:yks_kocu/core/utils/tarih.dart';
import 'package:yks_kocu/data/models/net_kaydi.dart';
import 'package:yks_kocu/data/models/ogrenci_profil.dart';
import 'package:yks_kocu/presentation/providers/konu_provider.dart';
import 'package:yks_kocu/presentation/providers/mufredat_provider.dart';
import 'package:yks_kocu/presentation/providers/profil_provider.dart';

Konu _ozel(int i, String ders, String baslik) => Konu(id: 'ozel-$i', ders: ders, alan: SinavAlani.TYT, baslik: baslik);

void main() {
  const serbestProfil = OgrenciProfil(hedefBolum: 'serbest', gunlukSaat: 3, onboardingTamamlandi: true);

  test('Serbest modda program yalnızca kullanıcının derslerinden oluşur, deneme bloğu eklenmez', () {
    final konular = [
      ...tumKonular,
      _ozel(1, 'Anatomi', 'Kemikler'),
      _ozel(2, 'Anatomi', 'Kaslar'),
      _ozel(3, 'Biyokimya', 'Enzimler'),
    ];
    expect(alanKonulari('serbest', konular).length, 3);
    expect(alanDersleri('serbest', konular), ['Anatomi', 'Biyokimya']);

    final hafta = haftalikProgramOlustur(
      profil: serbestProfil,
      konular: konular,
      ayar: DersProgramiAyar.varsayilan(serbestProfil),
      haftaBaslangic: haftaBaslangici(DateTime.now()),
    );
    final bloklar = hafta.expand((g) => g).where((b) => b.isCalismaBloku).toList();
    expect(bloklar, isNotEmpty);
    expect(bloklar.map((b) => b.ders).toSet(), {'Anatomi', 'Biyokimya'});
  });

  test('YKS alanında eklenen ders programa ve ders listesine girer', () {
    final konular = [...tumKonular, _ozel(1, 'Almanca', 'Artikeller')];
    final dersler = alanDersleri('sayisal', konular);
    expect(dersler.first, 'Matematik');
    expect(dersler.last, 'Almanca');
    expect(dersRengi('Almanca'), dersRengi('Almanca'));
  });

  test('Serbest modda sınav noktası derslerin ortalama puanıdır', () {
    final now = DateTime(2026, 5, 1);
    NetKaydi k(String ders, int puan) => NetKaydi(
          id: ders,
          tarih: '2026-05-01',
          alan: SinavAlani.TYT,
          ders: ders,
          dogru: puan,
          bos: 100 - puan,
          denemeAdi: 'Vize',
          createdAt: now,
        );
    final n = denemeNoktalari([k('Anatomi', 80), k('Biyokimya', 60)], SinavAlani.TYT, ortalama: true);
    expect(n.single.net, 70);
  });

  test('Müfredat sağlayıcısı: ders ekle/sil, hazır konu gizle, serbest moda geçiş', () async {
    SharedPreferences.setMockInitialValues({});
    final depo = SharedPrefsStorageService();
    await depo.init();
    final c = ProviderContainer(overrides: [storageServiceProvider.overrideWithValue(depo)]);
    addTearDown(c.dispose);

    await c.read(profilProvider.notifier).kaydetProfil(hedefBolum: 'sayisal', gunlukSaat: 3, ogrenmeMetod: OgrenmeMetod.dengeli);
    await c.read(konuProvider.notifier).hazir;
    final m = c.read(mufredatProvider.notifier);

    expect(c.read(konuProvider).length, tumKonular.length);

    await m.dersEkle('Almanca', ['Artikeller', 'Fiiller', 'artikeller']);
    await m.dersEkle('Staj');
    expect(c.read(mufredatProvider).ozelDersler, ['Almanca', 'Staj']);
    expect(c.read(konuProvider).where((k) => k.ozel).length, 3, reason: 'yinelenen konu eklenmez, konusuz derse Genel konular açılır');

    await m.hazirDersGizle(SinavAlani.AYT, 'Fizik', true);
    expect(c.read(konuProvider).any((k) => k.alan == SinavAlani.AYT && k.ders == 'Fizik'), isFalse);

    // Tamamlandı işareti, müfredat yeniden kurulunca korunur.
    final almanca = c.read(konuProvider).firstWhere((k) => k.ders == 'Almanca');
    await c.read(konuProvider.notifier).toggleTamamlandi(almanca.id);
    await m.hazirDersGizle(SinavAlani.AYT, 'Fizik', false);
    expect(c.read(konuProvider).firstWhere((k) => k.id == almanca.id).tamamlandi, isTrue);
    expect(c.read(konuProvider).length, tumKonular.length + 3);

    // Serbest moda geçince hazır YKS konuları kalkar.
    await c.read(profilProvider.notifier).kaydetProfil(hedefBolum: 'serbest', gunlukSaat: 3, ogrenmeMetod: OgrenmeMetod.dengeli);
    expect(c.read(serbestModProvider), isTrue);
    expect(c.read(konuProvider).every((k) => k.ozel), isTrue);
    expect(c.read(hedefGeriSayimProvider), isNull);

    await m.hedefAyarla(ad: 'Finaller', tarih: DateTime.now().add(const Duration(days: 10)));
    expect(c.read(hedefGeriSayimProvider), ('Finaller', 10));

    await m.dersSil('Staj');
    expect(c.read(mufredatProvider).ozelDersler, ['Almanca']);

    // Kalıcılık: yeni kapsayıcı aynı müfredatı yükler.
    final c2 = ProviderContainer(overrides: [storageServiceProvider.overrideWithValue(depo)]);
    addTearDown(c2.dispose);
    await c2.read(mufredatProvider.notifier).hazir;
    expect(c2.read(mufredatProvider).ozelDersler, ['Almanca']);
    expect(c2.read(mufredatProvider).hedefAd, 'Finaller');
  });
}
