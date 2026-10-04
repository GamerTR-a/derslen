/// Haftalık Ders Programı Motoru
///
/// Öğrencinin gün gün ayırabildiği süreyi (başlangıç saati + dakika), hedef
/// alanını, öğrenme metodunu ve konu durumunu (tamamlanan / zayıf) kullanarak
/// 7 günlük saatli bir program üretir:
///  * Dersler hedef alana göre önceliklendirilir; zayıf konu oranı ve kalan
///    konu sayısı ağırlığı artırır, öğrencinin "öncelikli" seçtiği dersler öne
///    çıkar, "hariç" tuttukları hiç planlanmaz.
///  * Blok sayısı derslere ağırlıkla orantılı dağıtılır ve hafta boyunca
///    serpiştirilir (aynı ders art arda gelmez, günlere dengeli yayılır).
///  * Her dersin konu sırası: zayıf + bitmemiş → bitmemiş → zayıf tekrar →
///    tamamlanan tekrar. Konular haftaya yayıldığı için her gün aynı konu
///    tekrarlanmaz.
///  * İsteğe bağlı olarak Pazar günü deneme sınavı bloğu eklenir.
///  * Öğrenci isterse programa girecek konuları tek tek seçer
///    ([DersProgramiAyar.seciliKonuIdleri]); program yalnızca bu konulardan
///    kurulur. Blokları elle ekleyip düzenleyerek kurduğu haftayı
///    “sabitleyebilir”; sabit program her hafta aynen yinelenir.
library;

import 'dart:math';

import '../../data/models/gunluk_checkin.dart';
import '../../data/models/konu.dart';
import '../../data/models/ogrenci_profil.dart';
import '../../data/models/plan_blok.dart';
import '../constants/app_constants.dart';
import '../constants/sinif_mufredati.dart';
import '../utils/tarih.dart';
import 'learning_engine.dart' show hedefDersOnceligi, metodBlokSure;

/// Tek bir günün müsaitlik ayarı.
class GunAyari {
  final bool aktif;

  /// Gün içi başlangıç saati (dakika, 17:00 → 1020).
  final int baslangicDk;

  /// O gün ayrılabilecek toplam süre (dakika, molalar dahil).
  final int sureDk;

  const GunAyari({this.aktif = true, required this.baslangicDk, required this.sureDk});

  GunAyari copyWith({bool? aktif, int? baslangicDk, int? sureDk}) => GunAyari(
        aktif: aktif ?? this.aktif,
        baslangicDk: baslangicDk ?? this.baslangicDk,
        sureDk: sureDk ?? this.sureDk,
      );

  int get etkinSureDk => aktif ? sureDk : 0;

  Map<String, dynamic> toJson() => {'a': aktif, 'b': baslangicDk, 's': sureDk};

  factory GunAyari.fromJson(Map<String, dynamic> j) => GunAyari(
        aktif: j['a'] as bool? ?? true,
        baslangicDk: ((j['b'] as num?) ?? 1020).toInt().clamp(0, 23 * 60),
        sureDk: ((j['s'] as num?) ?? 180).toInt().clamp(0, 720),
      );
}

class DersProgramiAyar {
  /// 7 gün, Pazartesi = 0.
  final List<GunAyari> gunler;
  final List<String> oncelikliDersler;
  final List<String> haricDersler;
  final bool pazarDeneme;

  /// Programa girecek konular (boşsa müfredattaki tüm konular kullanılır).
  final List<String> seciliKonuIdleri;

  /// Açıkken haftalık program yeniden üretilmez; öğrencinin düzenlediği hafta
  /// sonraki haftalara aynen taşınır.
  final bool sabitle;

  const DersProgramiAyar({
    required this.gunler,
    this.oncelikliDersler = const [],
    this.haricDersler = const [],
    this.pazarDeneme = true,
    this.seciliKonuIdleri = const [],
    this.sabitle = false,
  });

  /// Profildeki günlük çalışma saatinden makul bir başlangıç ayarı:
  /// hafta içi okul sonrası 17:00, hafta sonu 10:00.
  factory DersProgramiAyar.varsayilan(OgrenciProfil profil) {
    final gunluk = (profil.gunlukSaat * 60).clamp(60, 600);
    return DersProgramiAyar(
      gunler: [
        for (var i = 0; i < 5; i++) GunAyari(baslangicDk: 17 * 60, sureDk: gunluk),
        GunAyari(baslangicDk: 10 * 60, sureDk: (gunluk + 60).clamp(60, 600)),
        GunAyari(baslangicDk: 10 * 60, sureDk: gunluk),
      ],
    );
  }

