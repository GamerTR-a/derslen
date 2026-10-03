# LiseNET — YKS Koçu Mobil Uygulaması Master Kalıp & Denetim Belgesi (`kalıp.md`)

Bu belge, **LiseNET (YKS Koçu)** mobil uygulamasının mimari, güvenlik, UI/UX, performans, çevrimdışı öncelikli (Offline-First) veri yönetimi ve YKS algoritmalarının %100 sorunsuz, çökmesiz ve üretime hazır (Production-Ready) çalışmasını garanti altına alan 75 maddelik Master Denetim Kalıbıdır.

---

## 🛡️ Bölüm 1: Temel & İleri Düzey Güvenlik (1 - 25)

1. **API Key Sanitization:** API URL ve anahtarlar `String.fromEnvironment` ile güvenli şekilde alınır.
2. **Supabase Isolated Fallback:** Supabase ilklendirilemediğinde uygulama durmaz, çevrimdışı çalışma moduna geçer.
3. **Safe Storage Initialization:** `SharedPreferences` başlatılamazsa `SharedPrefsStorageService` hata fırlatmaz, bellek içi cache ile çalışmaya devam eder.
4. **Encrypted Token Management:** Hassas token ve kimlik bilgileri `FlutterSecureStorage` (iOS Keychain / Android KeyStore) ile saklanır.
5. **Data Minimization & Privacy:** Kullanıcının tüm yerel verilerini tek tıkla kalıcı olarak silme (`clearAllData`) imkanı sunulur.
6. **Input Sanitization:** Arama ve form girdi alanlarında SQLi / Script injection riski oluşturan karakterler süzülür.
7. **XSS Prevention:** Kullanıcı notları ve metin alanları render edilirken özel karakterler kaçış karakterleriyle işlenir.
8. **Network Timeout & Graceful Retry:** Ağ istekleri 15 saniyelik zaman aşımına tabidir. Hata durumunda Türkçe anlaşılır mesaj gösterilir.
9. **Log Masking:** Production loglarında kullanıcı e-postası, şifresi veya token bilgileri asla yazdırılmaz.
10. **Android Manifest Security:** `android:allowBackup="false"` ve `usesCleartextTraffic="false"` ayarları ile veri sızıntısı engellenir.
11. **iOS Keychain Protection:** iOS üzerinde Keychain koruma düzeyi `first_unlock_this_device` olarak ayarlanır.
12. **Immutable Data Models:** Modeller `copyWith` ve immutability prensibine uygun yönetilir.
13. **Session Persistence:** Oturum durumu cihaz kapansa dahi SharedPreferences/SecureStorage ile hatırlanır.
14. **Silent Local Cache Fallback:** İnternet kesildiğinde uygulamanın verileri gösterilmeye devam eder.
15. **Uncaught Error Boundary:** `FlutterError.onError` ve `PlatformDispatcher.instance.onError` yakalayıcıları açılışta aktif edilir.
16. **State Isolation:** Riverpod state nesneleri doğrudan mutasyona uğratılmaz.
17. **Route Protection:** GoRouter redirect fonksiyonu yetkisiz sayfalara erişimi engeller.
18. **BOLA Protection:** Kullanıcı verileri sadece o cihaza özel ID ile ilişkilendirilir.
19. **Rate Limiting Handling:** Auth isteklerinde rate-limit aşıldığında kullanıcıya uyarı gösterilir.
20. **Secure Password Handling:** Şifreler hafızada açık metin değişken olarak tutulmaz.
21. **KVKK Veri Sırfırlama Diyaloğu:** Profil sayfasından "Tüm Verilerimi Sil" işlemi çift onay ile yapılır.
22. **Environment Fallback Readiness:** SUPABASE_URL tanımlı olmadığında doğrudan mock auth mekanizması devreye girer.
23. **Secure Form State Reset:** Oturum kapatıldığında tüm form controller ve state bilgileri temizlenir.
24. **Memory Leak Prevention:** Timer, Controller ve AnimationController yapıları `dispose()` ile temizlenir.
25. **Production Build Stripping:** Print ifadeleri production derlemesinde tamamen devre dışı bırakılır.

---

## 🎨 Bölüm 2: UI / UX & Responsive Design Standartları (26 - 50)

