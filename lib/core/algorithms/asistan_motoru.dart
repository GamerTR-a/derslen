/// Koç Asistanı — cihaz içi analiz motoru.
///
/// İnternet ya da bulut yapay zekası olmadan çalışır: öğrencinin yazdığı
/// mesajın niyetini anahtar kelimelerle bulur, deneme sonuçlarını analiz eder,
/// ders programı için somut ve uygulanabilir değişiklik önerir. Bulut
/// yanıtları açıkken de program önerileri buradan gelir (deterministik ve
/// uygulamanın gerçekten uygulayabileceği değişiklikler).
library;

import 'dart:math';

import '../../data/models/konu.dart';
import '../../data/models/net_kaydi.dart';
import '../../data/models/ogrenci_profil.dart';
import '../../data/models/plan_blok.dart';
import '../constants/app_constants.dart';
import '../utils/tarih.dart';
import 'analiz_motoru.dart';
import 'ders_programi.dart';

enum AsistanNiyet {
  denemeAnalizi,
  denemeEkle,
  hedefNet,
  programIncele,
  programIyilestir,
  zayifDersler,
  konuDurumu,
  haftaOzeti,
  testCoz,
  kartTekrar,
  odakBaslat,
  arkaPlanSesi,
  bahce,
  mola,
  etutOdasi,
  motivasyon,
  yardim,
}

/// Uygulamada doğrudan bir işlem başlatan düğmelerin türü.
enum AsistanKomutTur { testBaslat, desteAc, odakBaslat, sesCal }

class AsistanKomut {
  final AsistanKomutTur tur;

  /// testBaslat ve odakBaslat için ders adı.
  final String? ders;

  /// desteAc için deste kimliği ('hepsi', 'yanlislar', 'fizik' …).
  final String? deste;

  /// sesCal için ses adı (AmbiyansSes.name).
  final String? ses;

  /// testBaslat: soru sayısı, odakBaslat: dakika (0 = serbest).
  final int sayi;

  const AsistanKomut.test(String this.ders, {this.sayi = 10})
      : tur = AsistanKomutTur.testBaslat,
        deste = null,
        ses = null;
  const AsistanKomut.deste(String this.deste)
      : tur = AsistanKomutTur.desteAc,
        ders = null,
        ses = null,
        sayi = 0;
  const AsistanKomut.odak(String this.ders, {this.sayi = 25})
      : tur = AsistanKomutTur.odakBaslat,
        deste = null,
        ses = null;
  const AsistanKomut.ses(String this.ses)
      : tur = AsistanKomutTur.sesCal,
        ders = null,
        deste = null,
        sayi = 0;
}

/// Asistan mesajındaki düğme: bir ekrana gitmek, başka bir analizi
/// çalıştırmak, önerilen program ayarını uygulamak ya da uygulamada bir işlemi
/// (test, kart tekrarı, odak seansı, arka plan sesi) başlatmak.
class AsistanAksiyon {
  final String etiket;
  final String? rota;
  final AsistanNiyet? niyet;
  final DersProgramiAyar? programAyari;
  final AsistanKomut? komut;

  const AsistanAksiyon.rota(this.etiket, String this.rota)
      : niyet = null,
        programAyari = null,
        komut = null;
  const AsistanAksiyon.niyet(this.etiket, AsistanNiyet this.niyet)
      : rota = null,
        programAyari = null,
        komut = null;
  const AsistanAksiyon.programUygula(this.etiket, DersProgramiAyar this.programAyari)
      : rota = null,
        niyet = null,
        komut = null;
  const AsistanAksiyon.komut(this.etiket, AsistanKomut this.komut)
      : rota = null,
        niyet = null,
        programAyari = null;
}

class AsistanYaniti {
  final String metin;
  final List<String> maddeler;
  final List<AsistanAksiyon> aksiyonlar;

  const AsistanYaniti(this.metin, {this.maddeler = const [], this.aksiyonlar = const []});

  /// Sohbet geçmişi için düz metin.
  String get duzMetin => [metin, for (final m in maddeler) '- $m'].join('\n');
}

/// Türkçe büyük/küçük harf dönüşümü locale'e bağlı olmadan (İ→i, I→ı).
String turkceKucuk(String s) => s
    .replaceAll('İ', 'i')
    .replaceAll('I', 'ı')
    .toLowerCase()
    .replaceAll('â', 'a')
    .replaceAll('î', 'i')
    .replaceAll('û', 'u');

AsistanNiyet niyetBul(String mesaj) {
  final m = turkceKucuk(mesaj);
  bool var_(List<String> kelimeler) => kelimeler.any(m.contains);

  if (var_(['bunald', 'stres', 'kaygı', 'motivasyon', 'yoruldum', 'yapamıyorum', 'moralim', 'sıkıldım', 'üzgün', 'endişe'])) {
    return AsistanNiyet.motivasyon;
  }
  if (var_(['iyileştir', 'düzenle', 'ayarla', 'değiştir', 'güncelle', 'öner', 'hazırla', 'oluştur']) && var_(['program', 'plan'])) {
    return AsistanNiyet.programIyilestir;
  }
  if (var_(['etüt', 'etut', 'odam', 'odada', 'odası', 'sıralama', 'kim çalış', 'kimler çalış', 'sıralamam'])) return AsistanNiyet.etutOdasi;
  if (var_(['deneme ekle', 'deneme gir', 'netimi gir', 'netlerimi gir', 'sonuç gir', 'sonucumu gir', 'deneme kaydet'])) {
    return AsistanNiyet.denemeEkle;
  }
  if (var_(['hedef', 'kaç net', 'kaç puan', 'yetişir', 'yetişecek', 'tahmin', 'sınava kadar'])) return AsistanNiyet.hedefNet;
  if (var_(['test', 'soru çöz', 'soru çözmek', 'soru çözeyim', 'soru sor', 'quiz'])) return AsistanNiyet.testCoz;
  if (var_(['kart', 'yanlışlarım', 'bilemedi', 'ezber', 'tekrar et', 'tekrar edeyim'])) return AsistanNiyet.kartTekrar;
  if (var_(['odak', 'pomodoro', 'zamanlayıcı', 'sayaç', 'seans', 'çalışmaya başla', 'çalışmak istiyorum', 'başlat'])) {
    return AsistanNiyet.odakBaslat;
  }
  if (var_(['ses', 'müzik', 'yağmur', 'dalga', 'şömine', 'kuş', 'gürültü', 'kafe', 'tik tak', 'vantilatör'])) {
    return AsistanNiyet.arkaPlanSesi;
  }
  if (var_(['bahçe', 'bitki', 'sula', 'tohum', 'yıldız', 'damla', 'ormanım'])) return AsistanNiyet.bahce;
  if (var_(['mola', 'oyun', 'zihin', 'beyin', 'dinlen'])) return AsistanNiyet.mola;
  if (var_(['deneme', 'net', 'sınav sonuc', 'sonucum'])) return AsistanNiyet.denemeAnalizi;
  if (var_(['zayıf', 'eksik', 'hangi derse', 'hangi ders', 'kötü olduğum', 'öncelik'])) return AsistanNiyet.zayifDersler;
  if (var_(['konu', 'müfredat', 'bitirdim', 'kaldı', 'kalan'])) return AsistanNiyet.konuDurumu;
  if (var_(['program', 'plan', 'bugün ne', 'yarın ne', 'takvim'])) return AsistanNiyet.programIncele;
  if (var_(['hafta', 'ne kadar çalış', 'süre', 'ilerleme', 'gelişim', 'özet', 'durumum'])) return AsistanNiyet.haftaOzeti;
  return AsistanNiyet.yardim;
}

