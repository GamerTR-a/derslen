/// Koç Asistanı sohbet durumu.
///
/// Her mesajda önce niyet bulunur. Ders ve sınav soruları önce cihazdaki
/// kartlar ve YKS rehberinde aranır; güçlü bir eşleşme varsa yanıt cihazdan
/// verilir (ücretsiz, kotasız). Bulut yanıtları açıksa (açık rıza + günlük
/// hak) geri kalan sorular, çalışma özeti ve bulunan notlarla birlikte
/// `koc-asistan` Edge Function'ına (Claude) gider; kapalıysa ya da
/// ulaşılamazsa cihaz içi motor yanıtlar. Program önerileri her zaman cihaz içi motordan gelir ve
/// tek dokunuşla uygulanabilir. Sohbet yalnızca bellekte tutulur.
library;

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/algorithms/analiz_motoru.dart';
import '../../core/algorithms/asistan_motoru.dart';
import '../../core/algorithms/bilgi_motoru.dart';
import '../../core/algorithms/ders_programi.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/sinif_mufredati.dart';
import '../../core/constants/soru_havuzu.dart';
import '../../core/services/ambiyans_service.dart';
import '../../core/services/etut_odasi_service.dart';
import '../../core/services/supabase_data_service.dart';
import '../../core/utils/tarih.dart';
import '../../data/models/net_kaydi.dart';
import 'analiz_provider.dart';
import 'auth_provider.dart';
import 'bahce_provider.dart';
import 'flashkart_provider.dart';
import 'konu_provider.dart';
import 'mufredat_provider.dart';
import 'net_provider.dart';
import 'odak_provider.dart';
import 'okul_provider.dart';
import 'ortam_provider.dart';
import 'plan_provider.dart';
import 'profil_provider.dart';
import 'test_provider.dart';

class AsistanMesaji {
  final bool kullanici;
  final String metin;
  final List<String> maddeler;
  final List<AsistanAksiyon> aksiyonlar;
  final bool bulut;
  final String? not;

  const AsistanMesaji({
    required this.kullanici,
    required this.metin,
    this.maddeler = const [],
    this.aksiyonlar = const [],
    this.bulut = false,
    this.not,
  });

  factory AsistanMesaji.yanit(AsistanYaniti y, {bool bulut = false, String? not}) =>
      AsistanMesaji(kullanici: false, metin: y.metin, maddeler: y.maddeler, aksiyonlar: y.aksiyonlar, bulut: bulut, not: not);

  String get duzMetin => [metin, for (final m in maddeler) '- $m'].join('\n');
}

class AsistanState {
  final List<AsistanMesaji> mesajlar;
  final bool yaziyor;

  /// Sunucuda açık rıza kayıtlı mı (null: bilinmiyor / çevrimdışı).
  final bool? bulutOnay;
  final int? kalanHak;

  const AsistanState({this.mesajlar = const [], this.yaziyor = false, this.bulutOnay, this.kalanHak});

  bool get bulutAcik => bulutOnay == true;

  AsistanState copyWith({List<AsistanMesaji>? mesajlar, bool? yaziyor, bool? bulutOnay, int? kalanHak}) => AsistanState(
        mesajlar: mesajlar ?? this.mesajlar,
        yaziyor: yaziyor ?? this.yaziyor,
        bulutOnay: bulutOnay ?? this.bulutOnay,
        kalanHak: kalanHak ?? this.kalanHak,
      );
}

class AsistanNotifier extends StateNotifier<AsistanState> {
  final Ref _ref;

  AsistanNotifier(this._ref) : super(const AsistanState());

  static const _niyetEtiketleri = {
    AsistanNiyet.denemeAnalizi: 'Son denememi analiz et',
    AsistanNiyet.denemeEkle: 'Deneme eklemek istiyorum',
    AsistanNiyet.hedefNet: 'Sınava kadar kaç net yaparım?',
    AsistanNiyet.programIncele: 'Ders programıma bak',
    AsistanNiyet.programIyilestir: 'Programımı iyileştir',
    AsistanNiyet.zayifDersler: 'Zayıf derslerim neler?',
    AsistanNiyet.konuDurumu: 'Hangi konular kaldı?',
    AsistanNiyet.haftaOzeti: 'Bu haftam nasıl?',
    AsistanNiyet.testCoz: 'Test çözmek istiyorum',
    AsistanNiyet.kartTekrar: 'Kartlarımı tekrar edeyim',
    AsistanNiyet.odakBaslat: 'Odak seansı başlat',
    AsistanNiyet.arkaPlanSesi: 'Arka plan sesi öner',
    AsistanNiyet.bahce: 'Bahçem nasıl?',
    AsistanNiyet.mola: 'Mola vermek istiyorum',
    AsistanNiyet.etutOdasi: 'Etüt odam nasıl?',
  };

