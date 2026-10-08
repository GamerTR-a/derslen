/// Koç Asistanı — cihaz içi bilgi motoru.
///
/// Öğrencinin ders ve sınav sorularını ("mitoz nedir", "TYT kaç soru",
/// "paragrafta nasıl hızlanırım") uygulamadaki hazır kartlar ve YKS
/// rehberi üzerinde arayarak yanıtlar. İnternet gerektirmez, kotası yoktur.
/// Bulut yapay zekası açıkken de önce burası denenir; bulunan içerik buluta
/// kaynak olarak gönderilir.
library;

import 'dart:math';

import '../constants/app_constants.dart';
import '../constants/flashkart_data.dart';
import '../constants/yks_rehber.dart';

/// Arama için sadeleştirme: küçük harf, Türkçe harfler ASCII karşılığına,
/// noktalama boşluğa. "Türev NEDİR?" ile "turev nedir" aynı sonucu verir.
String aramaMetni(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    final c = String.fromCharCode(r);
    b.write(switch (c) {
      'İ' || 'I' || 'ı' || 'î' || 'Î' => 'i',
      'Ç' || 'ç' => 'c',
      'Ğ' || 'ğ' => 'g',
      'Ö' || 'ö' => 'o',
      'Ş' || 'ş' => 's',
      'Ü' || 'ü' || 'û' || 'Û' => 'u',
      'â' || 'Â' => 'a',
      _ => c.toLowerCase(),
    });
  }
  return b.toString().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}

/// Soru kalıbı ve dolgu sözcükleri; aramada anlam taşımazlar.
const _dolgu = {
  'nedir', 'ne', 'nasil', 'neden', 'nicin', 'niye', 'kim', 'kimdir', 'nelerdir', 'neler', 'hangi', 'hangisi', 'mi', 'mu', //
  'midir', 'mudur', 'bana', 'bir', 'bu', 'su', 'ile', 've', 'veya', 'ya', 'da', 'de', 'ki', 'icin', 'gibi', 'kadar', 'daha',
  'cok', 'en', 'her', 'hakkinda', 'ilgili', 'anlat', 'anlatir', 'anlatsana', 'acikla', 'aciklar', 'misin', 'musun', 'soyle',
  'soyler', 'demek', 'denir', 'olan', 'olur', 'olarak', 'var', 'yok', 'lutfen', 'kisaca', 'ozetle', 'bilgi', 'ver', 'verir',
  'istiyorum', 'ogrenmek', 'konusu', 'konusunu', 'dersi', 'dersinde', 'ben', 'benim', 'sen', 'o', 'biraz', 'tam', 'peki',
  'merhaba', 'selam', 'tesekkurler', 'sey', 'arasindaki', 'arasinda', 'ise', 'yani', 'nasilsin', 'naber', 'fark', 'farki',
  'farklari', 'yapmaliyim', 'yapmali', 'yapayim', 'gerekir', 'gerekiyor', 'lazim', 'et', 'eder', 'oluyor', 'tesekkur',
};

/// Pek çok başlıkta geçen, tek başına konuyu belirlemeyen sözcükler
/// ("pisagor teoremi"nde ayırt edici olan "pisagor"dur).
const _genel = {
  'teoremi', 'teorem', 'yasasi', 'yasalari', 'yasa', 'kurali', 'kurallari', 'kural', 'formulu', 'formul', 'formulleri', //
  'bagintisi', 'ilkesi', 'ilkeleri', 'kanunu', 'ozellikleri', 'ozelligi', 'turleri', 'tipleri', 'cesitleri', 'nedenleri',
  'sonuclari', 'kavrami', 'tanimi', 'donemi', 'konu', 'konulari', 'soru', 'sorulari', 'ornek', 'ornekleri', 'hesaplama',
};

List<String> _sozcukler(String metin) =>
    [for (final s in aramaMetni(metin).split(' ')) if (s.length >= 2 || RegExp(r'^\d$').hasMatch(s)) s];

List<String> _anlamliSozcukler(String metin) => [for (final s in _sozcukler(metin)) if (!_dolgu.contains(s)) s];

/// İki sözcüğün eşleşme gücü (0, 0.7 ya da 1). Türkçe ekler sona geldiği
/// için ortak kök ön ekle yakalanır: "türevin" ↔ "türev", "asitler" ↔ "asit".
double _eslesme(String a, String b) {
  if (a == b) return 1;
  final kisa = min(a.length, b.length), uzun = max(a.length, b.length);
  if (kisa < 4) return 0;
  if (a.startsWith(b) || b.startsWith(a)) return kisa * 2 >= uzun ? 0.85 : 0.6;
  if (kisa < 6) return 0;
  var ortak = 0;
  while (ortak < kisa && a.codeUnitAt(ortak) == b.codeUnitAt(ortak)) {
    ortak++;
  }
  return ortak >= 5 && ortak >= uzun * 0.65 ? 0.7 : 0;
}