/// Bir denemenin tek alandaki (TYT/AYT) ders kayıtları.
class _Deneme {
  final String ad;
  final String tarih;
  final SinavAlani alan;
  final DateTime zaman;
  final List<NetKaydi> dersler;

  _Deneme(this.ad, this.tarih, this.alan, this.zaman, this.dersler);

  double get net => dersler.fold(0, (t, k) => t + k.net);
  int get dogru => dersler.fold(0, (t, k) => t + k.dogru);
  int get yanlis => dersler.fold(0, (t, k) => t + k.yanlis);
  int get bos => dersler.fold(0, (t, k) => t + k.bos);
  int get soru => dogru + yanlis + bos;
}

List<_Deneme> _denemeler(List<NetKaydi> netler) {
  final gruplar = <String, List<NetKaydi>>{};
  for (final k in netler) {
    gruplar.putIfAbsent('${k.tarih}|${k.denemeAdi ?? ''}|${k.alan.name}', () => []).add(k);
  }
  final liste = [
    for (final g in gruplar.values)
      _Deneme(
        g.first.denemeAdi ?? g.first.tarih,
        g.first.tarih,
        g.first.alan,
        g.map((k) => k.createdAt).reduce((a, b) => a.isBefore(b) ? a : b),
        g,
      ),
  ]..sort((a, b) => a.zaman.compareTo(b.zaman));
  return liste;
}

String _n(double v) => v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2);
String _isaretli(double v) => '${v >= 0 ? '+' : ''}${v.toStringAsFixed(1)}';
String _yuzde(double oran) => '%${(oran * 100).round()}';

