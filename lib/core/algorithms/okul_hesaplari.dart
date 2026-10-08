/// Okul panellerinin saf (yan etkisiz) hesapları: kod biçimi, panel
/// yönlendirmesi, haftalık özetler, sınıf ormanı ve rapor metinleri.
library;

import '../../data/models/okul_modelleri.dart';
import '../utils/tarih.dart';

/// Branş öğretmeni için seçilebilen dersler (Çalış ekranındaki ders adlarıyla
/// aynıdır; sunucu süzgeci bu adlarla eşleştirir).
const List<String> okulBranslari = [
  'Matematik', 'Türkçe', 'Edebiyat', 'Fizik', 'Kimya', 'Biyoloji',
  'Tarih', 'Coğrafya', 'Felsefe', 'Din Kültürü', 'İngilizce',
];

const List<String> okulSiniflari = ['9', '10', '11', '12', 'Mezun'];

// ─── Kodlar ──────────────────────────────────────────────────────────

/// Kullanıcının yazdığı kodu sunucunun beklediği biçime getirir.
String kodTemizle(String kod) => kod.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');

/// "SABCD2345" → "S-ABCD-2345" (okunması ve yazdırılması kolay olsun).
String kodBicimle(String kod) {
  final k = kodTemizle(kod);
  if (k.length != 9) return k;
  return '${k[0]}-${k.substring(1, 5)}-${k.substring(5)}';
}

/// Kodun önekinden türü: S = şube, T = öğretmen, M = müdür, V = veli.
KullaniciRolu? kodTuru(String kod) {
  final k = kodTemizle(kod);
  if (k.length != 9) return null;
  return switch (k[0]) {
    'S' => KullaniciRolu.ogrenci,
    'T' => KullaniciRolu.ogretmen,
    'M' => KullaniciRolu.mudur,
    'V' => KullaniciRolu.veli,
    _ => null,
  };
}

/// Kod kullanma sonucunun kullanıcıya gösterilecek açıklaması (başarı hariç).
String kodHataMetni(String durum, KullaniciRolu tur) {
  switch (durum) {
    case 'cok_deneme':
      return 'Çok fazla hatalı deneme yapıldı. Bir saat sonra tekrar dene.';
    case 'rol_uyumsuz':
      return tur == KullaniciRolu.ogrenci
          ? 'Bu hesap öğrenci hesabı değil; şube kodu yalnızca öğrenci hesabıyla kullanılır.'
          : 'Bu hesap başka bir rolde kullanılıyor. ${tur.etiket} paneli için yeni bir hesap aç.';
    case 'zaten_uye':
      return 'Bu hesap zaten bir okula bağlı.';
    default:
      return switch (tur) {
        KullaniciRolu.ogrenci => 'Kod geçersiz. Şube kodunu öğretmeninden yeniden iste.',
        KullaniciRolu.veli => 'Kod geçersiz ya da süresi dolmuş. Çocuğundan yeni bir veli kodu üretmesini iste.',
        KullaniciRolu.ogretmen => 'Kod geçersiz, kullanılmış ya da süresi dolmuş. Okul müdüründen yeni kod iste.',
        KullaniciRolu.mudur => 'Kod geçersiz, kullanılmış ya da süresi dolmuş. DersNet ekibinden yeni kod iste.',
      };
  }
}

// ─── Panel yönlendirmesi ─────────────────────────────────────────────

const List<String> _ortakRotalar = ['/ayarlar', '/gizlilik-politikasi', '/create-ticket', '/my-tickets'];
const List<String> _okulPanelRotalari = ['/ogretmen', '/veli', '/mudur', '/okul/'];

/// Oturumu açık kullanıcı [konum] rotasındayken başka bir yere gönderilmeli mi?
/// Gönderilecek rota ya da (yerindeyse) null döner. Asıl yetki sunucudadır;
/// bu yalnızca her rolün kendi ekranlarını görmesini sağlar.
String? panelYonlendirmesi(KullaniciRolu rol, String konum) {
  final panelde = _okulPanelRotalari.any(konum.startsWith);
  if (rol == KullaniciRolu.ogrenci) return panelde ? rol.ev : null;
  if (_ortakRotalar.any(konum.startsWith)) return null;
  if (konum == rol.ev || konum.startsWith('${rol.ev}/')) return null;
  if (konum.startsWith('/okul/') && rol != KullaniciRolu.mudur) return null;
  return rol.ev;
}