  /// Sohbetteki hızlı öneri çipleri.
  static const hizliNiyetler = [
    AsistanNiyet.denemeAnalizi,
    AsistanNiyet.testCoz,
    AsistanNiyet.kartTekrar,
    AsistanNiyet.odakBaslat,
    AsistanNiyet.programIyilestir,
    AsistanNiyet.hedefNet,
    AsistanNiyet.zayifDersler,
    AsistanNiyet.konuDurumu,
    AsistanNiyet.etutOdasi,
    AsistanNiyet.haftaOzeti,
    AsistanNiyet.bahce,
    AsistanNiyet.mola,
  ];

  static String niyetEtiketi(AsistanNiyet n) => _niyetEtiketleri[n] ?? 'Yardım';

  void _ekle(AsistanMesaji m) => state = state.copyWith(mesajlar: [...state.mesajlar, m]);

  /// Sohbet ilk açıldığında karşılama + o anki duruma uygun öneri.
  void karsilama(String oneri, {AsistanAksiyon? aksiyon}) {
    if (state.mesajlar.isNotEmpty) return;
    _ekle(AsistanMesaji(
      kullanici: false,
      metin: 'Merhaba! Denemelerini analiz edebilir, ders programını birlikte iyileştirebiliriz. $oneri',
      aksiyonlar: [?aksiyon],
    ));
  }

  /// Okul hesabında asistan yalnızca cihaz içi çalışır: öğrencinin verisi
  /// okulun bilgisi dışında bir yapay zeka servisine gönderilmez.
  bool get _okulHesabi => _ref.read(okulModuProvider);

  Future<void> bulutDurumunuYenile() async {
    if (_okulHesabi) {
      state = AsistanState(mesajlar: state.mesajlar, yaziyor: state.yaziyor);
      return;
    }
    final d = await AsistanBulutServisi.durum();
    if (d == null || !mounted) return;
    state = state.copyWith(bulutOnay: d.$1, kalanHak: d.$2);
  }

  Future<bool> bulutuAc() async {
    if (_okulHesabi) return false;
    try {
      await AsistanBulutServisi.onayVer();
      await bulutDurumunuYenile();
      return state.bulutAcik;
    } catch (_) {
      return false;
    }
  }

  Future<void> bulutuKapat() async {
    try {
      await AsistanBulutServisi.onayGeriAl();
    } catch (_) {}
    if (mounted) state = state.copyWith(bulutOnay: false);
  }

  /// Hızlı öneri çiplerinden ya da mesajdaki düğmelerden.
  Future<void> niyetCalistir(AsistanNiyet niyet) => gonder(niyetEtiketi(niyet), niyet: niyet);