/// Son denemenin ayrıntılı analizi: toplam net ve değişim, ders bazında
/// başarı, boş/yanlış oranlarının yorumu, gidişat ve somut öneriler.
AsistanYaniti denemeAnaliziYaniti(List<NetKaydi> netler) {
  final denemeler = _denemeler(netler);
  if (denemeler.isEmpty) {
    return const AsistanYaniti(
      'Henüz kayıtlı denemen yok. Netler ekranından ilk denemeni (ders ders doğru/yanlış/boş) eklersen güçlü ve zayıf olduğun dersleri, net kaybını ve gidişatını çıkarırım.',
      aksiyonlar: [AsistanAksiyon.rota('Deneme ekle', '/netler')],
    );
  }

  final son = denemeler.last;
  final ayniAlan = denemeler.where((d) => d.alan == son.alan).toList();
  final onceki = ayniAlan.length >= 2 ? ayniAlan[ayniAlan.length - 2] : null;
  final maddeler = <String>[];

  var ozet = '${son.ad} (${son.alan.name}): toplam ${_n(son.net)} net';
  if (onceki != null) {
    final fark = son.net - onceki.net;
    ozet += ', önceki ${son.alan.name} denemene göre ${_isaretli(fark)} net';
    ozet += fark >= 0 ? '. Güzel ilerleme!' : '. Moral bozma, nedenlerine birlikte bakalım.';
  } else {
    ozet += '.';
  }

  // Ders bazında başarı (net / soru) ve geçmiş ortalamayla karşılaştırma.
  final dersSonuclari = <(NetKaydi, double, double?)>[];
  for (final k in son.dersler.where((k) => k.toplamSoru > 0)) {
    final gecmis = netler
        .where((x) => x.alan == k.alan && x.ders == k.ders && x.id != k.id && x.createdAt.isBefore(k.createdAt))
        .map((x) => x.net)
        .toList();
    final ort = gecmis.isEmpty ? null : gecmis.reduce((a, b) => a + b) / gecmis.length;
    dersSonuclari.add((k, k.net / k.toplamSoru, ort));
  }
  if (dersSonuclari.length >= 2) {
    dersSonuclari.sort((a, b) => b.$2.compareTo(a.$2));
    final guclu = dersSonuclari.first;
    final zayif = dersSonuclari.last;
    maddeler.add('En güçlü dersin ${guclu.$1.ders}: ${_n(guclu.$1.net)}/${guclu.$1.toplamSoru} net (${_yuzde(max(0, guclu.$2))} verim).');
    maddeler.add('En çok puan kaçırdığın ders ${zayif.$1.ders}: ${_n(zayif.$1.net)}/${zayif.$1.toplamSoru} net. '
        'Bu hafta programında bu derse öncelik vermeni öneririm.');
  }
  for (final (k, _, ort) in dersSonuclari) {
    if (ort == null) continue;
    final fark = k.net - ort;
    if (fark <= -2) {
      maddeler.add('${k.ders} netin ortalamanın ${_n(fark.abs())} altında (${_n(k.net)} / ort. ${_n(ort)}). Son çalıştığın konulara bak.');
    } else if (fark >= 2) {
      maddeler.add('${k.ders} netin ortalamanın ${_n(fark)} üstünde; çalışman karşılık veriyor.');
    }
  }

  // Boş ve yanlış oranları.
  if (son.soru > 0) {
    final bosOran = son.bos / son.soru;
    final cevaplanan = son.dogru + son.yanlis;
    final yanlisOran = cevaplanan == 0 ? 0.0 : son.yanlis / cevaplanan;
    final kayip = son.yanlis * 0.25;
    if (yanlisOran >= 0.3) {
      maddeler.add('Cevapladığın soruların ${_yuzde(yanlisOran)}\'i yanlış; bu denemede yanlışlar yüzünden ${_n(kayip)} net kaybettin. '
          'Emin olmadığın soruda iki şıkka indiremiyorsan boş bırakmak daha kârlı.');
    } else if (bosOran >= 0.25) {
      maddeler.add('Soruların ${_yuzde(bosOran)}\'ini boş bıraktın. Yanlış oranın düşük (${_yuzde(yanlisOran)}); '
          'iki şıkka indirebildiğin sorularda risk alman netini artırabilir. Süre yetmediyse turlama tekniğini dene.');
    } else if (son.yanlis > 0) {
      maddeler.add('Yanlışların ${_n(kayip)} net götürdü. Yanlış yaptığın soruları "Yanlışlarım" destesine eklemek tekrarını kolaylaştırır.');
    }
  }

  // Gidişat.
  final trend = netTrendi(netler, son.alan);
  if (trend.noktalar.length >= 3) {
    final e = trend.egim;
    if (e >= 0.3) {
      maddeler.add('Son ${min(8, trend.noktalar.length)} ${son.alan.name} denemende deneme başına ortalama ${_isaretli(e)} net artıyorsun; bu hızla 5 deneme sonra ≈${trend.tahmin(5).toStringAsFixed(0)} net.');
    } else if (e <= -0.3) {
      maddeler.add('${son.alan.name} netlerin son denemelerde düşüş eğiliminde (${_isaretli(e)}/deneme). Konu tekrarını artırmanın zamanı.');
    } else {
      maddeler.add('${son.alan.name} netlerin son denemelerde yatay seyrediyor; yeni soru tipleri ve zamanlı çözümle ivme kazanabilirsin.');
    }
  } else {
    maddeler.add('Gidişat çıkarmam için en az 3 ${son.alan.name} denemesi gerekiyor; haftada bir deneme ideal.');
  }

  return AsistanYaniti(ozet, maddeler: maddeler, aksiyonlar: const [
    AsistanAksiyon.niyet('Programımı buna göre iyileştir', AsistanNiyet.programIyilestir),
    AsistanAksiyon.rota('Tüm netlerim', '/netler'),
  ]);
}

/// Zayıf dersler: son denemelerdeki verim (net/soru) ve zayıf işaretli konu
/// sayısı birleştirilerek sıralanır. Yalnızca öğrencinin alan dersleri.
List<String> zayifDersSiralamasi({
  required List<NetKaydi> netler,
  required List<Konu> konular,
  required OgrenciProfil profil,
}) {
  final dersler = alanDersleri(profil.hedefBolum, konular);
  final puan = <String, double>{};
  for (final d in dersler) {
    // Son 3 kaydın ortalama verimi (yoksa nötr 0.5).
    final kayitlar = netler.where((k) => k.ders == d && k.toplamSoru > 0).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final son = kayitlar.take(3).toList();
    final verim = son.isEmpty ? 0.5 : son.map((k) => k.net / k.toplamSoru).reduce((a, b) => a + b) / son.length;
    final dersKonulari = konular.where((k) => k.ders == d).toList();
    final zayifOran = dersKonulari.isEmpty ? 0.0 : dersKonulari.where((k) => k.zayif).length / dersKonulari.length;
    final kalanOran = dersKonulari.isEmpty ? 0.0 : dersKonulari.where((k) => !k.tamamlandi).length / dersKonulari.length;
    // Düşük verim, çok zayıf konu ve çok kalan konu → daha yüksek öncelik.
    puan[d] = (1 - verim.clamp(0.0, 1.0)) * 0.6 + zayifOran * 0.3 + kalanOran * 0.1;
  }
  return (puan.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).map((e) => e.key).toList();
}

AsistanYaniti zayifDerslerYaniti({
  required List<NetKaydi> netler,
  required List<Konu> konular,
  required OgrenciProfil profil,
}) {
  final sira = zayifDersSiralamasi(netler: netler, konular: konular, profil: profil);
  if (sira.isEmpty) return const AsistanYaniti('Alanına ait ders bulamadım; profilinde hedef alanını kontrol eder misin?');
  final maddeler = <String>[];
  for (final d in sira.take(3)) {
    final dk = konular.where((k) => k.ders == d).toList();
    final zayif = dk.where((k) => k.zayif).map((k) => k.baslik).take(3).toList();
    final kayit = netler.where((k) => k.ders == d).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final netBilgi = kayit.isEmpty ? 'deneme kaydı yok' : 'son net ${_n(kayit.first.net)}/${kayit.first.toplamSoru}';
    maddeler.add('$d: $netBilgi, ${dk.where((k) => k.tamamlandi).length}/${dk.length} konu bitti'
        '${zayif.isEmpty ? '' : '; zayıf konular: ${zayif.join(', ')}'}.');
  }
  return AsistanYaniti(
    netler.isEmpty
        ? 'Deneme kaydın olmadığı için konu durumuna göre sıraladım. Öncelik vermen gereken dersler:'
        : 'Deneme verimin ve konu durumuna göre öncelik vermen gereken dersler:',
    maddeler: maddeler,
    aksiyonlar: const [
      AsistanAksiyon.niyet('Bu derslere programda öncelik ver', AsistanNiyet.programIyilestir),
      AsistanAksiyon.rota('Konularım', '/konular'),
    ],
  );
}