/// Mesajda adı geçen ders → kart destesi anahtarı.
const _dersSozcukleri = {
  'matematik': 'matematik',
  'geometri': 'geometri',
  'fizik': 'fizik',
  'kimya': 'kimya',
  'biyoloji': 'biyoloji',
  'tarih': 'tarih',
  'cografya': 'cografya',
  'edebiyat': 'edebiyat',
  'felsefe': 'felsefe',
  'turkce': 'turkce',
  'ingilizce': 'ingilizce',
  'din': 'din',
};

enum BilgiKaynagi { kart, rehber }

/// Aranabilir tek bir bilgi parçası (bir kart ya da bir rehber maddesi).
class BilgiBelgesi {
  final BilgiKaynagi kaynak;
  final String id;
  final String baslik;

  /// Kart destesi anahtarı ('fizik', 'tarih' …); rehber maddelerinde null.
  final String? ders;
  final String? unite;
  final String metin;
  final List<String> maddeler;
  final String? ipucu;
  final (String, String)? rota;

  final List<String> _baslikS;
  final List<String> _anahtarS;
  final List<String> _uniteS;
  final List<String> _ipucuS;
  final List<String> _govdeS;

  BilgiBelgesi._({
    required this.kaynak,
    required this.id,
    required this.baslik,
    required this.metin,
    this.ders,
    this.unite,
    this.maddeler = const [],
    this.ipucu,
    this.rota,
    String anahtarlar = '',
  })  : _baslikS = _anlamliSozcukler(baslik),
        _anahtarS = _anlamliSozcukler(anahtarlar),
        _uniteS = _anlamliSozcukler(unite ?? ''),
        _ipucuS = _anlamliSozcukler(ipucu ?? ''),
        _govdeS = _anlamliSozcukler('$metin ${maddeler.join(' ')}');

  String get dersEtiketi => ders == null ? 'YKS rehberi' : (dersEtiketleri[ders] ?? ders!);

  /// Bulut yanıtına kaynak olarak gönderilecek düz metin.
  String get kaynakMetni => [
        '$baslik (${[dersEtiketi, ?unite].join(' · ')})',
        metin,
        ...maddeler,
      ].join('\n');
}

class BilgiEslesmesi {
  final BilgiBelgesi belge;
  final double puan;
  const BilgiEslesmesi(this.belge, this.puan);
}

class BilgiSonucu {
  /// En iyiden kötüye sıralı eşleşmeler (en çok 4).
  final List<BilgiEslesmesi> eslesmeler;

  /// Sorudaki anlamlı sözcüklerin ne kadarının en iyi belgede karşılandığı
  /// (0–1, nadir sözcükler daha ağır).
  final double kapsama;

  /// Sorunun en az bir sözcüğü belgenin başlığında ya da anahtarlarında.
  final bool baslikta;

  /// Soru, belgenin başlığıyla birebir örtüşüyor ("kalan teoremi").
  final bool tamBaslik;

  const BilgiSonucu(this.eslesmeler, this.kapsama, this.baslikta, {this.tamBaslik = false});
  static const bos = BilgiSonucu([], 0, false);

  BilgiBelgesi? get enIyi => eslesmeler.firstOrNull?.belge;

  /// Yanıt olarak gösterilecek kadar güvenilir.
  bool get yeterli => eslesmeler.isNotEmpty && baslikta && kapsama >= 0.5;

  /// Buluta sormaya gerek bırakmayacak kadar güçlü.
  bool get guclu => yeterli && kapsama >= 0.75;
}

List<BilgiBelgesi>? _belgeler;

List<BilgiBelgesi> get bilgiBelgeleri => _belgeler ??= [
      for (final r in yksRehberi)
        BilgiBelgesi._(
          kaynak: BilgiKaynagi.rehber,
          id: r.id,
          baslik: r.baslik,
          metin: r.metin,
          maddeler: r.maddeler,
          rota: r.rota,
          anahtarlar: r.anahtarlar,
        ),
      for (final k in flashKartlar)
        BilgiBelgesi._(
          kaynak: BilgiKaynagi.kart,
          id: k.id,
          baslik: k.on,
          ders: k.ders,
          unite: k.unite,
          metin: k.arka,
          ipucu: k.ipucu,
        ),
    ];

/// Mesaj bir bilgi sorusu kalıbında mı ("… nedir", "… açıkla", "kaç soru")?
bool bilgiSorusuMu(String mesaj) {
  final m = ' ${aramaMetni(mesaj)} ';
  const kaliplar = [
    ..._gucluKaliplar,
    ' ne zaman ', ' hangi yil', ' kac soru', ' kac dakika',
    ' nasil hesap', ' nasil calisilir ', ' nasil calismaliyim ', ' nasil bulunur ', ' nasil cozulur ', ' nasil yapilir ',
    ' nasil hizlan', ' eserleri ', ' kurali ', ' kurallari ', ' kac saat calis',
  ];
  return kaliplar.any(m.contains);
}

const _gucluKaliplar = [
  ' nedir ', ' ne demek', ' kimdir ', ' nelerdir ', ' acikla', ' anlat', ' formul', ' tanimi ', ' tanimla', //
  ' ozellikleri ', ' ozelligi ', ' farki ', ' fark nedir', ' ornek ver', ' ne ise yarar', ' kimin eseri', ' kim yazdi',
  ' neye denir', ' hakkinda bilgi',
];