  /// [bulutZorla]: cihazın yanıtlayabildiği bir ders sorusunu öğrencinin
  /// isteğiyle yapay zekaya da sorar.
  Future<void> gonder(String metin, {AsistanNiyet? niyet, bool bulutZorla = false}) async {
    final temiz = metin.trim();
    if (temiz.isEmpty || state.yaziyor) return;
    final n = bulutZorla ? AsistanNiyet.dersSorusu : (niyet ?? niyetBul(temiz));
    final bilgi = n == AsistanNiyet.dersSorusu ? bilgiAra(temiz) : null;
    final gecmis = [
      for (final m in state.mesajlar.skip(state.mesajlar.length > 12 ? state.mesajlar.length - 12 : 0))
        {'rol': m.kullanici ? 'user' : 'assistant', 'metin': m.duzMetin},
    ];
    _ekle(AsistanMesaji(kullanici: true, metin: temiz));
    state = state.copyWith(yaziyor: true);

    try {
      final veri = await _veri();
      final yerel = await _yerelYanit(n, temiz, veri, bilgi);

      // Program önerisi, uygulama içi işlemler (test, kart, odak, ses, bahçe,
      // etüt odası) ve ağır durum (kriz) yanıtları her zaman cihazdan: bu
      // yanıtlar gerçek verilere ve tek dokunuşla çalışan düğmelere dayanır.
      const uygulamaIci = {
        AsistanNiyet.programIyilestir,
        AsistanNiyet.denemeEkle,
        AsistanNiyet.testCoz,
        AsistanNiyet.kartTekrar,
        AsistanNiyet.odakBaslat,
        AsistanNiyet.arkaPlanSesi,
        AsistanNiyet.bahce,
        AsistanNiyet.etutOdasi,
        AsistanNiyet.mola,
        AsistanNiyet.netHesapla,
      };
      // Notlarda güçlü karşılığı olan ders sorusu da cihazdan yanıtlanır;
      // böylece bulut hakkı yalnızca gerçekten gereken sorulara harcanır.
      final yalnizYerel = uygulamaIci.contains(n) ||
          (n == AsistanNiyet.motivasyon && yerel.maddeler.isEmpty) ||
          (bilgi != null && bilgi.guclu && !bulutZorla);
      if (!state.bulutAcik || _okulHesabi || veri == null || yalnizYerel) {
        _ekle(AsistanMesaji.yanit(yerel));
        return;
      }

      try {
        final yanit = await AsistanBulutServisi.sor(
          mesaj: temiz,
          baglam: veri.baglam,
          gecmis: gecmis,
          kaynaklar: [
            if (bilgi != null)
              for (final e in bilgi.eslesmeler.take(3)) e.belge.kaynakMetni,
          ],
        );
        _ekle(AsistanMesaji(
          kullanici: false,
          metin: yanit,
          aksiyonlar: [for (final a in yerel.aksiyonlar) if (a.bulutSorusu == null) a],
          bulut: true,
        ));
        state = state.copyWith(kalanHak: state.kalanHak == null ? null : (state.kalanHak! - 1).clamp(0, 999));
      } on AsistanHatasi catch (e) {
        final not = switch (e.kod) {
          'limit' => 'Bugünkü bulut yanıt hakkın doldu; cihazdaki analizle yanıtladım. Yarın yenilenir.',
          'no_consent' => 'Bulut yanıtları kapalı; cihazdaki analizle yanıtladım.',
          'busy' => 'Yapay zeka şu an çok yoğun; cihazdaki analizle yanıtladım. Biraz sonra tekrar deneyebilirsin.',
          _ => 'Yapay zeka sunucusuna ulaşılamadı; cihazdaki analizle yanıtladım.',
        };
        if (e.kod == 'no_consent') state = state.copyWith(bulutOnay: false);
        if (e.kod == 'limit') state = state.copyWith(kalanHak: 0);
        _ekle(AsistanMesaji.yanit(yerel, not: not));
      }
    } catch (_) {
      _ekle(const AsistanMesaji(kullanici: false, metin: 'Verilerini okurken bir sorun oldu. Biraz sonra tekrar dener misin?'));
    } finally {
      if (mounted) state = state.copyWith(yaziyor: false);
    }
  }

