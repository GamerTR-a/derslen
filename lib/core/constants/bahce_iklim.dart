/// Orman için iklim bölgeleri. Her bölgenin kendi ormanı vardır; olgunlaşan
/// bitki, o an seçili bölgenin ormanına taşınır. Tamamı kozmetiktir ve
/// cihazda tutulur (sunucu kataloğuna bağlı değildir).
library;

import 'dart:math';

class IklimBolgesi {
  final String id;

  /// Coğrafi bölge (ör. "Amazon Havzası").
  final String ad;

  /// İklim tipi (ör. "Ekvatoral iklim").
  final String iklimTipi;
  final String aciklama;
  final String bitkiOrtusu;

  /// Bu iklimde sulandığında daha hızlı büyüyen tohumlar.
  final List<String> sevenler;

  /// Orman büyüdükçe kendiliğinden yerleşen yerli tür.
  final String yerliTur;

  const IklimBolgesi({
    required this.id,
    required this.ad,
    required this.iklimTipi,
    required this.aciklama,
    required this.bitkiOrtusu,
    required this.sevenler,
    required this.yerliTur,
  });

  String get yerliTurId => 'yerli_$id';
}

const String varsayilanIklim = 'iliman';

const List<IklimBolgesi> iklimBolgeleri = [
  IklimBolgesi(
    id: 'iliman',
    ad: 'Doğu Karadeniz',
    iklimTipi: 'Ilıman okyanusal iklim',
    aciklama: 'Her mevsim yağışlı, yazlar serin, kışlar ılık. Yıl boyu yeşil kalan gür ormanlar.',
    bitkiOrtusu: 'Geniş ve iğne yapraklı karışık orman',
    sevenler: ['seed_kiraz', 'seed_hus', 'seed_cam', 'seed_papatya'],
    yerliTur: 'Kayın',
  ),
  IklimBolgesi(
    id: 'akdeniz',
    ad: 'Akdeniz Kıyıları',
    iklimTipi: 'Akdeniz iklimi',
    aciklama: 'Yazlar sıcak ve kurak, kışlar ılık ve yağışlı. Kuraklığa dayanıklı, sert yapraklı bitkiler.',
    bitkiOrtusu: 'Maki ve kızılçam ormanı',
    sevenler: ['seed_limon', 'seed_cam', 'seed_gunebakan'],
    yerliTur: 'Zeytin',
  ),
  IklimBolgesi(
    id: 'step',
    ad: 'İç Anadolu',
    iklimTipi: 'Karasal iklim',
    aciklama: 'Yazlar sıcak ve kurak, kışlar soğuk ve karlı. İlkbahar yağmurlarıyla yeşerip yazın sararan otlar.',
    bitkiOrtusu: 'Bozkır (step)',
    sevenler: ['seed_lale', 'seed_gunebakan', 'seed_papatya', 'seed_kiraz'],
    yerliTur: 'Gelincik',
  ),
  IklimBolgesi(
    id: 'ekvatoral',
    ad: 'Amazon Havzası',
    iklimTipi: 'Ekvatoral iklim',
    aciklama: 'Yıl boyu sıcak ve her gün yağışlı. Dünyanın en zengin bitki çeşitliliği burada.',
    bitkiOrtusu: 'Tropikal yağmur ormanı',
    sevenler: ['seed_limon', 'seed_gunebakan'],
    yerliTur: 'Muz ağacı',
  ),
  IklimBolgesi(
    id: 'savan',
    ad: 'Doğu Afrika',
    iklimTipi: 'Savan iklimi',
    aciklama: 'Yıl boyu sıcak; yazlar yağışlı, kışlar kurak. Uzun otların arasında seyrek ağaçlar.',
    bitkiOrtusu: 'Savan',
    sevenler: ['seed_kaktus', 'seed_gunebakan', 'seed_limon'],
    yerliTur: 'Akasya',
  ),
  IklimBolgesi(
    id: 'col',
    ad: 'Büyük Sahra',
    iklimTipi: 'Çöl iklimi',
    aciklama: 'Yağış yok denecek kadar az, gece ile gündüz arasındaki sıcaklık farkı çok fazla.',
    bitkiOrtusu: 'Kurakçıl bitkiler ve vahalar',
    sevenler: ['seed_kaktus'],
    yerliTur: 'Hurma',
  ),
  IklimBolgesi(
    id: 'tayga',
    ad: 'Sibirya',
    iklimTipi: 'Sert karasal iklim',
    aciklama: 'Kışlar çok uzun ve dondurucu, yazlar kısa ve serin. Dünyanın en geniş orman kuşağı.',
    bitkiOrtusu: 'İğne yapraklı orman (tayga)',
    sevenler: ['seed_cam', 'seed_hus'],
    yerliTur: 'Ladin',
  ),
  IklimBolgesi(
    id: 'tundra',
    ad: 'Kuzey Kutup Kuşağı',
    iklimTipi: 'Tundra iklimi',
    aciklama: 'Yılın büyük bölümü donmuş toprak. Kısa yazda buzlar çözülünce yer yeşerir.',
    bitkiOrtusu: 'Yosun, liken ve cılız otlar',
    sevenler: ['seed_hus', 'seed_papatya'],
    yerliTur: 'Pamuk otu',
  ),
];

IklimBolgesi iklimBul(String? id) {
  for (final b in iklimBolgeleri) {
    if (b.id == id) return b;
  }
  return iklimBolgeleri.first;
}

/// İklimini seven bitki, sulandığında bu kadar fazladan büyür.
const int iklimSulamaBonusu = 1;

/// Ormana taşınan her bu kadar bitkide bir yerli tür kendiliğinden yerleşir.
const int yerliTurAraligi = 3;
const int maksYerliTur = 6;

int yerliTurSayisi(int bitkiSayisi) => min(bitkiSayisi ~/ yerliTurAraligi, maksYerliTur);

String ormanSeviyesi(int bitkiSayisi) {
  if (bitkiSayisi == 0) return 'Boş arazi';
  if (bitkiSayisi < 3) return 'Fidanlık';
  if (bitkiSayisi < 6) return 'Koru';
  if (bitkiSayisi < 12) return 'Genç orman';
  return 'Olgun orman';
}