class ProgramOnerisi {
  final DersProgramiAyar yeniAyar;
  final List<String> gerekceler;
  final bool degisti;
  const ProgramOnerisi(this.yeniAyar, this.gerekceler, this.degisti);
}

/// Verilere göre program ayarı önerisi: yük (plan uyumuna göre), öncelikli
/// dersler (zayıf ders sıralamasına göre) ve deneme sıklığı.
ProgramOnerisi programOnerisi({
  required OgrenciProfil profil,
  required DersProgramiAyar ayar,
  required DonemAnalizi analiz,
  required List<NetKaydi> netler,
  required List<Konu> konular,
}) {
  var yeni = ayar;
  final gerekceler = <String>[];

  final planliGun = analiz.planlananBlok.where((p) => p > 0).length;
  final uyum = analiz.planUyumu;
  int yuvarla(int dk) => (dk / 15).round() * 15;
  if (uyum != null && planliGun >= 3 && uyum < 0.5) {
    yeni = yeni.copyWith(gunler: [
      for (final g in yeni.gunler) g.aktif ? g.copyWith(sureDk: max(45, yuvarla((g.sureDk * 0.8).round()))) : g,
    ]);
    gerekceler.add('Son 30 günde planının ${_yuzde(uyum)}\'ini tamamlamışsın; günlük süreleri %20 azalttım. Bitirilebilir bir plan, bitmeyen uzun bir plandan daha çok çalıştırır.');
  } else if (uyum != null && planliGun >= 5 && uyum >= 0.9 && analiz.gunlukOrtalamaDk < 360) {
    yeni = yeni.copyWith(gunler: [
      for (var i = 0; i < 7; i++)
        (i < 5 && yeni.gunler[i].aktif) ? yeni.gunler[i].copyWith(sureDk: min(600, yeni.gunler[i].sureDk + 15)) : yeni.gunler[i],
    ]);
    gerekceler.add('Planına ${_yuzde(uyum)} uyuyorsun; hafta içi günlere 15\'er dakika ekledim.');
  }

  final sira = zayifDersSiralamasi(netler: netler, konular: konular, profil: profil)
      .where((d) => !ayar.haricDersler.contains(d))
      .take(2)
      .toList();
  if (sira.isNotEmpty && (sira.toSet().difference(ayar.oncelikliDersler.toSet()).isNotEmpty || ayar.oncelikliDersler.length != sira.length)) {
    yeni = yeni.copyWith(oncelikliDersler: sira);
    gerekceler.add('Öncelikli dersleri ${sira.join(' ve ')} yaptım (deneme verimin ve zayıf konuların en çok bu derslerde). Bu dersler haftada yaklaşık %60 daha fazla blok alacak.');
  }

  final son30 = DateTime.now().subtract(const Duration(days: 30));
  final denemeSayisi = _denemeler(netler).where((d) => d.zaman.isAfter(son30)).length;
  if (!ayar.pazarDeneme && denemeSayisi < 2 && ayar.gunler[6].aktif) {
    yeni = yeni.copyWith(pazarDeneme: true);
    gerekceler.add('Son 30 günde $denemeSayisi deneme çözmüşsün; Pazar günlerine deneme sınavı ekledim. Düzenli deneme, gelişimini ölçmenin tek yolu.');
  }

  final aktifGun = yeni.aktifGunSayisi;
  if (aktifGun == 7) {
    gerekceler.add('Not: Haftanın her günü çalışıyorsun; bir günü hafif tutmak (ya da dinlenme günü) tükenmeyi önler.');
  }

  return ProgramOnerisi(yeni, gerekceler, gerekceler.any((g) => !g.startsWith('Not:')));
}

AsistanYaniti programOnerisiYaniti(ProgramOnerisi o) {
  if (!o.degisti) {
    return AsistanYaniti(
      'Programın şu anki verilerine uygun görünüyor; değiştirmeye gerek görmedim.',
      maddeler: o.gerekceler,
      aksiyonlar: const [AsistanAksiyon.rota('Programımı aç', '/program')],
    );
  }
  return AsistanYaniti(
    'Verilerine göre programın için şu değişiklikleri öneriyorum. Uygularsan program bugünden itibaren yeniden hazırlanır; tamamladığın bloklar korunur.',
    maddeler: o.gerekceler,
    aksiyonlar: [
      AsistanAksiyon.programUygula('Önerileri uygula', o.yeniAyar),
      const AsistanAksiyon.rota('Programımı aç', '/program'),
    ],
  );
}

AsistanYaniti programIncelemeYaniti({
  required List<List<PlanBlok>> hafta,
  required DersProgramiAyar? ayar,
  required List<PlanBlok> bugun,
  required double? planUyumu,
}) {
  final dagilim = programDersDagilimi(hafta);
  final toplam = dagilim.values.fold<int>(0, (a, b) => a + b);
  if (toplam == 0) {
    return const AsistanYaniti(
      'Bu hafta için programında çalışma bloğu yok. Programım ekranından günlük sürelerini ayarlayabilir ya da "Programımı iyileştir" dersen verilerine göre bir öneri hazırlarım.',
      aksiyonlar: [
        AsistanAksiyon.niyet('Programımı iyileştir', AsistanNiyet.programIyilestir),
        AsistanAksiyon.rota('Programımı aç', '/program'),
      ],
    );
  }
  final sirali = dagilim.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final maddeler = <String>[
    'Bu hafta toplam ${sureMetni(toplam)} çalışma planlı. En çok süre: ${sirali.take(3).map((e) => '${e.key} ${_yuzde(e.value / toplam)}').join(', ')}.',
  ];
  final kalan = bugun.where((b) => b.isCalismaBloku && !b.tamamlandi).toList();
  if (kalan.isNotEmpty) {
    maddeler.add('Bugün ${kalan.length} blok kaldı; sıradaki ${kalan.first.saatFormatli}\'de ${kalan.first.ders}: ${kalan.first.konu}.');
  } else if (bugun.any((b) => b.isCalismaBloku)) {
    maddeler.add('Bugünün tüm bloklarını bitirdin, harika!');
  }
  if (planUyumu != null) maddeler.add('Son 30 günde plan uyumun ${_yuzde(planUyumu)}.');
  if (ayar != null && ayar.oncelikliDersler.isNotEmpty) maddeler.add('Öncelikli derslerin: ${ayar.oncelikliDersler.join(', ')}.');
  return AsistanYaniti('Programının özeti:', maddeler: maddeler, aksiyonlar: const [
    AsistanAksiyon.rota('Programımı aç', '/program'),
    AsistanAksiyon.niyet('Programımı iyileştir', AsistanNiyet.programIyilestir),
  ]);
}

