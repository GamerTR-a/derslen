/// Bahçe kataloğu — bitkiler, dekorlar ve büyüme kuralları.
/// Fiyatlar yalnızca gösterim içindir; gerçek fiyat sunucudaki
/// `garden_items` tablosundan okunur (bkz. supabase_schema.sql §13).
library;

enum BahceUrunTip { tohum, dekor, saksi }

class BahceUrunu {
  final String id;
  final String ad;
  final String emoji;
  final int fiyat;
  final BahceUrunTip tip;
  final String aciklama;

  const BahceUrunu({
    required this.id,
    required this.ad,
    required this.emoji,
    required this.fiyat,
    required this.tip,
    this.aciklama = '',
  });
}

const List<BahceUrunu> bahceUrunleri = [
  BahceUrunu(id: 'seed_papatya', ad: 'Papatya', emoji: '🌼', fiyat: 20, tip: BahceUrunTip.tohum, aciklama: 'Hızlı büyür, başlangıç için ideal.'),
  BahceUrunu(id: 'seed_lale', ad: 'Lale', emoji: '🌷', fiyat: 30, tip: BahceUrunTip.tohum, aciklama: 'Baharın habercisi.'),
  BahceUrunu(id: 'seed_gunebakan', ad: 'Ayçiçeği', emoji: '🌻', fiyat: 35, tip: BahceUrunTip.tohum, aciklama: 'Güneşi takip eder, sen de hedefini.'),
  BahceUrunu(id: 'seed_kaktus', ad: 'Kaktüs', emoji: '🌵', fiyat: 40, tip: BahceUrunTip.tohum, aciklama: 'Susuzluğa dayanıklı; solması zor.'),
  BahceUrunu(id: 'seed_limon', ad: 'Limon Fidesi', emoji: '🍋', fiyat: 45, tip: BahceUrunTip.tohum, aciklama: 'Emeğinin meyvesini verir.'),
  BahceUrunu(id: 'seed_hus', ad: 'Gümüş Huş', emoji: '🌳', fiyat: 60, tip: BahceUrunTip.tohum, aciklama: 'Uzun soluklu çalışmanın simgesi.'),
  BahceUrunu(id: 'seed_cam', ad: 'Çam Fidanı', emoji: '🌲', fiyat: 70, tip: BahceUrunTip.tohum, aciklama: 'Dört mevsim yeşil.'),
  BahceUrunu(id: 'seed_kiraz', ad: 'Kiraz Fidanı', emoji: '🌸', fiyat: 80, tip: BahceUrunTip.tohum, aciklama: 'Tam büyüyünce çiçek açar.'),
  BahceUrunu(id: 'deco_fener', ad: 'Bahçe Feneri', emoji: '🏮', fiyat: 40, tip: BahceUrunTip.dekor),
  BahceUrunu(id: 'deco_bank', ad: 'Ahşap Bank', emoji: '🪑', fiyat: 50, tip: BahceUrunTip.dekor),
  BahceUrunu(id: 'deco_kus', ad: 'Kuş Evi', emoji: '🐦', fiyat: 60, tip: BahceUrunTip.dekor),
  BahceUrunu(id: 'deco_gol', ad: 'Küçük Gölet', emoji: '🪷', fiyat: 120, tip: BahceUrunTip.dekor),
  BahceUrunu(id: 'pot_extra', ad: 'Yeni Saksı', emoji: '🪴', fiyat: 100, tip: BahceUrunTip.saksi, aciklama: 'Bahçene bir bitki yeri daha ekler.'),
];

BahceUrunu? bahceUrunuBul(String id) {
  for (final u in bahceUrunleri) {
    if (u.id == id) return u;
  }
  return null;
}

/// Onboarding sonunda sürpriz kutudan çıkabilecek ücretsiz tohumlar.
const List<String> hediyeTohumlari = ['seed_hus', 'seed_limon', 'seed_lale', 'seed_gunebakan', 'seed_kiraz'];

/// Büyüme puanı eşikleri: tohum → filiz → fide → olgun.
const List<int> buyumeEsikleri = [0, 2, 5, 9];
const List<String> buyumeEtiketleri = ['Tohum', 'Filiz', 'Fide', 'Olgun'];

/// Bir bitki bu kadar gün sulanmazsa solar.
const int solmaGunu = 2;

/// Günlük su damlası kazanma sınırları.
const int gunlukCheckinDamla = 3;
const int gunlukKartDamlaTavani = 10;
const int baslangicSaksiSayisi = 3;
const int maksSaksiSayisi = 9;
