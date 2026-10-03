Aşağıdaki kontrol listesi, önceki tüm maddeleri içerir ve genel mobil uygulama sorunları ile OWASP MASVS kategorilerine göre genişletilmiştir. En başta, listeyi bir yapay zeka modeline verirken kullanabileceğin hazır bir talimat metni var.

---

# 📋 Mobil Uygulama A'dan Z'ye Denetim Kontrol Listesi

## 0. Yapay Zeka Modeli İçin Kullanım Talimatı

Bu metni listeyle birlikte modele ver:

> Sen deneyimli bir mobil uygulama güvenlik ve kalite denetçisisin. Sana verdiğim proje kodunu aşağıdaki kontrol listesinin **her maddesine göre** incele. Hiçbir maddeyi atlama. Her madde için şu formatta yanıt ver:
>
> - **Durum:** ✅ Geçti / ❌ Kaldı / ⚠️ Kısmen / ➖ Uygulanamaz / ❓ Kodda doğrulanamadı
> - **Kanıt:** İlgili dosya adı ve satır numarası
> - **Risk seviyesi:** Kritik / Yüksek / Orta / Düşük
> - **Düzeltme önerisi:** Somut kod örneğiyle
>
> Kodu görmediğin maddelerde tahmin yürütme, "❓ Doğrulanamadı" yaz ve hangi dosyayı görmen gerektiğini belirt. "Production-ready" gibi genel ifadeler kullanma. Sonunda kritik ve yüksek riskli bulguları öncelik sırasına göre özetle.

---

## 1. Gizli Bilgi ve Anahtar Yönetimi

- [ ] İstemci kodunda gömülü API anahtarı, secret, şifre veya token yok (OpenAI, Stripe secret, AWS, SMTP vb.)
- [ ] Üçüncü taraf ücretli API çağrıları kendi backend üzerinden proxy'leniyor
- [ ] `.env` değerlerinin (`EXPO_PUBLIC_`, `REACT_APP_`, `--dart-define`, `BuildConfig`) bundle'a gömüldüğü ve gizli olmadığı biliniyor; bu değişkenlerde gerçek secret yok
- [ ] Supabase `service_role` anahtarı veya Firebase Admin SDK kimlik bilgileri uygulamada yok
- [ ] Google/Firebase API anahtarları paket adı ve SHA-1 parmak izi ile kısıtlanmış
- [ ] iOS API anahtarları bundle ID ile kısıtlanmış
- [ ] `.gitignore` içinde: `.env`, keystore (`.jks`, `.keystore`), `key.properties`, `google-services.json`, `GoogleService-Info.plist`, `*.p12`, `*.mobileprovision`
- [ ] Git geçmişinde daha önce commit edilmiş secret yok (gitleaks / trufflehog ile tarandı)
- [ ] Sızmış olabilecek anahtarlar döndürüldü (rotate edildi)
- [ ] İmza anahtarı (keystore) güvenli yerde yedekli ve şifreli; Play App Signing kullanılıyor
- [ ] Yorum satırlarında test şifresi, iç URL veya kimlik bilgisi yok
- [ ] Staging/iç sunucu adresleri release build'de yok

## 2. Yerel Veri Depolama