// ─── Haftalık özet ───────────────────────────────────────────────────

class HaftaOzeti {
  final int toplamDk;
  final int aktifGun;
  final int planBlok;
  final int planTamam;
  final List<OzetGunu> gunler;

  const HaftaOzeti({
    this.toplamDk = 0,
    this.aktifGun = 0,
    this.planBlok = 0,
    this.planTamam = 0,
    this.gunler = const [],
  });

  int? get planUyumu => planBlok == 0 ? null : (planTamam * 100 / planBlok).round().clamp(0, 100);
  int get gunlukOrtalama => gunler.isEmpty ? 0 : (toplamDk / gunler.length).round();
}

/// Bir günün gösterilecek süresi: sunucunun ölçtüğü odak süresi; o gün ölçüm
/// yoksa (çevrimdışı çalışma) öğrencinin kendi kaydı.
int gunSuresi(OzetGunu g) => g.dk > 0 ? g.dk : g.beyanDk;

/// [gunler] eskiden yeniye sıralıdır. [geri] = 0 son 7 gün, 1 ondan önceki 7 gün.
HaftaOzeti haftaOzeti(List<OzetGunu> gunler, {int geri = 0}) {
  final son = gunler.length - geri * 7;
  if (son <= 0) return const HaftaOzeti();
  final bas = son - 7 < 0 ? 0 : son - 7;
  final dilim = gunler.sublist(bas, son);
  var dk = 0, aktif = 0, blok = 0, tamam = 0;
  for (final g in dilim) {
    final s = gunSuresi(g);
    dk += s;
    if (s > 0) aktif++;
    blok += g.planBlok;
    tamam += g.planTamam;
  }
  return HaftaOzeti(toplamDk: dk, aktifGun: aktif, planBlok: blok, planTamam: tamam, gunler: dilim);
}

/// İki haftanın süre farkı: "+1 sa 20 dk" / "-45 dk" / "aynı".
String haftaFarkiMetni(int buHafta, int gecenHafta) {
  final fark = buHafta - gecenHafta;
  if (fark == 0) return 'geçen haftayla aynı';
  return '${fark > 0 ? '+' : '-'}${sureMetni(fark.abs())} (geçen haftaya göre)';
}

/// "bugün" / "dün" / "3 gün önce" / "2 hafta önce" / "henüz yok"
String sonAktifMetni(DateTime? t, [DateTime? simdi]) {
  if (t == null) return 'henüz yok';
  final gun = sadeceGun(simdi ?? DateTime.now()).difference(sadeceGun(t)).inDays;
  if (gun <= 0) return 'bugün';
  if (gun == 1) return 'dün';
  if (gun < 14) return '$gun gün önce';
  return '${gun ~/ 7} hafta önce';
}

String riskEtiketi(RiskDurumu r) => switch (r) {
      RiskDurumu.pasif => '14 gündür çalışma yok',
      RiskDurumu.dusus => 'Çalışma süresi düşüyor',
      RiskDurumu.yeni => 'Yeni katıldı',
      RiskDurumu.yok => 'Düzenli',
    };

String riskAciklamasi(OgrenciSatiri o) => switch (o.risk) {
      RiskDurumu.pasif => 'Son iki haftada hiç çalışma kaydı yok. Son etkinlik: ${sonAktifMetni(o.sonAktif)}.',
      RiskDurumu.dusus =>
        'Üç haftadır düşüyor: ${sureMetni(o.dk2Onceki7g)} → ${sureMetni(o.dkOnceki7g)} → ${sureMetni(o.dk7g)}.',
      RiskDurumu.yeni => 'Şubeye yeni katıldı; henüz çalışma kaydı yok.',
      RiskDurumu.yok => 'Bu hafta ${sureMetni(o.dk7g)} çalıştı.',
    };