AsistanYaniti haftaOzetiYaniti(DonemAnalizi a) {
  final maddeler = <String>[
    'Son 7 günde ${sureMetni(a.toplamDk)} çalıştın (${a.aktifGun}/7 gün, günlük ort. ${sureMetni(a.gunlukOrtalamaDk.round())}).',
    if (a.planUyumu != null) 'Plan uyumun ${_yuzde(a.planUyumu!)}.',
    if (a.seri > 0) '${a.seri} günlük çalışma serin var.',
    for (final i in a.icgoruler.take(3)) i.metin,
  ];
  return AsistanYaniti('Haftanın özeti:', maddeler: maddeler, aksiyonlar: const [
    AsistanAksiyon.rota('Gelişim analizim', '/analiz'),
  ]);
}

AsistanYaniti motivasyonYaniti(String mesaj) {
  final m = turkceKucuk(mesaj);
  final agir = ['kendime zarar', 'intihar', 'yaşamak istemiyorum', 'ölmek'].any(m.contains);
  if (agir) {
    return const AsistanYaniti(
      'Bunu yazman çok önemli ve seni ciddiye alıyorum. Lütfen şimdi güvendiğin bir yetişkinle (ailen, okul rehber öğretmenin) konuş. Kendini tehlikede hissediyorsan hemen 112\'yi ara. Yalnız değilsin.',
    );
  }
  return const AsistanYaniti(
    'YKS maratonunda bu hisler çok normal. Birkaç öneri:',
    maddeler: [
      'Önce 2 dakikalık bir nefes egzersizi yap; sonra sadece 25 dakikalık tek bir blok hedefle.',
      'Bugünün planını küçült: bir blok bile bitirmek seriyi korur.',
      'Uyku ve su önemli; yorgunken çözülen soru kalıcı olmaz.',
      'Kaygın uzun süredir devam ediyorsa okul rehber öğretmeninle konuşmak iyi gelir.',
    ],
    aksiyonlar: [AsistanAksiyon.rota('Odak seansı aç', '/calis')],
  );
}

AsistanYaniti yardimYaniti({required bool bulutAcik}) {
  return AsistanYaniti(
    bulutAcik
        ? 'Bana derslerinle, denemelerinle ya da çalışma programınla ilgili her şeyi sorabilirsin. Örneğin:'
        : 'Şu an cihazdaki analizlerle çalışıyorum. Şunları yapabilirim:',
    maddeler: const [
      '"Son denememi analiz et" ya da "deneme ekle": net değişimi, güçlü/zayıf ders, boş-yanlış yorumu',
      '"Hedefim 90 net, yetişir mi?": gidişatına göre sınav günü tahmini',
      '"Programımı iyileştir" / "Bugün ne çalışayım?": uygulanabilir program önerisi',
      '"Zayıf derslerim neler?" / "Hangi konular kaldı?" (ders eklemek için Müfredatım ekranı)',
      '"Test çözmek istiyorum": zayıf dersinden hazır test',
      '"Kartlarımı tekrar edeyim": bekleyen kartlar ve Yanlışlarım',
      '"Odak seansı başlat" / "Yağmur sesi aç"',
      '"Etüt odam nasıl?": odadaki sıran ve çalışanlar',
      '"Bahçem nasıl?", "Mola vermek istiyorum", "Bu haftam nasıl?"',
    ],
  );
}

/// Bulut yanıtları için öğrencinin çalışma özeti. İsim, e-posta, okul,
/// hedef üniversite gibi kimliği belirleyebilecek bilgiler bilerek YOK.
Map<String, dynamic> asistanBaglami({
  required OgrenciProfil profil,
  required DonemAnalizi analiz30,
  required List<NetKaydi> netler,
  required List<Konu> konular,
  required DersProgramiAyar? ayar,
  required List<List<PlanBlok>> hafta,
  required List<PlanBlok> bugun,
}) {
  final denemeler = _denemeler(netler);
  return {
    'bugun': gunAnahtari(DateTime.now()),
    if (profil.hedefBolum != serbestAlan) 'yksKalanGun': yksKalanGun(),
    'hedefAlan': profil.hedefBolumEtiketi,
    'sinif': profil.sinifSeviyesi,
    'ogrenmeMetodu': profil.ogrenmeMetodEtiketi,
    'gunlukHedefDk': profil.gunlukSaat * 60,
    'son30Gun': {
      'toplamCalismaDk': analiz30.toplamDk,
      'aktifGun': analiz30.aktifGun,
      'gunlukOrtalamaDk': analiz30.gunlukOrtalamaDk.round(),
      'planUyumu': analiz30.planUyumu == null ? null : (analiz30.planUyumu! * 100).round(),
      'calismaSerisiGun': analiz30.seri,
      'dersDagilimiDk': Map.fromEntries(analiz30.dersDagilimi.entries.take(8)),
    },
    'denemeler': [
      for (final d in denemeler.reversed.take(8))
        {
          'tarih': d.tarih,
          'ad': d.ad,
          'alan': d.alan.name,
          'toplamNet': double.parse(d.net.toStringAsFixed(2)),
          'dersler': {for (final k in d.dersler) k.ders: {'dogru': k.dogru, 'yanlis': k.yanlis, 'bos': k.bos, 'net': k.net}},
        },
    ],
    'dersNetOzeti': [
      for (final s in analiz30.dersNetTablosu)
        {
          'ders': '${s.alan.name} ${s.ders}',
          'denemeSayisi': s.denemeSayisi,
          'son': s.son,
          'ortalama': double.parse(s.ortalama.toStringAsFixed(2)),
          'enIyi': s.enIyi,
          'degisim': s.degisim == null ? null : double.parse(s.degisim!.toStringAsFixed(2)),
        },
    ],
    'konular': [
      for (final k in analiz30.konuDurumu)
        {
          'ders': k.ders,
          'toplam': k.toplam,
          'tamamlanan': k.tamamlanan,
          'zayif': k.zayif,
          'zayifKonular': konular.where((x) => x.ders == k.ders && x.zayif).map((x) => x.baslik).take(5).toList(),
        },
    ],
    'program': ayar == null
        ? null
        : {
            'haftalikDk': ayar.haftalikDk,
            'gunler': [
              for (var i = 0; i < 7; i++)
                {
                  'gun': gunAdlari[i],
                  'aktif': ayar.gunler[i].aktif,
                  'baslangic': saatMetni(ayar.gunler[i].baslangicDk),
                  'sureDk': ayar.gunler[i].sureDk,
                  'planliCalismaDk': hafta.length == 7
                      ? hafta[i].where((b) => b.isCalismaBloku).fold<int>(0, (t, b) => t + b.sure)
                      : 0,
                },
            ],
            'oncelikliDersler': ayar.oncelikliDersler,
            'haricDersler': ayar.haricDersler,
            'pazarDeneme': ayar.pazarDeneme,
            'bugununBloklari': [
              for (final b in bugun.where((b) => b.isCalismaBloku).take(10))
                {'saat': b.saatFormatli, 'ders': b.ders, 'konu': b.konu, 'dk': b.sure, 'tamamlandi': b.tamamlandi},
            ],
          },
    'otomatikIcgoruler': [for (final i in analiz30.icgoruler.take(6)) i.metin],
  };
}