26. **Çökmesiz Açılış (Boot Safety):** `WidgetsFlutterBinding.ensureInitialized()` ve try-catch sarılı main yapısı ile açılış garantilenir.
27. **GoRouter Error Boundary:** `errorBuilder` tanımlanarak bulunamayan sayfalarda yönlendirme hatası engellenir.
28. **PopScope Back Button Guard:** Ana ekran sekmelerinde geri tuşuna basıldığında uygulamadan kaza ile çıkılması engellenir.
29. **48x48 dp Touch Target:** Tüm ikon ve buton tıklama alanları minimum 48x48 dp boyutundadır.
30. **SafeArea Wrapping:** Çentikli ve kavisli ekranlarda içerikler çentik altında kalmaz.
31. **Pixel Overflow Prevention:** Form ve klavye açılan ekranlar `SingleChildScrollView` ile taşmaya karşı korunur.
32. **Haptic Feedback:** Görev tamamlama, kart çevirme ve test bitirmede dokunsal geri bildirim verilir.
33. **Smooth Micro-Animations:** Sekme ve ekran geçişleri `FadeTransition` ve `AnimatedSwitcher` ile akıcıdır.
34. **Empty State Illusration:** Liste veya veri olmadığında (ör. kayıtlı deneme yok) açıklayıcı görsel ve yönlendirici mesaj gösterilir.
35. **Deprecation Cleanup:** Deprecated `withOpacity` kullanımı `.withValues(alpha: ...)` ile güncellenmiştir.
36. **Modern Dark Theme Palette:** Gece modu tayfı `#0F172A` (Scaffold), `#1E293B` (Surface/Card) ve `#818CF8` (Primary Indigo) renkleriyle göz yormaz.
37. **Dynamic Visual Indicators:** Konu tamamlama ve net gelişimlerinde dairesel/çizgisel ilerleme barları kullanılır.
38. **Snackbar & Toast Feedback:** Başarılı/başarısız tüm işlemlerde anlık bilgilendirme çubuğu gösterilir.
39. **Readable Typography:** Yazı tipleri Okunabilirlik Standartlarına uygun punto ve satır yüksekliklerine sahiptir.
40. **Card Elevation & Radius:** Tüm kart elemanlarında tutarlı 20px köşe yuvarlatma uygulanır.
41. **Form Validation Feedback:** Şifre uzunluğu ve e-posta format hataları anlık olarak gösterilir.
42. **Accessible Icon Labels:** İkon butonlarında ekran okuyucular için semantics etiketleri yer alır.
43. **Loading Shimmer Effect:** Veriler yüklenirken skeleton/shimmer efektleri gösterilir.
44. **Responsive Layout Grid:** Tablet ve farklı ekran boyutlarında ızgara yapısı esnek adapte olur.
45. **Modal Bottom Sheets:** Detay dialog pencereleri alt katman (bottom sheet) olarak sürüklenip kapatılabilir.
46. **Clear Focus Node Management:** Klavye kapatma dokunuşlarında focus node otomatik bırakılır.
47. **Contrast Ratio Compliance:** Metin ve arka plan renk kontrastı WCAG standartlarına uygundur.
48. **Custom Scroll Physics:** Listelerde `BouncingScrollPhysics` ile doğal kaydırma hissi sağlanır.
49. **Interactive Badge System:** Başarı ve streak kazanımlarında rozet simgeleri gösterilir.
50. **Quick Search Filtering:** Konu takibi ve aramalarda anlık filtrelenmiş sonuç gösterimi yapılır.

---

## 🧠 Bölüm 3: YKS Koçu Özel Algoritma & İçerik Denetimi (51 - 75)

51. **SM-2 Algorithm Safety:** Flashkart akıllı tekrar algoritmasında sıfıra bölünme ve negatif aralık oluşması engellenir.
52. **Sliding Window Daily Plan:** Öğrenci alanına (Sayısal, EA, Sözel, YDT) göre dengeli günlük ders dağılımı yapılır.
53. **OGM Soru Bankası Safe Filter:** Soru havuzu boş geldiğinde alternatif test soruları otomatik yüklenir.
54. **Net & Sıralama Hesaplama:** TYT ve AYT net hesaplarında 4 yanlış 1 doğru götürme mantığı hassas hesaplanır.
55. **Sosyal & SOS Destek Modülü:** Sınav kaygısı ve motivasyon için nefes egzersizi ve mentor önerileri mevcuttur.
56. **Deneme İstatistik Çatısı:** `fl_chart` ile net grafiklerinde null veriler sıfır kabul edilerek çizim çökmesi önlenir.
57. **Flashkart Flip Animation:** 3D kart çevirme animasyonu takılmadan 60 FPS çalışır.
58. **Konu İlerleme Yüzdesi:** Ders bazlı tamamlanan konuların yüzdesi anlık hesaplanır.
59. **Onboarding Flow Persistence:** Seçilen alan (Sayısal/EA/Sözel/YDT) ve hedef üniversite bilgileri kalıcı kaydedilir.
60. **Email Verification Code Simulation:** E-posta doğrulama kod girişinde 6 haneli OTP doğrulaması yapılır.
61. **Profil Fotoğrafı / Avatar Desteği:** Kullanıcı profilinde dinamik harf avatarı gösterilir.
62. **Test Çözme Zamanlayıcısı:** Soru başına geçen süre sayacı arka planda sorunsuz ilerler.
63. **Yanlış Soru Analiz Deposu:** Yanlış yapılan sorular tekrar çözülmek üzere depolanır.
64. **Hedef Puan & Derece Göstergesi:** Öğrencinin hedeflediği sıralama ile anlık netleri kıyaslanır.
65. **Günlük Çalışma Süresi Sayacı:** Pomodoro/Zamanlayıcı süresi profil istatistiğine eklenir.
66. **Offline Test Modu:** İnternet olmadan da OGM soru bankasından test çözülebilir.
67. **Haftalık Plan Telafi Günü:** Tamamlanmayan konular otomatik telafi gününe devredilir.
68. **Net Artış Trend Analizi:** Son 5 denemenin ortalaması alınarak yükseliş/düşüş trendi hesaplanır.
69. **Performans Notları:** Koçun öğrenciye özel günlük tavsiye notu gösterilir.
70. **Çoklu Soru Tipi Desteği:** Çoktan seçmeli, doğru/yanlış ve boşluk doldurma soru kalıpları desteklenir.
71. **Ders Bazlı Renk Kodlaması:** Matematik, Fizik, Türkçe vb. derslerin ayırt edici renk temaları bulunur.
72. **Streak Çalışma Zinciri:** Üst üste uygulamaya girilen günler sayılır ve motive edici rozet verilir.
73. **Zamanlayıcı Ses Efektleri:** Odaklanma zamanlayıcısı bittiğinde zil sesi uyarısı çalınır.
74. **Sonuç Ekranı Detaylı Özet:** Çözülen testin analizi (Doğru, Yanlış, Boş, Net, Harcanan Süre) grafikle sunulur.
75. **Tam Üretime Hazır (Production-Ready) Doğrulama:** `flutter analyze` ve `flutter test` %100 sorunsuz geçer.
