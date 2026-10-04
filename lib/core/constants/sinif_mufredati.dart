/// 9, 10 ve 11. sınıf müfredatı — Türkiye Yüzyılı Maarif Modeli.
///
/// Tema/ünite ve konu adları MEB'in 2026-2027 Anadolu Lisesi taslak çerçeve
/// yıllık planlarından (tymm.meb.gov.tr) alınmış, ekranda okunabilsin diye
/// kısaltılmıştır. Her konu; soru havuzundaki ve hazır kartlardaki karşılığı
/// olan başlıklara bağlanır, böylece sınıf ve konu bazında test, deneme ve
/// kart tekrarı yapılabilir.
///
/// Din Kültürü ve yabancı dil için resmî çerçeve plan yayımlanmadığından bu
/// dersler hazır listede yoktur; öğrenci Müfredatım ekranından ekleyebilir.
library;

import '../../data/models/konu.dart';
import 'app_constants.dart';

class SinifKonusu {
  final String id;
  final int sinif;
  final String ders;
  final String tema;
  final String baslik;

  /// Soru havuzundaki karşılıklar: `Ders>Konu` ya da `Ders>Konu>Alt Başlık`.
  /// (Dersi ve konu adı bu konuyla aynı olan sorular ayrıca yazılmadan eşleşir.)
  final List<String> havuz;

  /// Hazır kartlardaki karşılıklar: `deste>ünite`.
  final List<String> kart;

  const SinifKonusu(this.id, this.sinif, this.ders, this.tema, this.baslik, [this.havuz = const [], this.kart = const []]);

  Konu get konu => Konu(id: id, ders: ders, alan: SinavAlani.TYT, baslik: baslik);

  /// Havuzdaki bir soru (ya da soru üreteci) bu konuya ait mi?
  bool soruEslesir(String soruDersi, String soruKonusu, String altBaslik) =>
      (soruDersi == ders && soruKonusu == baslik) ||
      havuz.contains('$soruDersi>$soruKonusu') ||
      havuz.contains('$soruDersi>$soruKonusu>$altBaslik');

  /// Hazır bir kart bu konuya ait mi? ([kartId] `<konu id>-k…` ile başlıyorsa
  /// kart doğrudan bu konu için yazılmıştır.)
  bool kartEslesir(String kartId, String deste, String unite) =>
      kartId.startsWith('$id-') || kart.contains('$deste>$unite');
}

/// Hazır müfredatı olan sınıflar.
const List<int> mufredatliSiniflar = [9, 10, 11];

/// Profildeki sınıf metninden ("10. Sınıf") sınıf numarası; lise ara sınıfı
/// değilse (12, mezun, üniversite…) null.
int? sinifNo(String? sinifSeviyesi) {
  if (sinifSeviyesi == null) return null;
  final m = RegExp(r'^\s*(\d{1,2})').firstMatch(sinifSeviyesi);
  return m == null ? null : int.tryParse(m.group(1)!);
}

/// Hazır Maarif müfredatı kullanılan sınıf mı (9, 10, 11)?
int? araSinif(String? sinifSeviyesi) {
  final s = sinifNo(sinifSeviyesi);
  return mufredatliSiniflar.contains(s) ? s : null;
}

const _mat = 'Matematik';
const _geo = 'Geometri';
const _fiz = 'Fizik';
const _kim = 'Kimya';
const _biy = 'Biyoloji';
const _edb = 'Türk Dili ve Edebiyatı';
const _tr = 'Türkçe';
const _tar = 'Tarih';
const _cog = 'Coğrafya';
const _fel = 'Felsefe';

