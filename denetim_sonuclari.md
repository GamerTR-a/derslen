# LiseNET (yks_kocu) — kontrol.md Denetim Sonuçları

## ✅ Bu oturumda uygulanan düzeltmeler (2026-09-27)

| # | Bulgu | Durum |
|---|---|---|
|1| Hesap silme çalışmıyordu (Kritik) | **Düzeltildi** — öğrenci ve koç ekranları artık `SupabaseAuthService.deleteAccount()` RPC'sini gerçekten çağırıyor |
|2| `profiles.xp` RLS ile korunmuyordu | **Düzeltildi (kod) + ⚠️ Aksiyon gerekiyor (DB)** — `award_xp()` SECURITY DEFINER RPC + `xp` alanını kilitleyen `WITH CHECK` eklendi, client artık RPC çağırıyor. **`supabase_schema.sql` sonundaki "MIGRATION" bloğunu canlı Supabase projenizde SQL Editor'den çalıştırmadan bu düzeltme production'a yansımaz.** |
|3| Oturum token'ları şifresiz SharedPreferences'taydı | **Düzeltildi** — `SecureSupabaseLocalStorage` (flutter_secure_storage tabanlı) `Supabase.initialize`'a bağlandı |
|4| `logout()` önbelleği tam temizlemiyordu | **Düzeltildi** — kullanıcıya özel namespaced veriler + secure storage artık logout'ta temizleniyor |
|5| Min şifre uzunluğu 6 karakterdi | **Düzeltildi** — sunucu tarafı doğrulama ve kayıt formu 8'e çıkarıldı (mevcut kullanıcılar login'de etkilenmez) |
|6| Network timeout neredeyse hiç yoktu | **Düzeltildi** — tüm Supabase istekleri için global 15s timeout (`TimeoutHttpClient`) |
|7| Gizlilik politikasına uygulama içi erişim yoktu | **Düzeltildi** — yeni in-app ekran (`/gizlilik-politikasi`) + Profil sekmesinden link |
|8| Şifre sıfırlama akışı yoktu | **Düzeltildi** — `/sifremi-unuttum` ekranı + `resetPasswordForEmail`, login'den link |
|9| iOS Privacy Manifest yoktu | **Düzeltildi** — `PrivacyInfo.xcprivacy` oluşturuldu ve Xcode projesine eklendi (Mac'te açıp doğrulamanız önerilir) |
|10| Kullanılmayan Kamera/Galeri/Mikrofon izin açıklamaları | **Düzeltildi** — Info.plist'ten kaldırıldı (özellik gerçekten planlanıyorsa paketle birlikte geri eklenmeli) |
|11| Release build obfuscation yoktu | **Düzeltildi** — `build_release.ps1` scripti (`--obfuscate --split-debug-info`) eklendi |
|12| Android `FLAG_SECURE` yoktu | **Düzeltildi** — giriş/kayıt ekranlarında etkin (MethodChannel, yalnızca bu ekranlarda; net/istatistik ekranlarının paylaşılabilir kalması için global uygulanmadı) |
|13| Kullanılmayan bağımlılıklar | **Düzeltildi** — `audioplayers`, `cached_network_image`, `connectivity_plus` kaldırıldı |
|14| Release'de sarmalanmamış `debugPrint` | **Düzeltildi** — 18 çağrının tamamı `kDebugMode` ile sarmalandı |
|15| `admin_tickets_tab.dart` controller sızıntısı | **Düzeltildi** — dialog kapanışında `dispose()` ediliyor |
|16| Koç detay ekranı mock veriyle çalışıyordu | **Kısmen** — gerçek backend entegrasyonu yapılmadı (ayrı bir özellik geliştirme işi); interim olarak ekrana "Beta: örnek veri" uyarı banner'ı eklendi |
|17| Gizlilik politikasında veri taşınabilirliği maddesi yoktu | **Düzeltildi** — PRIVACY_POLICY.md / privacy_policy.html'e eklendi |

`flutter analyze`: **No issues found**. `flutter test`: **4/4 geçti**.

### ⏳ Henüz yapılmayan / karar gerektiren maddeler
- **`key.properties` zayıf parolası** — gerçek keystore dosyasının parolasını değiştirmek `keytool -storepasswd` gerektirir ve mevcut imzalı `app-release.aab` ile uyumu etkileyebilir; sizin onayınız olmadan dokunulmadı.
- **Sertifika pinning** — uygulanmadı (orta öncelik, orta-büyük efor).
- **Crash raporlama (Sentry/Crashlytics)** — uygulanmadı; bir DSN/hesap ve yeni bir üçüncü taraf bağımlılık gerektirir, kararınızı bekliyor.
- **Koç paneli gerçek veri entegrasyonu** — sadece uyarı eklendi; gerçek `student_data`/`study_sessions`/sınav sonucu bağlama ayrı bir veri modeli/özellik işi.
- **`lib/l10n/` (boş), erişilebilirlik (`Semantics`), test kapsamı genişletme** — büyük efor gerektiren, uygulama genelinde dağılmış işler; bu oturumda kapsam dışı bırakıldı.
- **Kayıt ekranında "bu e-posta zaten kayıtlı" mesajı (user enumeration)** — bilinçli olarak dokunulmadı; UX'i bozmadan tam gizlemek zor (endüstri genelinde de yaygın bir pratik).
- **`AuthService`'teki offline/mock fallback** — `kalıp.md` Madde 22'de bilinçli bir tasarım kararı olarak belirtilmiş, dokunulmadı.

---

**Denetim tarihi:** 2026-09-27
**Kapsam:** `kontrol.md`'deki 34 bölümün tamamı, gerçek kaynak kodu (`lib/`, `android/`, `ios/`, `supabase_schema.sql`, `pubspec.yaml`) üzerinden.
**Metodoloji notu:** Proje bir git deposu değil (`.git` yok) — commit geçmişinde sızmış secret olup olmadığı doğrulanamadı, yalnızca disk üzerindeki mevcut dosyalar incelendi. `flutter analyze` gerçekten çalıştırıldı: **"No issues found!"**. Doğrulanamayan maddeler ❓ olarak işaretlendi, tahmin yürütülmedi.

---

## ÖNCELİKLİ BULGULAR (Kritik → Yüksek → Orta)

### 🔴 Kritik
1. **Hesap silme çalışmıyor.** Öğrenci tarafında "Hesabımı ve Tüm Verilerimi Sil" butonu yalnızca yerel veriyi (`storage.clear()`, `SecureStorageService.deleteAll()`) siliyor; sunucu tarafındaki gerçek silme fonksiyonu (`SupabaseAuthService.deleteAccount()` → RPC `delete_account`) **hiç çağrılmıyor**. Koç tarafında ise buton tamamen boş: `onTap: () {}`.
   **Kanıt:** `lib/presentation/screens/tabs/profil_sos_tab.dart:33-41`, `lib/presentation/screens/koc/tabs/koc_profil_tab.dart:182-189`, `lib/core/services/supabase_auth_service.dart:152-160`.
   **Etki:** Apple App Store Guideline 5.1.1(v) ve Google Play hesap silme politikası ihlali; KVKK m.11 kapsamında "silindi" izlenimi verip aslında silmemek yasal risk.
   **Düzeltme:** `_hesapSilOnay` içine `await SupabaseAuthService.deleteAccount();` ekle; koç tarafındaki boş `onTap`'i aynı akışa bağla.

### 🟠 Yüksek
2. **`profiles.xp` alanı RLS ile korunmuyor.** `profiles_update_own` politikası yalnızca `role` alanını mevcut değerle kilitliyor, `xp` serbest. `addXp()` client'ta oku-değiştir-yaz yapıyor → herhangi bir kullanıcı doğrudan REST API'ye `PATCH .../profiles?id=eq.<kendi_id>` ile `{"xp": 999999}` gönderip kendi XP'sini keyfi yükseltebilir.
   **Kanıt:** `lib/core/services/supabase_data_service.dart:237-247`, `supabase_schema.sql:71-76`.
   **Düzeltme:** `wallets`/`star_transactions` sisteminde yapıldığı gibi `award_xp()` adlı `SECURITY DEFINER` RPC yazılıp client'ın doğrudan `update({'xp':...})` çağırması engellenmeli; `profiles_update_own` politikasına `xp` için de `WITH CHECK` kilidi eklenmeli.
3. **Supabase oturum token'ları şifrelenmemiş.** `Supabase.initialize()` özel `authOptions/localStorage` almadan çağrılıyor → JWT access/refresh token varsayılan (SharedPreferences tabanlı, şifresiz) depoda tutuluyor. Proje zaten `flutter_secure_storage` tabanlı `SecureStorageService.saveAuthTokens/getAuthTokens` tanımlamış ama **hiç çağrılmıyor** — "false sense of security".
   **Kanıt:** `lib/main.dart:40-44`, `lib/core/storage/storage_service.dart:140-199`.
   **Düzeltme:** `SecureLocalStorage implements LocalStorage` (flutter_secure_storage tabanlı) yazıp `Supabase.initialize(authOptions: FlutterAuthClientOptions(localStorage: SecureLocalStorage()))` ile bağla.
4. **Şifre sıfırlama ("şifremi unuttum") akışı hiç yok.** `resetPasswordForEmail` vb. için grep sonucu boş, UI'da ilgili ekran yok.
   **Düzeltme:** `supabase.auth.resetPasswordForEmail()` + redirect ekranı eklenmeli.
5. **Gizlilik politikasına uygulama içinden erişim yok.** `lib/` genelinde "Gizlilik Politikası"/URL linki sıfır; `url_launcher` paketi bile yok. Mağaza inceleme reddi riski.
   **Düzeltme:** Ayarlar/Profil ekranına gizlilik politikası linki eklenmeli.
6. **`ios/Runner/PrivacyInfo.xcprivacy` yok.** Apple'ın Mayıs 2024'ten beri zorunlu kıldığı Privacy Manifest dosyası eksik.
7. **Koç paneli ekranı tamamen mock veri ile çalışıyor.** `ogrenci_detay_cards.dart` dosyasının başında geliştiricinin kendi itirafı: *"Bu ekran şu an tamamen mock veriyle çalışıyor (gerçek Supabase bağlantısı yok)"*. Üretimde koçlara yanlış/sahte öğrenci verisi gösteriliyor olabilir.
   **Kanıt:** `lib/presentation/screens/koc/widgets/ogrenci_detay_cards.dart:2`.
8. **Network timeout neredeyse hiç yok.** 50+ Supabase çağrısından yalnızca 1 tanesinde `.timeout()` var. Kötü ağda ekranlar süresiz "loading" durumunda kalabilir.
9. **Crash raporlama entegre değil** (Sentry/Crashlytics yok) — üretim hataları hiçbir yere düşmüyor, sadece `debugPrint`.
10. **`lib/l10n/` tamamen boş**, erişilebilirlik (`Semantics`/`semanticLabel`) proje genelinde sıfır, test kapsamı çok zayıf (`test/` sadece 2 dosya: 1 placeholder smoke test + 1 gerçek unit test, `integration_test/` yok).
11. **Release build obfuscation yok** (`--obfuscate --split-debug-info` hiçbir script/CI'da tanımlı değil; zaten CI/CD dosyası da yok).

### 🟡 Orta (özet, detaylar ilgili bölümlerde)
- `key.properties`: `storePassword=lisenet123`, `keyPassword=lisenet123` — zayıf, aynı parola, düz metin.
- `logout()` yalnızca 2 anahtarı temizliyor, senkronize önbelleği (profil/net/plan verisi) temizlemiyor.
- Kayıt (register) hata mesajı "bu e-posta zaten kayıtlı" → user enumeration.
- Minimum şifre uzunluğu client'ta yalnızca 6 karakter.
- `AuthService`'te Supabase client `null` ise (env eksikse) `signIn/signUp` **sahte `success:true`** döndürüyor — yanlış yapılandırılmış release build'de riskli.
- Oturum zaman aşımı / biyometrik kilit yok.
- iOS `Info.plist`'te kullanılmayan Kamera/Galeri/Mikrofon izin açıklamaları (kod tabanında `image_picker`/kayıt paketi yok).
- SM-2/streak mantığı tamamen `DateTime.now()` (cihaz saati) — sunucu zaman doğrulaması yok, manipülasyona açık.
- Kullanılmayan bağımlılıklar: `audioplayers`, `cached_network_image`, `connectivity_plus`.
- CI/CD yok, dev/staging/prod flavor ayrımı yok, proje git deposu bile değil.
- Sertifika pinning yok; Android `FLAG_SECURE` yok (ekran kaydı/recent-apps önizlemesi hassas ekranlarda açık).
- Sessizce yutulan boş `catch (_) {}` blokları (`auth_service.dart:179`, `supabase_auth_service.dart:168,176,187`, `supabase_data_service.dart:244-246`).

---

## BÖLÜM 1: Gizli Bilgi ve Anahtar Yönetimi

| # | Madde | Durum | Kanıt | Risk |
|---|---|---|---|---|
|1| Gömülü API anahtarı/secret | ✅ | `main.dart:35-36` — `String.fromEnvironment('SUPABASE_URL'/'SUPABASE_ANON_KEY')`, hardcoded değer yok | Düşük |
|2| 3. taraf ücretli API proxy | ➖ | OpenAI/Stripe/AWS/SMTP entegrasyonu yok, her şey Supabase üzerinden | — |
|3| `.env`/`EXPO_PUBLIC_` sızıntısı | ✅ | Proje bu pattern'i kullanmıyor (Flutter, `--dart-define` kullanıyor) | — |
|4| `service_role` / Firebase Admin SDK | ✅ | Kodda hiç geçmiyor, sadece `kontrol.md` dokümanında | — |
|5| Google/Firebase key kısıtlaması | ➖ | Firebase kullanılmıyor (`google-services.json` yok) | — |
|6| `.gitignore` kapsamı | ✅ | `key.properties`, `*.jks`, `*.keystore`, `*.aab`, `*.apk`, `mapping.txt`, `/symbols/` var. Eksik: `google-services.json`/`*.p12`/`*.mobileprovision` satırları yok (ama üretilmiyor da) | Düşük |
|7| Git geçmişinde secret | ❓ | Proje git deposu değil, doğrulanamadı | ❓ |
|8| Sızan anahtar rotasyonu | ❓ | Doğrulanamadı | ❓ |
|9| Keystore güvenliği | ❌ | `key.properties` içinde `storePassword=lisenet123`, `keyPassword=lisenet123` — zayıf ve aynı parola | **Orta** |
|10| Yorumlarda test şifresi/iç URL | ✅ | Grep sonuçlarının tamamı UI metni, gömülü kimlik bilgisi yok | — |
|11| Staging/iç sunucu adresi release'de | ✅ | `build.gradle.kts`'te URL tanımı yok | — |

**Düzeltme (madde 9):** `openssl rand -base64 24` ile güçlü/rastgele parola üretilip CI secret'ına taşınmalı.

## BÖLÜM 2: Yerel Veri Depolama

| # | Madde | Durum | Kanıt | Risk |
|---|---|---|---|---|
|1| Token/şifre güvenli depoda mı | ❌ | Supabase JWT varsayılan (şifresiz) SharedPreferences'ta; `SecureStorageService` tanımlı ama kullanılmıyor | **Yüksek** |
|2| Hassas veri düz SharedPreferences'ta mı | ❌ | `user_auth_email` dahil düz metin (`auth_provider.dart:144,191`) | **Yüksek** |
|3| Keychain erişim seviyesi | ➖ | iOS'ta secure storage fiilen kullanılmadığından uygulanamaz | — |
|4| `allowBackup` / dataExtractionRules | ✅ | `AndroidManifest.xml:11` → `allowBackup="false"` | Düşük |
|5| Yerel DB şifreleme (SQLCipher) | ➖ | sqflite/Hive yok, yerel DB yok | — |
|6| Harici depolamaya yazma | ➖ | Tespit edilmedi | — |
|7| Log/cache'de hassas veri | ⚠️ | `debugPrint` çağrılarında token/şifre interpolasyonu görülmedi ama exception mesajları (`$e`) bazı durumlarda PII içerebilir | Orta |
|8| Logout'ta tam temizlik | ⚠️ | `logout()` yalnızca 2 anahtarı siliyor, senkronize önbellek/SecureStorage temizlenmiyor (tam temizlik yalnızca "hesap sil" akışında var) | **Orta** |
|9| Reinstall sonrası Keychain eski token | ❓ | Secure storage kullanılmadığı için bu senaryo geçerli değil (sorun kaynağı farklı: madde 1) | — |
|10| WebView çerez/cache temizliği | ➖ | WebView kullanılmıyor | — |
|11| Bellekte hassas veri süresi | ❓ | Doğrulanamadı | ❓ |

**Düzeltme (madde 8):** `logout()` içine `await _storageService.clear();` + `await SecureStorageService.deleteAll();` eklenmeli.

## BÖLÜM 3: Kriptografi

| # | Madde | Durum | Kanıt |
|---|---|---|---|
|1| Kendi yazılmış şifreleme | ✅ | `encrypt/decrypt/Cipher/AES` grep → 0 sonuç |
|2| AES-ECB / sabit IV | ➖ | Şifreleme kullanılmıyor |
|3| Gömülü şifreleme anahtarı | ➖ | Uygulanamaz |
|4| MD5/SHA1 | ✅ | Kullanım yok, `crypto` paketi bağımlılıkta değil |
|5| Sunucuda parola hash (bcrypt vb.) | ❓ | Supabase Auth'un kendi iç mekanizması, bu repodan doğrulanamaz |
|6| Token/OTP güvenli RNG | ✅ | Tek `Random()` kullanımı `learning_engine.dart:277` — plan sıralamasını karıştırmak için, güvenlikle ilgisiz. OTP Supabase tarafından üretiliyor |
|7| Base64 "şifreleme" gibi kullanım | ✅ | `base64Encode/Decode` grep → 0 sonuç |

## BÖLÜM 4: Kimlik Doğrulama ve Oturum Yönetimi

| # | Madde | Durum | Kanıt | Risk |
|---|---|---|---|---|
|1| Sunucu tarafı doğrulama | ✅ | Supabase Auth SDK (`signInWithPassword`, `signUp`, `verifyOTP`) | — |
|2| OAuth PKCE / implicit | ➖ | OAuth kullanılmıyor (sadece e-posta+OTP) | — |
|3| Client secret kodda | ✅ | Yok, anon key zaten public-safe | Düşük |
|4| OAuth sistem tarayıcısı | ➖ | Uygulanamaz | — |
|5| Access/refresh token yönetimi | ✅ | Tamamen Supabase SDK'ya bırakılmış, custom decode/parse kodu yok | Düşük |
|6| Logout sunucuda oturumu sonlandırıyor mu | ✅ | `_client.auth.signOut()` | Düşük |
|7| Şifre değişikliğinde diğer oturumlar | ❓/❌ | Şifre değiştirme özelliği bulunamadı | Orta |
|8| Oturum zaman aşımı (inaktivite) | ❌ | Hiç yok | Orta |
|9| 401'de tek seferlik token yenileme | ✅ | Supabase SDK otomatik yönetiyor | Düşük |
|10| Biyometrik doğrulama (CryptoObject/SecAccessControl) | ❌ | `local_auth` paketi yok | Düşük-Orta |
|11| Rate limiting / brute-force | ⚠️ | Sunucu tarafı (Supabase) rate limit var, client bunu doğru yakalayıp gösteriyor; ek client-side throttling yok | Düşük |
|12| Hata mesajı kullanıcı varlığını ifşa etmiyor | ⚠️ | Login mesajı jenerik ("e-posta veya şifre hatalı") ✅ ama **register mesajı** "bu e-posta zaten kayıtlı" → user enumeration ❌ | **Orta** |
|13| Şifre sıfırlama token tek kullanımlık/kısa ömürlü | ❌ | Akış hiç yok | **Yüksek** |
|14| OTP süre/deneme sınırı | ✅ | Supabase `verifyOTP` (`OtpType.signup`) ile 6 haneli kod | Düşük |
|15| Güçlü şifre politikası (sunucu) | ⚠️ | Client'ta yalnızca `length < 6` kontrolü; DB seviyesinde bulunamadı | Orta |
|16| 2FA/MFA | ➖ | Yok, opsiyonel madde | — |
|17| JWT `alg:none` / sunucu doğrulama | ✅ | Supabase SDK yönetiyor, custom JWT kod yok | Düşük |
|18| JWT içinde hassas veri | ❓ | Doğrulanamadı (Supabase JWT içeriği bu repodan görünmüyor) | ❓ |

**Ek bulgu (kritik değil ama önemli):** `AuthService` içinde Supabase client `null` ise (`_supabase == null`) `signIn/signUp` **sahte `success:true`** döndürüyor (`auth_service.dart:148-153,164-169`). Yanlış yapılandırılmış/env eksik bir release build'de kullanıcı "giriş yapmış" gibi görünüp aslında doğrulanmamış olabilir. **Düzeltme:** Bu offline-fallback üretimde derleme zamanı bayrağıyla kısıtlanmalı, Supabase null ise net hata gösterilmeli.

## BÖLÜM 5: Yetkilendirme ve Backend Güvenliği

`supabase_schema.sql` içinde **13 tablo**, **13'ünde de RLS etkin** (RLS'siz tablo yok): `profiles, communities, posts, user_tickets, koc_tasks, student_data, curricula, subjects, topics, wallets, star_transactions, coach_students, study_sessions`.

| # | Madde | Durum | Kanıt | Risk |
|---|---|---|---|---|
|1| Tüm yetki kontrolleri sunucuda | ✅ | RLS + admin RPC'ler | Düşük |
|2| IDOR koruması (`auth.uid()`) | ✅ | Tüm politikalarda tutarlı `auth.uid() = user_id` deseni | Düşük |
|3| Firebase kuralları | ➖ | Firebase kullanılmıyor | — |
|4| Supabase RLS tüm tablolarda | ✅ | 13/13 tablo | Düşük |
|5| `USING(true)` gibi güvensiz politika | ⚠️ | `communities_select_all`, `posts_select_all` sadece SELECT için `true` — yazma ayrıca korunuyor, kasıtlı/makul tasarım | Düşük |
|6| Storage bucket politikaları | ➖ | Supabase Storage kullanılmıyor | — |
|7| Kullanıcı kendi rolünü değiştiremiyor | ✅ | `profiles_update_own` RLS'de `role` mevcut değerle kilitli + admin RPC çift katmanlı | Düşük |
|8| Bakiye/puan istemciden hesaplanmıyor | ⚠️ | `wallets`/`star_transactions` **SECURITY DEFINER RPC** ile doğru korunuyor (örnek iyi tasarım) **ANCAK `profiles.xp` korunmuyor** — bkz. Öncelikli Bulgu #2 | **Yüksek (xp için)** |
|9| Sunucuda girdi doğrulaması | ❓ | Kısmen doğrulanabildi (RPC'ler var), her tablo için tam doğrulama yapılmadı | ❓ |
|10| API rate limiting | ❓ | Supabase platform seviyesinde, bu repodan doğrulanamaz | ❓ |
|11| Sunucu hata yanıtlarında stack trace | ❓ | Doğrulanamadı | ❓ |
|12| Dosya yükleme doğrulama | ➖ | Dosya yükleme özelliği yok | — |
|13| Admin endpoint'leri ayrı/korumalı | ✅ | Çift katmanlı: client-side route guard (`admin_screen.dart:36-72`) + RLS admin politikaları | Düşük |
|14| Sunucu güvenlik logları | ❓ | Doğrulanamadı | ❓ |

**Ayrıca olumlu not:** `complete_study_session` RPC süreyi client beyanına değil sunucu saatine (`NOW() - started_at`) göre hesaplıyor — zaman manipülasyonuna karşı iyi tasarım örneği.

## BÖLÜM 6: Ağ Güvenliği

| # | Madde | Durum | Kanıt |
|---|---|---|---|
|1| HTTPS/TLS 1.2+ | ✅ | `http://` literal yok, Supabase varsayılan HTTPS/WSS |
|2| `usesCleartextTraffic=false` + NSC | ✅ | `AndroidManifest.xml:12`; NSC dosyası yok ama minSdk=24 için zorunlu değil |
|3| iOS ATS aktif | ✅ | `Info.plist`'te `NSAppTransportSecurity` hiç yok → varsayılan ATS geçerli |
|4| SSL doğrulama devre dışı kod | ✅ | `badCertificateCallback/TrustManager` grep → 0 |
|5| Sertifika pinning | ❌ | Yok | **Orta** |
|6| Pin süresi dolunca kilitlenmeme planı | ➖ | Pinning yok |
|7| Hassas veri URL query'de | ✅ | Supabase SDK soyutlaması, elle query birleştirme yok |
|8| Debug proxy/Flipper release'de kapalı | ❓ | Doğrulanamadı |
|9| Kullanıcı CA'sına güvenmeme | ❓ | Doğrulanamadı |
|10| WebSocket `wss://` | ➖ | Supabase Realtime kullanılmıyor |

## BÖLÜM 7: Platform Etkileşimi ve Saldırı Yüzeyi

**Deep link:** ✅ Custom scheme/intent-filter yok (`go_router` yalnızca in-app route), saldırı yüzeyi minimal.
**Android bileşenleri:** ⚠️ Kısmen — `MainActivity exported=true` (launcher için zorunlu/normal), `ScheduledNotificationBootReceiver exported=false` (doğru). Başka exported bileşen yok.
**PendingIntent / ContentProvider / FileProvider:** ➖ Kod içinde doğrudan kullanım yok, `flutter_local_notifications` paketine bırakılmış.
**WebView:** ➖ Uygulanamaz — proje WebView kullanmıyor.
**Ekran/pano güvenliği:**
- `FLAG_SECURE` ❌ yok — hassas ekranlarda ekran kaydı/recent-apps önizlemesi engellenmiyor (**Orta**)
- `secureTextEntry`/`obscureText` ✅ login/register şifre alanlarında var
- Panoya kopyalama ➖ kod yok

**İzinler:** Android manifest (`INTERNET`, `ACCESS_NETWORK_STATE`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`) kullanımla tutarlı, **ancak** `ACCESS_NETWORK_STATE`'i kullanması gereken `connectivity_plus` paketi hiç import edilmemiş. iOS `Info.plist`'teki Kamera/Galeri/Mikrofon izin açıklamaları kodda **karşılığı olmayan** (image_picker/camera/record paketi yok) kullanılmayan izinler — ⚠️ **Orta risk, mağaza incelemesinde sorgulanabilir.**

## BÖLÜM 8: Kod Düzeyinde Güvenlik

| # | Madde | Durum | Kanıt |
|---|---|---|---|
|1| SQL parametreli/injection | ➖ | Yerel SQL yok (sqflite kullanılmıyor) |
|2| eval/dinamik kod | ➖ | Dart'ta mekanizma yok |
|3| WebView XSS | ➖ | WebView yok |
|4| Path traversal | ✅ | Dosya sistemi işlemi/kullanıcı girdili path yok |
|5| ReDoS | ✅ | Sadece 3 basit e-posta regex'i, karmaşık backtracking yok |
|6| Format string/integer overflow (native) | ➖ | Native kod yazılmamış |
|7| Client saatine güven | ❌ | SM-2/streak tamamen `DateTime.now()`'a dayalı, sunucu zaman doğrulaması yok | **Orta** |

## BÖLÜM 9: Tersine Mühendislik ve Dayanıklılık

| # | Madde | Durum | Kanıt |
|---|---|---|---|
|1| R8/ProGuard (`minifyEnabled`, `shrinkResources`) | ✅ | `build.gradle.kts` release buildType'ta ikisi de `true` |
|2| ProGuard kuralları eksiksiz | ✅ | `proguard-rules.pro` var, Flutter/Supabase keep kuralları içeriyor |
|3| Flutter `--obfuscate --split-debug-info` | ❌ | Hiçbir script/CI'da yok | **Yüksek** |
|4| `android:debuggable=false` release'de | ✅ | Elle override yok, Flutter/AGP varsayılanı geçerli |
|5| Release'de log/print hassas veri yazmıyor | ❌ | 18 `debugPrint` çağrısı, hiçbiri `kDebugMode` ile sarılmamış (içerik incelemesinde PII/token görülmedi ama koruma yok) | Düşük-Orta |
|6| Root/jailbreak tespiti | ❌ | Yok (opsiyonel, düşük öncelik) | Düşük |
|7| Debugger/Frida tespiti | ❌ | Yok | Düşük |
|8| Uygulama bütünlüğü/imza doğrulama | ❓ | Doğrulanamadı |
|9| Play Integrity / App Attest | ❌ | Yok |
|10| Güvenlik kararları sunucuda da | ✅ | RLS (Bölüm 5) sunucu tarafı garantiyi sağlıyor |

## BÖLÜM 10: Ödeme ve Uygulama İçi Satın Alma
➖ **Tamamen uygulanamaz** — `pubspec.yaml`'de IAP paketi (`in_app_purchase`, `revenuecat` vb.) yok, uygulamada ödeme özelliği bulunmuyor.

## BÖLÜM 11: Bağımlılıklar ve Tedarik Zinciri

| # | Madde | Durum | Kanıt |
|---|---|---|---|
|1| Paketler gerçek/resmi kaynaktan | ✅ | Tüm 16 dependency tanınmış, meşru pub.dev paketleri |
|2| `npm audit`/`pub outdated` vb. çalıştırıldı | ❓ | Bu denetimde çalıştırılmadı |
|3| Bilinen açık içeren sürüm | ❓ | Doğrulanamadı |
|4| Deprecated paket/API | ✅ | `http` gibi eski paket kullanılmıyor, sürümler güncel |
|5| Lock dosyası commit edilmiş | ⚠️ | `pubspec.lock` diskte var ama proje git deposu olmadığından "commit" doğrulanamadı |
|6| Kullanılmayan bağımlılık | ❌ | **`audioplayers`, `cached_network_image`, `connectivity_plus`** hiç import edilmemiş | Düşük |
|7| Lisans uygunluğu (GPL) | ✅ | Tüm paketler MIT/BSD (Flutter ekosistemi standardı) | — |

## BÖLÜM 12: Gizlilik ve Yasal Uyumluluk

| # | Madde | Durum | Kanıt | Risk |
|---|---|---|---|---|
|1| KVKK/GDPR aydınlatma metni | ✅ | `PRIVACY_POLICY.md`/`privacy_policy.html` kapsamlı, toplanan veriler listelenmiş | — |
|2| Gizlilik politikası **uygulama içinden erişilebilir** | ❌ | `lib/` içinde sıfır referans/link | **Yüksek** |
|3| Veri minimizasyonu | ✅ | Genel olarak makul (profiles tablosunda e-posta yok) | — |
|4| Veri görüntüleme/dışa aktarma/silme hakkı | ⚠️ | Silme hakkı belgede var ama **dışa aktarma/taşınabilirlik hakkı metinde yok** ve silme fiilen çalışmıyor (bkz. Kritik #1) | Orta |
|5| Analitik/crash için onay | ➖ | Analitik/crash SDK'sı yok | — |
|6| Loglarda kişisel veri | ⚠️ | Doğrudan PII interpolasyonu görülmedi ama exception mesajları risk taşıyabilir | Orta |
|7| Veri saklama süreleri | ❓ | Doğrulanamadı | ❓ |

## BÖLÜM 13: Mağaza Gereksinimleri

| # | Madde | Durum | Kanıt |
|---|---|---|---|
|1| Hesap silme (Apple/Google zorunlu) | ❌ | Bkz. Kritik Bulgu #1 | **Kritik** |
|2| Sign in with Apple | ➖ | 3. taraf sosyal giriş yok |
|3| iOS Privacy Manifest (`PrivacyInfo.xcprivacy`) | ❌ | Dosya yok | **Yüksek** |
|4| Play Veri Güvenliği formu / Apple gizlilik etiketleri | ❓ | Store Connect/Play Console dışı, doğrulanamadı |
|5| ATT izni | ➖ | Takip yapılmıyor |
|6| `Info.plist` `NS...UsageDescription` | ⚠️ | Mevcut ve anlamlı **ama** kamera/galeri/mikrofon için karşılık gelen kod yok (kullanılmayan izin) | Orta |
|7| `targetSdkVersion` güncel | ✅ | `compileSdk=37, targetSdk=37, minSdk=24` |
|8| Foreground service beyanı | ➖ | Foreground service kullanılmıyor |
|9| Demo hesap bilgisi | ❓ | Doğrulanamadı |

## BÖLÜM 14: Mimari ve Kod Kalitesi

- Katman ayrımı (UI/iş mantığı/veri/state): ✅ `core/data/presentation` net ayrılmış.
- En büyük dosyalar: ⚠️ `gunluk_plan_tab.dart` (502), `ogrenci_detay_cards.dart` (457), `test_coz_screen.dart` (428), `onboarding_screen.dart` (427), `pomodoro_dialog.dart` (401) — 400+ satır widget'lar bölünmeli.
- Tutarlı isimlendirme: ✅ snake_case dosyalar, tutarlı Riverpod konvansiyonu.
- Yarım bırakılmış kod: ✅ yok.
- `as!`/force-unwrap: ✅ `as!` 0, `!` düşük yoğunlukta (~13).
- Lint kapatma: ✅ `analysis_options.yaml` temiz, sadece 1 noktasal `// ignore: deprecated_member_use`.
- Boş `catch` blokları: ⚠️ Var (`auth_service.dart:179`, `supabase_auth_service.dart:168,176,187`, `supabase_data_service.dart:244-246`) — **Orta risk**, log eklenmeli.
- Mock veri: ❌ Koç detay ekranı itiraflı mock veri (bkz. Yüksek Bulgu #7) — **Yüksek**.
- Ölü kod: ⚠️ `flutter analyze` temiz ama 3 kullanılmayan paket (Bölüm 11).
- Sihirli sayılar: ⚠️ `app_constants.dart` iyi merkezi ama `learning_engine.dart` içinde inline katsayılar (`0.6 + enerji*0.08` vb.) — adlandırılmış sabitlere taşınmalı.
- Tip güvenliği: ⚠️ `dueSayilariDersBazinda` fonksiyonunda `dynamic` kullanımı (code smell, düşük risk).

## BÖLÜM 15: Bellek, Yaşam Döngüsü ve Eşzamanlılık

- Timer/StreamSubscription/AnimationController dispose: ✅ İncelenen tüm örneklerde eksiksiz.
- StatefulWidget dispose oranı: ⚠️ 21 State sınıfından 14'ünde dispose (7'sinde gerçek eksiklik yok, ama `admin_tickets_tab.dart:51`'de yerel `TextEditingController` hiç dispose edilmiyor).
- `if (mounted)` kontrolü: ✅ 39 kullanım, async-sonrası setState güvenli.
- Ekrandan çıkışta istek iptali: ➖ Supabase SDK'nın doğası gereği uygulanamaz.
- Riverpod `autoDispose`: ❌ Hiç kullanılmıyor — ekran-özel state'ler (`TestFiltreState`, `AktifTestState`) kalıcı kalıyor. **Düşük-Orta.**

## BÖLÜM 16: Hata Yönetimi ve Ağ Dayanıklılığı

- Loading/empty/error/success ayrımı: ⚠️ Sadece 3 provider `AsyncValue` kullanıyor, geri kalanı standart olmayan ad-hoc `bool _isLoading` paterni.
- Ham teknik hata gösterimi: ❌ `supabase_auth_service.dart:207` ve `create_post_screen.dart:73` kullanıcıya `e.toString()` gösteriyor — **Orta**.
- Global hata yakalayıcı: ✅ `main.dart:18-24` `FlutterError.onError` + `PlatformDispatcher.instance.onError` var (bilinçli tasarım, "kalıp.md" referanslı) ama hiçbir crash servisine göndermiyor.
- Timeout: ❌ 50+ Supabase çağrısından sadece 1'inde var — **Yüksek**.
- Retry/exponential backoff: ❌ Yok.
- Çift tıklama engelleme: ⚠️ Sadece auth ekranlarında (`login/register/email_verification`) doğrulandı, diğer formlarda (post/ticket/deneme ekle) tutarlılık teyit edilmedi.

## BÖLÜM 17: Çökmeler ve Donmalar

- Crash raporlama (Crashlytics/Sentry): ❌ Yok — **Yüksek**.
- Symbol/mapping dosyaları: ⚠️ `mapping.txt` (9.4MB) ve `symbols/` kökte duruyor, `.gitignore`'da listeli ama proje git deposu olmadığı için pratik etkisi teyit edilemedi.
- ANR riski / ana thread bloklama: ✅ Ağır JSON parse yok, veri setleri derleme-zamanı sabit; `compute()`/`Isolate` ihtiyacı düşük.
- Gerçek cihazda release test: ❓ Doğrulanamadı.

## BÖLÜM 18: Performans

- `ListView.builder`: ✅ 5 kullanım; 2 yerde `ListView(children:...)` ama küçük/sabit listeler, sorunsuz.
- Liste `key` kullanımı: ❌ Proje genelinde sadece 2 `ValueKey`/`Key(` kullanımı — dinamik listelerde (net kayıtları, flashkart) key eksik.
- `const` kullanımı: ✅ 874 kullanım, yaygın.
- `cached_network_image` kullanımı: ❌ Paket var ama hiç kullanılmıyor (bkz. Bölüm 11).
- Açılış süresi optimizasyonu: ❓ Doğrulanamadı.
- Uygulama boyutu optimizasyonu: ❓ Doğrulanamadı (App Bundle kullanılıyor — `app-release.aab` mevcut).

## BÖLÜM 19: Pil ve Kaynak Kullanımı

- Sürekli yüksek hassasiyetli konum: ➖ Konum özelliği yok.
- Polling yerine event-driven: ✅ `Timer.periodic` sadece UI sayaçlarında (pomodoro/test süresi/nefes egzersizi); auth durumu `onAuthStateChange` stream'i ile event-driven.
- Arka plan işleri (WorkManager/BGTaskScheduler): ➖ Kullanılmıyor (zamanlanmış bildirimler OS seviyesinde `flutter_local_notifications` ile).
- Wake lock: ➖ Kullanılmıyor.

## BÖLÜM 20: Arayüz ve Duyarlı Tasarım

- `SafeArea`: ⚠️ Sadece 13 dosyada; ana shell ve admin/koç ekranlarının çoğunda yok.
- Karanlık mod: ✅ Gerçek 3-modlu (light/dark/system) destek var (`settings_provider.dart`, `ayarlar_screen.dart`) ancak 97 yerde/35 dosyada hardcoded `Colors.black/white` kullanımı kontrast sorununa yol açabilir — **Orta**.
- Geri tuşu/`PopScope`: ⚠️ Sadece 3 ekranda; form ekranlarında (post/ticket oluşturma) veri kaybı koruması yok.
- Tablet/responsive destek: ⚠️ `LayoutBuilder` hiç kullanılmıyor, `MediaQuery` minimal.

## BÖLÜM 21: Erişilebilirlik
❌ **Proje genelinde `Semantics`/`semanticLabel` sıfır kullanım.** Ekran okuyucu (VoiceOver/TalkBack) desteği yok — **Orta risk.** Dokunma alanı boyutu statik olarak doğrulanamadı (`IconButton` varsayılan 48x48 kullanıyor, override edilen yerler teyit edilmedi).

## BÖLÜM 22: Yerelleştirme
❌ **`lib/l10n/` tamamen boş**, `flutter_localizations`/gen-l10n altyapısı yok, tüm metinler hardcoded Türkçe. Ek bulgu: `koc_ogrencilerim_tab.dart:77-78` öğrenci arama filtresi `toLowerCase()` kullanıyor — Türkçe "İ/ı" karakterleri locale-aware olmadığından "Işık" gibi isimler arama sonucunda kaçabilir (**Orta**). `intl` paketi bağımlılıkta var ama `DateFormat` hiç kullanılmıyor — tarihler manuel string işlemeyle yönetiliyor.

## BÖLÜM 23: Formlar ve Kullanıcı Girdisi

- `keyboardType`: ⚠️ Sadece 6 yerde/4 dosyada tanımlı.
- Form `validator`: ⚠️ Sadece auth ve post/ticket ekranlarında; `deneme_ekle_dialog.dart`/`profil_duzenle_dialog.dart`'ta teyit edilemedi.
- `obscureText`: ✅ Şifre alanlarında var.
- `.trim()`: ✅ 34 kullanım, girdi temizliği yaygın.
- Çift tıklama koruması: ✅ Auth ekranlarında `_isLoading` paterni var.

## BÖLÜM 24: Veri, Senkronizasyon ve Önbellek

- Yerel DB migration: ➖ Yerel DB yok; `SyncedStorageService.migrateLegacyLocalData()` ile eski anahtar taşıma mantığı var (✅ iyi tasarım).
- Kullanıcı değişiminde önbellek karışması: ✅ Tüm anahtarlar `sd_<userId>_*` namespace'i ile ayrılmış — iyi tasarım.
- Tarihler UTC mi: ❌ `sm2.dart` ve streak mantığı tamamen client `DateTime.now()` — sunucu zaman doğrulaması yok (bkz. Bölüm 8 madde 7).

## BÖLÜM 25: Bildirimler

- `POST_NOTIFICATIONS` izni: ✅ Manifest'te var.
- Bildirime tıklayınca doğru ekran: ❌ `onDidReceiveNotificationResponse`/`payload` hiç kullanılmıyor — bildirime dokununca özel yönlendirme yok.
- Bildirim kanalları: ⚠️ İnline tanımlı (`'daily_reminder'`), `NotificationChannels` sabiti ile senkronizasyonu teyit edilmedi.

## BÖLÜM 26-29: Medya/Kamera, Konum/Sensör, İzin Akışları, Arka Plan İşleri
➖ **Tamamen uygulanamaz** — `image_picker`, `geolocator`, `permission_handler`, `workmanager` paketlerinin hiçbiri kullanılmıyor. (Not: iOS Info.plist'te buna rağmen kamera/galeri/mikrofon izin açıklamaları var — bkz. Bölüm 7/13.)

## BÖLÜM 30: Test
❌ **Yetersiz.** `test/` klasöründe yalnızca 2 dosya: `widget_test.dart` (gerçek içerik yok, `expect(1+1, equals(2))` placeholder) ve `learning_engine_and_sm2_test.dart` (SM-2/plan algoritması için gerçek, iyi kaliteli unit test). `integration_test/` yok. — **Yüksek risk**, kritik akışlar (auth, RLS senaryoları, checkout benzeri XP/star işlemleri) test edilmiyor.

## BÖLÜM 31: Build, Yapılandırma ve Dağıtım

- Dev/staging/prod flavor ayrımı: ❌ Yok, tek `applicationId`/config.
- CI/CD: ❌ Yok (`.github/workflows`, Codemagic, Bitrise vb. bulunamadı).
- `version`/`versionCode` tutarlılığı: ✅ `pubspec.yaml: 1.1.0+16`, Gradle/Info.plist otomatik senkronize.
- Zorunlu güncelleme mekanizması: ❓ Doğrulanamadı.

## BÖLÜM 32: İzleme, Loglama ve Analitik
✅ Ham `print()` hiç kullanılmıyor, sadece `debugPrint` (18 kez); incelenen örneklerde token/şifre/PII doğrudan loglanmıyor. ❌ Ancak `kDebugMode` ile sarmalama yok (Bölüm 9 madde 5) ve performans/backend anormallik izleme entegrasyonu yok.

## BÖLÜM 33: Yapay Zeka Tarafından Üretilen Koda Özgü Kontroller
✅ `learning_engine.dart`/`sm2.dart` deprecated API kullanmıyor, SM-2 formülü doğru uygulanmış, sınır kontrolleri var. ⚠️ `dueSayilariDersBazinda`'da `dynamic` tip kullanımı code smell. ✅ Paket/SDK sürümleri güncel ve tutarlı (`sdk: ^3.11.3`). ❌ Backend unutulmamış genel olarak (RLS var) **ama `xp` alanı istisna** (Bölüm 5 madde 8). ⚠️ "Bu ekran mock veriyle çalışıyor" itirafı kodun içinde bırakılmış — geçici/deneysel kod üretime sızmış.

## BÖLÜM 34: Framework'e Özgü Hızlı Kontroller (Flutter)

- `--obfuscate --split-debug-info`: ❌ Yok.
- `kDebugMode`/`kReleaseMode` kontrolü: ❌ Proje genelinde hiç kullanılmıyor.
- `HttpClient.badCertificateCallback` release'de: ✅ Yok (temiz).
- `dispose()` genel kullanımı: ⚠️ 43 State sınıfının ~29'unda yok (çoğu gerçek eksiklik değil, 1 somut örnek `admin_tickets_tab.dart` içinde controller sızıntısı).

## BÖLÜM 35: Önerilen Araçlar
Bu denetimde MobSF, gitleaks/trufflehog, Snyk/Dependabot, Burp/mitmproxy, Frida/objection, LeakCanary gibi harici araçlar **çalıştırılmadı** (statik kod incelemesiyle sınırlı). Proje bir git deposuna alınıp gitleaks/trufflehog ile geçmiş taraması, ayrıca MobSF ile derlenmiş APK/AAB üzerinde dinamik analiz yapılması önerilir.

---

## Sonuç

Kod tabanı mimari olarak disiplinli (`flutter analyze` temiz, katmanlı yapı, RLS kapsamı geniş, dispose/mounted kontrolleri genelde doğru), ancak üretime çıkmadan önce şu üç alan mutlaka kapatılmalı: **(1) hesap silme özelliğinin gerçekten çalışması** (mağaza reddi + KVKK riski), **(2) `xp` alanının RLS ile korunması** ve **(3) oturum token'larının gerçek secure storage'a taşınması**. Ardından gizlilik politikası linki, Privacy Manifest, şifre sıfırlama akışı, network timeout ve crash raporlama gibi mağaza uyumluluğu/dayanıklılık eksikleri giderilmelidir.