// ─── Uygulamanın diğer bölümleri ──────────────────────────────

/// Deneme girme rehberi.
AsistanYaniti denemeEkleYaniti() => const AsistanYaniti(
      'Denemeni Netler ekranından tek formda girebilirsin:',
      maddeler: [
        'TYT ya da AYT seç, istersen yayın adını yaz (boş bırakırsan "TYT Denemesi 3" gibi ad verilir).',
        'Her ders için doğru ve yanlış sayını gir; boş sayısı soru sayısından otomatik hesaplanır, net anında görünür.',
        'Girmediğin dersler kaydedilmez. Kaydettikten sonra bana "son denememi analiz et" de.',
      ],
      aksiyonlar: [
        AsistanAksiyon.rota('Deneme ekle', '/netler'),
        AsistanAksiyon.niyet('Son denememi analiz et', AsistanNiyet.denemeAnalizi),
      ],
    );

/// "Hedefim 90 net" gibi bir mesajdaki hedef neti.
double? mesajdakiHedefNet(String mesaj) {
  final m = RegExp(r'(\d{1,3}(?:[.,]\d+)?)\s*net').firstMatch(turkceKucuk(mesaj));
  return m == null ? null : double.tryParse(m.group(1)!.replaceAll(',', '.'));
}

/// Gidişata göre sınav günü net tahmini; mesajda hedef varsa ona göre yorum.
AsistanYaniti hedefNetYaniti({required List<NetKaydi> netler, required String mesaj, int? kalanGun}) {
  final gun = kalanGun ?? yksKalanGun();
  final hedef = mesajdakiHedefNet(mesaj);
  final alan = turkceKucuk(mesaj).contains('ayt') ? SinavAlani.AYT : SinavAlani.TYT;
  final trend = netTrendi(netler, alan);
  if (trend.noktalar.isEmpty) {
    return AsistanYaniti(
      'Tahmin için en az bir ${alan.name} denemesine ihtiyacım var. YKS\'ye $gun gün kaldı; haftada bir deneme çözersen gidişatını birlikte izleyebiliriz.',
      aksiyonlar: const [AsistanAksiyon.rota('Deneme ekle', '/netler')],
    );
  }
  final son30 = DateTime.now().subtract(const Duration(days: 30));
  final ayliK = trend.noktalar.where((d) => d.tarih.isAfter(son30)).length;
  final haftalik = max(1.0, ayliK / 4.3);
  final kalanDeneme = max(1, (gun / 7 * haftalik).floor());
  final tavan = alan == SinavAlani.TYT ? 120.0 : 80.0;
  final son = trend.son!;
  final ort3 = trend.noktalar.reversed.take(3).map((e) => e.net).reduce((a, b) => a + b) / min(3, trend.noktalar.length);
  final tahmin = trend.noktalar.length >= 3 ? min(tavan, trend.tahmin(kalanDeneme)) : null;

  final maddeler = <String>[
    'Son ${alan.name} netin ${_n(son)}, son denemelerin ortalaması ${_n(ort3)}, en iyin ${_n(trend.enIyi)}.',
    if (trend.noktalar.length >= 3) 'Deneme başına eğilimin ${_isaretli(trend.egim)} net.',
    'YKS\'ye $gun gün var; bu tempoda yaklaşık $kalanDeneme deneme daha çözersin.',
    if (tahmin != null) 'Bu gidişle sınav gününe ≈${tahmin.toStringAsFixed(0)} net ile girersin.',
  ];
  String metin;
  if (hedef != null) {
    final fark = hedef - ort3;
    if (fark <= 0) {
      metin = 'Hedefin ${_n(hedef)} net ve son ortalaman zaten bunun üstünde. Şimdi hedefi korumak ve yükseltmek zamanı!';
    } else {
      final gereken = fark / kalanDeneme;
      metin = 'Hedefin ${_n(hedef)} net: ortalamanla arandaki fark ${_n(fark)} net. Deneme başına ≈${gereken.toStringAsFixed(1)} net artış gerekiyor.';
      maddeler.add(trend.noktalar.length >= 3 && trend.egim >= gereken
          ? 'Şu anki artış hızın yeterli görünüyor; düzeni bozma.'
          : 'Şu anki hızın bunun altında. Zayıf derslere öncelik verip yanlışlarını düzenli tekrar edersen fark kapanır.');
    }
  } else {
    metin = '${alan.name} gidişatına göre tahminim (hedef netini de yazarsan, ör. "hedefim 90 net", ona göre hesaplarım):';
  }
  return AsistanYaniti(metin, maddeler: maddeler, aksiyonlar: const [
    AsistanAksiyon.niyet('Zayıf derslerim neler?', AsistanNiyet.zayifDersler),
    AsistanAksiyon.niyet('Programımı iyileştir', AsistanNiyet.programIyilestir),
  ]);
}