const List<SinifKonusu> sinifMufredati = [
  // ═══ 9. SINIF ═══════════════════════════════════════════════════════
  // Matematik
  SinifKonusu('s9-mat-01', 9, _mat, 'Sayılar', 'Üslü ve Köklü Gösterimler',
      ['$_mat>Üslü ve Köklü Sayılar', '$_mat>Temel Kavramlar>Üslü Sayılar', '$_mat>Temel Kavramlar>Köklü Sayılar'],
      ['matematik>Üslü Sayılar', 'matematik>Köklü Sayılar']),
  SinifKonusu('s9-mat-02', 9, _mat, 'Sayılar', 'Gerçek Sayı Aralıkları ve Kümeler', ['$_mat>Kümeler'], ['matematik>Kümeler']),
  SinifKonusu('s9-mat-03', 9, _mat, 'Sayılar', 'Sayı Kümeleri ve İşlem Özellikleri', [
    '$_mat>Temel Kavramlar>Tek ve Çift Sayılar',
    '$_mat>Temel Kavramlar>Rasyonel Sayılar',
    '$_mat>Temel Kavramlar>Ardışık Sayılar',
    '$_mat>Temel Kavramlar>Sayı Basamakları',
  ], ['matematik>Temel Kavramlar', 'matematik>Rasyonel Sayılar', 'matematik>Sayı Basamakları']),
  SinifKonusu('s9-mat-04', 9, _mat, 'Sayılar', 'Cebirsel İfadeler ve Özdeşlikler', ['$_mat>Çarpanlara Ayırma'], ['matematik>Özdeşlikler']),
  SinifKonusu('s9-mat-05', 9, _mat, 'Nicelikler ve Değişimler', 'Doğrusal Fonksiyonlar'),
  SinifKonusu('s9-mat-06', 9, _mat, 'Nicelikler ve Değişimler', 'Mutlak Değer Fonksiyonu', [
    '$_mat>Mutlak Değer ve Eşitsizlikler>Mutlak Değerli Denklemler',
    '$_mat>Mutlak Değer ve Eşitsizlikler>Mutlak Değerli Eşitsizlikler',
    '$_mat>Temel Kavramlar>Mutlak Değer',
  ], ['matematik>Mutlak Değer']),
  SinifKonusu('s9-mat-07', 9, _mat, 'Nicelikler ve Değişimler', 'Doğrusal Denklem ve Eşitsizlikler', [
    '$_mat>Denklemler',
    '$_mat>Mutlak Değer ve Eşitsizlikler>Basit Eşitsizlikler',
    '$_mat>Problemler',
    '$_mat>Oran – Orantı',
  ], ['matematik>Basit Eşitsizlikler', 'matematik>Problemler', 'matematik>Oran – Orantı']),
  SinifKonusu('s9-mat-08', 9, _mat, 'Geometrik Şekiller', 'Üçgende Açı ve Kenar Bağıntıları', ['$_geo>Doğruda ve Üçgende Açılar'],
      ['geometri>Doğruda Açılar', 'geometri>Üçgende Açılar', 'geometri>Üçgende Açı-Kenar']),
  SinifKonusu('s9-mat-09', 9, _mat, 'Eşlik ve Benzerlik', 'Geometrik Dönüşümler', ['$_geo>Analitik Geometri>Dönüşümler']),
  SinifKonusu('s9-mat-10', 9, _mat, 'Eşlik ve Benzerlik', 'Eşlik ve Benzerlik', ['$_geo>Benzerlik'], ['geometri>Benzerlik']),
  SinifKonusu('s9-mat-11', 9, _mat, 'Eşlik ve Benzerlik', 'Tales, Öklid ve Pisagor Teoremleri', ['$_geo>Dik Üçgen'],
      ['geometri>Dik Üçgen', 'geometri>Özel Üçgenler']),
  SinifKonusu('s9-mat-12', 9, _mat, 'Algoritma ve Bilişim', 'Algoritma Temelli Problemler'),
  SinifKonusu('s9-mat-13', 9, _mat, 'Algoritma ve Bilişim', 'Mantık Bağlaçları ve Niceleyiciler', ['$_mat>Mantık'], ['matematik>Mantık']),
  SinifKonusu('s9-mat-14', 9, _mat, 'İstatistiksel Araştırma Süreci', 'Tek Nicel Değişkenli Veri Dağılımları', ['$_mat>Veri ve İstatistik'],
      ['matematik>Veri ve İstatistik']),
  SinifKonusu('s9-mat-15', 9, _mat, 'Veriden Olasılığa', 'Deneysel ve Teorik Olasılık', ['$_mat>Sayma ve Olasılık>Olasılık'], ['matematik>Olasılık']),
  // Fizik
  SinifKonusu('s9-fiz-01', 9, _fiz, 'Fizik Bilimi ve Kariyer Keşfi', 'Fizik Bilimi ve Alt Dalları'),
  SinifKonusu('s9-fiz-02', 9, _fiz, 'Fizik Bilimi ve Kariyer Keşfi', 'Fizik Bilimine Yön Verenler ve Kariyer'),
  SinifKonusu('s9-fiz-03', 9, _fiz, 'Kuvvet ve Hareket', 'Temel ve Türetilmiş Nicelikler', ['$_fiz>Fizik Bilimine Giriş'], ['fizik>Fizik Bilimine Giriş']),
  SinifKonusu('s9-fiz-04', 9, _fiz, 'Kuvvet ve Hareket', 'Vektörler'),
  SinifKonusu('s9-fiz-05', 9, _fiz, 'Kuvvet ve Hareket', 'Doğadaki Temel Kuvvetler'),
  SinifKonusu('s9-fiz-06', 9, _fiz, 'Kuvvet ve Hareket', 'Hareket ve Hareket Türleri', ['$_fiz>Kuvvet ve Hareket>Ortalama Sürat']),
  SinifKonusu('s9-fiz-07', 9, _fiz, 'Akışkanlar', 'Katı ve Sıvı Basıncı', ['$_fiz>Basınç'], ['fizik>Basınç']),
  SinifKonusu('s9-fiz-08', 9, _fiz, 'Akışkanlar', 'Açık Hava Basıncı'),
  SinifKonusu('s9-fiz-09', 9, _fiz, 'Akışkanlar', 'Kaldırma Kuvveti', ['$_fiz>Kaldırma Kuvveti'], ['fizik>Kaldırma Kuvveti']),
  SinifKonusu('s9-fiz-10', 9, _fiz, 'Akışkanlar', 'Bernoulli İlkesi'),
  SinifKonusu('s9-fiz-11', 9, _fiz, 'Enerji', 'Isı, Sıcaklık ve İç Enerji', [], ['fizik>Isı ve Sıcaklık']),
  SinifKonusu('s9-fiz-12', 9, _fiz, 'Enerji', 'Öz Isı ve Isı Sığası', ['$_fiz>Isı ve Sıcaklık>Öz Isı', '$_fiz>Isı ve Sıcaklık>Isı Alışverişi']),
  SinifKonusu('s9-fiz-13', 9, _fiz, 'Enerji', 'Hâl Değişimi ve Isıl Denge', ['$_fiz>Isı ve Sıcaklık>Hâl Değişimi']),
  SinifKonusu('s9-fiz-14', 9, _fiz, 'Enerji', 'Isı Aktarım Yolları'),
  // Kimya
  SinifKonusu('s9-kim-01', 9, _kim, 'Etkileşim', 'Kimya Hayattır', ['$_kim>Kimya Bilimi', '$_kim>Kimya Her Yerde'],
      ['kimya>Kimya Bilimi', 'kimya>Kimya Her Yerde']),
  SinifKonusu('s9-kim-02', 9, _kim, 'Etkileşim', 'Kimyasal Maddeler ve Güvenlik'),
  SinifKonusu('s9-kim-03', 9, _kim, 'Etkileşim', 'Atom Teorileri ve Atomun Yapısı', [
    '$_kim>Atomun Yapısı>Temel Tanecikler',
    '$_kim>Atomun Yapısı>İzotop Atomlar',
    '$_kim>Atomun Yapısı>Atom Modelleri',
    '$_kim>Atomun Yapısı>İyonlar',
  ], ['kimya>Atomun Yapısı', 'kimya>Atom Modelleri', 'kimya>Atomik Yapı']),
  SinifKonusu('s9-kim-04', 9, _kim, 'Etkileşim', 'Orbitaller ve Elektron Dizilimi',
      ['$_kim>Atomun Yapısı>Elektron Dizilimi', '$_kim>Atomun Yapısı>Orbitaller']),
  SinifKonusu('s9-kim-05', 9, _kim, 'Etkileşim', 'Periyodik Tablo ve Periyodik Özellikler', ['$_kim>Periyodik Sistem'],
      ['kimya>Periyodik Sistem', 'kimya>Periyodik Tablo']),
  SinifKonusu('s9-kim-06', 9, _kim, 'Çeşitlilik', 'Metalik, İyonik ve Kovalent Bağ', [
    '$_kim>Kimyasal Türler Arası Etkileşimler>İyonik ve Kovalent Bağ',
    '$_kim>Kimyasal Türler Arası Etkileşimler>İyonik Bağ',
  ], ['kimya>Kimyasal Bağlar']),
  SinifKonusu('s9-kim-07', 9, _kim, 'Çeşitlilik', 'Lewis Yapısı ve Molekül Polarlığı', ['$_kim>Kimyasal Türler Arası Etkileşimler>Molekül Polarlığı']),
  SinifKonusu('s9-kim-08', 9, _kim, 'Çeşitlilik', 'Bileşiklerin Adlandırılması'),
  SinifKonusu('s9-kim-09', 9, _kim, 'Çeşitlilik', 'Moleküller Arası Etkileşimler', ['$_kim>Kimyasal Türler Arası Etkileşimler>Hidrojen Bağı'],
      ['kimya>Etkileşimler']),
  SinifKonusu('s9-kim-10', 9, _kim, 'Çeşitlilik', 'Katılar ve Sıvılar', ['$_kim>Maddenin Hâlleri'], ['kimya>Maddenin Hâlleri']),
  SinifKonusu('s9-kim-11', 9, _kim, 'Sürdürülebilirlik', 'Metal Nanoparçacıklar ve Yeşil Kimya'),
  // Biyoloji
  SinifKonusu('s9-biy-01', 9, _biy, 'Yaşam', 'Biyoloji ve Bilimin Doğası', [], ['biyoloji>Yaşam Bilimi']),
  SinifKonusu('s9-biy-02', 9, _biy, 'Yaşam', 'Canlıların Ortak Özellikleri', ['$_biy>Yaşam Bilimi Biyoloji']),
  SinifKonusu('s9-biy-03', 9, _biy, 'Yaşam', 'İnorganik Moleküller'),
  SinifKonusu('s9-biy-04', 9, _biy, 'Yaşam', 'Organik Moleküller', ['$_biy>Canlıların Temel Bileşenleri'], ['biyoloji>Temel Bileşenler']),
  SinifKonusu('s9-biy-05', 9, _biy, 'Organizasyon', 'Hücre ve Organeller', ['$_biy>Hücre>Organeller', '$_biy>Hücre>Prokaryot ve Ökaryot Hücre'],
      ['biyoloji>Hücre']),
  SinifKonusu('s9-biy-06', 9, _biy, 'Organizasyon', 'Hücre Zarından Madde Geçişleri', ['$_biy>Hücre>Osmoz', '$_biy>Hücre>Madde Geçişleri']),
  SinifKonusu('s9-biy-07', 9, _biy, 'Organizasyon', 'Canlıların Sınıflandırılması', ['$_biy>Canlıların Sınıflandırılması'], ['biyoloji>Sınıflandırma']),
  SinifKonusu('s9-biy-08', 9, _biy, 'Organizasyon', 'Biyoçeşitlilik'),
  // Türk Dili ve Edebiyatı
  SinifKonusu('s9-edb-01', 9, _edb, 'Sözün İnceliği', 'Şiir İnceleme', ['$_edb>Şiir Bilgisi', '$_edb>Söz Sanatları'],
      ['edebiyat>Şiir Bilgisi', 'edebiyat>Söz Sanatları']),
  SinifKonusu('s9-edb-02', 9, _edb, 'Sözün İnceliği', 'Deneme'),
  SinifKonusu('s9-edb-03', 9, _edb, 'Anlam Arayışı', 'Hikâye'),
  SinifKonusu('s9-edb-04', 9, _edb, 'Anlam Arayışı', 'Anı'),
  SinifKonusu('s9-edb-05', 9, _edb, 'Anlamın Yapı Taşları', 'Gezi Yazısı'),
  SinifKonusu('s9-edb-06', 9, _edb, 'Dilin Zenginliği', 'Roman ve Tiyatro'),
  SinifKonusu('s9-edb-07', 9, _edb, 'Dilin Zenginliği', 'Eleştiri ve Otobiyografi'),
  SinifKonusu('s9-edb-08', 9, _edb, 'Dil ve Anlatım (temalara yayılır)', 'Sözcükte ve Cümlede Anlam', ['$_tr>Sözcükte Anlam', '$_tr>Cümlede Anlam'],
      ['turkce>Sözcükte Anlam', 'turkce>Cümlede Anlam']),
  SinifKonusu('s9-edb-09', 9, _edb, 'Dil ve Anlatım (temalara yayılır)', 'Paragraf ve Anlatım', ['$_tr>Paragraf'], ['turkce>Paragraf']),
  SinifKonusu('s9-edb-10', 9, _edb, 'Dil ve Anlatım (temalara yayılır)', 'Yazım ve Noktalama', ['$_tr>Yazım Kuralları', '$_tr>Noktalama İşaretleri'],
      ['turkce>Yazım Kuralları', 'turkce>Noktalama İşaretleri']),
  // Tarih
  SinifKonusu('s9-tar-01', 9, _tar, 'Geçmişin İnşa Sürecinde Tarih', 'Tarihin Doğası ve Faydaları', ['$_tar>Tarih ve Zaman'], ['tarih>Tarih Bilimi']),
  SinifKonusu('s9-tar-02', 9, _tar, 'Geçmişin İnşa Sürecinde Tarih', 'Tarihsel Bilginin Üretimi ve Dijitalleşme'),
  SinifKonusu('s9-tar-03', 9, _tar, 'Eski Çağ Medeniyetleri', 'Tarım Devrimi, Yerleşme ve Ekonomi'),
  SinifKonusu('s9-tar-04', 9, _tar, 'Eski Çağ Medeniyetleri', 'Eski Çağ\'da Yönetim, Ordu ve Hukuk', ['$_tar>İlk Çağ Uygarlıkları'], ['tarih>İlk Çağ']),
  SinifKonusu('s9-tar-05', 9, _tar, 'Eski Çağ Medeniyetleri', 'Eski Çağ\'da İnanç, Bilim ve Sanat'),
  SinifKonusu('s9-tar-06', 9, _tar, 'Eski Çağ Medeniyetleri', 'Türklerde Konargöçer Yaşam', ['$_tar>İlk Türk Devletleri'], ['tarih>İlk Türk Devletleri']),
  SinifKonusu('s9-tar-07', 9, _tar, 'Orta Çağ Medeniyetleri', 'Orta Çağ\'da Kitlesel Göçler'),
  SinifKonusu('s9-tar-08', 9, _tar, 'Orta Çağ Medeniyetleri', 'Orta Çağ\'da Yönetim ve Ordu', ['$_tar>İslam Tarihi'], ['tarih>İslam Tarihi']),
  SinifKonusu('s9-tar-09', 9, _tar, 'Orta Çağ Medeniyetleri', 'Orta Çağ\'da Ticaret Yolları'),
  SinifKonusu('s9-tar-10', 9, _tar, 'Orta Çağ Medeniyetleri', 'Orta Çağ\'da Bilim, Kültür ve Sanat'),
  // Coğrafya
  SinifKonusu('s9-cog-01', 9, _cog, 'Coğrafyanın Doğası', 'Coğrafya Bilimi ve Bölümleri', ['$_cog>Doğa ve İnsan']),
  SinifKonusu('s9-cog-02', 9, _cog, 'Mekânsal Bilgi Teknolojileri', 'Haritalar', ['$_cog>Harita Bilgisi'], ['cografya>Harita Bilgisi', 'cografya>Harita']),
  SinifKonusu('s9-cog-03', 9, _cog, 'Mekânsal Bilgi Teknolojileri', 'Türkiye\'nin Coğrafi Konumu', ['$_cog>Coğrafi Konum'], ['cografya>Coğrafi Konum']),
  SinifKonusu('s9-cog-04', 9, _cog, 'Mekânsal Bilgi Teknolojileri', 'Mekânsal Bilgi Teknolojileri (CBS)'),
  SinifKonusu('s9-cog-05', 9, _cog, 'Doğal Sistemler ve Süreçler', 'Hava Olayları ve İklim Elemanları', [
    '$_cog>İklim Bilgisi>Sıcaklık',
    '$_cog>İklim Bilgisi>Basınç ve Rüzgârlar',
    '$_cog>İklim Bilgisi>Yağış Tipleri',
    '$_cog>İklim Bilgisi>Rüzgârlar',
  ], ['cografya>İklim', 'cografya>Atmosfer']),
  SinifKonusu('s9-cog-06', 9, _cog, 'Doğal Sistemler ve Süreçler', 'İklim Türleri',
      ['$_cog>İklim Bilgisi>İklim Tipleri', '$_cog>İklim Bilgisi>Muson İklimi'], ['cografya>Türkiye İklimi']),
  SinifKonusu('s9-cog-07', 9, _cog, 'Doğal Sistemler ve Süreçler', 'İklim Sistemindeki Değişiklikler'),
  SinifKonusu('s9-cog-08', 9, _cog, 'Beşerî Sistemler ve Süreçler', 'Nüfusun Değişimi, Dağılışı ve Hareketleri',
      ['$_cog>Nüfus>Nüfusun Dağılışı', '$_cog>Göç'], ['cografya>Nüfus', 'cografya>Göç']),
  SinifKonusu('s9-cog-09', 9, _cog, 'Beşerî Sistemler ve Süreçler', 'Nüfus Piramitleri ve Politikaları',
      ['$_cog>Nüfus>Nüfus Piramitleri', '$_cog>Nüfus>Nüfus Politikaları']),
  SinifKonusu('s9-cog-10', 9, _cog, 'Ekonomik Faaliyetler ve Etkileri', 'Ekonomik Faaliyetleri Etkileyen Faktörler'),
  SinifKonusu('s9-cog-11', 9, _cog, 'Afetler ve Sürdürülebilir Çevre', 'Tehlike, Risk ve Afet Türleri', ['$_cog>Doğal Afetler'],
      ['cografya>Doğal Afetler']),
  SinifKonusu('s9-cog-12', 9, _cog, 'Bölgeler, Ülkeler ve Küresel Bağlantılar', 'Bölge ve Bölge Sınırı', [], ['cografya>Bölgeler']),

  // ═══ 10. SINIF ══════════════════════════════════════════════════════
  // Matematik
  SinifKonusu('s10-mat-01', 10, _mat, 'Geometrik Şekiller', 'Dik Üçgende Trigonometrik Oranlar',
      ['$_mat>Trigonometri>Özel Açılar', '$_mat>Trigonometri>Trigonometrik Özdeşlikler']),
  SinifKonusu('s10-mat-02', 10, _mat, 'Geometrik Şekiller', 'Üçgende Yardımcı Elemanlar', ['$_geo>Üçgende Yardımcı Elemanlar'],
      ['geometri>Üçgende Yardımcı Elemanlar']),
  SinifKonusu('s10-mat-03', 10, _mat, 'Geometrik Şekiller', 'Üçgenin Alanı', ['$_geo>Üçgende Alan'], ['geometri>Üçgende Alan']),
  SinifKonusu('s10-mat-04', 10, _mat, 'Geometrik Şekiller', 'Sinüs ve Kosinüs Teoremleri'),
  SinifKonusu('s10-mat-05', 10, _mat, 'İstatistiksel Araştırma Süreci', 'İki Kategorik Değişkenli Veriler'),
  SinifKonusu('s10-mat-06', 10, _mat, 'Sayılar', 'Asal Çarpanlar ve Bölenler',
      ['$_mat>Temel Kavramlar>Asal Çarpanlar ve Bölen Sayısı', '$_mat>Temel Kavramlar>Faktöriyel']),
  SinifKonusu('s10-mat-07', 10, _mat, 'Sayılar', 'EBOB ve EKOK', ['$_mat>Temel Kavramlar>EBOB – EKOK'], ['matematik>EBOB – EKOK']),
  SinifKonusu('s10-mat-08', 10, _mat, 'Sayılar', 'Bölünebilme', ['$_mat>Temel Kavramlar>Bölünebilme', '$_mat>Temel Kavramlar>Bölme ve Kalan'],
      ['matematik>Bölünebilme']),
  SinifKonusu('s10-mat-09', 10, _mat, 'Nicelikler ve Değişimler', 'Fonksiyon Kavramı', [
    '$_mat>Fonksiyonlar>Fonksiyonun Değeri',
    '$_mat>Fonksiyonlar>Tanım Kümesi',
    '$_mat>Fonksiyonlar>Fonksiyonda Değer',
  ], ['matematik>Fonksiyonlar']),
  SinifKonusu('s10-mat-10', 10, _mat, 'Nicelikler ve Değişimler', 'Karesel Fonksiyonlar', ['$_mat>Parabol', '$_mat>İkinci Dereceden Denklemler'],
      ['matematik>Parabol', 'matematik>İkinci Dereceden Denklemler']),
  SinifKonusu('s10-mat-11', 10, _mat, 'Nicelikler ve Değişimler', 'Karekök ve Rasyonel Fonksiyonlar'),
  SinifKonusu('s10-mat-12', 10, _mat, 'Nicelikler ve Değişimler', 'Ters Fonksiyon', ['$_mat>Fonksiyonlar>Bileşke ve Ters Fonksiyon']),
  SinifKonusu('s10-mat-13', 10, _mat, 'Nicelikler ve Değişimler', 'Fonksiyonlarla Denklem ve Eşitsizlikler'),
  SinifKonusu('s10-mat-14', 10, _mat, 'Sayma, Algoritma ve Bilişim', 'Sayma Stratejileri', [
    '$_mat>Sayma ve Olasılık>Permütasyon',
    '$_mat>Sayma ve Olasılık>Kombinasyon',
    '$_mat>Sayma ve Olasılık>Koşullu Durumlar',
  ], ['matematik>Sayma']),
  SinifKonusu('s10-mat-15', 10, _mat, 'Analitik İnceleme', 'Noktanın Analitik İncelenmesi', ['$_geo>Analitik Geometri>İki Nokta Arası Uzaklık']),
  SinifKonusu('s10-mat-16', 10, _mat, 'Analitik İnceleme', 'Doğrunun Analitik İncelenmesi', [
    '$_geo>Analitik Geometri>Doğru Denklemi',
    '$_geo>Analitik Geometri>Noktanın Doğruya Uzaklığı',
    '$_geo>Analitik Geometri>Doğrunun Eğimi',
  ], ['geometri>Analitik Geometri']),
  SinifKonusu('s10-mat-17', 10, _mat, 'Veriden Olasılığa', 'Koşullu Olasılık ve Bayes Teoremi'),
  // Fizik
  SinifKonusu('s10-fiz-01', 10, _fiz, 'Kuvvet ve Hareket', 'Sabit Hızlı Hareket', ['$_fiz>Kuvvet ve Hareket>Düzgün Doğrusal Hareket'], ['fizik>Hareket']),
  SinifKonusu('s10-fiz-02', 10, _fiz, 'Kuvvet ve Hareket', 'Bir Boyutta Sabit İvmeli Hareket',
      ['$_fiz>Kuvvet ve Hareket>Sabit İvmeli Hareket', '$_fiz>Kuvvet ve Hareket>Düzgün Hızlanan Hareket']),
  SinifKonusu('s10-fiz-03', 10, _fiz, 'Enerji', 'İş, Enerji ve Güç', ['$_fiz>Enerji>İş', '$_fiz>Enerji>Güç'], ['fizik>Enerji']),
  SinifKonusu('s10-fiz-04', 10, _fiz, 'Enerji', 'Mekanik Enerji',
      ['$_fiz>Enerji>Kinetik Enerji', '$_fiz>Enerji>Potansiyel Enerji', '$_fiz>Enerji>Mekanik Enerjinin Korunumu']),
  SinifKonusu('s10-fiz-05', 10, _fiz, 'Enerji', 'Enerji Kaynakları', ['$_fiz>Enerji>Enerji Kaynakları']),
  SinifKonusu('s10-fiz-06', 10, _fiz, 'Elektrik', 'Elektrik Akımı ve Basit Devreler', [], ['fizik>Elektrik']),
  SinifKonusu('s10-fiz-07', 10, _fiz, 'Elektrik', 'Ohm Yasası', ['$_fiz>Elektrik>Ohm Yasası']),
  SinifKonusu('s10-fiz-08', 10, _fiz, 'Elektrik', 'Dirençlerin ve Üreteçlerin Bağlanması',
      ['$_fiz>Elektrik>Dirençlerin Bağlanması', '$_fiz>Elektrik>Direnç Bağlama']),
  SinifKonusu('s10-fiz-09', 10, _fiz, 'Elektrik', 'Elektrik Güvenliği ve Topraklama'),
  SinifKonusu('s10-fiz-10', 10, _fiz, 'Dalgalar', 'Dalgaların Temel Kavramları', ['$_fiz>Dalgalar>Dalga Hızı', '$_fiz>Dalgalar>Dalga Denklemi'],
      ['fizik>Dalgalar']),
  SinifKonusu('s10-fiz-11', 10, _fiz, 'Dalgalar', 'Dalgaların Sınıflandırılması', ['$_fiz>Dalgalar>Ses Dalgaları']),
  SinifKonusu('s10-fiz-12', 10, _fiz, 'Dalgalar', 'Su Dalgaları, Rezonans ve Deprem', ['$_fiz>Dalgalar>Su Dalgaları']),
  // Kimya
  SinifKonusu('s10-kim-01', 10, _kim, 'Etkileşim', 'Kimyasal Tepkimeler ve Türleri',
      ['$_kim>Kimyasal Tepkimeler>Tepkime Türleri', '$_kim>Kimyanın Temel Kanunları'], ['kimya>Kimyasal Tepkimeler', 'kimya>Kimyanın Temel Kanunları']),
  SinifKonusu('s10-kim-02', 10, _kim, 'Etkileşim', 'Mol Kavramı', ['$_kim>Mol Kavramı'], ['kimya>Mol Kavramı', 'kimya>Mol']),
  SinifKonusu('s10-kim-03', 10, _kim, 'Etkileşim', 'Denklem Denkleştirme ve Stokiyometri', [
    '$_kim>Kimyasal Tepkimeler>Denklem Denkleştirme',
    '$_kim>Kimyasal Tepkimeler>Denkleştirme',
    '$_kim>Kimyasal Tepkimeler>Kimyasal Hesaplamalar',
  ]),
  SinifKonusu('s10-kim-04', 10, _kim, 'Etkileşim', 'Gazların Özellikleri ve Gaz Yasaları',
      ['$_kim>Gazlar>Boyle Yasası', '$_kim>Gazlar>Charles Yasası'], ['kimya>Gazlar']),
  SinifKonusu('s10-kim-05', 10, _kim, 'Etkileşim', 'İdeal Gaz Yasası ve Graham Yasası',
      ['$_kim>Gazlar>Gazların Yayılması', '$_kim>Gazlar>Molar Hacim']),
  SinifKonusu('s10-kim-06', 10, _kim, 'Çeşitlilik', 'Çözünme Süreci ve Çözünürlük', ['$_kim>Karışımlar>Homojen ve Heterojen Karışımlar'],
      ['kimya>Karışımlar']),
  SinifKonusu('s10-kim-07', 10, _kim, 'Çeşitlilik', 'Derişim Birimleri', [
    '$_kim>Çözeltiler>Molarite',
    '$_kim>Çözeltiler>Kütlece Yüzde Derişim',
    '$_kim>Çözeltiler>Kütlece Yüzde',
  ], ['kimya>Çözeltiler']),
  SinifKonusu('s10-kim-08', 10, _kim, 'Çeşitlilik', 'Koligatif Özellikler', ['$_kim>Çözeltiler>Koligatif Özellikler']),
  SinifKonusu('s10-kim-09', 10, _kim, 'Sürdürülebilirlik', 'Yeşil Kimya ve Atmosferdeki Tepkimeler'),
  // Biyoloji
  SinifKonusu('s10-biy-01', 10, _biy, 'Enerji', 'ATP ve Canlılık İçin Enerji'),
  SinifKonusu('s10-biy-02', 10, _biy, 'Enerji', 'Fotosentez ve Kemosentez', ['$_biy>Enerji Dönüşümleri>Fotosentez'], ['biyoloji>Enerji Dönüşümleri']),
  SinifKonusu('s10-biy-03', 10, _biy, 'Enerji', 'Sindirim, Emilim ve Taşınma', ['$_biy>İnsan Fizyolojisi>Sindirim Sistemi'], ['biyoloji>Sindirim Sistemi']),
  SinifKonusu('s10-biy-04', 10, _biy, 'Enerji', 'Hücresel Solunum ve Fermantasyon',
      ['$_biy>Enerji Dönüşümleri>Oksijenli Solunum', '$_biy>Enerji Dönüşümleri>Fermantasyon']),
  SinifKonusu('s10-biy-05', 10, _biy, 'Ekoloji', 'Ekosistemin Bileşenleri ve Etkileşimler', ['$_biy>Ekoloji>Simbiyotik İlişkiler'], ['biyoloji>Ekoloji']),
  SinifKonusu('s10-biy-06', 10, _biy, 'Ekoloji', 'Ekosistemde Madde ve Enerji Akışı', ['$_biy>Ekoloji>Besin Piramidi', '$_biy>Ekoloji>Enerji Akışı']),
  SinifKonusu('s10-biy-07', 10, _biy, 'Ekoloji', 'Madde Döngüleri', ['$_biy>Ekoloji>Azot Döngüsü']),
  SinifKonusu('s10-biy-08', 10, _biy, 'Ekoloji', 'Ekolojik Sürdürülebilirlik'),
  // Türk Dili ve Edebiyatı
  SinifKonusu('s10-edb-01', 10, _edb, 'Sözün Ezgisi', 'Koşuk ve Sözlü Dönem', ['$_edb>İslamiyet Öncesi Türk Edebiyatı>Sözlü Edebiyat'],
      ['edebiyat>İslamiyet Öncesi']),
  SinifKonusu('s10-edb-02', 10, _edb, 'Sözün Ezgisi', 'Koşma, Türkü ve Ninni', ['$_edb>Halk Edebiyatı'],
      ['edebiyat>Halk Edebiyatı', 'edebiyat>Tekke Edebiyatı']),
  SinifKonusu('s10-edb-03', 10, _edb, 'Kelimelerin Ritmi', 'Gazel ve Kaside', ['$_edb>Divan Edebiyatı'],
      ['edebiyat>Divan Edebiyatı', 'edebiyat>Nazım Biçimleri']),
  SinifKonusu('s10-edb-04', 10, _edb, 'Kelimelerin Ritmi', 'Saf Şiir'),
  SinifKonusu('s10-edb-05', 10, _edb, 'Dünden Bugüne', 'Destan ve Halk Hikâyesi', ['$_edb>Edebî Türler>Destan']),
  SinifKonusu('s10-edb-06', 10, _edb, 'Dünden Bugüne', 'Mesnevi ve Fabl', ['$_edb>Geçiş Dönemi Eserleri'], ['edebiyat>Geçiş Dönemi']),
  SinifKonusu('s10-edb-07', 10, _edb, 'Nesillerin Mirası', 'Dede Korkut Hikâyeleri', [], ['edebiyat>Dede Korkut']),
  SinifKonusu('s10-edb-08', 10, _edb, 'Nesillerin Mirası', 'Tanzimat Dönemi', ['$_edb>Tanzimat Edebiyatı'], ['edebiyat>Tanzimat']),
  SinifKonusu('s10-edb-09', 10, _edb, 'Nesillerin Mirası', 'Servetifünun ve Fecriati', ['$_edb>Servet-i Fünun Edebiyatı', '$_edb>Fecr-i Ati'],
      ['edebiyat>Servet-i Fünun', 'edebiyat>Fecr-i Ati']),
  SinifKonusu('s10-edb-10', 10, _edb, 'Nesillerin Mirası', 'Millî Edebiyat Dönemi', ['$_edb>Millî Edebiyat'],
      ['edebiyat>Millî Edebiyat', 'edebiyat>Milli Edebiyat']),
  SinifKonusu('s10-edb-11', 10, _edb, 'Dil ve Anlatım (temalara yayılır)', 'Sözcük Türleri ve Ses Bilgisi',
      ['$_tr>Sözcük Türleri', '$_tr>Fiilimsiler', '$_tr>Ses Bilgisi', '$_tr>Yapı Bilgisi'],
      ['turkce>Sözcük Türleri', 'turkce>Ses Bilgisi', 'turkce>Fiilimsiler', 'turkce>Yapı Bilgisi']),
  // Tarih
  SinifKonusu('s10-tar-01', 10, _tar, 'Türkistan\'dan Türkiye\'ye (1040-1299)', 'Askerî Mücadeleler (1040-1299)',
      ['$_tar>Türkiye Tarihi', '$_tar>Türk-İslam Tarihi>Büyük Selçuklu Devleti'], ['tarih>Türkiye Tarihi']),
  SinifKonusu('s10-tar-02', 10, _tar, 'Türkistan\'dan Türkiye\'ye (1040-1299)', 'Selçuklularda Devlet ve Ordu Teşkilatı'),
  SinifKonusu('s10-tar-03', 10, _tar, 'Türkistan\'dan Türkiye\'ye (1040-1299)', 'Selçuklularda Sosyal ve Ekonomik Hayat'),
  SinifKonusu('s10-tar-04', 10, _tar, 'Türkistan\'dan Türkiye\'ye (1040-1299)', 'Türk-İslam Medeniyeti', [
    '$_tar>Türk-İslam Tarihi>Karahanlılar',
    '$_tar>Türk-İslam Tarihi>Nizamiye Medreseleri',
    '$_tar>Türk-İslam Tarihi>Talas Savaşı',
  ], ['tarih>Türk-İslam Devletleri']),
  SinifKonusu('s10-tar-05', 10, _tar, 'Beylikten Devlete Osmanlı (1299-1453)', 'Osmanlı\'nın Kuruluşu ve Mücadeleleri', [
    '$_tar>Osmanlı Kuruluş Dönemi>Orhan Bey Dönemi',
    '$_tar>Osmanlı Kuruluş Dönemi>Ankara Savaşı',
    '$_tar>Osmanlı Kuruluş Dönemi>Fetret Devri',
  ], ['tarih>Osmanlı Kuruluş']),
  SinifKonusu('s10-tar-06', 10, _tar, 'Beylikten Devlete Osmanlı (1299-1453)', 'Devletleşme: Ordu, Hukuk ve Toprak Sistemi',
      ['$_tar>Osmanlı Kuruluş Dönemi>Tımar Sistemi', '$_tar>Osmanlı Kuruluş Dönemi>Askerî Teşkilat']),
  SinifKonusu('s10-tar-07', 10, _tar, 'Beylikten Devlete Osmanlı (1299-1453)', 'Fetih ve İskân Politikaları'),
  SinifKonusu('s10-tar-08', 10, _tar, 'Beylikten Devlete Osmanlı (1299-1453)', 'İlim ve İrfan Geleneği'),
  SinifKonusu('s10-tar-09', 10, _tar, 'Cihan Devleti Osmanlı (1453-1683)', 'Siyasi ve Askerî Mücadeleler (1453-1683)',
      ['$_tar>Osmanlı Yükselme Dönemi'], ['tarih>Osmanlı Yükselme']),
  SinifKonusu('s10-tar-10', 10, _tar, 'Cihan Devleti Osmanlı (1453-1683)', 'Yönetim ve Orduda Değişim', ['$_tar>Osmanlı 17. Yüzyıl>Islahatlar'],
      ['tarih>Osmanlı 17. Yüzyıl']),
  SinifKonusu('s10-tar-11', 10, _tar, 'Cihan Devleti Osmanlı (1453-1683)', 'Sömürgecilik ve İsyanlar'),
  SinifKonusu('s10-tar-12', 10, _tar, 'Cihan Devleti Osmanlı (1453-1683)', 'Klasik Dönemde Bilim, Kültür ve Sanat', [],
      ['tarih>Osmanlı Kültür ve Medeniyet']),
  // Coğrafya
  SinifKonusu('s10-cog-01', 10, _cog, 'Coğrafyanın Doğası ve Mekânsal Bilgi Teknolojileri', 'Coğrafi Bakış ve CBS Uygulamaları'),
  SinifKonusu('s10-cog-02', 10, _cog, 'Doğal Sistemler ve Süreçler', 'Tektonik Süreçler',
      ['$_cog>Yer Şekilleri>İç Kuvvetler', '$_cog>Yer Şekilleri>Kayaçlar'], ['cografya>Kayaçlar']),
  SinifKonusu('s10-cog-03', 10, _cog, 'Doğal Sistemler ve Süreçler', 'Aşınım ve Birikim Şekilleri', [
    '$_cog>Yer Şekilleri>Akarsu Şekilleri',
    '$_cog>Yer Şekilleri>Karstik Şekiller',
    '$_cog>Topraklar>Erozyon',
  ], ['cografya>Yer Şekilleri']),
  SinifKonusu('s10-cog-04', 10, _cog, 'Beşerî Sistemler ve Süreçler', 'Yerleşmelerin Kuruluşu ve Fonksiyonları', ['$_cog>Yerleşme'],
      ['cografya>Yerleşme']),
  SinifKonusu('s10-cog-05', 10, _cog, 'Ekonomik Faaliyetler ve Etkileri', 'Ekonomik Sektörler ve Türkiye Ekonomisi',
      ['$_cog>Ekonomik Faaliyetler>Faaliyet Türleri'], ['cografya>Ekonomik Faaliyetler']),
  SinifKonusu('s10-cog-06', 10, _cog, 'Afetler ve Sürdürülebilir Çevre', 'Afetlerden Korunma ve Afet Bilinci'),
  SinifKonusu('s10-cog-07', 10, _cog, 'Bölgeler, Ülkeler ve Küresel Bağlantılar', 'Türk Kültürünün Mekânsal Özellikleri'),
  // Felsefe
  SinifKonusu('s10-fel-01', 10, _fel, 'Felsefenin Doğası', 'Felsefenin Doğası', ['$_fel>Felsefeye Giriş', '$_fel>Felsefenin Doğuşu'],
      ['felsefe>Felsefeye Giriş', 'felsefe>Felsefenin Doğuşu']),
  SinifKonusu('s10-fel-02', 10, _fel, 'Felsefe, Mantık ve Argümantasyon', 'Mantık ve Argümantasyon', ['$_fel>Mantık'], ['felsefe>Mantık']),
  SinifKonusu('s10-fel-03', 10, _fel, 'Varlık Felsefesi', 'Varlık Felsefesi', [], ['felsefe>Varlık Felsefesi']),
  SinifKonusu('s10-fel-04', 10, _fel, 'Bilgi Felsefesi', 'Bilgi Felsefesi', [], ['felsefe>Bilgi Felsefesi']),
  SinifKonusu('s10-fel-05', 10, _fel, 'Ahlak Felsefesi', 'Ahlak Felsefesi', [], ['felsefe>Ahlak Felsefesi']),
  SinifKonusu('s10-fel-06', 10, _fel, 'Estetik ve Sanat Felsefesi', 'Estetik ve Sanat Felsefesi', ['$_fel>Sanat Felsefesi'], ['felsefe>Sanat Felsefesi']),
  SinifKonusu('s10-fel-07', 10, _fel, 'Siyaset Felsefesi', 'Siyaset Felsefesi', [], ['felsefe>Siyaset Felsefesi']),
  SinifKonusu('s10-fel-08', 10, _fel, 'Din Felsefesi', 'Din Felsefesi', [], ['felsefe>Din Felsefesi']),
  SinifKonusu('s10-fel-09', 10, _fel, 'Bilim Felsefesi', 'Bilim Felsefesi', [], ['felsefe>Bilim Felsefesi']),

  // ═══ 11. SINIF ══════════════════════════════════════════════════════
  // Matematik
  SinifKonusu('s11-mat-01', 11, _mat, 'İstatistiksel Araştırma Süreci', 'İki Nicel Değişkenli Veriler'),
  SinifKonusu('s11-mat-02', 11, _mat, 'Geometrik Şekiller', 'Dörtgenler ve Özel Dörtgenler', ['$_geo>Dörtgenler'], ['geometri>Dörtgenler']),
  SinifKonusu('s11-mat-03', 11, _mat, 'Geometrik Şekiller', 'Çokgenler', ['$_geo>Çokgenler'], ['geometri>Çokgenler']),
  SinifKonusu('s11-mat-04', 11, _mat, 'Nicelikler ve Değişimler', 'Trigonometrik Fonksiyonlar',
      ['$_mat>Trigonometri>Birim Çember', '$_mat>Trigonometri>Yarım Açı Formülleri'], ['matematik>Trigonometri']),
  SinifKonusu('s11-mat-05', 11, _mat, 'Nicelikler ve Değişimler', 'Trigonometrik Denklemler'),
  SinifKonusu('s11-mat-06', 11, _mat, 'Nicelikler ve Değişimler', 'Üstel Fonksiyonlar', ['$_mat>Üslü ve Köklü Sayılar>Üslü Denklemler']),
  SinifKonusu('s11-mat-07', 11, _mat, 'Nicelikler ve Değişimler', 'Logaritmik Fonksiyonlar', ['$_mat>Logaritma'], ['matematik>Logaritma']),
  SinifKonusu('s11-mat-08', 11, _mat, 'Nicelikler ve Değişimler', 'Üstel ve Logaritmik Denklemler'),
  SinifKonusu('s11-mat-09', 11, _mat, 'Nicelikler ve Değişimler', 'Fonksiyonlarda Dört İşlem ve Bileşke'),
  // Fizik
  SinifKonusu('s11-fiz-01', 11, _fiz, 'Kuvvet ve Hareket', 'Serbest Düşme ve İki Boyutta Hareket',
      ['$_fiz>Kuvvet ve Hareket>Serbest Düşme', '$_fiz>Kuvvet ve Hareket>Yatay Atış']),
  SinifKonusu('s11-fiz-02', 11, _fiz, 'Kuvvet ve Hareket', 'Newton\'ın Hareket Yasaları', ['$_fiz>Kuvvet ve Hareket>Etki – Tepki'], ['fizik>Kuvvet']),
  SinifKonusu('s11-fiz-03', 11, _fiz, 'Kuvvet ve Hareket', 'Sürtünme Kuvveti ve Limit Hız', ['$_fiz>Kuvvet ve Hareket>Sürtünme Kuvveti']),
  SinifKonusu('s11-fiz-04', 11, _fiz, 'Kuvvet ve Hareket', 'Düzgün Çembersel Hareket', ['$_fiz>Kuvvet ve Hareket>Düzgün Çembersel Hareket'],
      ['fizik>Dairesel Hareket']),
  SinifKonusu('s11-fiz-05', 11, _fiz, 'Elektrik ve Manyetizma', 'Elektriksel Kuvvet ve Elektriksel Alan', ['$_fiz>Elektrik>Coulomb Kuvveti'],
      ['fizik>Elektrostatik']),
  SinifKonusu('s11-fiz-06', 11, _fiz, 'Elektrik ve Manyetizma', 'Manyetik Alan ve Manyetik Kuvvet', ['$_fiz>Manyetizma>Akım Geçen Telin Manyetik Alanı'],
      ['fizik>Manyetizma']),
  SinifKonusu('s11-fiz-07', 11, _fiz, 'Elektrik ve Manyetizma', 'İndüksiyon Akımı ve Transformatörler',
      ['$_fiz>Manyetizma>Elektromanyetik İndüksiyon']),
  SinifKonusu('s11-fiz-08', 11, _fiz, 'Optik', 'Işık Şiddeti, Işık Akısı ve Aydınlanma'),
  SinifKonusu('s11-fiz-09', 11, _fiz, 'Optik', 'Düzlem ve Küresel Aynalar', ['$_fiz>Optik>Düzlem Ayna'], ['fizik>Optik']),
  SinifKonusu('s11-fiz-10', 11, _fiz, 'Optik', 'Kırılma ve Görünür Derinlik', ['$_fiz>Optik>Kırılma']),
  SinifKonusu('s11-fiz-11', 11, _fiz, 'Optik', 'Fiber Optik ve Prizmalar', ['$_fiz>Optik>Renkler']),
  SinifKonusu('s11-fiz-12', 11, _fiz, 'Optik', 'Mercekler', ['$_fiz>Optik>Mercekler']),
  // Kimya
  SinifKonusu('s11-kim-01', 11, _kim, 'Etkileşim', 'Tepkimelerde Enerji ve Entalpi', ['$_kim>Kimyasal Tepkimelerde Enerji'],
      ['kimya>Kimyasal Tepkimelerde Enerji', 'kimya>Enerji']),
  SinifKonusu('s11-kim-02', 11, _kim, 'Etkileşim', 'Kimyasal Tepkimelerde Hız', [], ['kimya>Tepkime Hızları']),
  SinifKonusu('s11-kim-03', 11, _kim, 'Çeşitlilik', 'Kimyasal Denge', [], ['kimya>Kimyasal Denge']),
  SinifKonusu('s11-kim-04', 11, _kim, 'Çeşitlilik', 'Asit-Baz Dengesi ve pH', ['$_kim>Asitler ve Bazlar'], ['kimya>Asitler ve Bazlar']),
  SinifKonusu('s11-kim-05', 11, _kim, 'Çeşitlilik', 'Nötralleşme ve Titrasyon'),
  SinifKonusu('s11-kim-06', 11, _kim, 'Çeşitlilik', 'Çözünürlük Dengesi'),
  SinifKonusu('s11-kim-07', 11, _kim, 'Sürdürülebilirlik', 'Nanoteknoloji ve Sürdürülebilirlik'),
  // Biyoloji
  SinifKonusu('s11-biy-01', 11, _biy, 'Tepki', 'Bitkilerde Tepki', ['$_biy>Bitki Biyolojisi>Bitkisel Hormonlar']),
  SinifKonusu('s11-biy-02', 11, _biy, 'Tepki', 'Sinir Sistemi ve Duyu Organları',
      ['$_biy>İnsan Fizyolojisi>Sinir Sistemi', '$_biy>İnsan Fizyolojisi>Duyu Organları'], ['biyoloji>Sinir Sistemi', 'biyoloji>Duyu Organları']),
  SinifKonusu('s11-biy-03', 11, _biy, 'Tepki', 'Destek ve Hareket', ['$_biy>İnsan Fizyolojisi>Kas Kasılması'], ['biyoloji>Destek ve Hareket']),
  SinifKonusu('s11-biy-04', 11, _biy, 'Tepki', 'Bağışıklık ve Alerji', ['$_biy>İnsan Fizyolojisi>Bağışıklık'], ['biyoloji>Bağışıklık']),
  SinifKonusu('s11-biy-05', 11, _biy, 'Homeostazi', 'Homeostazi ve Geri Bildirim'),
  SinifKonusu('s11-biy-06', 11, _biy, 'Homeostazi', 'Endokrin Sistem ve Homeostazi', ['$_biy>İnsan Fizyolojisi>Endokrin Sistem'],
      ['biyoloji>Endokrin Sistem']),
  SinifKonusu('s11-biy-07', 11, _biy, 'Homeostazi', 'Dolaşım ve Solunum Sistemi',
      ['$_biy>İnsan Fizyolojisi>Dolaşım Sistemi', '$_biy>İnsan Fizyolojisi>Solunum Sistemi'], ['biyoloji>Dolaşım Sistemi', 'biyoloji>Solunum Sistemi']),
  SinifKonusu('s11-biy-08', 11, _biy, 'Homeostazi', 'Boşaltım Sistemi ve Homeostazi', ['$_biy>İnsan Fizyolojisi>Boşaltım Sistemi'],
      ['biyoloji>Boşaltım Sistemi']),
  SinifKonusu('s11-biy-09', 11, _biy, 'Homeostazi', 'Homeostazinin Bozulması ve Sağlık'),
  // Türk Dili ve Edebiyatı
  SinifKonusu('s11-edb-01', 11, _edb, 'Bir Diyeceğim Var!', 'Karagöz ve Geleneksel Tiyatro', ['$_edb>Edebî Türler>Geleneksel Türk Tiyatrosu']),
  SinifKonusu('s11-edb-02', 11, _edb, 'Bir Diyeceğim Var!', 'Mektup ve Dilekçe'),
  SinifKonusu('s11-edb-03', 11, _edb, 'Kültür Yolculuğu', 'Türk Dünyası Edebiyatı'),
  SinifKonusu('s11-edb-04', 11, _edb, 'Kültür Yolculuğu', 'Orhun Abideleri ve Dîvânu Lugâti\'t-Türk', [
    '$_edb>İslamiyet Öncesi Türk Edebiyatı>Yazılı Edebiyat',
    '$_edb>İslamiyet Öncesi Türk Edebiyatı>Yazılı Ürünler',
  ]),
  SinifKonusu('s11-edb-05', 11, _edb, 'Yaşamın İzinde', 'Roman', ['$_edb>Cumhuriyet Dönemi>Roman', '$_edb>Cumhuriyet Dönemi>Toplumcu Gerçekçi Roman'],
      ['edebiyat>Cumhuriyet Dönemi', 'edebiyat>Cumhuriyet']),
  SinifKonusu('s11-edb-06', 11, _edb, 'Yaşamın İzinde', 'Biyografi ve Tezkire'),
  SinifKonusu('s11-edb-07', 11, _edb, 'Hayatın Aynası', 'Modern Tiyatro'),
  SinifKonusu('s11-edb-08', 11, _edb, 'Hayatın Aynası', 'Küçürek Hikâye'),
  SinifKonusu('s11-edb-09', 11, _edb, 'Dil ve Anlatım (temalara yayılır)', 'Cümle Bilgisi ve Anlatım Bozuklukları',
      ['$_tr>Cümlenin Ögeleri', '$_tr>Cümle Türleri', '$_tr>Anlatım Bozuklukları', '$_tr>Fiiller'],
      ['turkce>Cümle Bilgisi', 'turkce>Anlatım Bozuklukları', 'turkce>Fiiller']),
  // Tarih
  SinifKonusu('s11-tar-01', 11, _tar, 'Değişen Dünyada Osmanlı (1683-1789)', 'Siyasi ve Askerî Mücadeleler (1683-1789)',
      ['$_tar>Osmanlı 17. Yüzyıl>Karlofça Antlaşması', '$_tar>Osmanlı 18. Yüzyıl>Küçük Kaynarca Antlaşması']),
  SinifKonusu('s11-tar-02', 11, _tar, 'Değişen Dünyada Osmanlı (1683-1789)', 'Lale Devri ve 18. Yüzyıl Islahatları',
      ['$_tar>Osmanlı 18. Yüzyıl>Lale Devri', '$_tar>Osmanlı 18. Yüzyıl>Islahatlar'], ['tarih>Osmanlı 18. Yüzyıl']),
  SinifKonusu('s11-tar-03', 11, _tar, 'Değişen Dünyada Osmanlı (1683-1789)', 'Sanayi Devrimi ve Etkileri'),
  SinifKonusu('s11-tar-04', 11, _tar, 'Dönüşüm Sürecinde Osmanlı (1789-1908)', 'Fransız İhtilali ve Etkileri'),
  SinifKonusu('s11-tar-05', 11, _tar, 'Dönüşüm Sürecinde Osmanlı (1789-1908)', 'Siyasi ve İdari Gelişmeler (1789-1908)',
      ['$_tar>Osmanlı 19. Yüzyıl'], ['tarih>Osmanlı 19. Yüzyıl']),
  SinifKonusu('s11-tar-06', 11, _tar, 'Dönüşüm Sürecinde Osmanlı (1789-1908)', 'Bilim, Sanat ve Sanayileşme Çabaları'),
  SinifKonusu('s11-tar-07', 11, _tar, 'Savaşlar Sarmalında Osmanlı (1908-1918)', 'Siyasi ve Askerî Gelişmeler (1908-1918)',
      ['$_tar>Osmanlı 20. Yüzyıl', '$_tar>I. Dünya Savaşı'], ['tarih>Osmanlı 20. Yüzyıl', 'tarih>I. Dünya Savaşı']),
  SinifKonusu('s11-tar-08', 11, _tar, 'Savaşlar Sarmalında Osmanlı (1908-1918)', 'Göçler, Salgınlar ve Osmanlı Mirası'),
  // Coğrafya
  SinifKonusu('s11-cog-01', 11, _cog, 'Coğrafyanın Doğası ve Mekânsal Bilgi Teknolojileri', 'Mekânsal Sorunlar ve Web Tabanlı CBS'),
  SinifKonusu('s11-cog-02', 11, _cog, 'Doğal Sistemler ve Süreçler', 'Su Kaynakları', [], ['cografya>Su Kaynakları']),
  SinifKonusu('s11-cog-03', 11, _cog, 'Beşerî Sistemler ve Süreçler', 'Yerleşmelerin Mekânsal Organizasyonu'),
  SinifKonusu('s11-cog-04', 11, _cog, 'Ekonomik Faaliyetler ve Etkileri', 'Tarım ve Gıda Güvencesi', ['$_cog>Ekonomik Faaliyetler>Tarım']),
  SinifKonusu('s11-cog-05', 11, _cog, 'Ekonomik Faaliyetler ve Etkileri', 'Madenler ve Enerji Kaynakları',
      ['$_cog>Enerji Kaynakları', '$_cog>Ekonomik Faaliyetler>Madenler'], ['cografya>Enerji']),
  SinifKonusu('s11-cog-06', 11, _cog, 'Ekonomik Faaliyetler ve Etkileri', 'Sanayileşmenin Mekânsal Etkileri'),
  SinifKonusu('s11-cog-07', 11, _cog, 'Afetler ve Sürdürülebilir Çevre', 'Gezegen Sınırı ve Küresel İklim Değişikliği',
      ['$_cog>Çevre ve Toplum>Küresel Çevre Sorunları'], ['cografya>Çevre']),
  SinifKonusu('s11-cog-08', 11, _cog, 'Bölgeler, Ülkeler ve Küresel Bağlantılar', 'Türkiye\'nin Kültürel Hinterlandı'),
  // Felsefe
  SinifKonusu('s11-fel-01', 11, _fel, 'Çevre Sorunları ve Felsefe', 'Çevre Sorunları ve Felsefe'),
  SinifKonusu('s11-fel-02', 11, _fel, 'Teknoloji ve Hayat', 'Teknoloji ve Hayat'),
  SinifKonusu('s11-fel-03', 11, _fel, 'Akıl ve İnanç', 'Akıl ve İnanç', ['$_fel>İslam Felsefesi'], ['felsefe>İslam Felsefesi', 'felsefe>Orta Çağ Felsefesi']),
  SinifKonusu('s11-fel-04', 11, _fel, 'Edebiyat ve Felsefe', 'Edebiyat ve Felsefe'),
  SinifKonusu('s11-fel-05', 11, _fel, 'Hayatın Anlamı', 'Hayatın Anlamı', ['$_fel>20. Yüzyıl Felsefesi'], ['felsefe>20. Yüzyıl']),
  SinifKonusu('s11-fel-06', 11, _fel, 'Hukuk ve Felsefe', 'Hukuk ve Felsefe'),
];

final Map<String, SinifKonusu> _idHaritasi = {for (final k in sinifMufredati) k.id: k};

SinifKonusu? sinifKonusuBul(String id) => _idHaritasi[id];

/// Bir sınıfın konuları (müfredat sırasıyla).
List<SinifKonusu> sinifKonulari(int sinif) => [for (final k in sinifMufredati) if (k.sinif == sinif) k];

/// Bir sınıfın dersleri (müfredat sırasıyla).
List<String> sinifDersleri(int sinif) {
  final l = <String>[];
  for (final k in sinifMufredati) {
    if (k.sinif == sinif && !l.contains(k.ders)) l.add(k.ders);
  }
  return l;
}

/// Bir konunun teması (hazır sınıf konusu değilse null).
String? konuTemasi(String konuId) => _idHaritasi[konuId]?.tema;
