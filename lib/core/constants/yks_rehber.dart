/// Koç Asistanı'nın cihaz içi YKS rehberi: sınav yapısı, net ve puan hesabı,
/// çalışma teknikleri. İnternet ve bulut yapay zekası olmadan yanıtlanır.
///
/// Yıla göre değişebilen ayrıntılar (başarı sırası şartları, katsayılar)
/// bilerek sayı verilmeden anlatılır ve ÖSYM kılavuzuna yönlendirilir.
library;

class RehberMaddesi {
  final String id;
  final String baslik;

  /// Aramada başlık kadar ağırlıklı eşleşen sözcükler (öğrencinin soruyu
  /// sorarken kullanacağı ifadeler).
  final String anahtarlar;
  final String metin;
  final List<String> maddeler;

  /// Yanıtın altında gösterilecek ekran düğmesi (etiket, rota).
  final (String, String)? rota;

  const RehberMaddesi(this.id, this.baslik, this.anahtarlar, this.metin, this.maddeler, [this.rota]);
}

const List<RehberMaddesi> yksRehberi = [
  // ─── Sınav yapısı ─────────────────────────────────────────
  RehberMaddesi(
    'tyt-yapi',
    'TYT kaç soru, kaç dakika?',
    'tyt temel yeterlilik testi soru sayisi sure dakika dagilim hangi dersler kac soru cikiyor oturum',
    'TYT (Temel Yeterlilik Testi) 120 soruluk tek oturumdur ve 165 dakika sürer. Tüm adaylar için zorunludur.',
    [
      'Türkçe: 40 soru',
      'Sosyal Bilimler: 20 soru (Tarih 5, Coğrafya 5, Felsefe 5, Din Kültürü 5)',
      'Temel Matematik: 40 soru (yaklaşık 30 matematik, 10 geometri)',
      'Fen Bilimleri: 20 soru (Fizik 7, Kimya 7, Biyoloji 6)',
      'Soru başına ortalama 80 saniyen var; Türkçe ve matematik toplam puanın büyük kısmını belirler.',
    ],
  ),
  RehberMaddesi(
    'ayt-yapi',
    'AYT kaç soru, kaç dakika?',
    'ayt alan yeterlilik testi soru sayisi sure dakika dagilim hangi dersler kac soru cikiyor oturum fizik kimya biyoloji edebiyat',
    'AYT (Alan Yeterlilik Testleri) 40\'ar soruluk 4 testten oluşur (toplam 160 soru) ve 180 dakika sürer. Yalnızca kendi alanının testlerini çözersin.',
    [
      'Türk Dili ve Edebiyatı – Sosyal Bilimler 1: Edebiyat 24, Tarih-1 10, Coğrafya-1 6',
      'Sosyal Bilimler 2: Tarih-2 11, Coğrafya-2 11, Felsefe Grubu 12, Din Kültürü 6',
      'Matematik: 40 soru (yaklaşık 30 matematik, 10 geometri)',
      'Fen Bilimleri: Fizik 14, Kimya 13, Biyoloji 13',
      'Sayısal: Matematik + Fen. Eşit Ağırlık: Matematik + Edebiyat-Sosyal 1. Sözel: Edebiyat-Sosyal 1 + Sosyal 2.',
    ],
  ),
  RehberMaddesi(
    'ydt-yapi',
    'YDT (Yabancı Dil Testi)',
    'ydt yabanci dil testi ingilizce dil puani kac soru sure dakika',
    'YDT 80 soruluk tek testtir ve 120 dakika sürer. Dil puanıyla öğrenci alan bölümleri (İngilizce öğretmenliği, mütercim tercümanlık, dil ve edebiyat bölümleri) için girilir.',
    [
      'Soru türleri: kelime, dil bilgisi, cloze test, cümle tamamlama, çeviri, paragraf, diyalog, anlamca yakın cümle, paragraf tamamlama, anlam bütünlüğünü bozan cümle.',
      'Dil puanı TYT ve YDT sonuçlarından hesaplanır; AYT gerekmez.',
    ],
  ),
  RehberMaddesi(
    'alanlar',
    'Puan türleri: Sayısal, Eşit Ağırlık, Sözel, Dil',
    'puan turu turleri alan sayisal esit agirlik sozel dil say ea soz hangi bolum hangi puan turuyle aliyor alan secimi',
    'YKS\'de bölümler dört puan türünden biriyle öğrenci alır:',
    [
      'Sayısal (SAY): mühendislikler, tıp, diş hekimliği, eczacılık, fen bölümleri. AYT Matematik + Fen.',
      'Eşit Ağırlık (EA): hukuk, işletme, iktisat, psikoloji, sınıf öğretmenliği. AYT Matematik + Edebiyat-Sosyal 1.',
      'Sözel (SÖZ): tarih, coğrafya, edebiyat öğretmenlikleri, gazetecilik, ilahiyat. AYT Edebiyat-Sosyal 1 + Sosyal 2.',
      'Dil (DİL): yabancı dil öğretmenlikleri, mütercim tercümanlık. YDT.',
      'Yalnızca TYT puanıyla ön lisans (2 yıllık) programlarına yerleşebilirsin.',
    ],
  ),
  RehberMaddesi(
    'net-hesabi',
    'Net nasıl hesaplanır?',
    'net nasil hesaplanir hesaplama kac yanlis bir dogruyu goturur dort yanlis dogru goturuyor net formulu bos',
    'Net = Doğru − (Yanlış ÷ 4). Dört yanlış bir doğruyu götürür; boş bırakılan soru neti etkilemez.',
    [
      'Örnek: 28 doğru, 8 yanlış ⟹ 28 − 8/4 = 26 net.',
      'Hiç fikrin olmayan soruyu boş bırakmak, rastgele işaretlemekten güvenlidir.',
      'İki şıkka indirebildiğin soruda işaretlemek uzun vadede kazandırır: doğru +1, yanlış −0,25.',
      'Bana "30 doğru 6 yanlış kaç net" yazarsan hesaplarım.',
    ],
    ('Deneme ekle', '/netler'),
  ),
  RehberMaddesi(
    'puan-hesabi',
    'YKS puanı nasıl hesaplanır?',
    'puan nasil hesaplanir hesaplama yerlestirme puani ham puan tyt yuzde 40 ayt yuzde 60 katki obp diploma notu ortaogretim basari puani okul puani',
    'Yerleştirme puanı = sınav puanı + okul başarı katkısı. Sınav puanında her testin neti, o testin katsayısıyla çarpılıp toplanır.',
    [
      'SAY, EA ve SÖZ puanlarında TYT\'nin ağırlığı %40, AYT\'nin ağırlığı %60\'tır.',
      'OBP (Ortaöğretim Başarı Puanı) = diploma notu × 5 (en çok 500). Yerleştirme puanına OBP × 0,12 eklenir; yani en çok 60 puan.',
      'Bir önceki yıl bir programa yerleştiysen OBP katkın yarıya iner.',
      'Test katsayıları her yıl sınav sonuçlarına göre az da olsa değişir; kesin değerler için ÖSYM\'nin o yılki kılavuzuna bak.',
    ],
  ),
  RehberMaddesi(
    'baraj',
    'Baraj puanı ve başarı sırası şartı',
    'baraj puani var mi kalkti kac puan 150 180 basari sirasi sarti siralama sinir tip hukuk muhendislik tercih yapabilmek',
    '2022\'den itibaren TYT ve AYT için baraj puanı uygulanmıyor. Ancak puanının hesaplanması için bazı koşullar var:',
    [
      'TYT puanının hesaplanması için Türkçe ya da Temel Matematik testinden en az 0,5 net yapman gerekir.',
      'Tıp, hukuk, mühendislik, mimarlık, öğretmenlik gibi bazı programlar için ayrıca başarı sırası şartı aranır.',
      'Başarı sırası sınırları yıldan yıla güncellenebildiği için tercih döneminde ÖSYM kılavuzundan kontrol et.',
    ],
  ),
  RehberMaddesi(
    'takvim',
    'YKS ne zaman?',
    'yks ne zaman sinav tarihi hangi ay kac gun kaldi basvuru tarihleri sonuclar ne zaman aciklanir tercih',
    'YKS her yıl genellikle haziran ayında bir hafta sonu yapılır: cumartesi TYT, pazar sabah AYT ve öğleden sonra YDT.',
    [
      'Başvurular genellikle şubat–mart aylarında ÖSYM\'nin AİS sistemi üzerinden alınır.',
      'Sonuçlar çoğunlukla temmuz ayında açıklanır, ardından tercih dönemi başlar.',
      'Kesin tarihler için ÖSYM\'nin o yılki sınav takvimine bak.',
    ],
  ),

  // ─── Çalışma teknikleri ───────────────────────────────────
  RehberMaddesi(
    'pomodoro',
    'Pomodoro tekniği',
    'pomodoro teknigi nedir nasil uygulanir 25 dakika calisma mola odaklanamiyorum dikkatim dagiliyor odaklanma',
    'Pomodoro, çalışmayı kısa ve kesintisiz bloklara bölme tekniğidir: 25 dakika tek işe odak, 5 dakika mola; dört bloktan sonra 15–30 dakika uzun mola.',
    [
      'Blok başlamadan ne çalışacağını yaz; blok sırasında telefonu başka odaya bırak.',
      'Aklına gelen başka işleri bir kâğıda not al, bloktan sonra bak.',
      '25 dakika kısa geliyorsa 50 dakika çalışma + 10 dakika mola dene (deneme ve paragraf için daha uygun).',
      'Uygulamadaki odak seansı her 25 dakikada 10 yıldız kazandırır ve bahçeni büyütür.',
    ],
    ('Odak seansı aç', '/calis'),
  ),
  RehberMaddesi(
    'aralikli-tekrar',
    'Aralıklı tekrar ve unutma eğrisi',
    'aralikli tekrar unutma egrisi unutuyorum calistigimi unutuyorum tekrar nasil yapilir ne zaman tekrar kalici ogrenme ezber',
    'Öğrenilen bilgi tekrar edilmezse birkaç günde büyük kısmı unutulur. Çözüm, tekrarı aralıkları açarak yapmaktır.',
    [
      'Yeni konuyu aynı gün akşam, sonra 1 gün, 3 gün, 1 hafta ve 1 ay sonra kısa kısa tekrar et.',
      'Tekrar ederken notu okumak yerine kendini sına: kapat, hatırlamaya çalış, sonra kontrol et (aktif hatırlama).',
      'Uygulamadaki kartlar bu aralıkları senin yerine hesaplar; her gün bekleyen kartları bitirmen yeterli.',
    ],
    ('Kartlara git', '/flashkart'),
  ),
  RehberMaddesi(
    'deneme-analizi',
    'Deneme analizi nasıl yapılır?',
    'deneme analizi nasil yapilir deneme sonrasi ne yapmaliyim yanlislarima nasil bakmaliyim yanlis defteri hata turleri',
    'Denemenin asıl faydası çözdükten sonra başlar. Her yanlış ve boş için nedenini bul:',
    [
      'Bilgi eksiği: konuyu bilmiyorsun ⟹ konu tekrarı ve o konudan 20–30 soru.',
      'İşlem ya da dikkat hatası: biliyordun ama yanlış yaptın ⟹ soruyu baştan, yavaş çöz; hata türünü not al.',
      'Süre: yetişmedi ⟹ turlama tekniği ve zamanlı branş denemesi.',
      'Yanlış sorunun çözümünü okuyup geçme; birkaç gün sonra kapalı şekilde yeniden çöz.',
      'Deneme netlerini uygulamaya girersen ders ders gidişatını ve net kaybını ben çıkarırım.',
    ],
    ('Deneme ekle', '/netler'),
  ),
  RehberMaddesi(
    'turlama',
    'Turlama tekniği ve sınavda süre yönetimi',
    'turlama teknigi sure yetmiyor sure yetistiremiyorum sinavda zaman yonetimi hangi dersten baslamaliyim soru basina kac dakika',
    'Turlama, soruları zorluk sırasına göre birkaç turda çözmektir; kolay soruların puanını garantiye alır.',
    [
      '1. tur: okur okumaz çözebildiğin sorular. Takıldığın soruya işaret koy, geç.',
      '2. tur: biraz uğraş isteyen işaretli sorular. 3. tur: kalan süre varsa en zorlar.',
      'Bir soruda 2 dakikayı geçtiysen bırak; aynı sürede iki kolay soru çözebilirsin.',
      'Hangi testle başlayacağını denemelerde dene ve sınav günü değiştirme. Çoğu aday en güçlü olduğu testle başlar.',
      'Cevapları kitapçıktan optik forma sayfa sayfa aktar; sona bırakma.',
    ],
  ),
  RehberMaddesi(
    'paragraf',
    'Paragraf soruları nasıl hızlanır?',
    'paragraf nasil cozulur hizlanir paragrafta yavasim paragraf yanlisim cok turkce netim artmiyor okuma hizi turkce nasil calisilir',
    'TYT Türkçe\'nin yarısından fazlası paragraftır ve paragraf bilgiyle değil düzenli pratikle gelişir.',
    [
      'Her gün 20–30 paragraf sorusu çöz; haftada 5 gün yapmak, bir günde 150 soru çözmekten etkilidir.',
      'Önce soru kökünü oku, sonra paragrafı; ne aradığını bilerek okursun.',
      '"Değinilmemiştir", "çıkarılamaz" gibi olumsuz köklerin altını çiz.',
      'Şıkları paragraftaki bir cümleyle doğrula; kendi yorumunla değil.',
      'Dil bilgisi az soruyla gelir ama kuralları bellidir: yazım, noktalama ve anlatım bozukluğunu kartlarla tekrar et.',
    ],
  ),
  RehberMaddesi(
    'matematik-calisma',
    'Matematik nasıl çalışılır?',
    'matematik nasil calisilir matematigim kotu matematik yapamiyorum temelim yok sifirdan matematik problem cozemiyorum problemler geometri nasil calisilir',
    'Matematik izleyerek değil, çözerek öğrenilir. Temelden başlayıp her konuyu soruyla pekiştir:',
    [
      'Sıra önemli: temel kavramlar, sayılar, bölünebilme, rasyonel sayılar, denklemler ⟹ sonra problemler ve fonksiyonlar.',
      'Konu anlatımından hemen sonra kolay sorular, ertesi gün orta zorlukta sorular çöz.',
      'Çözemediğin soruda çözüme bakmadan önce en az 3–4 dakika uğraş; sonra çözümü kapatıp kendin yeniden çöz.',
      'Problemler TYT matematiğin en büyük parçasıdır: her gün 15–20 problem, türlere ayırarak (yaş, işçi, hareket, yüzde, karışım).',
      'Geometride formül ezberi yetmez; her konudan şekil çizerek bol soru çöz.',
    ],
  ),
  RehberMaddesi(
    'fen-calisma',
    'Fen (Fizik, Kimya, Biyoloji) nasıl çalışılır?',
    'fen nasil calisilir fizik nasil calisilir kimya nasil calisilir biyoloji nasil calisilir fizik yapamiyorum biyoloji ezber',
    'Fen derslerinin çalışma biçimi birbirinden farklıdır:',
    [
      'Fizik: formülü ezberlemek yerine nereden geldiğini ve birimlerini anla; her konudan grafik ve yorum sorusu çöz.',
      'Kimya: mol ve temel hesaplamalar sağlam olmadan ilerleme; sözel kısımları (periyodik özellikler, bağlar) tablo ve kartla tekrar et.',
      'Biyoloji: bilgi yoğun derstir; konu sonunda kendi şemanı çiz ve aralıklı tekrarla pekiştir. Soruların çoğu yorumdur, çıkmış sorulara bak.',
      'Üç derste de yanlış yaptığın soruyu birkaç gün sonra yeniden çöz.',
    ],
  ),
  RehberMaddesi(
    'sozel-calisma',
    'Sözel dersler (Tarih, Coğrafya, Edebiyat, Felsefe) nasıl çalışılır?',
    'sozel nasil calisilir tarih nasil calisilir cografya nasil calisilir edebiyat nasil calisilir felsefe ezberleyemiyorum ezber nasil yapilir yazar eser',
    'Sözel derslerde hedef ezber değil, bilgiyi bağlamıyla hatırlamaktır:',
    [
      'Tarih: olayları neden–sonuç zinciriyle ve kronolojik sırayla çalış; kendi zaman çizelgeni çıkar.',
      'Coğrafya: harita üzerinde çalış; iklim, yer şekli ve ekonomik etkinliği birbirine bağla. Grafik ve harita sorusu çöz.',
      'Edebiyat: dönem özelliklerini öğren, sonra yazar–eser eşleştirmelerini kartlarla tekrar et.',
      'Felsefe: filozof ezberi yerine kavramları öğren; sorular çoğunlukla paragraf yorumudur.',
      'Okuduktan sonra kitabı kapatıp konuyu kendi cümlelerinle anlatabiliyorsan öğrenmişsindir.',
    ],
    ('Kartlara git', '/flashkart'),
  ),
  RehberMaddesi(
    'gunluk-calisma',
    'Günde kaç saat çalışmalı, kaç soru çözmeli?',
    'gunde kac saat calismaliyim gunde kac soru cozmeliyim gunluk calisma suresi kac saat ders calismak yeterli verimli calisma',
    'Önemli olan süre değil, kesintisiz ve planlı çalışılan zamandır. Genel bir çerçeve:',
    [
      '12. sınıf ve mezun: okul dışında günde 4–6 saat verimli çalışma iyi bir hedeftir; son aylarda artırılabilir.',
      '9–11. sınıf: günde 1,5–3 saat düzenli çalışma ve okul derslerini günü gününe tekrar yeterlidir.',
      'Soru sayısı hedefi koyacaksan derse göre koy: paragraf 20–30, problem 15–20, diğer derslerde konu başına 30–40 soru.',
      'Haftada bir günü hafif tut; uykudan kısma, yorgunken çözülen soru kalıcı olmaz.',
      'Bitirebildiğin bir program, bitiremediğin iddialı bir programdan daha çok çalıştırır.',
    ],
    ('Programımı aç', '/program'),
  ),
  RehberMaddesi(
    'oncelik',
    'TYT mi AYT mi, konu mu soru mu?',
    'tyt mi ayt mi once hangisi konu mu soru mu once konulari bitirmek mi nereden baslamaliyim nasil baslamaliyim yks ye nasil hazirlanilir calisma plani strateji',
    'Sıralama hedefine ve kalan süreye göre değişir, ama çoğu öğrenci için işleyen düzen şudur:',
    [
      'Önce TYT temelini (Türkçe-paragraf, temel matematik) oturt; AYT matematik ve fen bu temelin üstüne kurulur.',
      'Konu çalışması ile soru çözümünü ayırma: her konunun ardından aynı hafta o konudan soru çöz.',
      'Tüm konular bitmeden deneme çözmeye başla; haftada bir TYT denemesi eksiklerini gösterir.',
      'Sınava 2–3 ay kala ağırlığı konu tekrarından deneme ve yanlış analizine kaydır.',
      'Bana "programımı iyileştir" dersen verilerine göre öncelikli derslerini belirlerim.',
    ],
    ('Programımı aç', '/program'),
  ),
  RehberMaddesi(
    'kaynak',
    'Kaynak (soru bankası) nasıl seçilir?',
    'kaynak secimi hangi kaynak almaliyim soru bankasi hangi kitap hangi yayin kac kaynak bitirmeliyim kaynak onerisi',
    'Belirli bir yayın önermem; ama doğru kaynağı seçmenin ölçütleri bellidir:',
    [
      'Seviyene uygun olsun: soruların yaklaşık %60–70\'ini çözebildiğin kaynak seni geliştirir. Çok kolay ya da çok zor kaynak zaman kaybıdır.',
      'Her ders için aynı anda bir konu anlatımı ve bir–iki soru bankası yeter; yarım kalan çok kaynak yerine biten az kaynak.',
      'Çözümlü ya da video çözümlü olması, yanlışlarını analiz etmeni kolaylaştırır.',
      'ÖSYM\'nin çıkmış soruları en güvenilir kaynaktır; son 5–6 yılın sorularını mutlaka çöz.',
    ],
  ),
  RehberMaddesi(
    'son-donem',
    'Sınava son aylar ve son hafta',
    'son 3 ay son ay son hafta sinava az kaldi yetisir mi son donemde ne yapmaliyim sinavdan onceki gun sinav gunu ne yapmaliyim',
    'Son dönemde amaç yeni konu yığmak değil, bildiklerini nete çevirmektir:',
    [
      'Son 3 ay: haftada 2–3 deneme, her denemenin ayrıntılı analizi ve eksik çıkan konuların kısa tekrarı.',
      'Son ay: çıkmış sorular, sınav saatinde (10.15) zamanlı denemeler ve yanlışlarının tekrarı.',
      'Son hafta: yeni kaynak açma; formül ve kart tekrarı yap, uyku düzenini sınav saatine göre ayarla.',
      'Sınavdan önceki gün ağır çalışma; sınav giriş belgeni ve kimliğini hazırla, erken yat.',
      'Sınav günü takıldığın soruda oyalanma, turlama yap; bir testin kötü gitmesi diğerini etkilemesin.',
    ],
  ),
  RehberMaddesi(
    'erken-hazirlik',
    '9, 10 ve 11. sınıfta YKS\'ye hazırlık',
    '9 sinif 10 sinif 11 sinif sinifim siniftayim yks ye erken hazirlik ne zaman baslamaliyim simdiden calismali miyim okul dersleri yeterli mi',
    'YKS soruları 9–12. sınıf müfredatının tamamından gelir; bu yüzden okul derslerini iyi öğrenmek en iyi erken hazırlıktır.',
    [
      '9–10. sınıf: okul konularını günü gününe çalış, düzenli kitap oku (paragraf hızının temeli) ve matematik temelini sağlam tut.',
      '11. sınıf: AYT konularının büyük bölümü bu yıl işlenir; okul konularını soru bankasıyla destekle, yazın TYT eksiklerini kapat.',
      'Erken dönemde uzun saatler değil, düzen önemli: her gün kısa ama kesintisiz çalışma alışkanlığı kazan.',
      'Uygulamada sınıfına göre konu, soru ve kartlar hazır; Müfredatım ekranından sınıfını seçebilirsin.',
    ],
    ('Konularım', '/konular'),
  ),
  RehberMaddesi(
    'mezun',
    'Mezun olarak hazırlanmak',
    'mezun mezunum olarak hazirlanmak mezuna kaldim ikinci yil tekrar hazirlaniyorum mezun programi',
    'Mezun senesinin en büyük avantajı zaman, en büyük riski düzensizliktir:',
    [
      'Güne okul varmış gibi sabit saatte başla; çalışma, mola ve uyku saatlerin belli olsun.',
      'Geçen yılın deneme ve sınav sonucuna bakıp en çok net kaybettiğin dersleri öne al; bildiğin konuları baştan dinleyerek zaman harcama.',
      'İlk aylarda TYT temelini ve AYT\'de eksik kalan konuları kapat, yılın ikinci yarısını denemeye ayır.',
      'Önceki yıl bir programa yerleştiysen OBP katkının yarıya ineceğini hesaba kat.',
    ],
  ),
];