/// Konu ilerlemesi: ders ders tamamlanan konular ve sıradaki konular.
AsistanYaniti konuDurumuYaniti({required List<Konu> konular, required OgrenciProfil profil}) {
  final ilgili = alanKonulari(profil.hedefBolum, konular);
  if (ilgili.isEmpty) return const AsistanYaniti('Alanına ait konu bulamadım; profilinde hedef alanını kontrol eder misin?');
  final biten = ilgili.where((k) => k.tamamlandi).length;
  final dersler = alanDersleri(profil.hedefBolum, ilgili);
  final satirlar = <(String, int, int)>[
    for (final d in dersler)
      (d, ilgili.where((k) => k.ders == d && k.tamamlandi).length, ilgili.where((k) => k.ders == d).length),
  ]..sort((a, b) => (a.$2 / max(1, a.$3)).compareTo(b.$2 / max(1, b.$3)));
  final maddeler = <String>[
    for (final (d, b, t) in satirlar.take(4)) '$d: $b/$t konu (${_yuzde(b / max(1, t))})',
  ];
  final enGeri = satirlar.first.$1;
  final siradaki = ilgili.where((k) => k.ders == enGeri && !k.tamamlandi).take(3).map((k) => k.baslik).toList();
  if (siradaki.isNotEmpty) maddeler.add('$enGeri dersinde sıradaki konular: ${siradaki.join(', ')}.');
  return AsistanYaniti(
    'Alanındaki ${ilgili.length} konunun $biten tanesini bitirdin (${_yuzde(biten / ilgili.length)}). En geride kalan dersler:',
    maddeler: maddeler,
    aksiyonlar: [
      const AsistanAksiyon.rota('Konularım', '/konular'),
      AsistanAksiyon.komut('$enGeri çalışmaya başla', AsistanKomut.odak(enGeri)),
    ],
  );
}

/// Test önerisi: zayıf ders sırası ile uygulama içi test başarıları
/// birleştirilir; havuzda sorusu olan ilk ders önerilir.
AsistanYaniti testOnerisiYaniti({
  required List<String> zayifSira,
  required Map<String, int> havuzSayilari,
  required List<TestKaydi> testler,
  required String mesaj,
}) {
  final m = turkceKucuk(mesaj);
  // Mesajda ders adı geçiyorsa onu kullan.
  String? istenen;
  for (final d in havuzSayilari.keys) {
    if (m.contains(turkceKucuk(d)) || (d == 'Türk Dili ve Edebiyatı' && m.contains('edebiyat'))) {
      istenen = d;
      break;
    }
  }
  final son30 = gunAnahtari(DateTime.now().subtract(const Duration(days: 30)));
  final basari = <String, (int, int)>{};
  for (final t in testler.where((t) => t.tarih.compareTo(son30) >= 0)) {
    final o = basari[t.ders] ?? (0, 0);
    basari[t.ders] = (o.$1 + t.dogru, o.$2 + t.toplam);
  }
  final testZayif = (basari.entries.where((e) => e.value.$2 >= 5 && havuzSayilari.containsKey(e.key)).toList()
        ..sort((a, b) => (a.value.$1 / a.value.$2).compareTo(b.value.$1 / b.value.$2)))
      .map((e) => e.key)
      .toList();
  final adaylar = <String>[
    ?istenen,
    ...zayifSira.where(havuzSayilari.containsKey),
    ...testZayif,
    ...havuzSayilari.keys,
  ];
  final secim = <String>[];
  for (final d in adaylar) {
    if (!secim.contains(d)) secim.add(d);
    if (secim.length == 2) break;
  }
  final ilk = secim.first;
  final maddeler = <String>[
    if (istenen == null) '$ilk dersini öneriyorum: deneme verimin, zayıf konuların ya da son test başarın bu derste en düşük.',
    'Havuzda $ilk dersinden ${havuzSayilari[ilk]} soru var; 10 soruluk karışık zorlukta bir test hazırlayabilirim.',
    for (final e in (basari.entries.toList()..sort((a, b) => (a.value.$1 / a.value.$2).compareTo(b.value.$1 / b.value.$2))).take(3))
      'Son 30 günde ${e.key} testlerinde doğru oranın ${_yuzde(e.value.$1 / e.value.$2)} (${e.value.$2} soru).',
    'Yanlış yaptığın sorular otomatik olarak "Yanlışlarım" kart destene eklenir.',
  ];
  return AsistanYaniti(
    istenen != null ? '$istenen testi hazır:' : 'Bugün şu testi çözmeni öneririm:',
    maddeler: maddeler,
    aksiyonlar: [
      for (final d in secim) AsistanAksiyon.komut('$d testi başlat (10 soru)', AsistanKomut.test(d)),
      const AsistanAksiyon.rota('Kendim seçeyim', '/test-olustur'),
    ],
  );
}