// ─── Sınıf ormanı ────────────────────────────────────────────────────

/// Şubenin birlikte büyüttüğü orman: her 5 saatlik ortak çalışma bir ağaç.
const int agacBasinaDakika = 300;

int ormanAgacSayisi(int toplamDk) => toplamDk < 0 ? 0 : toplamDk ~/ agacBasinaDakika;

/// Sıradaki ağaca ilerleme (0..1).
double siradakiAgacIlerlemesi(int toplamDk) =>
    toplamDk <= 0 ? 0 : (toplamDk % agacBasinaDakika) / agacBasinaDakika;

/// Şubenin haftalık ortak hedefi: öğrenci başına 5 saat.
int sinifHaftalikHedefi(int uye) => (uye < 1 ? 1 : uye) * 300;

// ─── Rapor metinleri ─────────────────────────────────────────────────

/// Velinin paylaşabileceği / saklayabileceği haftalık özet.
String veliOzetMetni(OgrenciOzeti o) {
  final bu = haftaOzeti(o.gunler);
  final gecen = haftaOzeti(o.gunler, geri: 1);
  final satirlar = <String>[
    '${o.ad} · haftalık çalışma özeti',
    'Toplam çalışma: ${sureMetni(bu.toplamDk)} (${haftaFarkiMetni(bu.toplamDk, gecen.toplamDk)})',
    'Çalışılan gün: ${bu.aktifGun} / 7',
    if (bu.planUyumu != null) 'Program uyumu: %${bu.planUyumu} (${bu.planTamam} / ${bu.planBlok} blok)',
    if (o.dersDk.isNotEmpty) 'En çok çalışılan ders (son 4 hafta): ${enCokCalisilanDers(o.dersDk)}',
    if (o.netler.isNotEmpty) 'Son deneme: ${o.netler.first.deneme} (${o.netler.first.alan}) ${netMetni(o.netler.first.net)} net',
  ];
  return satirlar.join('\n');
}

String enCokCalisilanDers(Map<String, int> dersDk) {
  if (dersDk.isEmpty) return '';
  final e = dersDk.entries.reduce((a, b) => b.value > a.value ? b : a);
  return '${e.key} (${sureMetni(e.value)})';
}

String netMetni(double net) => net == net.roundToDouble() ? net.toStringAsFixed(0) : net.toStringAsFixed(2);

/// Müdürün dönem / hafta raporu: yalnızca toplamlar, öğrenci adı içermez.
String okulRaporuMetni(OkulOzeti o) {
  final b = StringBuffer()
    ..writeln('${o.okul} · DersNet çalışma raporu')
    ..writeln('Tarih: ${o.tarih}')
    ..writeln()
    ..writeln('Kayıtlı öğrenci: ${o.ogrenci}  ·  Öğretmen: ${o.ogretmen}  ·  Bağlı veli: ${o.veli}')
    ..writeln('Son 7 günde çalışan öğrenci: ${o.aktif7g} (%${o.aktifOrani})')
    ..writeln('Öğrenci başına haftalık ortalama: ${sureMetni(o.ortDk7g)}')
    ..writeln('Rehber öğretmenin ilgilenmesi gereken öğrenci: ${o.risk}')
    ..writeln()
    ..writeln('Şubeler (son 7 gün)');
  for (final s in o.subeler) {
    b.writeln(
        '${s.sube.etiket}: ${s.ogrenci} öğrenci, %${s.aktifOrani} aktif, ortalama ${sureMetni(s.ortDk7g)}, ${s.risk} uyarı');
  }
  if (o.haftalar.isNotEmpty) {
    b
      ..writeln()
      ..writeln('Haftalık toplam çalışma');
    for (final h in o.haftalar) {
      final t = DateTime.tryParse(h.bas);
      b.writeln('${t == null ? h.bas : kisaTarih(t)} haftası: ${sureMetni(h.toplamDk)}, ${h.aktif} öğrenci');
    }
  }
  return b.toString().trimRight();
}