/// Uygulama komutu olma ihtimali çok düşük, açık bir konu sorusu
/// ("… nedir", "… arasındaki fark", "… açıkla").
bool acikBilgiSorusuMu(String mesaj) {
  final m = ' ${aramaMetni(mesaj)} ';
  return _gucluKaliplar.any(m.contains);
}

/// [mesaj] için kartlar ve rehberde arama yapar.
BilgiSonucu bilgiAra(String mesaj) {
  final sozcukler = _anlamliSozcukler(mesaj).toSet().toList();
  // Yalnızca ders adı ("matematik") bir soru değildir.
  if (sozcukler.every(_dersSozcukleri.containsKey)) return BilgiSonucu.bos;

  final belgeler = bilgiBelgeleri;
  double enIyiAlan(String s, List<String> alan) {
    var e = 0.0;
    for (final a in alan) {
      final x = _eslesme(s, a);
      if (x > e) {
        e = x;
        if (e == 1) break;
      }
    }
    return e;
  }

  // Her belge için sözcük başına (ağırlıklı eşleşme, başlıkta mı).
  final n = belgeler.length;
  final ham = List.generate(n, (_) => List<double>.filled(sozcukler.length, 0));
  final baslikta = List.generate(n, (_) => List<bool>.filled(sozcukler.length, false));
  final belgeSayisi = List<int>.filled(sozcukler.length, 0);
  for (var i = 0; i < n; i++) {
    final b = belgeler[i];
    for (var j = 0; j < sozcukler.length; j++) {
      final s = sozcukler[j];
      final bas = [enIyiAlan(s, b._baslikS), enIyiAlan(s, b._anahtarS), enIyiAlan(s, b._uniteS) * 0.8].reduce(max);
      final puan = [
        // Soruda geçen ders adı ("fizik ohm yasası") o dersin kartlarıyla eşleşir.
        if (b.ders != null && _dersSozcukleri[s] == b.ders) 1.0,
        bas * 3.0,
        enIyiAlan(s, b._ipucuS) * 1.2,
        enIyiAlan(s, b._govdeS) * 1.0,
      ].reduce(max);
      if (puan > 0) {
        ham[i][j] = puan;
        baslikta[i][j] = bas > 0;
        belgeSayisi[j]++;
      }
    }
  }
  // Nadir sözcük daha ayırt edicidir; hiçbir belgede geçmeyen sözcük en
  // ağırıdır ve kapsamayı düşürür ("kuantum dolanıklık nedir" yanıtsız kalır).
  final agirlik = [
    for (var j = 0; j < sozcukler.length; j++)
      log(1 + n / (belgeSayisi[j] + 0.5)) * (_genel.contains(sozcukler[j]) ? 0.3 : 1.0),
  ];
  final toplamAgirlik = agirlik.reduce((a, b) => a + b);

  final sonuc = <(BilgiEslesmesi, double, bool, bool)>[];
  for (var i = 0; i < n; i++) {
    var puan = 0.0, karsilanan = 0.0;
    var bas = false;
    for (var j = 0; j < sozcukler.length; j++) {
      if (ham[i][j] == 0) continue;
      puan += ham[i][j] * agirlik[j];
      karsilanan += agirlik[j] * min(1.0, ham[i][j]);
      bas = bas || baslikta[i][j];
    }
    if (puan == 0) continue;
    final b = belgeler[i];
    // Başlığın tamamı soruda geçiyorsa ("mitoz bölünme nedir") tam isabet.
    final baslikTam = b._baslikS.isNotEmpty && b._baslikS.every((t) => sozcukler.any((s) => _eslesme(s, t) > 0));
    if (baslikTam) puan *= 1.5;
    final kapsama = karsilanan / toplamAgirlik;
    final tam = baslikTam && sozcukler.length >= 2 && b.kaynak == BilgiKaynagi.kart && sozcukler.every((s) => enIyiAlan(s, b._baslikS) >= 0.85);
    sonuc.add((BilgiEslesmesi(b, puan * (0.5 + kapsama)), kapsama, bas, tam));
  }
  if (sonuc.isEmpty) return BilgiSonucu.bos;
  sonuc.sort((a, b) => b.$1.puan.compareTo(a.$1.puan));
  final ilk = sonuc.first;
  return BilgiSonucu(
    [for (final s in sonuc.take(4)) if (s.$1.puan >= ilk.$1.puan * 0.55) s.$1],
    ilk.$2,
    ilk.$3,
    tamBaslik: ilk.$4,
  );
}

/// "40 doğru 12 yanlış kaç net" gibi bir mesajdaki (doğru, yanlış) sayıları.
(int, int)? mesajdakiDogruYanlis(String mesaj) {
  final m = aramaMetni(mesaj);
  final d = RegExp(r'(\d{1,3}) ?(?:dogru|d\b)').firstMatch(m);
  final y = RegExp(r'(\d{1,3}) ?(?:yanlis|y\b)').firstMatch(m);
  if (d == null || (y == null && !m.contains('net'))) return null;
  return (int.parse(d.group(1)!), y == null ? 0 : int.parse(y.group(1)!));
}