  Future<AsistanYaniti> _yerelYanit(AsistanNiyet n, String metin, _AsistanVerisi? v, BilgiSonucu? bilgi) async {
    // Profilden bağımsız çalışabilenler.
    switch (n) {
      case AsistanNiyet.dersSorusu:
        return bilgiYaniti(
          mesaj: metin,
          sonuc: bilgi ?? bilgiAra(metin),
          havuzDersleri: _havuzDersleri,
          bulutAcik: state.bulutAcik && v != null,
          kalanGun: _ref.read(serbestModProvider) ? null : yksKalanGun(),
        );
      case AsistanNiyet.netHesapla:
        final (d, y) = mesajdakiDogruYanlis(metin) ?? (0, 0);
        return netHesabiYaniti(d, y);
      case AsistanNiyet.arkaPlanSesi:
        return _sesYaniti(metin);
      case AsistanNiyet.etutOdasi:
        return _etutYaniti();
      case AsistanNiyet.bahce:
        final b = _ref.read(bahceProvider);
        return bahceYaniti(
          yildiz: b.yildiz,
          damla: b.damla,
          ekili: b.ekiliBitki,
          susuz: b.susuzBitki,
          olgun: b.saksilar.where((x) => !x.bos && x.olgun).length,
          bosSaksi: b.saksilar.where((x) => x.bos).length,
          tohum: b.envanter.values.fold(0, (t, v) => t + v),
        );
      case AsistanNiyet.mola:
        return molaYaniti(gecenDakika: _ref.read(odakProvider).gecenDakika);
      case AsistanNiyet.kartTekrar:
        final k = _ref.read(flashkartProvider);
        return kartTekrarYaniti(
          bekleyen: _ref.read(desteDueSayilariProvider),
          desteAdlari: dersEtiketleri,
          yanlisToplam: k.desteKartlari(yanlisDeste).length,
          kalanYeniKart: k.kalanYeniKart,
        );
      case AsistanNiyet.denemeEkle:
        return denemeEkleYaniti();
      case AsistanNiyet.motivasyon:
        return motivasyonYaniti(metin);
      default:
        break;
    }
    if (v == null) {
      return const AsistanYaniti('Önce profilini (hedef alan ve günlük çalışma süresi) tamamlaman gerekiyor; sonra analizlerine başlayabilirim.');
    }
    switch (n) {
      case AsistanNiyet.denemeAnalizi:
        return denemeAnaliziYaniti(v.netler);
      case AsistanNiyet.zayifDersler:
        return zayifDerslerYaniti(netler: v.netler, konular: v.girdi.konular, profil: v.girdi.profil);
      case AsistanNiyet.programIyilestir:
        final ayar = v.program.ayar;
        if (ayar == null) {
          return const AsistanYaniti('Programın henüz hazır değil; birkaç saniye sonra tekrar dene.',
              aksiyonlar: [AsistanAksiyon.rota('Programımı aç', '/program')]);
        }
        return programOnerisiYaniti(programOnerisi(
          profil: v.girdi.profil,
          ayar: ayar,
          analiz: v.analiz30,
          netler: v.netler,
          konular: v.girdi.konular,
        ));
      case AsistanNiyet.programIncele:
        return programIncelemeYaniti(
          hafta: v.program.hafta,
          ayar: v.program.ayar,
          bugun: _ref.read(gunlukPlanProvider),
          planUyumu: v.analiz30.planUyumu,
        );
      case AsistanNiyet.haftaOzeti:
        return haftaOzetiYaniti(donemAnalizi(v.girdi, 7));
      case AsistanNiyet.hedefNet:
        if (_ref.read(serbestModProvider)) {
          final m = _ref.read(mufredatProvider);
          final gun = m.hedefeKalanGun;
          return AsistanYaniti(
            gun == null
                ? 'Serbest müfredatta hedef sınav tarihin kayıtlı değil. Müfredatım ekranından sınav adını ve tarihini eklersen geri sayımı ve temponu buna göre yorumlarım.'
                : '${m.hedefAd ?? 'Sınavına'} $gun gün kaldı. Sınav sonuçlarını Sonuçlar ekranına 100 üzerinden girersen ders ders gidişatını çıkarırım.',
            aksiyonlar: const [
              AsistanAksiyon.rota('Müfredatım', '/mufredat'),
              AsistanAksiyon.rota('Sınav sonucu ekle', '/netler'),
            ],
          );
        }
        return hedefNetYaniti(netler: v.netler, mesaj: metin);
      case AsistanNiyet.konuDurumu:
        return konuDurumuYaniti(konular: v.girdi.konular, profil: v.girdi.profil);
      case AsistanNiyet.testCoz when _ref.read(serbestModProvider):
        return const AsistanYaniti(
          'Hazır soru havuzu YKS derslerini içeriyor; kendi derslerin için hazır test yok. Bunun yerine önemli tanım ve formülleri karta dönüştürüp aralıklı tekrar edebilirsin.',
          aksiyonlar: [
            AsistanAksiyon.komut('Kartlarım destesini aç', AsistanKomut.deste('ozel')),
            AsistanAksiyon.rota('YKS soru havuzuna bak', '/test-olustur'),
          ],
        );
      case AsistanNiyet.testCoz:
        final sayilar = <String, int>{};
        for (final soru in soruHavuzu) {
          sayilar[soru.ders] = (sayilar[soru.ders] ?? 0) + 1;
        }
        return testOnerisiYaniti(
          zayifSira: zayifDersSiralamasi(netler: v.netler, konular: v.girdi.konular, profil: v.girdi.profil),
          havuzSayilari: sayilar,
          testler: v.girdi.testler,
          mesaj: metin,
        );
      case AsistanNiyet.odakBaslat:
        final odak = _ref.read(odakProvider);
        final siradaki = _ref.read(gunlukPlanProvider).where((b) => b.isCalismaBloku && !b.tamamlandi && b.ders != 'Deneme').firstOrNull;
        final zayif = zayifDersSiralamasi(netler: v.netler, konular: v.girdi.konular, profil: v.girdi.profil).firstOrNull;
        return odakYaniti(
          seansSuruyor: odak.aktif,
          gecenDakika: odak.gecenDakika,
          siradakiDers: siradaki == null ? null : odakDersAdi(siradaki.ders ?? 'Genel'),
          siradakiKonu: siradaki?.konu,
          siradakiSure: siradaki?.sure,
          zayifDers: zayif == null ? null : odakDersAdi(zayif),
          bugunDk: v.girdi.calismaGunluk[gunAnahtari(DateTime.now())] ?? 0,
          hedefDk: v.girdi.profil.gunlukSaat * 60,
        );
      case AsistanNiyet.yardim:
        return yardimYaniti(bulutAcik: state.bulutAcik);
      case AsistanNiyet.denemeEkle ||
            AsistanNiyet.arkaPlanSesi ||
            AsistanNiyet.etutOdasi ||
            AsistanNiyet.bahce ||
            AsistanNiyet.mola ||
            AsistanNiyet.kartTekrar ||
            AsistanNiyet.motivasyon ||
            AsistanNiyet.dersSorusu ||
            AsistanNiyet.netHesapla:
        return yardimYaniti(bulutAcik: state.bulutAcik);
    }
  }