  DersProgramiAyar copyWith({
    List<GunAyari>? gunler,
    List<String>? oncelikliDersler,
    List<String>? haricDersler,
    bool? pazarDeneme,
    List<String>? seciliKonuIdleri,
    bool? sabitle,
  }) =>
      DersProgramiAyar(
        gunler: gunler ?? this.gunler,
        oncelikliDersler: oncelikliDersler ?? this.oncelikliDersler,
        haricDersler: haricDersler ?? this.haricDersler,
        pazarDeneme: pazarDeneme ?? this.pazarDeneme,
        seciliKonuIdleri: seciliKonuIdleri ?? this.seciliKonuIdleri,
        sabitle: sabitle ?? this.sabitle,
      );

  DersProgramiAyar gunGuncelle(int index, GunAyari yeni) =>
      copyWith(gunler: [for (var i = 0; i < 7; i++) i == index ? yeni : gunler[i]]);

  int get haftalikDk => gunler.fold(0, (t, g) => t + g.etkinSureDk);
  int get aktifGunSayisi => gunler.where((g) => g.aktif && g.sureDk > 0).length;

  Map<String, dynamic> toJson() => {
        'gunler': [for (final g in gunler) g.toJson()],
        'oncelikli': oncelikliDersler,
        'haric': haricDersler,
        'pazarDeneme': pazarDeneme,
        'konular': seciliKonuIdleri,
        'sabit': sabitle,
      };

  factory DersProgramiAyar.fromJson(Map<String, dynamic> j, OgrenciProfil profil) {
    final ham = (j['gunler'] as List?) ?? const [];
    if (ham.length != 7) return DersProgramiAyar.varsayilan(profil);
    return DersProgramiAyar(
      gunler: [for (final g in ham) GunAyari.fromJson(Map<String, dynamic>.from(g as Map))],
      oncelikliDersler: ((j['oncelikli'] as List?) ?? const []).cast<String>(),
      haricDersler: ((j['haric'] as List?) ?? const []).cast<String>(),
      pazarDeneme: j['pazarDeneme'] as bool? ?? true,
      seciliKonuIdleri: [for (final e in (j['konular'] as List?) ?? const []) if (e is String) e],
      sabitle: j['sabit'] as bool? ?? false,
    );
  }
}

/// Hedef alana göre sınavına girilen AYT dersleri.
const Map<String, List<String>> alanAytDersleri = {
  'sayisal': ['Matematik', 'Fizik', 'Kimya', 'Biyoloji'],
  'esit_agirlik': ['Matematik', 'Türk Dili ve Edebiyatı', 'Tarih', 'Coğrafya'],
  'sozel': ['Türk Dili ve Edebiyatı', 'Tarih', 'Coğrafya'],
  'dil': [],
  serbestAlan: [],
};

/// Serbest müfredat: hazır YKS konuları yok, yalnızca kullanıcının dersleri.
const String serbestAlan = 'serbest';

/// Öğrencinin sorumlu olduğu konular: kendi eklediği konular + (YKS
/// alanlarında) tüm TYT ve alanına ait AYT konuları.
List<Konu> alanKonulari(String hedefBolum, List<Konu> konular) {
  if (hedefBolum == serbestAlan) return [for (final k in konular) if (k.ozel) k];
  final ayt = alanAytDersleri[hedefBolum] ?? const [];
  return [for (final k in konular) if (k.ozel || k.alan == SinavAlani.TYT || ayt.contains(k.ders)) k];
}

/// Programa girecek konular: öğrencinin sorumlu olduğu konulardan, (seçim
/// yaptıysa) yalnızca kendi seçtikleri. Seçilenlerin hiçbiri artık müfredatta
/// yoksa seçim yok sayılır.
List<Konu> programKonulari(String hedefBolum, List<Konu> konular, DersProgramiAyar ayar) {
  final hepsi = alanKonulari(hedefBolum, konular);
  if (ayar.seciliKonuIdleri.isEmpty) return hepsi;
  final secili = ayar.seciliKonuIdleri.toSet();
  final sonuc = [for (final k in hepsi) if (secili.contains(k.id)) k];
  return sonuc.isEmpty ? hepsi : sonuc;
}

