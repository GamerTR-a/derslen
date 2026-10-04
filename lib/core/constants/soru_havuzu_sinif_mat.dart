/// 9, 10 ve 11. sınıf matematik soruları — Türkiye Yüzyılı Maarif Modeli
/// konularına göre DersNet için özgün olarak yazılmıştır. Sayısal alıştırma
/// soruları ayrıca soru_sablonlari_mat.dart dosyasındaki şablonlarla üretilir;
/// buradaki sorular kavram ve yorum ağırlıklıdır.
library;

import '../../data/models/soru.dart';
import 'sinif_mufredati.dart';

Soru _q(String id, String konuId, String alt, SoruZorluk z, String metin, List<String> sec, String dogru, String cozum) {
  final k = sinifKonusuBul(konuId)!;
  return Soru(
    id: id,
    ders: k.ders,
    konu: k.baslik,
    altBaslik: alt,
    zorluk: z,
    soruMetni: metin,
    secenekler: {'A': sec[0], 'B': sec[1], 'C': sec[2], 'D': sec[3], 'E': sec[4]},
    dogruSecenek: dogru,
    cozumAciklama: cozum,
  );
}

const _k = SoruZorluk.kolay;
const _o = SoruZorluk.orta;
const _z = SoruZorluk.zor;

final List<Soru> sinifMatSorulari = [
  // ═══ 9. SINIF ═══════════════════════════════════════════════════════
  _q('sm-001', 's9-mat-05', 'Doğrusal Fonksiyonun Grafiği', _k, "f(x) = 3x − 6 doğrusal fonksiyonunun grafiği x eksenini hangi noktada keser?",
      ["(−6, 0)", "(0, −6)", "(2, 0)", "(3, 0)", "(−2, 0)"], 'C',
      "x eksenini kestiği noktada f(x) = 0 olur: 3x − 6 = 0 ⟹ x = 2. Nokta (2, 0). Grafik y eksenini ise (0, −6) noktasında keser."),
  _q('sm-002', 's9-mat-05', 'Doğrusal Fonksiyonun Nitel Özellikleri', _o, "f(x) = −2x + 5 fonksiyonu için aşağıdakilerden hangisi doğrudur?",
      ["Artan bir fonksiyondur.", "Grafiği orijinden geçer.", "x arttıkça f(x) artar.", "Azalan bir fonksiyondur; x bir birim arttığında f(x) iki birim azalır.", "Sabit fonksiyondur."], 'D',
      "Eğim (değişim oranı) −2 olduğundan fonksiyon azalandır: x bir birim artınca değer 2 birim azalır. f(0) = 5 olduğundan grafik orijinden geçmez."),
  _q('sm-003', 's9-mat-05', 'Doğrusal İlişki', _o,
      "Bir depodaki su miktarı (litre) zamanla doğrusal olarak azalmaktadır. Başlangıçta 120 L su bulunan depodan her dakika 8 L su boşaltılıyor. Depo kaç dakika sonra tamamen boşalır?",
      ["12", "15", "16", "20", "8"], 'B',
      "Su miktarı f(t) = 120 − 8t fonksiyonuyla ifade edilir. 120 − 8t = 0 ⟹ t = 15 dakika."),
  _q('sm-004', 's9-mat-09', 'Dönüşümler', _k, "Düzlemde bir şeklin bir doğruya göre simetriğinin alınması hangi geometrik dönüşümdür?",
      ["Öteleme", "Dönme", "Benzerlik (homoteti)", "Kayma", "Yansıma"], 'E',
      "Yansıma, şeklin bir doğruya (simetri eksenine) göre ayna görüntüsünü verir. Öteleme, dönme ve yansıma şeklin boyutunu değiştirmez."),
  _q('sm-005', 's9-mat-09', 'Dönüşümler', _o, "A(3, −4) noktasının orijine göre simetriği olan noktanın koordinatları aşağıdakilerden hangisidir?",
      ["(−3, 4)", "(3, 4)", "(−3, −4)", "(4, −3)", "(−4, 3)"], 'A',
      "Orijine göre simetride her iki koordinat da işaret değiştirir: (x, y) → (−x, −y). A(3, −4) → (−3, 4)."),
  _q('sm-006', 's9-mat-12', 'Algoritma', _k, "Bir problemin çözümü için izlenecek yolun sıralı, açık ve sonlu adımlarla ifade edilmesine ne ad verilir?",
      ["Değişken", "Algoritma", "Döngü", "Veri", "Denklem"], 'B',
      "Algoritma; belirli bir problemi çözen, açık, sıralı ve sonlu adımlar dizisidir. Akış şemasıyla ya da sözde kodla gösterilebilir."),
  _q('sm-007', 's9-mat-12', 'Algoritma', _o,
      "Bir algoritma şu adımlardan oluşuyor:\n1. Bir n doğal sayısı al.\n2. n çift ise n'yi 2'ye böl, tek ise n'yi 3 ile çarpıp 1 ekle.\n3. Sonuç 1 değilse 2. adıma dön.\nn = 6 için algoritma 1'e ulaşana kadar 2. adım kaç kez uygulanır?",
      ["6", "7", "9", "8", "5"], 'D',
      "6 → 3 → 10 → 5 → 16 → 8 → 4 → 2 → 1. Toplam 8 adım uygulanır."),
  _q('sm-008', 's9-mat-13', 'Mantık Bağlaçları', _k, "p ile q önermeleri için “p ∧ q” bileşik önermesi hangi durumda doğrudur?",
      ["p doğru, q yanlış iken", "p yanlış, q doğru iken", "Yalnızca p ve q'nun ikisi de doğru iken", "p ve q'nun ikisi de yanlış iken", "Her durumda"], 'C',
      "“ve” bağlacıyla kurulan bileşik önerme yalnızca iki önerme de doğruyken doğrudur."),
  _q('sm-009', 's9-mat-13', 'Niceleyiciler', _o, "“Her gerçek sayının karesi sıfırdan büyüktür veya sıfıra eşittir.” önermesinin sembolik gösterimi aşağıdakilerden hangisidir?",
      ["∀x ∈ ℝ, x² ≥ 0", "∃x ∈ ℝ, x² ≥ 0", "∀x ∈ ℝ, x² < 0", "∃x ∈ ℝ, x² < 0", "∀x ∈ ℝ, x² > 0"], 'A',
      "“Her” sözcüğü evrensel niceleyici (∀) ile gösterilir. Önerme: ∀x ∈ ℝ, x² ≥ 0. “Bazı / en az bir” ise varlıksal niceleyici (∃) ile gösterilir."),
  _q('sm-010', 's9-mat-13', 'Niceleyiciler', _z, "“Her öğrenci ödevini yapmıştır.” önermesinin olumsuzu (değili) aşağıdakilerden hangisidir?",
      ["Hiçbir öğrenci ödevini yapmamıştır.", "Her öğrenci ödevini yapmamıştır.", "Öğrencilerin çoğu ödevini yapmıştır.", "Bazı öğrenciler ödevini yapmıştır.", "En az bir öğrenci ödevini yapmamıştır."], 'E',
      "“Her x için p(x)” önermesinin değili “Bazı (en az bir) x için p(x) değil” biçimindedir: (∀x, p(x))′ ≡ ∃x, p′(x)."),
  _q('sm-011', 's9-mat-14', 'Veri Dağılımı', _k, "Bir veri grubunda en çok tekrar eden değere ne ad verilir?",
      ["Medyan (ortanca)", "Tepe değer (mod)", "Aritmetik ortalama", "Açıklık", "Standart sapma"], 'B',
      "Tepe değer (mod) en sık görülen değerdir. Medyan sıralı verinin ortasındaki değer, açıklık en büyük ile en küçük değerin farkıdır."),
  _q('sm-012', 's9-mat-14', 'Veri Dağılımı', _o,
      "Bir sınıftaki öğrencilerin boy uzunlukları incelenirken aşırı uç bir değer (çok uzun bir öğrenci) bulunuyor. Bu durumda verinin merkezini en iyi temsil eden ölçü aşağıdakilerden hangisidir?",
      ["Aritmetik ortalama", "Açıklık", "Medyan (ortanca)", "En büyük değer", "Veri sayısı"], 'C',
      "Aritmetik ortalama uç değerlerden çok etkilenir. Medyan sıralamaya dayandığından uç değerlerden etkilenmez ve merkezi daha iyi temsil eder."),
  _q('sm-013', 's9-mat-14', 'Grafik Yorumlama', _o, "Sürekli nicel bir verinin (örneğin öğrencilerin boyları) dağılımını aralıklara ayırarak göstermek için en uygun grafik türü hangisidir?",
      ["Daire grafiği", "Çizgi grafiği", "Şekil grafiği", "Histogram", "Ağaç şeması"], 'D',
      "Histogram, sürekli veriyi eşit genişlikte aralıklara (gruplara) ayırır ve her aralıktaki veri sayısını bitişik sütunlarla gösterir."),
  // ═══ 10. SINIF ══════════════════════════════════════════════════════
  _q('sm-014', 's10-mat-04', 'Sinüs Teoremi', _o, "Sinüs teoremi bir ABC üçgeni için aşağıdakilerden hangisini ifade eder?",
      ["a / sin A = b / sin B = c / sin C", "a² = b² + c²", "a · sin A = b · sin B", "a + b + c = 180", "a / cos A = b / cos B"], 'A',
      "Bir üçgende her kenarın, karşısındaki açının sinüsüne oranı sabittir ve çevrel çemberin çapına (2R) eşittir."),
  _q('sm-015', 's10-mat-05', 'İki Yönlü Tablo', _o,
      "Bir okuldaki 40 öğrenciye müzik kursuna gidip gitmediği soruluyor. 18 kız öğrencinin 6'sı, 22 erkek öğrencinin 4'ü kursa gittiğini söylüyor. Kursa giden öğrencilerin yüzde kaçı kızdır?",
      ["25", "15", "33", "45", "60"], 'E',
      "Kursa giden toplam 6 + 4 = 10 öğrenci vardır; bunların 6'sı kızdır: 6 / 10 = %60."),
  _q('sm-016', 's10-mat-05', 'Kategorik Veri', _k, "Aşağıdakilerden hangisi kategorik (nitel) bir değişkendir?",
      ["Boy uzunluğu", "Göz rengi", "Sınav puanı", "Yaş", "Günlük kitap okuma süresi"], 'B',
      "Kategorik değişkenler sayıyla ölçülmez, sınıflara ayrılır: göz rengi, cinsiyet, kan grubu gibi. Diğerleri nicel değişkenlerdir."),
  _q('sm-017', 's10-mat-05', 'İki Kategorik Değişken', _z,
      "Bir ankette 100 kişiden 60'ı kadın, 40'ı erkektir. Kadınların 30'u, erkeklerin 20'si spor yaptığını belirtiyor. Bu verilere göre aşağıdaki yorumlardan hangisi doğrudur?",
      ["Kadınlar erkeklerden daha yüksek oranda spor yapmaktadır.", "Erkekler kadınlardan daha yüksek oranda spor yapmaktadır.", "Spor yapma oranı kadınlarda ve erkeklerde aynıdır; cinsiyet ile spor yapma arasında ilişki görülmemektedir.", "Spor yapanların çoğu erkektir.", "Ankete katılanların %30'u spor yapmaktadır."], 'C',
      "Kadınlarda oran 30/60 = %50, erkeklerde 20/40 = %50. Koşullu oranlar eşit olduğundan iki değişken arasında ilişki gözlenmez."),
  _q('sm-018', 's10-mat-11', 'Karekök Fonksiyonu', _o, "f(x) = √x fonksiyonu için aşağıdakilerden hangisi yanlıştır?",
      ["Tanım kümesi [0, ∞) aralığıdır.", "Görüntü kümesi [0, ∞) aralığıdır.", "Artan bir fonksiyondur.", "Grafiği x ekseninin altında kalan noktalar içerir.", "f(0) = 0 olur."], 'D',
      "Karekök negatif değer almaz; grafik x ekseninin altına inmez. Tanım ve görüntü kümesi [0, ∞), fonksiyon artandır."),
  _q('sm-019', 's10-mat-12', 'Ters Fonksiyon', _o, "Bir f fonksiyonu ile ters fonksiyonu f⁻¹'in grafikleri hangi doğruya göre simetriktir?",
      ["y = x", "y = −x", "x = 0", "y = 0", "y = 1"], 'A',
      "f(a) = b ise f⁻¹(b) = a olur; (a, b) ve (b, a) noktaları y = x doğrusuna göre simetriktir."),
  _q('sm-020', 's10-mat-13', 'Denklem ve Eşitsizlikler', _o, "x² = 9 denkleminin gerçek sayılardaki çözüm kümesi aşağıdakilerden hangisidir?",
      ["{3}", "{9}", "{−9, 9}", "{0, 3}", "{−3, 3}"], 'E',
      "x² = 9 ⟹ x = 3 veya x = −3. Çözüm kümesi {−3, 3}. Yalnızca pozitif kökün alınması sık yapılan bir hatadır."),
  _q('sm-021', 's10-mat-17', 'Koşullu Olasılık', _o, "A ve B olayları için “B olayının gerçekleştiği bilindiğine göre A'nın olasılığı” aşağıdakilerden hangisiyle hesaplanır?",
      ["P(A) · P(B)", "P(A ∩ B) / P(B)", "P(A) + P(B)", "P(A ∩ B) / P(A)", "P(A) − P(B)"], 'B',
      "Koşullu olasılık: P(A | B) = P(A ∩ B) / P(B), P(B) > 0. Örnek uzay B olayına daraltılır."),
  // ═══ 11. SINIF ══════════════════════════════════════════════════════
  _q('sm-022', 's11-mat-01', 'Saçılım Grafiği', _k, "İki nicel değişken arasındaki ilişkiyi incelemek için kullanılan grafik türü aşağıdakilerden hangisidir?",
      ["Daire grafiği", "Sütun grafiği", "Saçılım (serpilme) grafiği", "Histogram", "Kutu grafiği"], 'C',
      "Saçılım grafiğinde her gözlem, iki değişkenin değerlerine göre bir nokta olarak işaretlenir; noktaların dizilişi ilişkinin yönünü ve gücünü gösterir."),
  _q('sm-023', 's11-mat-01', 'İlişki ve Nedensellik', _z,
      "Bir araştırmada dondurma satışları ile boğulma olaylarının sayısı arasında güçlü pozitif ilişki bulunuyor. Bu sonuçla ilgili en doğru yorum aşağıdakilerden hangisidir?",
      ["Dondurma yemek boğulmaya neden olur.", "Boğulma olayları dondurma satışını artırır.", "İlişki hatalı hesaplanmıştır.", "İki değişken de sıcak hava gibi üçüncü bir etkenden etkilenmektedir; ilişki nedensellik göstermez.", "İki değişken arasında negatif ilişki vardır."], 'D',
      "İlişki (korelasyon) nedensellik anlamına gelmez. Sıcak havalarda hem dondurma satışı hem denize girenlerin sayısı artar."),
  _q('sm-024', 's11-mat-05', 'Trigonometrik Denklemler', _o, "sin x = 0 denkleminin [0°, 360°) aralığındaki çözüm kümesi aşağıdakilerden hangisidir?",
      ["{0°, 180°}", "{90°, 270°}", "{0°, 90°}", "{180°}", "{90°}"], 'A',
      "Birim çemberde sinüs, noktanın ordinatıdır; ordinat 0° ve 180°'de sıfırdır. 360° aralığa dâhil değildir."),
  _q('sm-025', 's11-mat-05', 'Trigonometrik Denklemler', _z, "sin x = 2 denkleminin gerçek sayılardaki çözüm kümesi için aşağıdakilerden hangisi doğrudur?",
      ["Tek elemanlıdır.", "İki elemanlıdır.", "Sonsuz elemanlıdır.", "{90°} kümesidir.", "Boş kümedir."], 'E',
      "Her x için −1 ≤ sin x ≤ 1 olduğundan sin x = 2 eşitliğini sağlayan gerçek sayı yoktur; çözüm kümesi boştur."),
  _q('sm-026', 's11-mat-08', 'Üstel ve Logaritmik Denklemler', _o, "log₂(x) < 3 eşitsizliğinin çözüm kümesi aşağıdakilerden hangisidir?",
      ["(−∞, 8)", "(0, 8)", "(8, ∞)", "(0, 3)", "(3, 8)"], 'B',
      "Logaritmanın tanımlı olması için x > 0 olmalıdır. Taban 1'den büyük olduğundan log₂(x) < 3 ⟹ x < 2³ = 8. Çözüm: (0, 8)."),
  _q('sm-027', 's11-mat-09', 'Bileşke Fonksiyon', _o, "Fonksiyonlarda bileşke işlemiyle ilgili aşağıdakilerden hangisi doğrudur?",
      ["Her zaman f ∘ g = g ∘ f olur.", "Bileşke işlemi yalnızca doğrusal fonksiyonlarda tanımlıdır.", "Genel olarak değişme özelliği yoktur; f ∘ g ile g ∘ f farklı olabilir.", "(f ∘ g)(x) = f(x) · g(x) olur.", "(f ∘ g)(x) = f(x) + g(x) olur."], 'C',
      "(f ∘ g)(x) = f(g(x)) biçiminde tanımlanır. Bileşke işleminin birleşme özelliği vardır, değişme özelliği genel olarak yoktur."),
];