  static final Set<String> _havuzDersleri = {for (final s in soruHavuzu) s.ders};

  /// Mesajda adı geçen arka plan sesini bulur; yoksa zaman ve duruma göre öneri.
  AsistanYaniti _sesYaniti(String metin) {
    final m = turkceKucuk(metin);
    const anahtarlar = {
      AmbiyansSes.firtina: ['fırtına', 'gök gürültü', 'şimşek'],
      AmbiyansSes.yagmur: ['yağmur'],
      AmbiyansSes.okyanus: ['okyanus', 'dalga', 'deniz'],
      AmbiyansSes.dere: ['dere', 'şelale', 'akarsu', 'su sesi'],
      AmbiyansSes.ruzgar: ['rüzgar', 'rüzgâr'],
      AmbiyansSes.orman: ['orman', 'kuş'],
      AmbiyansSes.somine: ['şömine', 'ateş', 'odun'],
      AmbiyansSes.kafe: ['kafe', 'kahve', 'kalabalık'],
      AmbiyansSes.saat: ['saat', 'tik'],
      AmbiyansSes.fan: ['vantilatör', 'fan', 'klima'],
      AmbiyansSes.pembe: ['pembe'],
      AmbiyansSes.derin: ['kahverengi', 'derin'],
      AmbiyansSes.beyaz: ['beyaz'],
      AmbiyansSes.alfa: ['alfa', 'binoral', 'binaural'],
      AmbiyansSes.sessiz: ['kapat', 'sustur', 'sessiz', 'durdur'],
    };
    AmbiyansSes? secilen;
    for (final e in anahtarlar.entries) {
      if (e.value.any(m.contains)) {
        secilen = e.key;
        break;
      }
    }
    final ortam = _ref.read(ortamProvider);
    if (secilen == AmbiyansSes.sessiz) {
      return const AsistanYaniti('Arka plan sesini kapatabilirim.',
          aksiyonlar: [AsistanAksiyon.komut('Sesi kapat', AsistanKomut.ses('sessiz'))]);
    }
    if (secilen != null) {
      return AsistanYaniti(
        '“${secilen.etiket}” sesini açıp seçili yapabilirim. Odak seansı sürerken çalar; ses seviyesini Çalış › Manzara ve ses bölümünden ayarlayabilirsin.',
        aksiyonlar: [
          AsistanAksiyon.komut('${secilen.etiket} çal', AsistanKomut.ses(secilen.name)),
          const AsistanAksiyon.niyet('Odak seansı başlat', AsistanNiyet.odakBaslat),
        ],
      );
    }
    final saat = DateTime.now().hour;
    final oneriler = saat >= 21 || saat < 6
        ? [AmbiyansSes.yagmur, AmbiyansSes.somine, AmbiyansSes.derin]
        : [AmbiyansSes.orman, AmbiyansSes.kafe, AmbiyansSes.pembe];
    return AsistanYaniti(
      'Şu an seçili ses: ${ortam.sesEtiketi}. ${saat >= 21 || saat < 6 ? 'Akşam' : 'Gündüz'} çalışması için önerilerim (kendi ses dosyanı da yükleyebilirsin):',
      maddeler: const [
        'Sözsüz ve düzenli sesler (yağmur, pembe gürültü) dikkat dağıtmadan dış gürültüyü bastırır.',
        'Alfa dalgası kulaklıkla dinlendiğinde etkilidir.',
      ],
      aksiyonlar: [
        for (final a in oneriler) AsistanAksiyon.komut(a.etiket, AsistanKomut.ses(a.name)),
        const AsistanAksiyon.rota('Tüm sesler', '/calis'),
      ],
    );
  }

