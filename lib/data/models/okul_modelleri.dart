/// Okul panellerinin (öğretmen, veli, müdür) ve öğrencinin "Okulum" bölümünün
/// veri modelleri. Sunucu tarafı: supabase_migrations/21_okul_yapisi.sql ve
/// 22_okul_raporlama.sql (JSONB döndüren fonksiyonlar).
library;

int _i(dynamic v) => (v as num?)?.toInt() ?? 0;
String _s(dynamic v, [String yedek = '']) => (v as String?) ?? yedek;
DateTime? _t(dynamic v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;
List<Map<String, dynamic>> _liste(dynamic v) =>
    [for (final e in (v as List?) ?? const []) if (e is Map) Map<String, dynamic>.from(e)];

/// Uygulamadaki dört panel. `profiles.role` değerinden türetilir; 'baskan' ve
/// 'admin' öğrenci panelini kullanır.
enum KullaniciRolu {
  ogrenci,
  ogretmen,
  veli,
  mudur;

  static KullaniciRolu coz(String? rol) {
    switch (rol) {
      case 'teacher':
        return KullaniciRolu.ogretmen;
      case 'parent':
        return KullaniciRolu.veli;
      case 'principal':
        return KullaniciRolu.mudur;
      default:
        return KullaniciRolu.ogrenci;
    }
  }

  /// Kayıt akışındaki tür adı (okul_kodu_kullan'ın p_tur değeri).
  String get tur => switch (this) {
        KullaniciRolu.ogrenci => 'ogrenci',
        KullaniciRolu.ogretmen => 'ogretmen',
        KullaniciRolu.veli => 'veli',
        KullaniciRolu.mudur => 'mudur',
      };

  static KullaniciRolu? turden(String? tur) {
    for (final r in KullaniciRolu.values) {
      if (r.tur == tur) return r;
    }
    return null;
  }

  String get etiket => switch (this) {
        KullaniciRolu.ogrenci => 'Öğrenci',
        KullaniciRolu.ogretmen => 'Öğretmen',
        KullaniciRolu.veli => 'Veli',
        KullaniciRolu.mudur => 'Müdür',
      };

  /// Panelin ana rotası.
  String get ev => switch (this) {
        KullaniciRolu.ogrenci => '/ana',
        KullaniciRolu.ogretmen => '/ogretmen',
        KullaniciRolu.veli => '/veli',
        KullaniciRolu.mudur => '/mudur',
      };
}

class SubeBilgisi {
  final String id;
  final String sinif;
  final String ad;

  const SubeBilgisi({required this.id, required this.sinif, required this.ad});

  String get etiket => '$sinif-$ad';

  factory SubeBilgisi.fromJson(Map<String, dynamic> j) =>
      SubeBilgisi(id: _s(j['id']), sinif: _s(j['sinif']), ad: _s(j['ad']));
}

class Cocuk {
  final String id;
  final String ad;
  final String? sinif;

  const Cocuk({required this.id, required this.ad, this.sinif});

  factory Cocuk.fromJson(Map<String, dynamic> j) =>
      Cocuk(id: _s(j['id']), ad: _s(j['ad'], 'Öğrenci'), sinif: j['sinif'] as String?);
}

/// Oturumdaki kullanıcının okul durumu (okul_durumum).
class OkulDurumu {
  final String rol;
  final String ad;
  final String? okulId;
  final String? okulAd;
  final bool okulAktif;
  final SubeBilgisi? sube;
  final bool rehber;
  final String? brans;
  final List<Cocuk> cocuklar;
  final int veliSayisi;

  const OkulDurumu({
    this.rol = 'student',
    this.ad = '',
    this.okulId,
    this.okulAd,
    this.okulAktif = true,
    this.sube,
    this.rehber = false,
    this.brans,
    this.cocuklar = const [],
    this.veliSayisi = 0,
  });

  KullaniciRolu get panel => KullaniciRolu.coz(rol);

  /// Bir okulun şubesine kayıtlı öğrenci: açık topluluk kapalıdır.
  bool get okulOgrencisi => panel == KullaniciRolu.ogrenci && okulId != null && sube != null;

  factory OkulDurumu.fromJson(Map<String, dynamic> j) {
    final okul = j['okul'] is Map ? Map<String, dynamic>.from(j['okul'] as Map) : null;
    final sube = j['sube'] is Map ? Map<String, dynamic>.from(j['sube'] as Map) : null;
    return OkulDurumu(
      rol: _s(j['rol'], 'student'),
      ad: _s(j['ad']),
      okulId: okul?['id'] as String?,
      okulAd: okul?['ad'] as String?,
      okulAktif: okul?['aktif'] as bool? ?? true,
      sube: sube == null ? null : SubeBilgisi.fromJson(sube),
      rehber: j['rehber'] as bool? ?? false,
      brans: j['brans'] as String?,
      cocuklar: [for (final c in _liste(j['cocuklar'])) Cocuk.fromJson(c)],
      veliSayisi: _i(j['veli_sayisi']),
    );
  }
}

/// okul_kodu_kullan sonucu.
class KodSonucu {
  /// 'ok' | 'gecersiz' | 'cok_deneme' | 'rol_uyumsuz' | 'zaten_uye' | 'onay_gerekli'
  final String durum;
  final String? okul;
  final String? sinif;
  final String? sube;
  final String? ogrenci;

  const KodSonucu({required this.durum, this.okul, this.sinif, this.sube, this.ogrenci});

  bool get basarili => durum == 'ok';

  factory KodSonucu.fromJson(Map<String, dynamic> j) => KodSonucu(
        durum: _s(j['durum'], 'gecersiz'),
        okul: j['okul'] as String?,
        sinif: j['sinif'] as String?,
        sube: j['sube'] as String?,
        ogrenci: j['ogrenci'] as String?,
      );
}

class VeliBaglantisi {
  final String id;
  final String durum; // 'bekliyor' | 'aktif'
  final String? kod;
  final String karsiAd;

  /// Bağlantının diğer ucundaki hesabın kimliği (bekleyen kodda null).
  final String? karsiId;
  final bool benOgrenci;
  final DateTime? sonGecerlilik;

  const VeliBaglantisi({
    required this.id,
    required this.durum,
    this.kod,
    required this.karsiAd,
    this.karsiId,
    required this.benOgrenci,
    this.sonGecerlilik,
  });

  bool get aktif => durum == 'aktif';

  factory VeliBaglantisi.fromJson(Map<String, dynamic> j) => VeliBaglantisi(
        id: _s(j['id']),
        durum: _s(j['durum'], 'bekliyor'),
        kod: j['kod'] as String?,
        karsiAd: _s(j['karsi_ad']),
        karsiId: j['karsi_id'] as String?,
        benOgrenci: j['ben_ogrenci'] as bool? ?? false,
        sonGecerlilik: _t(j['son_gecerlilik']),
      );
}

// ─── Öğretmen ────────────────────────────────────────────────────────

class SinifKarti {
  final SubeBilgisi sube;
  final int ogrenciSayisi;
  final int aktif7g;
  final int ortDk7g;
  final int riskSayisi;

  const SinifKarti({
    required this.sube,
    required this.ogrenciSayisi,
    required this.aktif7g,
    required this.ortDk7g,
    required this.riskSayisi,
  });

  factory SinifKarti.fromJson(Map<String, dynamic> j) => SinifKarti(
        sube: SubeBilgisi(id: _s(j['sube_id']), sinif: _s(j['sinif']), ad: _s(j['ad'])),
        ogrenciSayisi: _i(j['ogrenci_sayisi']),
        aktif7g: _i(j['aktif_7g']),
        ortDk7g: _i(j['ort_dk_7g']),
        riskSayisi: _i(j['risk_sayisi']),
      );
}

class OgretmenSiniflari {
  final bool rehber;
  final String? brans;
  final String okul;
  final List<SinifKarti> siniflar;

  const OgretmenSiniflari({required this.rehber, this.brans, required this.okul, required this.siniflar});

  factory OgretmenSiniflari.fromJson(Map<String, dynamic> j) => OgretmenSiniflari(
        rehber: j['rehber'] as bool? ?? false,
        brans: j['brans'] as String?,
        okul: _s(j['okul']),
        siniflar: [for (final s in _liste(j['siniflar'])) SinifKarti.fromJson(s)],
      );
}

/// 'pasif' | 'dusus' | 'yeni' | 'yok'
enum RiskDurumu {
  pasif,
  dusus,
  yeni,
  yok;

  static RiskDurumu coz(String? s) => switch (s) {
        'pasif' => RiskDurumu.pasif,
        'dusus' => RiskDurumu.dusus,
        'yeni' => RiskDurumu.yeni,
        _ => RiskDurumu.yok,
      };

  bool get uyari => this == RiskDurumu.pasif || this == RiskDurumu.dusus;
}

class OgrenciSatiri {
  final String id;
  final String ad;
  final int dk7g;
  final int dkOnceki7g;
  final int aktifGun;
  final int planBlok;
  final int planTamam;
  final DateTime? sonAktif;
  final RiskDurumu risk;

  /// Yalnızca uyarı listesinde dolu ("11-A").
  final String? sube;
  final int dk2Onceki7g;

  const OgrenciSatiri({
    required this.id,
    required this.ad,
    required this.dk7g,
    required this.dkOnceki7g,
    this.aktifGun = 0,
    this.planBlok = 0,
    this.planTamam = 0,
    this.sonAktif,
    this.risk = RiskDurumu.yok,
    this.sube,
    this.dk2Onceki7g = 0,
  });

  /// Program uyumu yüzdesi; program yoksa null.
  int? get planUyumu => planBlok == 0 ? null : (planTamam * 100 / planBlok).round().clamp(0, 100);

  factory OgrenciSatiri.fromJson(Map<String, dynamic> j) => OgrenciSatiri(
        id: _s(j['id']),
        ad: _s(j['ad'], 'Öğrenci'),
        dk7g: _i(j['dk_7g']),
        dkOnceki7g: _i(j['dk_onceki_7g']),
        aktifGun: _i(j['aktif_gun']),
        planBlok: _i(j['plan_blok']),
        planTamam: _i(j['plan_tamam']),
        sonAktif: _t(j['son_aktif']),
        risk: RiskDurumu.coz(j['risk'] as String?),
        sube: j['sube'] as String?,
        dk2Onceki7g: _i(j['dk_2onceki_7g']),
      );
}

class SubeOzeti {
  final SubeBilgisi sube;
  final bool rehber;
  final String? brans;
  final List<OgrenciSatiri> ogrenciler;

  const SubeOzeti({required this.sube, required this.rehber, this.brans, required this.ogrenciler});

  factory SubeOzeti.fromJson(Map<String, dynamic> j) => SubeOzeti(
        sube: SubeBilgisi.fromJson(Map<String, dynamic>.from((j['sube'] as Map?) ?? const {})),
        rehber: j['rehber'] as bool? ?? false,
        brans: j['brans'] as String?,
        ogrenciler: [for (final o in _liste(j['ogrenciler'])) OgrenciSatiri.fromJson(o)],
      );
}

class KonuSatiri {
  final String ders;
  final String konu;
  final int dogru;
  final int yanlis;
  final int bos;
  final int ogrenci;

  const KonuSatiri({
    required this.ders,
    required this.konu,
    required this.dogru,
    required this.yanlis,
    required this.bos,
    required this.ogrenci,
  });

  int get toplam => dogru + yanlis + bos;
  int get basari => toplam == 0 ? 0 : (dogru * 100 / toplam).round();

  factory KonuSatiri.fromJson(Map<String, dynamic> j) => KonuSatiri(
        ders: _s(j['ders']),
        konu: _s(j['konu']),
        dogru: _i(j['dogru']),
        yanlis: _i(j['yanlis']),
        bos: _i(j['bos']),
        ogrenci: _i(j['ogrenci']),
      );
}

// ─── Öğrenci özeti (öğretmen ve veli ortak) ──────────────────────────

class OzetGunu {
  /// YYYY-MM-DD
  final String gun;

  /// Sunucunun ölçtüğü odak süresi.
  final int dk;

  /// Öğrencinin kendi kaydındaki süre.
  final int beyanDk;
  final int planBlok;
  final int planTamam;

  const OzetGunu({required this.gun, this.dk = 0, this.beyanDk = 0, this.planBlok = 0, this.planTamam = 0});

  factory OzetGunu.fromJson(Map<String, dynamic> j) => OzetGunu(
        gun: _s(j['gun']),
        dk: _i(j['dk']),
        beyanDk: _i(j['beyan_dk']),
        planBlok: _i(j['plan_blok']),
        planTamam: _i(j['plan_tamam']),
      );
}

class OzetDenemesi {
  final String deneme;
  final String alan;
  final double net;
  final DateTime? tarih;

  const OzetDenemesi({required this.deneme, required this.alan, required this.net, this.tarih});

  factory OzetDenemesi.fromJson(Map<String, dynamic> j) => OzetDenemesi(
        deneme: _s(j['deneme']),
        alan: _s(j['alan']),
        net: (j['net'] as num?)?.toDouble() ?? 0,
        tarih: _t(j['tarih']),
      );
}

class OzetTesti {
  final String ders;
  final int dogru;
  final int yanlis;
  final int bos;

  const OzetTesti({required this.ders, required this.dogru, required this.yanlis, required this.bos});

  int get toplam => dogru + yanlis + bos;
  int get basari => toplam == 0 ? 0 : (dogru * 100 / toplam).round();

  factory OzetTesti.fromJson(Map<String, dynamic> j) =>
      OzetTesti(ders: _s(j['ders']), dogru: _i(j['dogru']), yanlis: _i(j['yanlis']), bos: _i(j['bos']));
}

class Gorusme {
  final String id;
  final String not;
  final String? hedef;
  final DateTime? tarih;
  final String ogretmen;
  final bool benim;

  const Gorusme({required this.id, required this.not, this.hedef, this.tarih, required this.ogretmen, required this.benim});

  factory Gorusme.fromJson(Map<String, dynamic> j) => Gorusme(
        id: _s(j['id']),
        not: _s(j['not']),
        hedef: j['hedef'] as String?,
        tarih: _t(j['tarih']),
        ogretmen: _s(j['ogretmen'], 'Öğretmen'),
        benim: j['benim'] as bool? ?? false,
      );
}

class OgrenciOzeti {
  /// 'kendi' | 'veli' | 'rehber' | 'brans'
  final String erisim;
  final String? brans;
  final String ad;
  final String? sinif;
  final String? sube;
  final String? okul;

  /// Son 28 gün, eskiden yeniye.
  final List<OzetGunu> gunler;
  final Map<String, int> dersDk;
  final List<OzetDenemesi> netler;
  final int? konuTamam;
  final int? konuZayif;
  final List<OzetTesti> testler;

  /// Yalnızca rehber öğretmene gelir; diğerlerinde null.
  final List<Gorusme>? gorusmeler;

  const OgrenciOzeti({
    required this.erisim,
    this.brans,
    required this.ad,
    this.sinif,
    this.sube,
    this.okul,
    required this.gunler,
    this.dersDk = const {},
    this.netler = const [],
    this.konuTamam,
    this.konuZayif,
    this.testler = const [],
    this.gorusmeler,
  });

  bool get rehberGorunumu => erisim == 'rehber';

  factory OgrenciOzeti.fromJson(Map<String, dynamic> j) {
    final konu = j['konu'] is Map ? Map<String, dynamic>.from(j['konu'] as Map) : null;
    final dersDk = j['ders_dk'] is Map ? Map<String, dynamic>.from(j['ders_dk'] as Map) : const <String, dynamic>{};
    return OgrenciOzeti(
      erisim: _s(j['erisim'], 'veli'),
      brans: j['brans'] as String?,
      ad: _s(j['ad'], 'Öğrenci'),
      sinif: j['sinif'] as String?,
      sube: j['sube'] as String?,
      okul: j['okul'] as String?,
      gunler: [for (final g in _liste(j['gunler'])) OzetGunu.fromJson(g)],
      dersDk: {for (final e in dersDk.entries) e.key: _i(e.value)},
      netler: [for (final n in _liste(j['netler'])) OzetDenemesi.fromJson(n)],
      konuTamam: (konu?['tamam'] as num?)?.toInt(),
      konuZayif: (konu?['zayif'] as num?)?.toInt(),
      testler: [for (final t in _liste(j['testler'])) OzetTesti.fromJson(t)],
      gorusmeler: j['gorusmeler'] == null ? null : [for (final g in _liste(j['gorusmeler'])) Gorusme.fromJson(g)],
    );
  }
}

// ─── Öneriler ────────────────────────────────────────────────────────

class Oneri {
  final String id;
  final String ders;
  final String konu;
  final String? not;
  final int sureDk;
  final DateTime? bitis;
  final DateTime? olusturma;

  /// Öğretmen görünümü.
  final String? sube;
  final int ogrenciSayisi;
  final int eklendi;
  final int tamamlandi;

  /// Öğrenci görünümü: null | 'eklendi' | 'tamamlandi'
  final String? durum;
  final String? ogretmen;

  const Oneri({
    required this.id,
    required this.ders,
    required this.konu,
    this.not,
    this.sureDk = 30,
    this.bitis,
    this.olusturma,
    this.sube,
    this.ogrenciSayisi = 0,
    this.eklendi = 0,
    this.tamamlandi = 0,
    this.durum,
    this.ogretmen,
  });

  factory Oneri.fromJson(Map<String, dynamic> j) => Oneri(
        id: _s(j['id']),
        ders: _s(j['ders']),
        konu: _s(j['konu']),
        not: j['not'] as String?,
        sureDk: _i(j['sure_dk']) == 0 ? 30 : _i(j['sure_dk']),
        bitis: j['bitis'] is String ? DateTime.tryParse(j['bitis'] as String) : null,
        olusturma: _t(j['created_at']),
        sube: j['sube'] as String?,
        ogrenciSayisi: _i(j['ogrenci_sayisi']),
        eklendi: _i(j['eklendi']),
        tamamlandi: _i(j['tamamlandi']),
        durum: j['durum'] as String?,
        ogretmen: j['ogretmen'] as String?,
      );
}

// ─── Öğrenci: sınıfım ────────────────────────────────────────────────

class SinifDurumu {
  final String okul;
  final String sube;
  final int uye;
  final int calisan;
  final int haftaDk;
  final int toplamDk;
  final int benimHaftaDk;
  final int katilan;

  const SinifDurumu({
    required this.okul,
    required this.sube,
    this.uye = 0,
    this.calisan = 0,
    this.haftaDk = 0,
    this.toplamDk = 0,
    this.benimHaftaDk = 0,
    this.katilan = 0,
  });

  factory SinifDurumu.fromJson(Map<String, dynamic> j) => SinifDurumu(
        okul: _s(j['okul']),
        sube: _s(j['sube']),
        uye: _i(j['uye']),
        calisan: _i(j['calisan']),
        haftaDk: _i(j['hafta_dk']),
        toplamDk: _i(j['toplam_dk']),
        benimHaftaDk: _i(j['benim_hafta_dk']),
        katilan: _i(j['katilan']),
      );
}

// ─── Müdür ───────────────────────────────────────────────────────────

class SubeToplami {
  final SubeBilgisi sube;
  final int ogrenci;
  final int aktif7g;
  final int ortDk7g;
  final int toplamDk7g;
  final int risk;
  final int planBlok;
  final int planTamam;

  const SubeToplami({
    required this.sube,
    this.ogrenci = 0,
    this.aktif7g = 0,
    this.ortDk7g = 0,
    this.toplamDk7g = 0,
    this.risk = 0,
    this.planBlok = 0,
    this.planTamam = 0,
  });

  int get aktifOrani => ogrenci == 0 ? 0 : (aktif7g * 100 / ogrenci).round();

  factory SubeToplami.fromJson(Map<String, dynamic> j) => SubeToplami(
        sube: SubeBilgisi.fromJson(j),
        ogrenci: _i(j['ogrenci']),
        aktif7g: _i(j['aktif_7g']),
        ortDk7g: _i(j['ort_dk_7g']),
        toplamDk7g: _i(j['toplam_dk_7g']),
        risk: _i(j['risk']),
        planBlok: _i(j['plan_blok']),
        planTamam: _i(j['plan_tamam']),
      );
}

class HaftaToplami {
  /// Haftanın pazartesisi (YYYY-MM-DD).
  final String bas;
  final int toplamDk;
  final int aktif;

  const HaftaToplami({required this.bas, this.toplamDk = 0, this.aktif = 0});

  factory HaftaToplami.fromJson(Map<String, dynamic> j) =>
      HaftaToplami(bas: _s(j['bas']), toplamDk: _i(j['toplam_dk']), aktif: _i(j['aktif']));
}

class OkulOzeti {
  final String okul;
  final String tarih;
  final int ogrenci;
  final int ogretmen;
  final int veli;
  final List<SubeToplami> subeler;
  final List<HaftaToplami> haftalar;

  const OkulOzeti({
    required this.okul,
    required this.tarih,
    this.ogrenci = 0,
    this.ogretmen = 0,
    this.veli = 0,
    this.subeler = const [],
    this.haftalar = const [],
  });

  int get aktif7g => subeler.fold(0, (t, s) => t + s.aktif7g);
  int get risk => subeler.fold(0, (t, s) => t + s.risk);
  int get toplamDk7g => subeler.fold(0, (t, s) => t + s.toplamDk7g);
  int get aktifOrani => ogrenci == 0 ? 0 : (aktif7g * 100 / ogrenci).round();
  int get ortDk7g => ogrenci == 0 ? 0 : (toplamDk7g / ogrenci).round();

  factory OkulOzeti.fromJson(Map<String, dynamic> j) => OkulOzeti(
        okul: _s(j['okul']),
        tarih: _s(j['tarih']),
        ogrenci: _i(j['ogrenci']),
        ogretmen: _i(j['ogretmen']),
        veli: _i(j['veli']),
        subeler: [for (final s in _liste(j['subeler'])) SubeToplami.fromJson(s)],
        haftalar: [for (final h in _liste(j['haftalar'])) HaftaToplami.fromJson(h)],
      );
}

class YonetimSubesi {
  final SubeBilgisi sube;
  final String kod;
  final int ogrenciSayisi;
  final List<String> ogretmenler;

  const YonetimSubesi({required this.sube, required this.kod, this.ogrenciSayisi = 0, this.ogretmenler = const []});

  factory YonetimSubesi.fromJson(Map<String, dynamic> j) => YonetimSubesi(
        sube: SubeBilgisi.fromJson(j),
        kod: _s(j['kod']),
        ogrenciSayisi: _i(j['ogrenci_sayisi']),
        ogretmenler: [for (final o in (j['ogretmenler'] as List?) ?? const []) '$o'],
      );
}

class YonetimOgretmeni {
  final String id;
  final String ad;
  final bool rehber;
  final String? brans;
  final Set<String> subeIdleri;

  const YonetimOgretmeni({required this.id, required this.ad, this.rehber = false, this.brans, this.subeIdleri = const {}});

  String get gorev => rehber ? 'Rehber öğretmen' : (brans ?? 'Branş öğretmeni');

  factory YonetimOgretmeni.fromJson(Map<String, dynamic> j) => YonetimOgretmeni(
        id: _s(j['id']),
        ad: _s(j['ad'], 'Öğretmen'),
        rehber: j['rehber'] as bool? ?? false,
        brans: j['brans'] as String?,
        subeIdleri: {for (final s in (j['sube_ids'] as List?) ?? const []) '$s'},
      );
}

class OgretmenDaveti {
  final String kod;
  final bool rehber;
  final String? brans;
  final DateTime? sonGecerlilik;

  const OgretmenDaveti({required this.kod, this.rehber = false, this.brans, this.sonGecerlilik});

  String get gorev => rehber ? 'Rehber öğretmen' : (brans ?? 'Branş öğretmeni');

  factory OgretmenDaveti.fromJson(Map<String, dynamic> j) => OgretmenDaveti(
        kod: _s(j['kod']),
        rehber: j['rehber'] as bool? ?? false,
        brans: j['brans'] as String?,
        sonGecerlilik: _t(j['son_gecerlilik']),
      );
}

class YonetimOzeti {
  final String okulAd;
  final List<YonetimSubesi> subeler;
  final List<YonetimOgretmeni> ogretmenler;
  final List<OgretmenDaveti> davetler;

  const YonetimOzeti({
    required this.okulAd,
    this.subeler = const [],
    this.ogretmenler = const [],
    this.davetler = const [],
  });

  factory YonetimOzeti.fromJson(Map<String, dynamic> j) => YonetimOzeti(
        okulAd: _s((j['okul'] as Map?)?['ad']),
        subeler: [for (final s in _liste(j['subeler'])) YonetimSubesi.fromJson(s)],
        ogretmenler: [for (final o in _liste(j['ogretmenler'])) YonetimOgretmeni.fromJson(o)],
        davetler: [for (final d in _liste(j['davetler'])) OgretmenDaveti.fromJson(d)],
      );
}

// ─── Uygulama yöneticisi ─────────────────────────────────────────────

class AdminOkul {
  final String id;
  final String ad;
  final String il;
  final String ilce;
  final bool aktif;
  final int ogrenci;
  final int ogretmen;
  final List<String> mudurler;
  final String? bekleyenKod;

  const AdminOkul({
    required this.id,
    required this.ad,
    this.il = '',
    this.ilce = '',
    this.aktif = true,
    this.ogrenci = 0,
    this.ogretmen = 0,
    this.mudurler = const [],
    this.bekleyenKod,
  });

  String get konum => [ilce, il].where((s) => s.isNotEmpty).join(', ');

  factory AdminOkul.fromJson(Map<String, dynamic> j) => AdminOkul(
        id: _s(j['id']),
        ad: _s(j['ad']),
        il: _s(j['il']),
        ilce: _s(j['ilce']),
        aktif: j['aktif'] as bool? ?? true,
        ogrenci: _i(j['ogrenci']),
        ogretmen: _i(j['ogretmen']),
        mudurler: [for (final m in (j['mudurler'] as List?) ?? const []) '$m'],
        bekleyenKod: j['bekleyen_kod'] as String?,
      );
}