/// Bir hedef alan için programa girebilecek dersler: önce alanın öncelik
/// sırasındaki dersler, ardından kullanıcının eklediği diğer dersler.
List<String> alanDersleri(String hedefBolum, List<Konu> konular) {
  final mevcut = <String>[];
  for (final k in alanKonulari(hedefBolum, konular)) {
    if (!mevcut.contains(k.ders)) mevcut.add(k.ders);
  }
  final sira = hedefBolum == serbestAlan
      ? const <String>[]
      : (hedefDersOnceligi[hedefBolum] ?? hedefDersOnceligi['sayisal']!);
  return [
    for (final d in sira) if (mevcut.contains(d)) d,
    for (final d in mevcut) if (!sira.contains(d)) d,
  ];
}

/// Molalar dahil [sureDk] içine kaç çalışma bloğu sığar.
int gunBlokSayisi(int sureDk, OgrenmeMetod metod) {
  final blok = metodBlokSure[metod] ?? 25;
  var t = 0;
  var n = 0;
  while (t + blok <= sureDk) {
    t += blok;
    n++;
    t += _molaSuresi(metod, n);
  }
  return n;
}

int _molaSuresi(OgrenmeMetod metod, int bitenBlok) {
  if (metod == OgrenmeMetod.derinlemeci) return 10;
  if (bitenBlok % 4 == 0) return 15;
  if (bitenBlok % 2 == 0) return 5;
  return 0;
}