  Future<AsistanYaniti> _etutYaniti() async {
    try {
      final odalar = await EtutOdasiService.odalar();
      final benim = odalar.where((o) => o.benim).firstOrNull;
      if (benim == null) {
        final oneri = (odalar.where((o) => !o.dolu).toList()..sort((a, b) => b.calisanSayisi.compareTo(a.calisanSayisi))).take(3);
        return AsistanYaniti(
          'Henüz bir etüt odasında değilsin. Katıldığın andan itibaren odak sürene göre sıralanırsın. Şu an en hareketli odalar:',
          maddeler: [for (final o in oneri) '${o.ad}: ${o.uyeSayisi}/${o.kapasite} üye, ${o.calisanSayisi} kişi çalışıyor'],
          aksiyonlar: const [AsistanAksiyon.rota('Etüt odalarını gör', '/study-rooms')],
        );
      }
      final uyeler = await EtutOdasiService.durum(benim.id);
      final ben = uyeler.where((u) => u.ben).firstOrNull;
      final sira = ben == null ? null : uyeler.indexOf(ben) + 1;
      final calisanlar = uyeler.where((u) => u.calisiyor && !u.ben).toList();
      final onumdeki = sira != null && sira > 1 ? uyeler[sira - 2] : null;
      return AsistanYaniti(
        '${benim.ad} odasındasın${sira == null ? '' : ': ${uyeler.length} kişi arasında $sira. sıradasın'}.',
        maddeler: [
          if (ben != null) 'Katıldığından beri ${sureMetni(ben.toplamDk)} çalıştın.',
          if (onumdeki != null && ben != null)
            'Bir üst sıradaki ${onumdeki.ad} ile aranda ${sureMetni(max(0, onumdeki.toplamDk - ben.toplamDk))} fark var; bir odak seansı yetebilir.',
          calisanlar.isEmpty
              ? 'Şu an odada çalışan başka kimse yok; ilk başlatan sen ol!'
              : 'Şu an çalışanlar: ${calisanlar.take(4).map((u) => '${u.ad} (${u.aktifDers ?? 'odak'})').join(', ')}.',
        ],
        aksiyonlar: [
          AsistanAksiyon.rota('Odama git', '/etut-odasi/${benim.id}'),
          const AsistanAksiyon.niyet('Odak seansı başlat', AsistanNiyet.odakBaslat),
        ],
      );
    } on EtutHatasi catch (e) {
      return AsistanYaniti('Etüt odası bilgilerini alamadım: ${e.mesaj}',
          aksiyonlar: const [AsistanAksiyon.rota('Etüt odaları', '/study-rooms')]);
    }
  }