- [ ] Token, şifre ve hassas veriler güvenli depolamada: iOS Keychain, Android Keystore / EncryptedSharedPreferences, `expo-secure-store`, `flutter_secure_storage`
- [ ] Hassas veri `AsyncStorage`, `SharedPreferences`, `UserDefaults`, düz SQLite veya düz dosyada tutulmuyor
- [ ] Keychain erişim seviyesi uygun (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly` gibi)
- [ ] `android:allowBackup="false"` veya yedekleme kuralları (`dataExtractionRules`, `fullBackupContent`) hassas verileri hariç tutuyor
- [ ] Hassas yerel veritabanı şifreli (SQLCipher vb.)
- [ ] Hassas veriler harici depolamaya (SD kart, paylaşılan klasör) yazılmıyor
- [ ] Önbellek, geçici dosya ve log dosyalarında hassas veri kalmıyor
- [ ] Logout sırasında token, önbellek, yerel DB, kullanıcı dosyaları ve bellek içi state temizleniyor
- [ ] Uygulama silinip yeniden kurulduğunda iOS Keychain'de eski token kalma durumu ele alınmış
- [ ] WebView çerezleri ve önbelleği logout'ta temizleniyor
- [ ] Hassas veriler bellekte gereğinden uzun tutulmuyor

## 3. Kriptografi

- [ ] Kendi yazılmış şifreleme algoritması yok; platform/kanıtlanmış kütüphaneler kullanılıyor
- [ ] AES-ECB kullanılmıyor; AES-GCM tercih ediliyor
- [ ] Sabit veya tekrar kullanılan IV/nonce yok
- [ ] Şifreleme anahtarı koda gömülü değil; Keystore/Keychain'de üretilip saklanıyor
- [ ] MD5/SHA1 güvenlik amaçlı kullanılmıyor
- [ ] Şifre hash'leme (sunucuda) bcrypt / scrypt / Argon2 ile yapılıyor
- [ ] Token, OTP ve rastgele değerler kriptografik olarak güvenli üreteçle oluşturuluyor (`Math.random()` / `Random()` değil)
- [ ] Base64 "şifreleme" olarak kullanılmıyor

## 4. Kimlik Doğrulama ve Oturum Yönetimi

- [ ] Kimlik doğrulama sunucuda yapılıyor; istemcide "giriş yapıldı" bayrağıyla yetinilmiyor
- [ ] OAuth akışında PKCE kullanılıyor; implicit flow yok
- [ ] Client secret mobil uygulamada yok
- [ ] OAuth girişi gömülü WebView yerine sistem tarayıcısıyla yapılıyor (ASWebAuthenticationSession / Custom Tabs)
- [ ] Access token kısa ömürlü; refresh token rotasyonu var
- [ ] Refresh token çalınma/yeniden kullanım tespiti var
- [ ] Sunucu tarafında token iptali (revocation) mümkün
- [ ] Logout sunucuda da oturumu sonlandırıyor
- [ ] Şifre değişikliğinde diğer oturumlar sonlandırılıyor
- [ ] Oturum zaman aşımı (hareketsizlik) tanımlı, özellikle hassas uygulamalarda
- [ ] 401 yanıtında tek seferlik, kuyruklanmış token yenileme mantığı var (eşzamanlı çoklu yenileme yok)
- [ ] Biyometrik doğrulama kriptografik anahtara bağlı (Android `CryptoObject`, iOS Keychain `SecAccessControl`); yalnızca true/false kontrolü değil
- [ ] Biyometri kaydı değiştiğinde anahtar geçersiz kılınıyor
- [ ] Giriş, OTP ve şifre sıfırlamada rate limiting ve brute-force koruması var
- [ ] Hata mesajları kullanıcı varlığını ifşa etmiyor ("e-posta veya şifre hatalı")
- [ ] Şifre sıfırlama token'ları tek kullanımlık ve kısa ömürlü
- [ ] OTP süresi ve deneme sayısı sınırlı
- [ ] Güçlü şifre politikası sunucuda uygulanıyor
- [ ] İsteğe bağlı 2FA/MFA desteği (hassas uygulamalarda)
- [ ] JWT imzası sunucuda doğrulanıyor; `alg: none` kabul edilmiyor
- [ ] JWT içinde hassas veri yok (payload herkes tarafından okunabilir)

## 5. Yetkilendirme ve Backend Güvenliği

- [ ] Tüm yetki kontrolleri sunucuda; istemcideki "admin butonu gizleme" tek koruma değil
- [ ] IDOR kontrolü: her istekte kaynağın o kullanıcıya ait olduğu doğrulanıyor (`/orders/123`)
- [ ] Firebase Firestore/Realtime DB/Storage kurallarında `allow read, write: if true` yok
- [ ] Firebase kuralları kullanıcı kimliği ve veri doğrulaması içeriyor (Rules Playground ile test edildi)
- [ ] Supabase'de tüm tablolarda RLS etkin ve politikalar yazılmış
- [ ] Supabase Storage bucket politikaları tanımlı
- [ ] Kullanıcı kendi rolünü/yetkisini değiştiremiyor (mass assignment: `role`, `isAdmin`, `balance` alanları)
- [ ] Fiyat, indirim, bakiye gibi değerler istemciden alınmıyor; sunucuda hesaplanıyor
- [ ] Sunucuda tüm girdi doğrulaması yapılıyor (istemci doğrulaması yalnızca UX için)
- [ ] API rate limiting ve kötüye kullanım koruması var
- [ ] Sunucu hata yanıtlarında stack trace, SQL hatası veya iç bilgi yok
- [ ] Dosya yüklemede tür, boyut ve içerik sunucuda doğrulanıyor
- [ ] Yüklenen dosyalar tahmin edilemez isimlerle ve erişim kontrolüyle saklanıyor
- [ ] Admin endpoint'leri ayrı ve korunmuş
- [ ] Sunucu tarafında güvenlik logları ve anormallik uyarıları var

## 6. Ağ Güvenliği

- [ ] Tüm trafik HTTPS/TLS 1.2+ üzerinden
- [ ] Android `usesCleartextTraffic="false"`; Network Security Config tanımlı
- [ ] iOS ATS aktif; `NSAllowsArbitraryLoads` kapalı (istisnalar gerekçeli)
- [ ] SSL doğrulamasını devre dışı bırakan kod yok (`badCertificateCallback => true`, her şeyi kabul eden `TrustManager`, `HostnameVerifier`)
- [ ] Hassas uygulamalarda sertifika sabitleme (pinning) var ve yedek pin tanımlı
- [ ] Pin süresi dolduğunda uygulamanın kilitlenmemesi için plan var
- [ ] Hassas veriler URL/query parametresinde gönderilmiyor
- [ ] Debug proxy/Flipper/ağ inceleme araçları release'de devre dışı
- [ ] Kullanıcı eklenmiş CA sertifikalarına release'de güvenilmiyor
- [ ] WebSocket bağlantıları `wss://` ve kimlik doğrulamalı

## 7. Platform Etkileşimi ve Saldırı Yüzeyi

**Deep link / URL şemaları**

- [ ] Deep link parametreleri doğrulanıyor ve temizleniyor
- [ ] Hassas akışlarda custom scheme yerine Universal Links / App Links kullanılıyor (`assetlinks.json`, `apple-app-site-association` doğru)
- [ ] Deep link ile kimlik doğrulama atlanamıyor veya yetkisiz ekran açılamıyor
- [ ] Deep link ile gelen URL'ler WebView'de doğrudan açılmıyor (open redirect yok)

**Android bileşenleri**

- [ ] Gereksiz `android:exported="true"` Activity, Service, Receiver, Provider yok
- [ ] Dışa açık bileşenler izinle korunuyor
- [ ] ContentProvider'larda path traversal ve SQL injection yok
- [ ] PendingIntent'ler `FLAG_IMMUTABLE` ile oluşturuluyor
- [ ] Intent ile gelen veriler doğrulanıyor
- [ ] `FileProvider` doğru yapılandırılmış; tüm dizinler paylaşılmıyor

**WebView**

- [ ] Gerek yoksa JavaScript kapalı
- [ ] `addJavascriptInterface` / JS köprüsü yalnızca güvenilir içerikte
- [ ] `setAllowFileAccess`, `setAllowUniversalAccessFromFileURLs` kapalı
- [ ] Yalnızca izinli alan adları yükleniyor (allowlist)
- [ ] `originWhitelist={['*']}` gibi geniş izinler yok (React Native)
- [ ] WebView'de mixed content engelli

**Ekran ve pano**

- [ ] Hassas ekranlarda Android `FLAG_SECURE` aktif
- [ ] iOS'ta uygulama arka plana geçerken hassas ekran gizleniyor (uygulama değiştirici önizlemesi)
- [ ] Şifre alanlarında `secureTextEntry`, otomatik düzeltme ve klavye önbelleği kapalı
- [ ] Hassas veri panoya kopyalanıyorsa süre sonunda temizleniyor; Android 13+ hassas pano işareti kullanılıyor
- [ ] Üçüncü taraf klavyelerin hassas alanlarda kısıtlanması değerlendirildi

**İzinler**

- [ ] Yalnızca gerçekten kullanılan izinler istenmiş (manifest ve Info.plist taraması)
- [ ] İzinler ihtiyaç anında ve açıklamayla isteniyor
- [ ] Üçüncü taraf SDK'ların eklediği izinler kontrol edildi (birleştirilmiş manifest)

## 8. Kod Düzeyinde Güvenlik

- [ ] Yerel SQLite sorguları parametreli; string birleştirme yok
- [ ] Kullanıcı girdisi `eval`, dinamik kod veya komut çalıştırmada kullanılmıyor
- [ ] WebView'e basılan kullanıcı içeriği XSS'e karşı temizleniyor
- [ ] Dosya yollarında path traversal kontrolü var (zip slip dahil)
- [ ] Serileştirme/deserileştirme güvenli
- [ ] Regex'ler ReDoS'a açık değil
- [ ] Format string ve integer overflow riskleri (native kodda) kontrol edildi
- [ ] Hassas işlemler istemci saatine güvenmiyor

## 9. Tersine Mühendislik ve Dayanıklılık

- [ ] Android R8/ProGuard etkin (`minifyEnabled true`, `shrinkResources true`)
- [ ] ProGuard kuralları eksiksiz; reflection kullanan kütüphaneler (Gson, Retrofit modelleri) korunmuş
- [ ] Flutter'da `--obfuscate --split-debug-info` kullanılıyor
- [ ] React Native'de Hermes bytecode kullanılıyor
- [ ] `android:debuggable="false"` release'de
- [ ] Release build'de `console.log`, `print`, `Log.d` ile hassas veri yazılmıyor; loglar temizleniyor
- [ ] Hassas uygulamalarda root/jailbreak tespiti var
- [ ] Debugger, emülatör, Frida/hook tespiti (gerekliyse)
- [ ] Uygulama bütünlüğü/imza doğrulaması
- [ ] Play Integrity API veya iOS App Attest / DeviceCheck ile backend istemciyi doğruluyor
- [ ] Güvenlik kontrolleri yalnızca istemcide değil, sunucu tarafında da karar veriliyor

## 10. Ödeme ve Uygulama İçi Satın Alma

- [ ] Satın alma makbuzları sunucuda doğrulanıyor (App Store Server API, Google Play Developer API)
- [ ] Abonelik durumu sunucudan alınıyor; istemci bayrağıyla açılmıyor
- [ ] Sunucu bildirimleri (App Store Server Notifications, Google RTDN) işleniyor: iade, iptal, yenileme
- [ ] Satın almayı geri yükleme (restore purchases) çalışıyor
- [ ] Yarıda kalan/bekleyen işlemler ele alınıyor
- [ ] Kart bilgisi uygulamada saklanmıyor; ödeme sağlayıcısının SDK'sı kullanılıyor
- [ ] Çift ödeme engelleniyor (idempotency key)
- [ ] Dijital içerik için mağaza ödeme kurallarına uyuluyor

## 11. Bağımlılıklar ve Tedarik Zinciri

- [ ] Tüm paketler gerçekten var ve resmi kaynaktan (uydurma paket / slopsquatting kontrolü)
- [ ] Paketlerin indirilme sayısı, bakım durumu ve son güncelleme tarihi kontrol edildi
- [ ] `npm audit`, `flutter pub outdated`, OWASP Dependency-Check, Snyk veya Dependabot çalıştırıldı
- [ ] Bilinen güvenlik açığı olan sürüm yok
- [ ] Kullanımdan kaldırılmış (deprecated) paket veya API yok
- [ ] Lock dosyası (`package-lock.json`, `yarn.lock`, `pubspec.lock`, `Podfile.lock`) commit edilmiş
- [ ] Paket sürümleri framework sürümüyle uyumlu
- [ ] Kullanılmayan bağımlılıklar kaldırıldı
- [ ] Bağımlılık lisansları ticari kullanıma uygun (GPL vb. kontrolü)
- [ ] Üçüncü taraf SDK'ların topladığı veriler biliniyor

## 12. Gizlilik ve Yasal Uyumluluk

- [ ] KVKK aydınlatma metni ve gerekli açık rızalar mevcut
- [ ] GDPR (AB kullanıcıları varsa) gereklilikleri karşılanıyor
- [ ] Gizlilik politikası uygulama içinde ve mağaza sayfasında erişilebilir
- [ ] Veri minimizasyonu: yalnızca gerekli veri toplanıyor
- [ ] Kullanıcı verisini görüntüleme, dışa aktarma ve silme hakkı sağlanıyor
- [ ] Analitik ve crash raporlama için onay mekanizması var
- [ ] Verilerin yurt dışına aktarımı (sunucu konumu) değerlendirildi
- [ ] Çocuklara yönelik içerikte COPPA ve mağaza aile politikaları
- [ ] Loglarda ve analitikte kişisel veri (e-posta, telefon, konum) yok veya maskeleniyor
- [ ] Veri saklama süreleri tanımlı

## 13. Mağaza Gereksinimleri

- [ ] Uygulama içinden hesap silme özelliği var (Apple ve Google zorunluluğu)
- [ ] Üçüncü taraf sosyal giriş varsa "Sign in with Apple" eklendi (iOS)
- [ ] iOS Privacy Manifest (`PrivacyInfo.xcprivacy`) ve Required Reason API beyanları tamam
- [ ] Google Play Veri Güvenliği formu ve Apple gizlilik etiketleri doğru dolduruldu
- [ ] Takip yapılıyorsa App Tracking Transparency (ATT) izni isteniyor
- [ ] Tüm `Info.plist` izin açıklamaları (`NS...UsageDescription`) mevcut ve anlamlı
- [ ] `targetSdkVersion` Google Play'in güncel minimum gereksiniminde
- [ ] Foreground service türleri beyan edilmiş (Android 14+)
- [ ] Hassas izinler (SMS, arama geçmişi, arka plan konumu, tüm dosyalara erişim) için beyan formları
- [ ] Demo hesap bilgileri inceleme ekibi için hazır
- [ ] Uygulama ikonu, ekran görüntüleri ve açıklama politikalara uygun

## 14. Mimari ve Kod Kalitesi

- [ ] UI, iş mantığı, veri erişimi ve state yönetimi ayrılmış (katmanlı mimari)
- [ ] Tek dosyada yüzlerce satırlık dev bileşen yok
- [ ] Tutarlı isimlendirme, klasör yapısı ve state yönetimi yaklaşımı
- [ ] Parça parça üretilen kodlar arasında tutarsızlık yok
- [ ] Silinmiş veya "// geri kalan kod aynı" ile atlanmış kısım yok
- [ ] `// @ts-ignore`, `any`, `!` (force unwrap), `as!`, `lateinit` kötüye kullanımı yok
- [ ] Lint kuralları kapatılmamış; uyarılar giderilmiş
- [ ] Hatayı sessizce yutan boş `catch` blokları yok
- [ ] Mock veri, sahte API yanıtı ve TODO/FIXME yer tutucuları production'da yok
- [ ] Ölü kod ve kullanılmayan import'lar temizlendi
- [ ] Sihirli sayılar ve sabit değerler sabit/yapılandırma dosyasında
- [ ] Tip güvenliği (TypeScript strict, Dart null-safety, Kotlin null-safety) etkin
- [ ] Aşırı mühendislik veya yetersiz yapı yok; proje boyutuna uygun mimari

## 15. Bellek, Yaşam Döngüsü ve Eşzamanlılık

- [ ] Event listener, subscription, timer ve stream'ler kapatılıyor (`useEffect` cleanup, `dispose()`, `onDestroy`)
- [ ] Android'de Activity/Context sızıntısı yok (LeakCanary ile kontrol)
- [ ] iOS'ta retain cycle yok (`[weak self]`)
- [ ] Bileşen kapandıktan sonra state güncellenmiyor
- [ ] Ekrandan çıkıldığında devam eden istekler iptal ediliyor (`AbortController`, `CancelToken`)
- [ ] Hızlı ardışık isteklerde race condition yok (arama, filtreleme)
- [ ] Process death sonrası state geri yükleniyor (Android `SavedStateHandle`, `onSaveInstanceState`)
- [ ] Arka plan ↔ ön plan geçişleri doğru yönetiliyor (token yenileme, veri tazeleme, bağlantılar)
- [ ] Ağır işler (JSON parse, görsel işleme, şifreleme) ana thread dışında
- [ ] Deadlock ve thread-safety sorunları yok
- [ ] Yapılandırma değişikliklerinde (ekran döndürme, karanlık mod, dil) veri kaybı yok

## 16. Hata Yönetimi ve Ağ Dayanıklılığı

- [ ] Her ekranda yükleniyor, boş, hata ve başarı durumları tasarlanmış
- [ ] Mutlu yol dışındaki senaryolar ele alınmış
- [ ] Çevrimdışı durumda anlamlı mesaj ve mümkünse önbellekten içerik
- [ ] Bağlantı geri geldiğinde otomatik yeniden deneme
- [ ] İsteklerde timeout tanımlı
- [ ] Retry mantığı exponential backoff ile; POST gibi idempotent olmayan isteklerde dikkatli
- [ ] Null, eksik alan ve beklenmeyen API yanıtları uygulamayı çökertmiyor
- [ ] 4xx/5xx durum kodları ayrı ayrı ele alınıyor
- [ ] Global hata yakalayıcı: React Error Boundary, `FlutterError.onError`, `PlatformDispatcher.onError`, `Thread.setDefaultUncaughtExceptionHandler`
- [ ] Kullanıcıya teknik değil anlaşılır hata mesajları gösteriliyor
- [ ] Butonlara çift basma engelleniyor (çift sipariş/ödeme)
- [ ] Yavaş ağda (3G, yüksek gecikme) test edildi
- [ ] Sayfalama (pagination) veya sonsuz kaydırma doğru çalışıyor
- [ ] Sunucu bakım/zorunlu güncelleme yanıtları ele alınıyor

## 17. Çökmeler ve Donmalar

- [ ] Crash raporlama (Crashlytics, Sentry) entegre ve release'de aktif
- [ ] Symbol/mapping dosyaları (dSYM, `mapping.txt`, Flutter debug info) yükleniyor
- [ ] Android ANR (uygulama yanıt vermiyor) riski olan ana thread işleri yok
- [ ] iOS watchdog zaman aşımına neden olan açılış işleri yok
- [ ] Düşük bellek uyarıları ele alınıyor
- [ ] Eski işletim sistemi sürümlerinde (minimum SDK / iOS sürümü) test edildi
- [ ] Release build gerçek cihazda test edildi (debug'da çalışıp release'de çöken sorunlar)

## 18. Performans

- [ ] Uzun listelerde sanallaştırma: `FlatList`/`FlashList`, `ListView.builder`, `LazyColumn`, `RecyclerView`, `UICollectionView`
- [ ] Liste öğelerinde benzersiz ve kararlı key (index değil)
- [ ] Gereksiz yeniden render yok (`memo`, `useCallback`, `useMemo`, `const` widget)
- [ ] Görseller boyutlandırılmış, sıkıştırılmış (WebP/AVIF) ve önbellekleniyor
- [ ] Açılış süresi ölçüldü ve optimize edildi (lazy loading, ertelenmiş başlatma)
- [ ] Animasyonlar 60/120 fps'de akıcı; native driver kullanılıyor
- [ ] Uygulama boyutu optimize: App Bundle, kullanılmayan kaynaklar ve kütüphaneler temizlendi
- [ ] Gereksiz ağ istekleri ve tekrarlayan çağrılar yok
- [ ] Büyük verilerde arama/filtreleme için debounce kullanılıyor
- [ ] Bellek kullanımı profil araçlarıyla (Android Profiler, Instruments, Flutter DevTools) incelendi

## 19. Pil ve Kaynak Kullanımı

- [ ] Sürekli yüksek hassasiyetli konum takibi yok
- [ ] Gereksiz polling yerine push/WebSocket tercih ediliyor
- [ ] Arka plan işleri sistem planlayıcılarıyla (WorkManager, BGTaskScheduler) yapılıyor
- [ ] Wake lock'lar serbest bırakılıyor
- [ ] Sensörler kullanılmadığında kapatılıyor
- [ ] Mobil veride büyük indirmeler kullanıcı onayıyla

## 20. Arayüz ve Duyarlı Tasarım

- [ ] Safe area, çentik, Dynamic Island ve alt gezinme çubuğu hesaba katılmış
- [ ] Android 15 edge-to-edge uyumu
- [ ] Android geri tuşu ve predictive back hareketi doğru çalışıyor
- [ ] Klavye form alanlarını kapatmıyor
- [ ] Küçük telefon, büyük telefon, tablet, katlanabilir cihazlarda test edildi
- [ ] Yatay mod destekleniyor veya bilinçli olarak kilitlendi
- [ ] Karanlık mod destekleniyor; sabit renk yok
- [ ] Uzun metinler taşmıyor, kesiliyor veya satır atlıyor
- [ ] iOS ve Android platform alışkanlıklarına uygun gezinme
- [ ] Dokunmatik geri bildirim (ripple/highlight) var

## 21. Erişilebilirlik

- [ ] Tüm etkileşimli öğelerde erişilebilirlik etiketleri (`accessibilityLabel`, `contentDescription`, `Semantics`)
- [ ] VoiceOver ve TalkBack ile tüm akışlar test edildi
- [ ] Dokunma alanları en az 44×44 pt / 48×48 dp
- [ ] Dinamik yazı boyutu destekleniyor; büyük yazıda arayüz bozulmuyor
- [ ] Renk kontrastı WCAG AA seviyesinde
- [ ] Bilgi yalnızca renkle iletilmiyor
- [ ] Odak sırası mantıklı
- [ ] Animasyonları azaltma tercihi (reduce motion) dikkate alınıyor

## 22. Yerelleştirme

- [ ] Metinler koda sabit yazılmamış; i18n altyapısı var
- [ ] Türkçe `i/İ` ve `ı/I` dönüşümleri locale belirtilerek yapılıyor (e-posta karşılaştırmada `toLowerCase()` hatası)
- [ ] Tarih, saat, sayı ve para birimi yerel formatta
- [ ] Çoğul ifadeler doğru yönetiliyor
- [ ] RTL dil desteği (gerekliyse)
- [ ] Çevirilerde metin uzunluğu farkları arayüzü bozmuyor

## 23. Formlar ve Kullanıcı Girdisi

- [ ] Uygun klavye tipleri (e-posta, telefon, sayısal)
- [ ] Otomatik doldurma ipuçları (`textContentType`, `autofillHints`) tanımlı; şifre yöneticileri çalışıyor
- [ ] Anlık ve anlaşılır doğrulama mesajları
- [ ] Emoji, özel karakter ve çok uzun girişlerde uygulama bozulmuyor
- [ ] Baştaki/sondaki boşluklar temizleniyor
- [ ] Gönderim sırasında buton devre dışı
- [ ] Yarım kalmış form verisi yanlışlıkla kaybolmuyor

## 24. Veri, Senkronizasyon ve Önbellek

- [ ] Yerel veritabanı migration'ları yazılmış ve eski sürümden güncelleme test edildi
- [ ] Çevrimdışı değişikliklerde çakışma çözüm stratejisi var
- [ ] Tarihler sunucuda UTC olarak saklanıyor; saat dilimi dönüşümleri doğru
- [ ] Önbellek geçersiz kılma stratejisi tanımlı
- [ ] Kullanıcı değiştiğinde önceki kullanıcının önbelleği gösterilmiyor
- [ ] Abonelik süresi ve kampanya bitişi gibi kontroller sunucu saatine göre

## 25. Bildirimler

- [ ] Android 13+ `POST_NOTIFICATIONS` izni isteniyor
- [ ] Push token'ı logout'ta sunucudan siliniyor
- [ ] Bildirim içeriğinde OTP veya hassas veri yok (kilit ekranı)
- [ ] Bildirime tıklayınca doğru ekran açılıyor (uygulama kapalı, arka planda, açıkken)
- [ ] Bildirim kanalları (Android) tanımlı
- [ ] Kullanıcı bildirim tercihlerini yönetebiliyor

## 26. Medya, Kamera ve Dosyalar

- [ ] Android 13+ granüler medya izinleri ve Photo Picker kullanılıyor
- [ ] iOS sınırlı fotoğraf erişimi (limited library) ele alınıyor
- [ ] Yüklenen görsellerde EXIF konum verisi temizleniyor
- [ ] Büyük dosya yüklemelerinde ilerleme, iptal ve devam ettirme
- [ ] İndirilen dosyalar doğrulanıyor; güvenilmeyen kaynaktan kod çalıştırılmıyor

## 27. Konum ve Sensörler

- [ ] Yalnızca gereken hassasiyet isteniyor (yaklaşık konum yeterliyse)
- [ ] Arka plan konumu yalnızca gerçekten gerekliyse ve gerekçeli
- [ ] Konum izni reddedildiğinde uygulama çalışmaya devam ediyor
- [ ] Konum verisi gereğinden uzun saklanmıyor

## 28. İzin Akışları

- [ ] İzin reddedildiğinde uygulama çökmüyor
- [ ] "Bir daha sorma" seçildiğinde kullanıcı ayarlara yönlendiriliyor
- [ ] İzin istenmeden önce neden gerektiği açıklanıyor
- [ ] Kullanıcı izni ayarlardan kaldırıp geri döndüğünde uygulama doğru davranıyor

## 29. Arka Plan İşleri

- [ ] Doze modu ve App Standby etkileri hesaba katılmış
- [ ] iOS arka plan yürütme sınırlarına uyuluyor
- [ ] Arka plan işleri başarısız olursa yeniden deneniyor
- [ ] Foreground service kullanımı gerekçeli ve bildirimli

## 30. Test

- [ ] Birim testleri iş mantığını kapsıyor (yalnızca "render oluyor mu" testleri değil)
- [ ] Entegrasyon ve uçtan uca testler (Detox, Maestro, Appium, Espresso, XCUITest, `integration_test`)
- [ ] Hata senaryoları ve kenar durumlar test ediliyor
- [ ] Güvenlik testleri: MobSF statik/dinamik analiz
- [ ] Firebase/Supabase kuralları için otomatik testler
- [ ] Farklı cihaz ve işletim sistemi sürümlerinde test (Firebase Test Lab vb.)
- [ ] Güncelleme senaryosu test edildi (eski sürümden yeni sürüme)
- [ ] Temiz kurulum senaryosu test edildi

## 31. Build, Yapılandırma ve Dağıtım

- [ ] Dev, staging ve production ortamları ayrı (ayrı API, ayrı Firebase projesi, ayrı paket adı/flavor)
- [ ] Release build yapılandırması debug'dan ayrı ve doğru
- [ ] Sürüm numaralandırması tutarlı (`versionCode`/`buildNumber` artıyor)
- [ ] CI/CD hattı var (GitHub Actions, Codemagic, Bitrise, EAS, Fastlane)
- [ ] CI'da secret'lar güvenli değişkenlerde
- [ ] Zorunlu güncelleme mekanizması var (kritik açıklarda eski sürümü durdurmak için)
- [ ] OTA güncellemeleri (Expo Updates, Shorebird vb.) imzalı ve mağaza kurallarına uygun
- [ ] `build.gradle`, `Podfile`, `AndroidManifest.xml`, `Info.plist` doğru ve güncel
- [ ] Aşamalı yayın (staged rollout) kullanılıyor

## 32. İzleme, Loglama ve Analitik

- [ ] Yapılandırılmış loglama; release'de log seviyesi düşük
- [ ] Loglarda token, şifre ve kişisel veri yok
- [ ] Performans izleme (açılış süresi, ağ süreleri)
- [ ] Önemli olaylar için analitik; kullanıcı onayına bağlı
- [ ] Backend hata ve anormallik uyarıları kurulu

## 33. Yapay Zeka Tarafından Üretilen Koda Özgü Kontroller

- [ ] Üretilen her paket adı ve API resmi dokümantasyonda doğrulandı
- [ ] Kullanımdan kaldırılmış API'ler (Android `AsyncTask`, Kotlin synthetics, eski React Navigation sözdizimi, null-safety öncesi Dart) yok
- [ ] Güvenlik önlemleri yalnızca istendiğinde değil, varsayılan olarak var
- [ ] Backend tarafı unutulmamış (doğrulama, yetkilendirme, rate limiting)
- [ ] Hata çözmek için eklenen geçici güvenlik gevşetmeleri (HTTP izni, SSL kapatma, açık kurallar) geri alındı
- [ ] Uzun konuşmalarda başta belirlenen mimari ve kütüphanelerden sapma yok
- [ ] Yapılandırma dosyalarındaki değişiklikler elle gözden geçirildi
- [ ] "Tamamlandı" denilen özellikler gerçekten uçtan uca çalışıyor

## 34. Framework'e Özgü Hızlı Kontroller

**React Native / Expo**

- [ ] `EXPO_PUBLIC_` değişkenlerinde secret yok
- [ ] Hermes etkin; release'de `__DEV__` kontrolleri doğru
- [ ] `react-native-webview` güvenli yapılandırılmış
- [ ] Expo `app.json` / `app.config.js` izinleri minimum

**Flutter**

- [ ] `--obfuscate --split-debug-info` ile derleniyor
- [ ] `kDebugMode` / `kReleaseMode` kontrolleri doğru
- [ ] `HttpClient.badCertificateCallback` release'de yok
- [ ] Controller'lar ve stream'ler `dispose()` ediliyor

**Native Android**

- [ ] R8 etkin, `debuggable false`, Network Security Config tanımlı
- [ ] Jetpack Security / Keystore kullanılıyor
- [ ] LeakCanary ile sızıntı kontrolü yapıldı

**Native iOS**

- [ ] ATS aktif, Keychain doğru erişim seviyesiyle
- [ ] Privacy Manifest tamam
- [ ] `[weak self]` ile retain cycle önlendi

## 35. Önerilen Araçlar

- **Statik/dinamik güvenlik analizi:** MobSF, OWASP MASTG test senaryoları
- **Secret taraması:** gitleaks, trufflehog
- **Bağımlılık taraması:** Snyk, Dependabot, `npm audit`, OWASP Dependency-Check
- **Trafik inceleme:** Burp Suite, mitmproxy, Charles
- **Çalışma zamanı analizi:** Frida, objection
- **Bellek ve performans:** LeakCanary, Android Profiler, Xcode Instruments, Flutter DevTools
- **Referans standartlar:** OWASP MASVS ve OWASP Mobile Top 10

---

Modelin daha isabetli sonuç vermesi için listeyi tek seferde değil, bölüm bölüm (örneğin önce 1–10 güvenlik, sonra 14–19 kalite) ve ilgili dosyalarla birlikte vermeni öneririm; tek istekte her şeyi denetletmek, modelin maddeleri yüzeysel geçmesine yol açabilir.

İstersen bu listeyi düzenleyip işaretleyebileceğin bir dokümana da dönüştürebilirim.