/// Kart tekrarı: deste bazında bekleyen kartlar, Yanlışlarım ve günlük yeni
/// kart hakkı.
AsistanYaniti kartTekrarYaniti({
  required Map<String, int> bekleyen,
  required Map<String, String> desteAdlari,
  required int yanlisToplam,
  required int kalanYeniKart,
}) {
  final toplam = bekleyen['hepsi'] ?? 0;
  final yanlisBekleyen = bekleyen['yanlislar'] ?? 0;
  final desteler = bekleyen.entries.where((e) => e.key != 'hepsi' && e.key != 'yanlislar' && e.value > 0).toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  if (toplam == 0) {
    return AsistanYaniti(
      'Bugün tekrar bekleyen kartın yok, tüm destelerin çiçek açmış!',
      maddeler: [
        if (yanlisToplam > 0) 'Yanlışlarım destende $yanlisToplam kart var; tekrar zamanları geldikçe burada görünecek.',
        'Kendi formül ya da kavram kartlarını “Kart ekle” ile oluşturabilirsin.',
      ],
      aksiyonlar: const [AsistanAksiyon.rota('Kartlara git', '/flashkart')],
    );
  }
  return AsistanYaniti(
    'Bugün $toplam kart tekrar bekliyor. Kısa bir tekrar turu unutmayı ciddi ölçüde azaltır.',
    maddeler: [
      if (yanlisBekleyen > 0) 'Yanlışlarım: $yanlisBekleyen kart (testteki yanlışların ve “Bilemedim” dediklerin). Önce bunlarla başla.',
      for (final e in desteler.take(3)) '${desteAdlari[e.key] ?? e.key}: ${e.value} kart',
      if (kalanYeniKart > 0) 'Bugün $kalanYeniKart yeni kart daha tanıtılabilir.',
    ],
    aksiyonlar: [
      if (yanlisBekleyen > 0) const AsistanAksiyon.komut('Yanlışlarımı tekrar et', AsistanKomut.deste('yanlislar')),
      if (desteler.isNotEmpty)
        AsistanAksiyon.komut('${desteAdlari[desteler.first.key] ?? desteler.first.key} destesini aç', AsistanKomut.deste(desteler.first.key)),
      const AsistanAksiyon.komut('Tüm kartlar', AsistanKomut.deste('hepsi')),
    ],
  );
}

/// Odak seansı önerisi: programdaki sıradaki blok ya da en zayıf ders.
AsistanYaniti odakYaniti({
  required bool seansSuruyor,
  required int gecenDakika,
  required String? siradakiDers,
  required String? siradakiKonu,
  required int? siradakiSure,
  required String? zayifDers,
  required int bugunDk,
  required int hedefDk,
}) {
  if (seansSuruyor) {
    return AsistanYaniti('Zaten $gecenDakika dakikadır odak seansındasın. Seans bitince süren bahçene ve istatistiklerine eklenecek.',
        aksiyonlar: const [AsistanAksiyon.rota('Sayaca dön', '/calis')]);
  }
  final ders = siradakiDers ?? zayifDers ?? 'Genel';
  final sure = (siradakiSure ?? 25) >= 45 ? 50 : 25;
  return AsistanYaniti(
    siradakiDers != null
        ? 'Programındaki sıradaki blok: ${siradakiKonu ?? siradakiDers} ($siradakiSure dk). Hemen başlatabilirim.'
        : '${zayifDers != null ? '$zayifDers dersine' : 'Genel'} odaklanan bir seans öneriyorum.',
    maddeler: [
      'Bugün ${sureMetni(bugunDk)} çalıştın; günlük hedefin ${sureMetni(hedefDk)}.',
      'Her 25 dakika 10 yıldız kazandırır ve bahçendeki bitkileri büyütür.',
      'Arka plan sesi istersen “yağmur sesi aç” gibi yazabilirsin.',
    ],
    aksiyonlar: [
      AsistanAksiyon.komut('$ders · $sure dk başlat', AsistanKomut.odak(ders, sayi: sure)),
      AsistanAksiyon.komut('$ders · serbest mod', AsistanKomut.odak(ders, sayi: 0)),
    ],
  );
}

/// Bahçe özeti.
AsistanYaniti bahceYaniti({
  required int yildiz,
  required int damla,
  required int ekili,
  required int susuz,
  required int olgun,
  required int bosSaksi,
  required int tohum,
}) {
  final maddeler = <String>[
    '$yildiz yıldızın ve $damla su damlan var.',
    if (ekili == 0) 'Hiç bitkin yok; ${tohum > 0 ? 'kesende $tohum tohum var, hemen ekebilirsin.' : 'mağazadan bir tohum alıp ekebilirsin.'}',
    if (susuz > 0) '$susuz bitkin bugün sulanmadı; sulamak da büyütür.',
    if (olgun > 0) '$olgun bitkin olgunlaştı; ormanına taşıyıp saksıyı yeni tohuma açabilirsin.',
    if (bosSaksi > 0 && tohum > 0 && ekili > 0) '$bosSaksi boş saksın ve $tohum tohumun var.',
    'Her 25 dakikalık odak ekili bitkilerin hepsini büyütür; damlaları check-in ve kart tekrarıyla kazanırsın.',
  ];
  return AsistanYaniti('Bahçenin durumu:', maddeler: maddeler, aksiyonlar: [
    const AsistanAksiyon.rota('Bahçeye git', '/bahce'),
    if (damla < 3) const AsistanAksiyon.niyet('Kart tekrarıyla damla kazan', AsistanNiyet.kartTekrar),
  ]);
}

/// Mola önerisi: kısa zihin oyunları ve nefes.
AsistanYaniti molaYaniti({required int gecenDakika}) {
  final oneriler = [
    'Dikkat için Schulte Tablosu (1 dk)',
    'Çalışma belleği için 2-Geri',
    'Hız için Hangisi Büyük?',
    'Kelime bilgisi için Eş / Zıt Anlam',
    'Görsel hafıza için Kare Hafızası',
  ]..shuffle(Random(DateTime.now().day));
  return AsistanYaniti(
    gecenDakika >= 50
        ? '$gecenDakika dakikadır çalışıyorsun; 5-10 dakikalık bir mola hak ettin.'
        : 'Kısa bir mola dikkatini tazeler. Önerilerim:',
    maddeler: [
      ...oneriler.take(3),
      'Ekrandan uzaklaşıp su içmek ve biraz yürümek de iyi bir moladır.',
      'Moladan sonra dönmek için 25 dakikalık bir odak seansı başlatabilirim.',
    ],
    aksiyonlar: const [
      AsistanAksiyon.rota('Zihin Açıcı oyunlar', '/mini-oyunlar'),
      AsistanAksiyon.niyet('Odak seansı başlat', AsistanNiyet.odakBaslat),
    ],
  );
}