  /// Uygulama içi bir komutu çalıştırır ve sohbete sonucu yazar. Ekran
  /// değişikliği gerekiyorsa gidilecek rotayı döndürür.
  Future<String?> komutCalistir(AsistanKomut k) async {
    switch (k.tur) {
      case AsistanKomutTur.testBaslat:
        final f = _ref.read(testFiltreProvider.notifier);
        // Önerilen ders öğrencinin sınıf müfredatında yoksa tüm havuzdan seçilir.
        final sinif = _ref.read(testFiltreProvider).sinif;
        if (sinif != null && !sinifDersleri(sinif).contains(k.ders)) f.sinifDegistir(null);
        f
          ..dersDegistir(k.ders!)
          ..zorlukDegistir('hepsi')
          ..soruSayisiDegistir(k.sayi);
        _ref.read(aktifTestProvider.notifier).testOlustur(_ref.read(testFiltreProvider));
        if (_ref.read(aktifTestProvider).sorular.isEmpty) {
          f.dersDegistir('hepsi');
          _ekle(AsistanMesaji(kullanici: false, metin: '${k.ders} için havuzda soru bulamadım; test oluşturma ekranından başka bir ders seçebilirsin.'));
          return '/test-olustur';
        }
        return '/test-coz';
      case AsistanKomutTur.desteAc:
        _ref.read(flashkartProvider.notifier).dersSec(k.deste!);
        return '/flashkart';
      case AsistanKomutTur.odakBaslat:
        final odak = _ref.read(odakProvider.notifier);
        if (!_ref.read(odakProvider).aktif) {
          odak
            ..sureSec(k.sayi)
            ..dersSec(k.ders!);
          await odak.baslat();
        }
        return '/calis';
      case AsistanKomutTur.sesCal:
        final ses = AmbiyansSes.values.firstWhere((x) => x.name == k.ses, orElse: () => AmbiyansSes.sessiz);
        await _ref.read(ortamProvider.notifier).sesSec(ses);
        await ambiyansCal(_ref.read(ortamProvider));
        _ekle(AsistanMesaji(
          kullanici: false,
          metin: ses == AmbiyansSes.sessiz
              ? 'Arka plan sesini kapattım.'
              : '“${ses.etiket}” çalıyor ve seçili ses oldu. Kapatmak için “sesi kapat” yazabilirsin.',
        ));
        return null;
    }
  }

  Future<_AsistanVerisi?> _veri() async {
    final girdi = await analizGirdisiHazirla(
      storage: _ref.read(storageServiceProvider),
      profil: _ref.read(profilProvider).value,
      netler: _ref.read(netProvider),
      konular: _ref.read(konuProvider),
      kartlar: _ref.read(flashkartProvider),
    );
    if (girdi == null) return null;
    final analiz30 = donemAnalizi(girdi, 30);
    final program = _ref.read(programProvider);
    final netler = _ref.read(netProvider);
    return _AsistanVerisi(
      girdi: girdi,
      analiz30: analiz30,
      netler: netler,
      program: program,
      baglam: asistanBaglami(
        profil: girdi.profil,
        analiz30: analiz30,
        netler: netler,
        konular: _ref.read(konuProvider),
        ayar: program.ayar,
        hafta: program.hafta,
        bugun: _ref.read(gunlukPlanProvider),
      ),
    );
  }

  /// Önerilen program ayarını uygular ve sonucu sohbete yazar.
  Future<void> programiUygula(DersProgramiAyar ayar) async {
    if (state.yaziyor) return;
    state = state.copyWith(yaziyor: true);
    try {
      final ilkGun = await _ref.read(programProvider.notifier).ayarKaydet(ayar);
      final bugun = DateTime.now().weekday - 1;
      _ekle(AsistanMesaji(
        kullanici: false,
        metin: ilkGun > bugun
            ? 'Önerileri uyguladım. Bugün tamamladığın blok olduğu için yeni program yarından başlıyor.'
            : 'Önerileri uyguladım; programın bugünden itibaren yeniden hazırlandı.',
        aksiyonlar: const [AsistanAksiyon.rota('Yeni programımı gör', '/program')],
      ));
    } catch (_) {
      _ekle(const AsistanMesaji(kullanici: false, metin: 'Programı güncelleyemedim; Programım ekranından tekrar deneyebilirsin.'));
    } finally {
      if (mounted) state = state.copyWith(yaziyor: false);
    }
  }
}

/// Çalış ekranındaki ders adlarıyla eşleştirme (odak seansı için).
String odakDersAdi(String ders) => switch (ders) {
      'Türk Dili ve Edebiyatı' => 'Edebiyat',
      'Fen Bilimleri' => 'Fizik',
      'Sosyal Bilimler' => 'Tarih',
      '' => 'Genel',
      _ => ders,
    };

class _AsistanVerisi {
  final AnalizGirdisi girdi;
  final DonemAnalizi analiz30;
  final List<NetKaydi> netler;
  final ProgramState program;
  final Map<String, dynamic> baglam;

  const _AsistanVerisi({
    required this.girdi,
    required this.analiz30,
    required this.netler,
    required this.program,
    required this.baglam,
  });
}

/// Kullanıcı değişince (çıkış/giriş) sohbet sıfırlanır.
final asistanProvider = StateNotifierProvider<AsistanNotifier, AsistanState>((ref) {
  ref.watch(authProvider.select((s) => s.userId));
  ref.watch(profilProvider.select((p) => p.value?.onboardingTamamlandi));
  return AsistanNotifier(ref);
});