String _renkHex(String ders) {
  final c = dersRengi(ders);
  return '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}

class _DersKuyrugu {
  final String ders;
  final List<(Konu, PlanBlokTip)> sira;
  var _i = 0;

  _DersKuyrugu(this.ders, this.sira);

  (Konu, PlanBlokTip)? sonraki() {
    if (sira.isEmpty) return null;
    final e = sira[_i % sira.length];
    _i++;
    return e;
  }
}

_DersKuyrugu _kuyrukOlustur(String ders, List<Konu> konular, OgrenmeMetod metod, bool tytOnce) {
  final dersKonulari = konular.where((k) => k.ders == ders).toList();
  int alanSirasi(Konu k) => tytOnce && k.alan == SinavAlani.AYT ? 1 : 0;
  final bitmemis = dersKonulari.where((k) => !k.tamamlandi).toList()
    ..sort((a, b) => alanSirasi(a).compareTo(alanSirasi(b)));
  final zayifBitmemis = bitmemis.where((k) => k.zayif).toList();
  final digerBitmemis = bitmemis.where((k) => !k.zayif).toList();
  final zayifBiten = dersKonulari.where((k) => k.tamamlandi && k.zayif).toList();
  final biten = dersKonulari.where((k) => k.tamamlandi && !k.zayif).toList();

  final sira = <(Konu, PlanBlokTip)>[
    for (final k in zayifBitmemis) (k, PlanBlokTip.soru),
    for (var i = 0; i < digerBitmemis.length; i++)
      (
        digerBitmemis[i],
        metod == OgrenmeMetod.pratik && i.isOdd ? PlanBlokTip.soru : PlanBlokTip.calisma,
      ),
    for (final k in zayifBiten) (k, PlanBlokTip.soru),
    for (final k in biten) (k, PlanBlokTip.tekrar),
  ];
  return _DersKuyrugu(ders, sira);
}

/// Derslerin haftalık ağırlıkları (öncelik, zayıflık, kalan konu).
Map<String, double> dersAgirliklari(OgrenciProfil profil, List<Konu> tumKonular, DersProgramiAyar ayar) {
  final konular = programKonulari(profil.hedefBolum, tumKonular, ayar);
  final dersler = alanDersleri(profil.hedefBolum, konular)
      .where((d) => !ayar.haricDersler.contains(d))
      .toList();
  final n = dersler.length;
  final sonuc = <String, double>{};
  for (var i = 0; i < n; i++) {
    final d = dersler[i];
    final dk = konular.where((k) => k.ders == d).toList();
    if (dk.isEmpty) continue;
    final kalanOran = dk.where((k) => !k.tamamlandi).length / dk.length;
    final zayifOran = dk.where((k) => k.zayif).length / dk.length;
    var w = 1.0 + (n - i) / n; // alan önceliği: 1..2
    w *= 0.45 + kalanOran; // bitmiş ders yalnızca tekrar ağırlığı alır
    w *= 1.0 + zayifOran;
    if (ayar.oncelikliDersler.contains(d)) w *= 1.6;
    sonuc[d] = w;
  }
  return sonuc;
}

/// Toplam blok sayısını ağırlıklara göre (en büyük kalan yöntemiyle) dağıtır.
Map<String, int> bloklariDagit(Map<String, double> agirliklar, int toplamBlok) {
  if (agirliklar.isEmpty || toplamBlok <= 0) return {};
  final toplamW = agirliklar.values.fold<double>(0, (a, b) => a + b);
  final ham = {for (final e in agirliklar.entries) e.key: e.value / toplamW * toplamBlok};
  final pay = {for (final e in ham.entries) e.key: e.value.floor()};
  var kalan = toplamBlok - pay.values.fold<int>(0, (a, b) => a + b);
  final kesirler = ham.entries.toList()
    ..sort((a, b) => (b.value - b.value.floor()).compareTo(a.value - a.value.floor()));
  for (var i = 0; kalan > 0; i = (i + 1) % kesirler.length, kalan--) {
    pay[kesirler[i].key] = pay[kesirler[i].key]! + 1;
  }
  // Blok yeterliyse her ders haftada en az bir kez görünsün.
  if (toplamBlok >= pay.length) {
    for (final d in pay.keys.toList()) {
      if (pay[d] == 0) {
        final enCok = pay.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
        pay[enCok] = pay[enCok]! - 1;
        pay[d] = 1;
      }
    }
  }
  pay.removeWhere((_, v) => v <= 0);
  return pay;
}

/// Dersleri haftaya serpiştirir: her adımda "hedefine en uzak" ders seçilir,
/// aynı ders mümkünse art arda gelmez.
List<String> dersSirasiOlustur(Map<String, int> pay, {Random? karistir}) {
  final kalan = Map<String, int>.from(pay);
  final kullanilan = {for (final d in pay.keys) d: 0};
  final toplam = pay.values.fold<int>(0, (a, b) => a + b);
  final sira = <String>[];
  String? son;
  for (var adim = 0; adim < toplam; adim++) {
    final adaylar = kalan.entries.where((e) => e.value > 0).map((e) => e.key).toList();
    if (karistir != null) adaylar.shuffle(karistir);
    final secenek = adaylar.where((d) => d != son).toList();
    final havuz = secenek.isEmpty ? adaylar : secenek;
    // Oransal geride kalan (kullanılan/pay en düşük) ders seçilir.
    havuz.sort((a, b) {
      final ra = kullanilan[a]! / pay[a]!;
      final rb = kullanilan[b]! / pay[b]!;
      final c = ra.compareTo(rb);
      return c != 0 ? c : pay[b]!.compareTo(pay[a]!);
    });
    final d = havuz.first;
    sira.add(d);
    kalan[d] = kalan[d]! - 1;
    kullanilan[d] = kullanilan[d]! + 1;
    son = d;
  }
  return sira;
}

/// 7 günlük programı üretir. [ilkGun]'den önceki günler boş liste döner
/// (çağıran taraf geçmiş günleri eski programdan korur).
List<List<PlanBlok>> haftalikProgramOlustur({
  required OgrenciProfil profil,
  required List<Konu> konular,
  required DersProgramiAyar ayar,
  required DateTime haftaBaslangic,
  int ilkGun = 0,
  DateTime? simdi,
}) {
  final now = simdi ?? DateTime.now();
  final metod = profil.ogrenmeMetod;
  final blokSure = metodBlokSure[metod] ?? 25;
  final haftaNo = haftaBaslangic.difference(DateTime(2024, 1, 1)).inDays ~/ 7;
  final tytOnce = yksKalanGun() > 150;

  // Pazar deneme bloğu (varsa) günün süresinden düşülür.
  final pazar = ayar.gunler[6];
  final denemeVar =
      ayar.pazarDeneme && profil.hedefBolum != serbestAlan && pazar.aktif && pazar.sureDk >= 120 && ilkGun <= 6;
  final aytDeneme = haftaNo.isOdd && profil.hedefBolum != 'dil';
  // 9-11. sınıflarda TYT/AYT yerine uygulama içi sınıf denemesi önerilir.
  final sinif = araSinif(profil.sinifSeviyesi);
  final denemeSure = !denemeVar ? 0 : min(pazar.sureDk, sinif != null ? 75 : (aytDeneme ? 180 : 165));

  final gunBlok = <int>[
    for (var g = 0; g < 7; g++)
      g < ilkGun
          ? 0
          : gunBlokSayisi(
              ayar.gunler[g].etkinSureDk - (g == 6 && denemeVar ? denemeSure + 15 : 0),
              metod,
            ),
  ];
  final toplamBlok = gunBlok.fold<int>(0, (a, b) => a + b);

  final agirliklar = dersAgirliklari(profil, konular, ayar);
  final pay = bloklariDagit(agirliklar, toplamBlok);
  final sira = dersSirasiOlustur(
    pay,
    karistir: metod == OgrenmeMetod.savasan ? Random(haftaNo) : null,
  );
  final ilgiliKonular = programKonulari(profil.hedefBolum, konular, ayar);
  final kuyruklar = {for (final d in pay.keys) d: _kuyrukOlustur(d, ilgiliKonular, metod, tytOnce)};
  final dersBlokSayaci = <String, int>{};

  var siraIndex = 0;
  final hafta = <List<PlanBlok>>[];
  for (var g = 0; g < 7; g++) {
    final gunTarihi = haftaBaslangic.add(Duration(days: g));
    final anahtar = gunAnahtari(gunTarihi);
    final gunAyari = ayar.gunler[g];
    final bloklar = <PlanBlok>[];
    if (g < ilkGun || !gunAyari.aktif) {
      hafta.add(bloklar);
      continue;
    }

    var saat = gunAyari.baslangicDk;
    if (g == 6 && denemeVar) {
      bloklar.add(PlanBlok(
        id: '$anahtar-deneme',
        konu: sinif != null ? '$sinif. Sınıf Genel Denemesi' : (aytDeneme ? 'AYT Deneme Sınavı' : 'TYT Deneme Sınavı'),
        ders: 'Deneme',
        sure: denemeSure,
        tip: PlanBlokTip.soru,
        renk: '#0EA5E9',
        saat: saatMetni(saat),
        createdAt: now,
        updatedAt: now,
      ));
      saat += denemeSure;
      bloklar.add(_mola('$anahtar-dm', 15, saat, now));
      saat += 15;
    }

    for (var b = 0; b < gunBlok[g] && siraIndex < sira.length; b++) {
      final ders = sira[siraIndex++];
      final secim = kuyruklar[ders]!.sonraki();
      final sayac = (dersBlokSayaci[ders] ?? 0) + 1;
      dersBlokSayaci[ders] = sayac;
      var tip = secim?.$2 ?? PlanBlokTip.tekrar;
      if (metod == OgrenmeMetod.stratejist && sayac % 3 == 0 && tip == PlanBlokTip.calisma) {
        tip = PlanBlokTip.tekrar;
      }
      bloklar.add(PlanBlok(
        id: '$anahtar-$b-${secim?.$1.id ?? ders}',
        konu: secim?.$1.baslik ?? '$ders genel tekrar',
        ders: ders,
        sure: blokSure,
        tip: tip,
        renk: _renkHex(ders),
        saat: saatMetni(saat),
        createdAt: now,
        updatedAt: now,
      ));
      saat += blokSure;
      final mola = _molaSuresi(metod, b + 1);
      if (mola > 0 && b + 1 < gunBlok[g]) {
        bloklar.add(_mola('$anahtar-m$b', mola, saat, now));
        saat += mola;
      }
    }
    hafta.add(bloklar);
  }
  return hafta;
}

PlanBlok _mola(String id, int sure, int saat, DateTime now) => PlanBlok(
      id: id,
      konu: sure >= 10 ? 'Uzun mola' : 'Kısa mola',
      ders: '',
      sure: sure,
      tip: PlanBlokTip.mola,
      renk: '#10B981',
      saat: saatMetni(saat),
      createdAt: now,
      updatedAt: now,
    );

/// Öğrencinin elle eklediği program bloğu.
PlanBlok elleBlok({
  required String gunAnahtar,
  required String ders,
  required String konu,
  required int sureDk,
  required int baslangicDk,
  PlanBlokTip tip = PlanBlokTip.calisma,
  DateTime? simdi,
}) {
  final now = simdi ?? DateTime.now();
  final mola = tip == PlanBlokTip.mola;
  return PlanBlok(
    id: '$gunAnahtar-e${now.microsecondsSinceEpoch}',
    konu: konu,
    ders: mola ? '' : ders,
    sure: sureDk,
    tip: tip,
    renk: mola ? '#10B981' : _renkHex(ders),
    saat: saatMetni(baslangicDk),
    createdAt: now,
    updatedAt: now,
  );
}

/// Blok saatini gün içi dakikaya çevirir (saat yoksa null).
int? blokBaslangicDk(PlanBlok b) => _dakika(b.saat);

/// Blokları başlangıç saatine göre sıralar (saatsizler sonda, sıra korunur).
List<PlanBlok> saateGoreSirali(List<PlanBlok> bloklar) {
  final l = [...bloklar];
  final sira = {for (var i = 0; i < l.length; i++) l[i].id: i};
  l.sort((a, b) {
    final c = (_dakika(a.saat) ?? 100000).compareTo(_dakika(b.saat) ?? 100000);
    return c != 0 ? c : sira[a.id]!.compareTo(sira[b.id]!);
  });
  return l;
}

/// Bir günün son bloğunun bittiği an (gün içi dakika); blok yoksa null.
int? gunSonuDk(List<PlanBlok> bloklar) {
  int? son;
  for (final b in bloklar) {
    final bas = _dakika(b.saat);
    if (bas == null) continue;
    if (son == null || bas + b.sure > son) son = bas + b.sure;
  }
  return son;
}

/// Sabitlenmiş (şablon) haftayı yeni haftanın tarihlerine taşır: blok
/// kimliklerindeki gün ön eki yenilenir, tamamlanma işaretleri sıfırlanır.
List<List<PlanBlok>> sablondanHafta(List<List<PlanBlok>> sablon, DateTime haftaBaslangic, {DateTime? simdi}) {
  final now = simdi ?? DateTime.now();
  return [
    for (var g = 0; g < 7; g++)
      [
        for (final (i, b) in (g < sablon.length ? sablon[g] : const <PlanBlok>[]).indexed)
          b.copyWith(
            id: '${gunAnahtari(haftaBaslangic.add(Duration(days: g)))}-s$i-${b.id.length > 11 ? b.id.substring(11) : b.id}',
            tamamlandi: false,
            createdAt: now,
            updatedAt: now,
          ),
      ],
  ];
}

/// Bugünün programını check-in'e göre uyarlar: yüksek streste başa nefes
/// egzersizi eklenir; enerji/stres kapasiteyi düşürüyorsa sondaki bloklar
/// bugünlük çıkarılır. Blok kimlikleri değişmez (tamamlanma takibi için).
({List<PlanBlok> bloklar, int cikarilan}) gunlukPlaniUyarla(List<PlanBlok> program, GunlukCheckin checkin, String gunAnahtar) {
  if (program.isEmpty) return (bloklar: program, cikarilan: 0);
  final calisma = program.where((b) => b.isCalismaBloku).toList();
  final kapasite = (checkin.enerjiKatsayi * checkin.stresKatsayi).clamp(0.5, 1.0);
  final tutulacak = kapasite >= 0.95 ? calisma.length : max(1, (calisma.length * kapasite).ceil());
  final cikarilan = calisma.length - tutulacak;

  var sonuc = <PlanBlok>[];
  var sayac = 0;
  for (final b in program) {
    if (b.isCalismaBloku) {
      sayac++;
      if (sayac > tutulacak) break;
    }
    sonuc.add(b);
  }
  // Blok çıkarıldıysa sonda kalan molalar da atılır (öğrencinin gün sonuna
  // kendi eklediği mola korunur).
  while (cikarilan > 0 && sonuc.isNotEmpty && sonuc.last.isMola) {
    sonuc.removeLast();
  }

  if (checkin.stres >= 4 && sonuc.isNotEmpty) {
    final ilk = sonuc.first;
    final ilkSaat = _dakika(ilk.saat) ?? 17 * 60;
    sonuc = [
      PlanBlok(
        id: '$gunAnahtar-nefes',
        konu: 'Nefes egzersizi ve odaklanma',
        ders: 'Psikoloji',
        sure: 5,
        tip: PlanBlokTip.egzersiz,
        renk: '#14B8A6',
        saat: saatMetni(max(0, ilkSaat - 5)),
        createdAt: ilk.createdAt,
        updatedAt: ilk.updatedAt,
      ),
      ...sonuc,
    ];
  }
  return (bloklar: sonuc, cikarilan: cikarilan);
}

int? _dakika(String? saat) {
  if (saat == null || !saat.contains(':')) return null;
  final p = saat.split(':');
  final s = int.tryParse(p[0]);
  final d = int.tryParse(p[1]);
  if (s == null || d == null) return null;
  return s * 60 + d;
}

/// Haftalık programdaki derslere ayrılan toplam dakika.
Map<String, int> programDersDagilimi(List<List<PlanBlok>> hafta) {
  final m = <String, int>{};
  for (final gun in hafta) {
    for (final b in gun.where((b) => b.isCalismaBloku)) {
      final d = (b.ders == null || b.ders!.isEmpty) ? 'Genel' : b.ders!;
      m[d] = (m[d] ?? 0) + b.sure;
    }
  }
  return m;
}
