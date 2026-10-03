# DersNet (LiseNET) — A'dan Z'ye Denetim Raporu

Tarih: 3 Ekim 2026 · Kapsam: `lib/` (37.036 satır Dart), `android/`, `ios/Runner`, `supabase_schema.sql` + `supabase_migrations/13–18`, `supabase/functions/koc-asistan`, `test/`, derleme betikleri.

**Yöntem ve sınırlar.** Kaynak kod ve SQL dosyaları okundu; `flutter analyze` (0 sorun), `flutter test` (78/78 geçti) ve `flutter pub outdated` çalıştırıldı. Canlı Supabase projesi, Play Console / App Store Connect ayarları, gerçek cihaz davranışı ve derlenmiş `.aab` içeriği **incelenmedi**; bunlara bağlı maddeler "❓ Doğrulanamadı" olarak işaretlendi. SQL dosyalarının canlıya uygulandığı varsayımı kod dışı bir bilgidir (proje notlarına göre şema 1–18 kurulu), bu raporda dosyadaki hâli değerlendirildi. Hukuki maddeler hukuki görüş değildir.

## Düzeltme durumu (3 Ekim 2026, denetim sonrası)

Aşağıdaki tablolar denetim anındaki durumu gösterir. Sonrasında yapılanlar:

| Bulgu | Yapılan | Kalan |
|---|---|---|
| B3 çalışma oturumu hilesi | `supabase_migrations/19` içinde `trg_study_sessions_before_insert` | Migration canlıda çalıştırılmalı |
| B4 çok cihazda veri kaybı | `synced_storage_service.dart` zaman damgalı çakışma kuralı + gönderilemeyen yazmaların yeniden denenmesi; ön plana dönüşte eşitleme; 8 yeni test | Migration 19 (sunucu `updated_at`) |
| B5 görünmeyen hatalar | `hata_bildirim_service.dart` + `hata_bildir` RPC (kendi sunucuna, 30 gün); gizlilik politikası güncellendi | Migration 19 |
| B6 denetimsiz metinler | Ad/etiket kısaltma ve kelime filtresi, talep sınırı (migration 19); formlarda `maxLength` | Migration 19 |
| Zorunlu güncelleme | `surum_kontrol.dart` + `app_config` tablosu | Migration 19 |
| Sistem yazı boyutu | `main.dart` sistem ölçeğiyle çarpıyor (0.8–1.6) | Büyük yazıda ekranlar cihazda gözden geçirilmeli |
| Şifre değişikliği | Tüm cihazlardan çıkış | — |
| Açık rıza | Kayıt ekranında ayrı onay kutusu | Veri sorumlusu kimliği politikaya eklenmeli (B2) |
| Diğer | Network Security Config, şifre alanlarında öneri kapalı, etüt yoklaması arka planda duruyor, ham sunucu hataları gizlendi, ölü ProGuard kuralları silindi, `.gitignore` genişletildi | — |
| Edge Function API parametreleri | Güncel Claude API ile doğrulandı, değişiklik gerekmedi | Deploy |
| B1 sürüm kontrolü ve keystore | — | Kullanıcı işlemi |

Durum işaretleri: ✅ Geçti · ❌ Kaldı · ⚠️ Kısmen · ➖ Uygulanamaz · ❓ Kodda doğrulanamadı

---

## Öncelikli bulgular (Kritik ve Yüksek)

Kritik seviyede bulgu çıkmadı: istemcide gizli anahtar yok, tüm tablolarda RLS açık, rol/XP/yıldız/fiyat sunucuda kilitli, ücretli yapay zeka çağrısı Edge Function arkasında ve kotalı.

| # | Bulgu | Risk | Kanıt |
|---|---|---|---|
| B1 | Proje sürüm kontrolünde değil; tek kopya OneDrive klasöründe. İmza anahtarı (`upload-keystore.jks`) ve parolaları düz metin olarak aynı klasörde ve bulutla eşitleniyor. | Yüksek | `.git` yok; `android/app/upload-keystore.jks`, `key.properties`, `android/key.properties` |
| B2 | Aydınlatma metninde veri sorumlusunun kimliği yok; yurt dışı aktarım açık rızası, politika onayı ve veli beyanı tek onay kutusunda birleştirilmiş. Kullanıcı kitlesi 14–18 yaş. | Yüksek (hukuki) | `assets/legal/privacy_policy.md`, `register_screen.dart:185-210` |
| B3 | `study_sessions` tablosuna istemci keyfi `started_at / ended_at / actual_minutes` ile satır ekleyebiliyor: yıldız kazanımı ve topluluk/etüt sıralaması manipüle edilebilir; koç sahte veri görür. | Orta–Yüksek | `supabase_schema.sql:716` (yalnızca `auth.uid() = user_id`), `:939`, `:2015`, `:2103` |
| B4 | Çok cihazlı kullanımda veri kaybı: yerel kopya varsa buluttan hiç güncellenmiyor, sonraki yazma buluttaki yeni veriyi eziyor. | Orta–Yüksek | `synced_storage_service.dart:85-91`, `:210-225` |
| B5 | Crash raporlama yok ve global hata yakalayıcı release'de hataları sessizce yutuyor; sahadaki hatalar görünmez. | Orta–Yüksek | `main.dart:23-31`, `pubspec.yaml` |
| B6 | Diğer reşit olmayan kullanıcılara görünen ad (`profiles.name`) ve oturum etiketi (`study_sessions.label`) için uzunluk sınırı ve kelime filtresi yok; destek talepleri sınırsız uzunlukta ve hız sınırı olmadan eklenebiliyor. | Orta | `supabase_schema.sql:1282-1283`, `:700`, `:54-55`, `:120` |

Düzeltme örnekleri raporun sonundaki "Düzeltme kodları" bölümünde.

---

## 1. Gizli Bilgi ve Anahtar Yönetimi

| Madde | Durum | Kanıt | Risk | Düzeltme |
|---|---|---|---|---|
| İstemcide gömülü API anahtarı/secret yok | ✅ | `lib/` içinde `https://` veya anahtar deseni yok; `main.dart:46-47` yalnızca `String.fromEnvironment` | — | — |
| Ücretli API çağrıları backend üzerinden | ✅ | `supabase/functions/koc-asistan/index.ts:21` anahtar sunucu ortam değişkeninde; istemci `functions.invoke` (`supabase_data_service.dart:817`) | — | — |
| `--dart-define` değerlerinin gizli olmadığı biliniyor | ✅ | Yalnızca `SUPABASE_URL` ve `SUPABASE_ANON_KEY` (`dart_defines.json`, `build_release.ps1:60-61`); ikisi de herkese açık değerler | — | — |
| `service_role` / Admin SDK uygulamada yok | ✅ | `lib/` ve `android/` taraması; Edge Function da anon anahtar + kullanıcı JWT'si kullanıyor (`index.ts:91`) | — | — |
| Google/Firebase anahtarları kısıtlı | ➖ | Firebase/Google API kullanılmıyor (`pubspec.yaml`) | — | — |
| iOS API anahtarları bundle ID ile kısıtlı | ➖ | Aynı gerekçe | — | — |
| `.gitignore` kapsamı | ⚠️ | `.gitignore:44-49` `key.properties`, `*.jks`, `*.keystore`, `dart_defines.json` var; `.env`, `*.p12`, `*.mobileprovision`, `google-services.json` yok (şu an bu dosyalar projede de yok) | Düşük | Eksik desenleri ekle |
| Git geçmişinde secret yok | ➖ | Proje git deposu değil (`.git` yok) → bkz. B1 | Yüksek | Depo oluştur, ilk commit'ten önce `gitleaks detect` çalıştır |
| Sızmış anahtarlar döndürüldü | ❓ | Kodla doğrulanamaz; anon anahtar ve keystore parolası OneDrive'da | Orta | Supabase panelinde anahtar geçmişini kontrol et |
| Keystore yedekli/şifreli; Play App Signing | ❌ / ❓ | Keystore ve parolaları aynı klasörde düz metin (`key.properties` iki kopya); Play App Signing durumu Play Console'da | Yüksek | Parolaları parola yöneticisine taşı, kök dizindeki `key.properties` kopyasını sil, keystore'u şifreli çevrimdışı yedekle |
| Yorumlarda kimlik bilgisi yok | ✅ | `lib/`, `android/`, `supabase/` taraması | — | — |
| Staging/iç adres release'de yok | ✅ | Tek URL derleme zamanında enjekte ediliyor; `lib/` içinde sabit URL yok | — | — |

## 2. Yerel Veri Depolama

| Madde | Durum | Kanıt | Risk | Düzeltme |
|---|---|---|---|---|
| Token güvenli depolamada | ✅ | `main.dart:57-59` → `SecureSupabaseLocalStorage` (`storage_service.dart:207-234`) | — | — |
| Hassas veri düz depoda tutulmuyor | ⚠️ | Token güvenli; ancak ad/e-posta `lisenet_cached_auth_user` (`supabase_auth_service.dart:201-205`) ve check-in (enerji/odak/stres) verisi SharedPreferences'ta (`sd_<uid>_*`) | Düşük | `cacheAuthUser` kullanılmıyorsa kaldır |
| Keychain erişim seviyesi | ✅ | `storage_service.dart:144-146` `first_unlock_this_device` | — | — |
| `allowBackup="false"` | ✅ | `AndroidManifest.xml:11` | — | — |
| Hassas yerel DB şifreli | ➖ | Yerel SQLite yok | — | — |
| Harici depolamaya yazılmıyor | ✅ | Yalnızca `getApplicationDocumentsDirectory` (`ortam_provider.dart:200, 243`) | — | — |
| Önbellek/log/geçici dosyada hassas veri | ✅ | Tüm `debugPrint` çağrıları `kDebugMode` koşullu; dosya logu yok | — | — |
| Logout'ta temizlik | ✅ | `auth_provider.dart:279-297` (sunucu signOut, kullanıcı anahtarları, güvenli depo, özel fotoğraf) | — | — |
| iOS yeniden kurulumda eski token | ✅ | `main.dart:88-100` | — | — |
| WebView çerezleri | ➖ | WebView yok | — | — |
| Hassas veri bellekte uzun tutulmuyor | ✅ | Şifre yalnızca `TextEditingController`'da, ekranla birlikte `dispose` | — | — |

## 3. Kriptografi

| Madde | Durum | Kanıt | Risk | Düzeltme |
|---|---|---|---|---|
| Kendi yazılmış şifreleme yok | ✅ | `lib/` taraması; kripto kodu yok | — | — |
| AES-ECB yok | ➖ | Uygulama şifreleme yapmıyor | — | — |
| Sabit IV/nonce yok | ➖ | Aynı | — | — |
| Anahtar koda gömülü değil | ➖ | Aynı; `flutter_secure_storage` platform anahtarını yönetiyor | — | — |
| MD5/SHA1 güvenlik amaçlı kullanılmıyor | ✅ | Eski `md5` tabanlı davet kodu (`schema:610`) §15'te `gen_random_bytes` ile değiştirilmiş (`:1624`) | — | — |
| Şifre hash'leme bcrypt/Argon2 | ✅ | Supabase Auth (GoTrue) bcrypt kullanır; uygulama şifre saklamıyor | — | — |
| Güvenli rastgele üreteç | ✅ | Davet kodu `extensions.gen_random_bytes(5)`; Dart `Random()` yalnızca oyun/animasyon için (`mini_oyunlar_screen.dart:156` vb.) | — | — |
| Base64 "şifreleme" yok | ✅ | Tarama | — | — |

## 4. Kimlik Doğrulama ve Oturum Yönetimi

| Madde | Durum | Kanıt | Risk | Düzeltme |
|---|---|---|---|---|
| Kimlik doğrulama sunucuda | ✅ | Release'de yerel bayrak akışı kapalı (`auth_provider.dart:114-117`, `auth_service.dart:38`) | — | — |
| OAuth PKCE | ➖ | OAuth/sosyal giriş yok | — | — |
| Client secret yok | ✅ | Tarama | — | — |
| OAuth sistem tarayıcısı | ➖ | OAuth yok | — | — |
| Kısa ömürlü access token, refresh rotasyonu | ❓ | supabase_flutter otomatik yeniliyor; süre ve rotasyon Supabase panel ayarı | Orta | Auth › Sessions: JWT 1 saat, "Refresh token rotation" açık |
| Refresh token yeniden kullanım tespiti | ❓ | Panel ayarı ("Reuse interval") | Orta | Panelde doğrula |
| Sunucuda token iptali | ✅ | `auth.signOut()` (`supabase_auth_service.dart:194`) | — | — |
| Logout sunucuda da | ✅ | Aynı | — | — |
| Şifre değişikliğinde diğer oturumlar | ⚠️ | Şifre yenilemeden sonra yalnızca o cihazda `signOut()` (`auth_service.dart:228`), varsayılan kapsam o oturum | Orta | `signOut(scope: SignOutScope.global)` |
| Hareketsizlik zaman aşımı | ➖ | Finans/sağlık uygulaması değil | Düşük | — |
| 401'de tekil yenileme | ✅ | supabase_flutter/gotrue yerleşik | — | — |
| Biyometri kripto anahtarına bağlı | ➖ | Biyometri yok | — | — |
| Biyometri değişince anahtar geçersiz | ➖ | Aynı | — | — |
| Rate limiting / brute-force | ⚠️ | İstemci kilidi yalnızca bellekte ve atlanabilir (`login_screen.dart:23-24, 59-62`); gerçek koruma Supabase Auth sınırları (panel) | Orta | Panelde Auth rate limit ve CAPTCHA'yı doğrula |
| Hata mesajı kullanıcı varlığını ifşa etmiyor | ⚠️ | Giriş ve şifre sıfırlama ifşa etmiyor (`auth_service.dart:197-201`); kayıt "zaten hesap mevcut" diyor (`supabase_auth_service.dart:129, 228`) ve giriş "doğrulanmamış" diyor (`:232`) | Düşük | Kayıtta nötr mesaj |
| Sıfırlama token'ı tek kullanımlık/kısa ömürlü | ✅ / ❓ | OTP `verifyOTP(type: recovery)` tek kullanımlık (`auth_service.dart:223`); süre panel ayarı | Düşük | OTP süresini ≤ 1 saat yap |
| OTP süresi ve deneme sınırı | ❓ | Panel ayarı | Orta | Panelde doğrula |
| Güçlü şifre politikası sunucuda | ❓ | İstemcide yalnızca ≥ 8 karakter (`supabase_auth_service.dart:43-47`); sunucu politikası panelde | Orta | Auth › Password: min 8 + harf/rakam, sızdırılmış şifre kontrolü |
| 2FA/MFA | ➖ | Hassas uygulama sınıfında değil; admin hesabı için önerilir | Düşük | Admin hesabında MFA |
| JWT imzası sunucuda doğrulanıyor | ✅ | PostgREST + Edge Function `auth.getUser()` (`index.ts:94`) | — | — |
| JWT içinde hassas veri yok | ✅ | Kayıt metadata'sı: ad, sınıf, alan (`supabase_auth_service.dart:115-119`) | — | — |

Ek: E-posta doğrulaması kapatılırsa (proje notlarındaki "doğrulamasız kayıt" hedefi) başkasının adresiyle hesap açılabilir. Risk: Orta. Kapatılacaksa en azından CAPTCHA ve kayıt hız sınırı açılmalı.

## 5. Yetkilendirme ve Backend Güvenliği

| Madde | Durum | Kanıt | Risk | Düzeltme |
|---|---|---|---|---|
| Yetki kontrolleri sunucuda | ✅ | Admin işlemleri `is_admin()` politikalarıyla (`schema:1242-1271`); istemci kontrolü (`admin_screen.dart:36-72`) ikinci katman | — | — |
| IDOR | ✅ | Tüm kullanıcı tabloları `auth.uid()` ile sınırlı; koç erişimi aktif ilişkiye bağlı (`:668-678`, `:1057-1070`) | — | — |
| Firebase `if true` | ➖ | Firebase yok | — | — |
| Firebase kural doğrulaması | ➖ | Aynı | — | — |
| Tüm tablolarda RLS + politika | ✅ | 27 tablonun 27'sinde `ENABLE ROW LEVEL SECURITY`; `USING (true)` yalnızca herkese açık katalog (`communities`, `etut_odalari`), eski `posts_select_all` ve `community_members_select_all` §15'te kaldırılmış (`:1455`, `:1360`) | — | — |
| Storage bucket politikaları | ➖ | Storage kullanılmıyor; dış görsel sunucuda sıfırlanıyor (`:1437`) | — | — |
| Kullanıcı kendi rolünü değiştiremiyor | ✅ | INSERT `role='student' AND xp=0` (`:1276-1277`); UPDATE'te `role/xp/id` tetikleyiciyle kilitli (`:1287-1302`) | — | — |
| Fiyat/bakiye sunucuda | ✅ | `buy_garden_item` fiyatı katalogdan okuyor, idempotent (`:1106`); `wallets` yazma politikası yok; `award_xp/spend_stars` istemciye kapalı (`:1706-1722`) | — | — |
| Sunucuda girdi doğrulaması | ⚠️ | Gönderi, deneme, davet doğrulanıyor; **`study_sessions` INSERT (B3)**, `profiles.name`, `user_tickets.subject/description`, `study_sessions.label` doğrulanmıyor (B6) | Orta–Yüksek | Bkz. Düzeltme 1 ve 2 |
| API rate limiting | ⚠️ | Gönderi 5/saat (`:1166`), dürtme, davet 10/saat, asistan 20/gün (`:1829`); talep ve `student_data` yazmaları sınırsız (boyut < 512 KB/anahtar `:1690`, anahtar sayısı sınırsız) | Orta | Bkz. Düzeltme 2 |
| Hata yanıtlarında iç bilgi yok | ⚠️ | Edge Function yalnızca kod döndürüyor (`index.ts:138-150`); `etut_odasi_service.dart:105` ve `supabase_data_service.dart:546` ham Postgres mesajını kullanıcıya gösteriyor | Düşük | Bilinmeyen hatalarda sabit metin göster |
| Dosya yükleme doğrulaması | ➖ | Sunucuya dosya yüklenmiyor | — | — |
| Tahmin edilemez dosya adı | ➖ | Aynı | — | — |
| Admin endpoint'leri korumalı | ✅ | Ayrı endpoint yok; aynı tablolar `is_admin()` ile | — | — |
| Güvenlik logları / anormallik uyarısı | ❌ | Kodda/SQL'de denetim kaydı yok (rol değişikliği dahil) | Orta | Rol değişikliklerini bir `audit_log` tablosuna tetikleyiciyle yaz; Supabase log uyarıları |

## 6. Ağ Güvenliği

| Madde | Durum | Kanıt | Risk | Düzeltme |
|---|---|---|---|---|
| Tüm trafik HTTPS | ✅ | `lib/` içinde `http://` yok; Supabase URL https | — | — |
| `usesCleartextTraffic="false"`; NSC tanımlı | ⚠️ | `AndroidManifest.xml:12` var; `res/xml/network_security_config.xml` yok | Düşük | Düzeltme 6 |
| iOS ATS aktif | ✅ | `Info.plist` içinde `NSAppTransportSecurity` istisnası yok | — | — |
| SSL doğrulamasını kapatan kod yok | ✅ | `badCertificateCallback` taraması: yok | — | — |
| Sertifika sabitleme | ➖ | Hassas uygulama sınıfında değil | Düşük | — |
| Pin süresi planı | ➖ | Pinning yok | — | — |
| Hassas veri URL'de değil | ✅ | Kimlik bilgileri gövdede; PostgREST filtrelerinde yalnızca UUID | — | — |
| Debug proxy/Flipper release'de kapalı | ✅ | Böyle bir bağımlılık yok | — | — |
| Kullanıcı CA'larına güvenilmiyor | ✅ | targetSdk 37 varsayılanı (`build.gradle.kts:40`) | — | — |
| WebSocket wss ve kimlik doğrulamalı | ➖ | İstemcide Realtime kanalı kullanılmıyor (`.channel(` yok); SQL'de hazır politika var (`:1737-1763`) | — | — |

## 7. Platform Etkileşimi ve Saldırı Yüzeyi

| Madde | Durum | Kanıt | Risk | Düzeltme |
|---|---|---|---|---|
| Deep link parametreleri doğrulanıyor | ➖ | Manifest'te deep link intent-filter yok; iç rota `int.tryParse` (`app_router.dart:249`) | — | — |
| Universal/App Links | ➖ | Deep link yok | — | — |
| Deep link ile kimlik doğrulama atlanamıyor | ✅ | Tüm rotalar `redirect` denetiminden geçiyor (`app_router.dart:154-192`) | — | — |
| Deep link URL'si WebView'de açılmıyor | ➖ | WebView yok | — | — |
| Gereksiz `exported="true"` yok | ✅ | Yalnızca launcher Activity; receiver `exported="false"` (`AndroidManifest.xml:15, 43`) | — | — |
| Dışa açık bileşenler korumalı | ✅ | Aynı | — | — |
| ContentProvider güvenliği | ➖ | Uygulamanın kendi provider'ı yok | — | — |
| PendingIntent `FLAG_IMMUTABLE` | ✅ | Kendi native kod yok; `flutter_local_notifications` 19.x | — | — |
| Intent verisi doğrulanıyor | ✅ | `MainActivity.kt:21` tek boolean argüman | — | — |
| FileProvider yapılandırması | ❓ | `image_picker`/`file_picker` kendi provider'ını ekler; birleştirilmiş manifest incelenmedi | Düşük | `build/app/intermediates/merged_manifests/release` kontrolü |
| WebView maddeleri (6 madde: JS, JS köprüsü, dosya erişimi, allowlist, originWhitelist, mixed content) | ➖ | WebView paketi yok (`pubspec.yaml`) | — | — |
| Android `FLAG_SECURE` | ✅ | `MainActivity.kt:20-26`, giriş/kayıt ekranlarında `SecureScreenMixin` | — | — |
| iOS arka planda ekran gizleme | ❌ | `secure_screen_service.dart:16` iOS'ta no-op | Düşük | `SceneDelegate.sceneWillResignActive` içinde bulanık kaplama |
| Şifre alanları | ⚠️ | `obscureText` tümünde var; `enableSuggestions/autocorrect: false` yalnızca `sifremi_unuttum_screen.dart:214-215`'te; giriş/kayıt şifre alanlarında yok (`login_screen.dart:168`, `register_screen.dart:142`) | Düşük | İki alana da ekle |
| Pano temizliği | ➖ | `Clipboard` kullanımı yok | — | — |
| Üçüncü taraf klavye kısıtı | ➖ | Hassas sınıf değil | — | — |
| Yalnızca kullanılan izinler | ✅ | INTERNET, NETWORK_STATE, POST_NOTIFICATIONS, BOOT_COMPLETED (`AndroidManifest.xml:2-5`); iOS yalnızca fotoğraf kitaplığı | — | — |
| İzinler ihtiyaç anında | ✅ | Bildirim izni yalnızca hatırlatma açılınca (`settings_provider.dart:104`) | — | — |
| SDK'ların eklediği izinler | ❓ | Birleştirilmiş manifest incelenmedi | Düşük | `aapt dump permissions` ile `.aab` kontrolü |

## 8. Kod Düzeyinde Güvenlik

| Madde | Durum | Kanıt | Risk | Düzeltme |
|---|---|---|---|---|
| SQLite sorguları parametreli | ➖ | Yerel SQL yok; PostgREST/RPC parametreli | — | — |
| `eval`/dinamik kod yok | ✅ | Tarama | — | — |
| WebView XSS | ➖ | WebView yok; gönderiler `Text` ile basılıyor | — | — |
| Path traversal | ✅ | Dosya adı uygulamada üretiliyor, uzantı `[a-z0-9]` süzülüyor (`ortam_provider.dart:245-246`) | — | — |
| Serileştirme güvenli | ✅ | JSON + freezed; okuma hataları yakalanıyor (`storage_service.dart:49-57`) | — | — |
| ReDoS | ⚠️ | İstemci regex'leri basit. Sunucuda `moderation_words.word` regex'e kaçışsız ekleniyor (`schema:1442`); yalnızca admin yazabildiği için risk düşük | Düşük | `regexp_replace(w.word, '([.^$*+?()\[\]{}\|\\])', '\\\1', 'g')` ile kaçır |
| Format string / integer overflow (native) | ➖ | Native kod 33 satır Kotlin | — | — |
| Hassas işlemler istemci saatine güvenmiyor | ⚠️ | Yıldız süresi sunucuda ölçülüyor (`:2103`), ama başlangıç damgası istemciden yazılabiliyor (B3) | Orta–Yüksek | Düzeltme 1 |

## 9. Tersine Mühendislik ve Dayanıklılık

| Madde | Durum | Kanıt | Risk | Düzeltme |
|---|---|---|---|---|
| R8 etkin | ✅ | `build.gradle.kts:56-57` | — | — |
| ProGuard kuralları | ⚠️ | `proguard-rules.pro:13-14` var olmayan `com.supabase.**` paketlerini koruyor (etkisiz ama zararsız); release derlemesinin çalıştığı cihazda doğrulanmadı | Düşük | Ölü kuralları sil |
| Flutter `--obfuscate --split-debug-info` | ✅ | `build_release.ps1:58-59` | — | — |
| Hermes | ➖ | React Native değil | — | — |
| `debuggable=false` | ✅ | Release buildType'ta geçersiz kılma yok | — | — |
| Release'de hassas log yok | ✅ | Tüm loglar `kDebugMode` koşullu | — | — |
| Root/jailbreak tespiti | ➖ | Hassas sınıf değil | — | — |
| Debugger/Frida tespiti | ➖ | Aynı | — | — |
| İmza/bütünlük doğrulaması | ➖ | Aynı | — | — |
| Play Integrity / App Attest | ❌ | Yok; oyunlaştırma API'leri betikle çağrılabilir | Düşük | Sunucu sınırları yeterli tutulursa gerekmez |
| Güvenlik kararları sunucuda | ✅ | Bkz. bölüm 5 | — | — |

## 10. Ödeme ve Uygulama İçi Satın Alma

Uygulamada gerçek para ile ödeme veya uygulama içi satın alma yok (`pubspec.yaml`'da IAP/ödeme paketi yok); "yıldız" yalnızca oyun içi puan. Sekiz maddenin tümü ➖. İlgili tek uyarlanabilir kontrol: çift harcama `p_purchase_id` idempotency anahtarıyla engelleniyor (`supabase_data_service.dart:378`) ✅.

| Madde | Durum |
|---|---|
| Makbuz sunucuda doğrulanıyor | ➖ |
| Abonelik durumu sunucudan | ➖ |
| Sunucu bildirimleri | ➖ |
| Restore purchases | ➖ |
| Bekleyen işlemler | ➖ |
| Kart bilgisi saklanmıyor | ➖ |
| Çift ödeme engeli | ➖ (yıldız için ✅) |
| Mağaza ödeme kuralları | ➖ |

## 11. Bağımlılıklar ve Tedarik Zinciri

| Madde | Durum | Kanıt | Risk | Düzeltme |
|---|---|---|---|---|
| Paketler gerçek ve resmi kaynaktan | ✅ | `flutter pub outdated` 19 doğrudan bağımlılığın tümünü pub.dev'de çözdü | — | — |
| Bakım durumu kontrolü | ⚠️ | Doğrudan paketler güncel yayın alıyor; `build_resolvers`, `build_runner_core` (geçişli, yalnızca geliştirme) "discontinued" | Düşük | `build_runner`'ı 2.15+ sürümüne yükselt |
| Denetim aracı çalıştırıldı | ⚠️ | Bu denetimde `flutter pub outdated` çalıştırıldı; OSV/Snyk taraması yapılmadı | Orta | `osv-scanner --lockfile pubspec.lock` |
| Bilinen açıklı sürüm yok | ❓ | Açık veritabanı taraması yapılmadı | Orta | Aynı |
| Deprecated paket/API yok | ⚠️ | `main.dart:53` `anonKey` deprecated (bilinçli `ignore`); `flutter_local_notifications` 19.5 → 22.3, `flutter_riverpod` 2.6 → 3.x | Düşük | Planlı yükseltme |
| Lock dosyası commit edilmiş | ❌ | `pubspec.lock` var ama depo yok (B1) | Yüksek | Depo oluştur |
| Sürümler framework ile uyumlu | ✅ | `flutter analyze` ve 78 test geçti (Flutter 3.41.5 / Dart 3.11.3) | — | — |
| Kullanılmayan bağımlılık yok | ⚠️ | `riverpod_generator`, `riverpod_lint`, `custom_lint` tanımlı ama `analysis_options.yaml`'da `custom_lint` eklentisi etkin değil; `cupertino_icons` kullanımı doğrulanmadı | Düşük | Kullanılmayanları kaldır veya `custom_lint`'i etkinleştir |
| Lisanslar ticari kullanıma uygun | ⚠️ | Yazı tipleri OFL ve lisans kaydı var (`main.dart:70-73`); paket lisansları tek tek taranmadı | Düşük | `flutter pub deps` + lisans taraması |
| SDK'ların topladığı veriler biliniyor | ✅ | Analitik/reklam SDK'sı yok; `PrivacyInfo.xcprivacy` izleme yok | — | — |

## 12. Gizlilik ve Yasal Uyumluluk

| Madde | Durum | Kanıt | Risk | Düzeltme |
|---|---|---|---|---|
| KVKK aydınlatma metni ve açık rızalar | ⚠️ | Metin var; **veri sorumlusunun adı/adresi yok**; yurt dışı aktarım rızası + politika onayı + veli beyanı tek kutuda (`register_screen.dart:185-210`); yapay zeka rızası ayrı ve geri alınabilir ✅ (`asistan_sohbet_sheet.dart:104-123`) | Yüksek | Veri sorumlusu kimliğini ekle; açık rızayı ayrı, isteğe bağlı olmayan-gerekçeli ayrı kutuya böl; hukukçu görüşü al |
| GDPR | ⚠️ | Politika GDPR'a atıf yapıyor; AB kullanıcısı hedeflenmiyorsa mağaza dağıtımını Türkiye ile sınırla | Düşük | Dağıtım ülkelerini kısıtla |
| Politika uygulama içi ve mağazada | ✅ / ❓ | Uygulama içi her oturum durumunda erişilebilir (`app_router.dart:165`); mağaza bağlantısı doğrulanamaz. `assets/legal/privacy_policy.md` ile kökteki `PRIVACY_POLICY.md` **farklı** | Orta | İki kopyayı eşitle |
| Veri minimizasyonu | ✅ | Ad, e-posta, sınıf, alan; asistana ad/e-posta gitmiyor (politika §2f, `index.ts:3-5`) | — | — |
| Görüntüleme/dışa aktarma/silme | ⚠️ | Silme uygulama içinde ✅ (`profil_sos_tab.dart:45`, `schema:1671-1683`); dışa aktarma yalnızca e-posta talebiyle | Düşük | Ayarlara "Verilerimi indir (JSON)" ekle |
| Analitik/crash onayı | ➖ | İkisi de yok | — | Crash raporlama eklenirse politika ve onay güncellenmeli |
| Yurt dışı aktarım değerlendirildi | ⚠️ | Politikada var (§4); açık rızaya dayandırılmış, bkz. ilk satır | Orta | Hukukçu görüşü |
| Çocuklara yönelik içerik | ⚠️ | 14–18 hedef; veli onayı yalnızca beyan; yaş sorulmuyor (13 yaş altı engeli yok). Topluluk için şikâyet/engelleme/kelime filtresi var ✅ | Orta | Kayıtta doğum yılı sor, 13 altını engelle; Play "Hedef kitle" beyanını buna göre doldur |
| Loglarda kişisel veri yok | ✅ | Edge Function yalnızca hata mesajı logluyor (`index.ts:113, 141-149`) | — | — |
| Saklama süreleri tanımlı | ✅ | Politika §5; SQL'de 30 günlük temizlik (`:1645`, `:1841`) | — | — |

## 13. Mağaza Gereksinimleri

| Madde | Durum | Kanıt | Risk | Düzeltme |
|---|---|---|---|---|
| Uygulama içi hesap silme | ✅ | `profil_sos_tab.dart:19-66` | — | — |
| Sign in with Apple | ➖ | Sosyal giriş yok | — | — |
| iOS Privacy Manifest | ⚠️ | `PrivacyInfo.xcprivacy` var (UserDefaults CA92.1); çalışma/deneme verileri "OtherUserContent" altında, ad ayrı beyan edilmemiş | Düşük | `Name` veri türünü ekle |
| Veri Güvenliği formu / gizlilik etiketleri | ❓ | Mağaza panelleri | Orta | Politika §2 ile eşleştir (Anthropic aktarımı dahil) |
| ATT | ➖ | İzleme yok | — | — |
| Info.plist izin açıklamaları | ✅ | `NSPhotoLibraryUsageDescription` anlamlı; kamera/mikrofon kullanılmıyor | — | — |
| targetSdk güncel | ✅ | `targetSdk = 37` | — | — |
| Foreground service türleri | ➖ | FGS yok | — | — |
| Hassas izin beyan formları | ➖ | Hassas izin yok | — | — |
| Demo hesap | ❓ | Kod dışı | Düşük | İnceleme notuna ekle |
| İkon/ekran görüntüsü/açıklama | ❓ | Mağaza varlıkları incelenmedi | Düşük | — |

## 14. Mimari ve Kod Kalitesi

| Madde | Durum | Kanıt | Risk | Düzeltme |
|---|---|---|---|---|
| Katmanlı mimari | ⚠️ | `core/algorithms` iyi ayrılmış; `data/repositories` ve `data/datasources` **boş**, ekranlar doğrudan Supabase sorguluyor (`admin_screen.dart:43`, `role_provider.dart:14`) | Düşük | Boş klasörleri sil veya servisleri oraya taşı |
| Dev bileşen yok | ❌ | `grafikler.dart` 1076, `calis_tab.dart` 818, `flashkart_tab.dart` 769, `ders_programi_screen.dart` 738 satır | Düşük | Alt widget dosyalarına böl |
| Tutarlı isimlendirme | ⚠️ | Türkçe/İngilizce karışık (`ozelFotoSec` / `createTicket`); paket adı `yks_kocu`, namespace `com.lisenet`, applicationId `com.DersNet`, kanal `com.lisenet/secure_screen` | Düşük | Tek ad belirle |
| Parçalar arası tutarsızlık | ⚠️ | İki ayrı auth servisi ve iki hata eşleyici (`auth_service.dart:40`, `supabase_auth_service.dart:221`); `SecureStorageService` içinde kullanılmayan `saveAuthTokens/saveSupabaseCredentials` (`storage_service.dart:169-200`) | Düşük | Birleştir, ölü kodu sil |
| "Geri kalan kod aynı" atlaması yok | ✅ | Tarama | — | — |
| `!`, `dynamic` kötüye kullanımı | ✅ | Yaklaşık 14 `!`; `dynamic` çoğunlukla JSON | — | — |
| Lint kapatılmamış | ⚠️ | `flutter analyze`: 0 sorun; 10 satır içi `ignore`; Android `lint { checkReleaseBuilds = false; abortOnError = false }` (`build.gradle.kts:22-25`) | Düşük | Android lint'i yeniden aç |
| Boş catch yok | ❌ | 55 sessiz `catch`; ör. `main.dart:37, 64, 99`, `supabase_data_service.dart:294, 451, 503` | Orta | En azından `kDebugMode` logu + crash raporlayıcıya ilet |
| Mock/TODO production'da yok | ✅ | TODO/FIXME yok; sahte başarı akışı release'de kapalı | — | — |
| Ölü kod temizlendi | ⚠️ | Yukarıdaki kullanılmayan yardımcılar; `assignChairman/updateUserRole` gibi koç/başkan işlevleri | Düşük | — |
| Sihirli sayılar sabitlerde | ⚠️ | Edge Function sabitleri adlandırılmış ✅; istemcide 15 sn/30 sn/5 deneme satır içi | Düşük | — |
| Tip güvenliği | ✅ | Dart 3 null-safety | — | — |
| Proje boyutuna uygun mimari | ✅ | Riverpod + servisler yeterli | — | — |

## 15. Bellek, Yaşam Döngüsü ve Eşzamanlılık

| Madde | Durum | Kanıt | Risk | Düzeltme |
|---|---|---|---|---|
| Listener/timer kapatılıyor | ✅ | Timer kullanan 10 dosyanın tümünde `cancel()` var; `auth_provider.dart:92-95` abonelik iptali | — | — |
| Android Context sızıntısı | ❓ | LeakCanary çalıştırılmadı; native kod minimal | Düşük | — |
| iOS retain cycle | ➖ | Özel Swift kodu yok | — | — |
| Kapanan bileşende state güncellenmiyor | ✅ | `mounted` kontrolleri (`login_screen.dart:53`, `auth_provider.dart:160`) | — | — |
| İstekler iptal ediliyor | ⚠️ | İptal belirteci yok; 15 sn zaman aşımı + `mounted` kontrolü var | Düşük | — |
| Race condition yok | ✅ | Oturum açma yarışı ele alınmış (`odak_provider.dart:112-128`), `auth_provider.dart:161` | — | — |
| Process death sonrası state | ⚠️ | Kalıcı veri depoda; süren odak sayacı ve yarım test bellekte (`odak_provider.dart`) | Orta | Sayaç başlangıcını kalıcı depoya yaz, açılışta devam ettir |
| Arka plan ↔ ön plan | ⚠️ | Yalnızca etüt odası gözlemliyor (`etut_odasi_screen.dart:45-46`); odak sayacı duvar saatine dayanıyor ✅ | Düşük | — |
| Ağır işler ana thread dışında | ⚠️ | Ambiyans sesi sentezi Dart'ta (`ambiyans_service.dart`, 466 satır); isolate kullanımı doğrulanmadı | Düşük | `compute()` ile üret |
| Deadlock/thread-safety | ✅ | Tek isolate | — | — |
| Yapılandırma değişikliğinde veri kaybı | ✅ | `configChanges` tam liste (`AndroidManifest.xml:19`) | — | — |

## 16. Hata Yönetimi ve Ağ Dayanıklılığı

| Madde | Durum | Kanıt | Risk | Düzeltme |
|---|---|---|---|---|
| Yükleniyor/boş/hata/başarı durumları | ⚠️ | Auth, admin, etüt ekranlarında var; tüm ekranlar tek tek doğrulanmadı | Düşük | — |
| Mutlu yol dışı senaryolar | ✅ | Kısmi kayıt, doğrulanmamış hesap, yarım şifre yenileme ele alınmış (`auth_service.dart:171-177, 219-243`) | — | — |
| Çevrimdışı mesaj ve önbellek | ✅ | Yerel öncelikli depo; ağ hatası mesajı (`supabase_auth_service.dart:21-28`) | — | — |
| Bağlantı gelince yeniden deneme | ❌ | Başarısız bulut yazması yutuluyor, kuyruk yok (`synced_storage_service.dart:51-53`); B4 ile birlikte | Orta–Yüksek | Düzeltme 3 |
| Timeout | ✅ | `timeout_http_client.dart:12-13` (15 sn / 60 sn) | — | — |
| Exponential backoff | ❌ | Yeniden deneme mantığı yok | Düşük | Kuyrukla birlikte ekle |
| Beklenmeyen yanıt çökertmiyor | ✅ | Null güvenli ayrıştırma (`etut_odasi_service.dart:29-37`) | — | — |
| 4xx/5xx ayrı ele alınıyor | ✅ | Edge Function 400/401/403/429/500/502/503; istemci `AsistanHatasi` kodları | — | — |
| Global hata yakalayıcı | ⚠️ | Var (`main.dart:23-31`) ama release'de hiçbir yere raporlamıyor | Orta–Yüksek | Düzeltme 4 |
| Anlaşılır hata mesajları | ✅ | Türkçe eşlenmiş mesajlar | — | — |
| Çift basma engeli | ✅ | `_isLoading` (`create_ticket_screen.dart:180`), satın alma idempotent | — | — |
| Yavaş ağ testi | ❓ | Kodla doğrulanamaz | — | — |
| Sayfalama | ⚠️ | Akış ilk 30 gönderiyle sınırlı, devamı yok (`supabase_data_service.dart:168-176`); admin istatistikleri tüm satırları çekip sayıyor (`:241-247`) | Düşük | `.range()` ile sayfalama; `count` kullan |
| Bakım/zorunlu güncelleme | ❌ | Mekanizma yok | Orta | Düzeltme 5 |

## 17. Çökmeler ve Donmalar

| Madde | Durum | Kanıt | Risk | Düzeltme |
|---|---|---|---|---|
| Crash raporlama | ❌ | Sentry/Crashlytics yok | Orta–Yüksek | Düzeltme 4 |
| Sembol dosyaları yükleniyor | ⚠️ | `symbols/` ve `mapping.txt` üretiliyor; yükleme elle | Düşük | Play Console'a her sürümde yükle |
| ANR riski | ⚠️ | Açılışta sıralı `await` zinciri: prefs, güvenli depo, Supabase, bildirim, tarih yerelleştirme (`main.dart:36-76`) | Düşük | Bildirim ve tarih başlatmasını `runApp` sonrasına al |
| iOS watchdog | ⚠️ | Aynı zincir | Düşük | Aynı |
| Düşük bellek uyarıları | ➖ | Büyük bellek kullanan özellik yok | — | — |
| Minimum OS testi | ❓ | minSdk 24; test kaydı yok | Orta | API 24 emülatöründe duman testi |
| Release build gerçek cihazda | ❓ | Kodla doğrulanamaz | Orta | — |

## 18. Performans

| Madde | Durum | Kanıt | Risk | Düzeltme |
|---|---|---|---|---|
| Liste sanallaştırma | ⚠️ | 20 `builder/separated` kullanımı, 15 düz `ListView(` | Düşük | Uzun olabilenleri `builder`'a çevir |
| Kararlı key | ❓ | Tek tek incelenmedi | Düşük | — |
| Gereksiz yeniden render | ❓ | Profil aracıyla ölçülmedi | Düşük | — |
| Görseller optimize | ✅ | Seçilen fotoğraf 1600 px / %85 (`ortam_provider.dart:196-197`); sahneler kodla çiziliyor | — | — |
| Açılış süresi ölçüldü | ❓ | Ölçüm kaydı yok; bkz. 17 ANR satırı | Düşük | — |
| Animasyonlar akıcı | ❓ | Cihazda ölçülmedi | Düşük | — |
| Uygulama boyutu | ⚠️ | App Bundle + R8 ✅; `.aab` yaklaşık 48–50 MB | Düşük | `flutter build appbundle --analyze-size` |
| Gereksiz ağ isteği | ⚠️ | `getMap` yerelde yoksa her seferinde buluta gidiyor (`synced_storage_service.dart:210-219`); rol iki ayrı provider'da sorgulanıyor | Düşük | — |
| Debounce | ⚠️ | Admin kullanıcı araması için debounce doğrulanmadı | Düşük | — |
| Bellek profili | ❓ | Çalıştırılmadı | Düşük | — |

## 19. Pil ve Kaynak Kullanımı

| Madde | Durum | Kanıt | Risk | Düzeltme |
|---|---|---|---|---|
| Sürekli konum takibi yok | ✅ | Konum kullanılmıyor | — | — |
| Polling yerine push/WebSocket | ⚠️ | Etüt odası 30 sn'de bir sorguluyor (`etut_odasi_screen.dart:34`); arka plana geçince durdurulmuyor | Düşük | `paused` durumunda timer'ı iptal et |
| Sistem planlayıcıları | ✅ | Bildirim `zonedSchedule` + `inexactAllowWhileIdle` (`notification_service.dart:66`) | — | — |
| Wake lock | ➖ | Yok | — | — |
| Sensörler | ➖ | Yok | — | — |
| Mobil veride büyük indirme | ➖ | Yok | — | — |

## 20. Arayüz ve Duyarlı Tasarım

| Madde | Durum | Kanıt | Risk | Düzeltme |
|---|---|---|---|---|
| Safe area | ✅ | Ekranların çoğunda `SafeArea` | — | — |
| Android 15 edge-to-edge | ❓ | targetSdk 37'de zorunlu; cihazda doğrulanmadı | Orta | Alt gezinme çubuğu altında içerik kontrolü |
| Geri tuşu / predictive back | ⚠️ | `PopScope` 3 yerde (`shell_screen.dart:43`, test ekranları); manifest'te `enableOnBackInvokedCallback` yok | Düşük | `android:enableOnBackInvokedCallback="true"` |
| Klavye alanları kapatmıyor | ✅ | `adjustResize` (`AndroidManifest.xml:21`) | — | — |
| Farklı ekran boyutları | ❓ | Test kaydı yok | Düşük | — |
| Yatay mod | ⚠️ | Kilit yok; iOS yatay açık (`Info.plist`), yatay düzen test edilmemiş | Düşük | `SystemChrome.setPreferredOrientations([portraitUp])` |
| Karanlık mod; sabit renk yok | ⚠️ | İki tema var; `presentation/` içinde (çizimler hariç) 81 sabit renk kullanımı (ör. `app_router.dart:144` `Colors.white`) | Düşük | Tema renklerine taşı |
| Uzun metin taşması | ❓ | Tek tek incelenmedi | Düşük | — |
| Platform alışkanlıkları | ✅ | go_router, alt sekmeler, geri oku | — | — |
| Dokunmatik geri bildirim | ✅ | Material bileşenleri + `HapticFeedback` | — | — |

## 21. Erişilebilirlik

| Madde | Durum | Kanıt | Risk | Düzeltme |
|---|---|---|---|---|
| Erişilebilirlik etiketleri | ⚠️ | Tüm uygulamada yaklaşık 55 `Semantics/tooltip/semanticLabel`; kodla çizilen sahne ve grafiklerin çoğu etiketsiz | Orta | `CustomPaint` ve ikon düğmelerine `Semantics(label:)` |
| VoiceOver/TalkBack testi | ❓ | Kayıt yok | Orta | — |
| Dokunma alanı ≥ 48 dp | ❓ | Ölçülmedi | Düşük | — |
| Dinamik yazı boyutu | ❌ | `main.dart:116-121` sistem ölçeğini uygulama ayarıyla **değiştiriyor**; sistemde büyük yazı seçen kullanıcı yok sayılıyor | Orta | `MediaQuery.textScalerOf(context)` ile çarp, 0.8–1.6 aralığına sıkıştır |
| Kontrast WCAG AA | ❓ | Ölçülmedi | Düşük | — |
| Bilgi yalnızca renkle değil | ❓ | Grafikler tek tek incelenmedi | Düşük | — |
| Odak sırası | ❓ | Test edilmedi | Düşük | — |
| Reduce motion | ✅ | 8 yerde `disableAnimations` (`cizim_widgetlari.dart:12`, `flashkart_tab.dart:161`) | — | — |

## 22. Yerelleştirme

| Madde | Durum | Kanıt | Risk | Düzeltme |
|---|---|---|---|---|
| i18n altyapısı | ❌ | `lib/l10n/` boş; tüm metinler kodda. Yalnızca Türkçe hedefleniyorsa kabul edilebilir | Düşük | — |
| Türkçe i/İ dönüşümleri | ⚠️ | E-posta için güvenli (Dart `toLowerCase` yerelden bağımsız). Türkçe metin karşılaştırmalarında `I→i` hatası: `mufredat_provider.dart:123-126`, `onboarding_screen.dart:55`; baş harf `toUpperCase()` "i"yi "I" yapar (`ana_sayfa_tab.dart:88`, `etut_odasi_screen.dart:212`) | Düşük | Türkçe duyarlı yardımcı: `s.replaceAll('I','ı').replaceAll('İ','i').toLowerCase()` |
| Tarih/sayı yerel formatta | ✅ | `initializeDateFormatting('tr_TR')` (`main.dart:76`) | — | — |
| Çoğul ifadeler | ➖ | Türkçe'de sayıyla çoğul eki gerekmiyor | — | — |
| RTL | ➖ | Gerekli değil | — | — |
| Çeviri uzunluk farkları | ➖ | Tek dil | — | — |

## 23. Formlar ve Kullanıcı Girdisi

| Madde | Durum | Kanıt | Risk | Düzeltme |
|---|---|---|---|---|
| Klavye tipleri | ✅ | E-posta ve sayı alanları (`login_screen.dart:128`, `email_verification_screen.dart:148`) | — | — |
| Otomatik doldurma ipuçları | ✅ | `login_screen.dart:129, 169`, `register_screen.dart:103, 143`, `sifremi_unuttum_screen.dart:205` | — | — |
| Doğrulama mesajları | ✅ | Form validator'ları | — | — |
| Emoji/çok uzun giriş | ⚠️ | Talep ve gönderi alanlarında `maxLength` yok (`create_ticket_screen.dart:155`, `create_post_screen.dart:167`); gönderi sunucuda 5000 ile sınırlı, talep sınırsız | Orta | `maxLength` + sunucu CHECK (Düzeltme 2) |
| Boşluk kırpma | ⚠️ | E-posta kırpılıyor ✅; **şifre de kırpılıyor** (`login_screen.dart:51`, `register_screen.dart:38`), baştaki/sondaki boşluklu şifreler sessizce değişir (tutarlı uygulandığı için kilitlenme yok) | Düşük | Şifreyi kırpma |
| Gönderimde buton devre dışı | ✅ | `_isLoading` | — | — |
| Yarım form kaybolmuyor | ⚠️ | Test çözme ekranında `PopScope` var; gönderi/talep formunda çıkış onayı yok | Düşük | — |

## 24. Veri, Senkronizasyon ve Önbellek

| Madde | Durum | Kanıt | Risk | Düzeltme |
|---|---|---|---|---|
| Yerel migration | ⚠️ | Eski anahtar taşıma var (`synced_storage_service.dart:100-126`); JSON şema sürümü yok | Düşük | Her anahtara `v` alanı |
| Çakışma çözüm stratejisi | ❌ | B4: yerel kopya her zaman kazanıyor, bulut tüm anahtarı eziyor | Orta–Yüksek | Düzeltme 3 |
| Tarihler UTC | ⚠️ | Sunucu `TIMESTAMPTZ` ✅; `updated_at` istemci saatinden ve saat dilimsiz (`synced_storage_service.dart:49`); hafta başlangıcı yerel saat dilimsiz gönderiliyor (`supabase_data_service.dart:741-747`); kota günü UTC (`schema:1789, 1843`) | Düşük | `.toUtc().toIso8601String()`; `updated_at`'i sunucu varsayılanına bırak |
| Önbellek geçersiz kılma | ❌ | Yok (B4 ile aynı kök neden) | Orta–Yüksek | Düzeltme 3 |
| Kullanıcı değişince eski önbellek gösterilmiyor | ✅ | `sd_<uid>_` ad alanı + çıkışta temizlik (`synced_storage_service.dart:31, 165-178`) | — | — |
| Süre kontrolleri sunucu saatine göre | ✅ | Davet 48 saat, kota, yıldız tavanı sunucuda | — | — |

## 25. Bildirimler

| Madde | Durum | Kanıt | Risk | Düzeltme |
|---|---|---|---|---|
| POST_NOTIFICATIONS izni | ✅ | `AndroidManifest.xml:4`, `notification_service.dart:37` | — | — |
| Push token logout'ta siliniyor | ➖ | Uzak push yok; ancak yerel hatırlatma çıkışta iptal edilmiyor (`auth_provider.dart:279-297`) | Düşük | Çıkışta `NotificationService.cancel()` |
| Bildirimde hassas veri yok | ✅ | Sabit metin (`notification_service.dart:53-54`) | — | — |
| Tıklayınca doğru ekran | ⚠️ | Tıklama işleyicisi tanımlı değil (`:23`); uygulama ana sayfada açılır | Düşük | `onDidReceiveNotificationResponse` ile `/plan` |
| Bildirim kanalları | ✅ | `daily_reminder` (`:57-60`) | — | — |
| Tercih yönetimi | ✅ | Ayarlarda aç/kapat ve saat (`settings_provider.dart:104-106`) | — | — |

## 26. Medya, Kamera ve Dosyalar

| Madde | Durum | Kanıt | Risk | Düzeltme |
|---|---|---|---|---|
| Photo Picker / granüler izin | ✅ | `image_picker` galeri; manifest'te depolama izni yok | — | — |
| iOS sınırlı fotoğraf erişimi | ✅ | Sistem seçicisi kullanılıyor | — | — |
| EXIF temizliği | ➖ | Fotoğraf sunucuya yüklenmiyor; cihazda kalıyor | — | — |
| Büyük dosya yükleme | ➖ | Yükleme yok; yerel ses dosyası boyut sınırlı (`ortam_provider.dart:239-241`) | — | — |
| İndirilen dosya doğrulaması | ➖ | İndirme yok | — | — |

## 27. Konum ve Sensörler

Konum ve sensör kullanılmıyor (`pubspec.yaml`, manifest). Dört maddenin tümü ➖.

## 28. İzin Akışları

| Madde | Durum | Kanıt | Risk | Düzeltme |
|---|---|---|---|---|
| Ret durumunda çökmüyor | ✅ | `requestPermissions` try/catch, `false` döner (`notification_service.dart:30-45`) | — | — |
| "Bir daha sorma" → ayarlara yönlendirme | ❌ | Kalıcı retten sonra ayarlara yönlendirme yok | Düşük | `permission_handler.openAppSettings()` veya açıklayıcı mesaj |
| İzin öncesi açıklama | ⚠️ | Kullanıcı hatırlatmayı açınca isteniyor (bağlam var), ayrı açıklama ekranı yok | Düşük | — |
| İzin ayarlardan kaldırılınca | ⚠️ | Uygulama ayarı "açık" kalır, bildirim sessizce gelmez | Düşük | Açılışta izin durumunu kontrol et |

## 29. Arka Plan İşleri

| Madde | Durum | Kanıt | Risk | Düzeltme |
|---|---|---|---|---|
| Doze/App Standby | ✅ | `inexactAllowWhileIdle` | — | — |
| iOS arka plan sınırları | ✅ | Arka plan işi yok | — | — |
| Başarısız iş yeniden deneniyor | ➖ | Arka plan işi yok (senkron kuyruğu için bkz. Düzeltme 3) | — | — |
| Foreground service | ➖ | Yok | — | — |

## 30. Test

| Madde | Durum | Kanıt | Risk | Düzeltme |
|---|---|---|---|---|
| Birim testleri iş mantığını kapsıyor | ⚠️ | 15 dosya, 78 test, hepsi geçti; algoritmalar (SM-2, program, analiz, asistan) kapsanıyor; auth, senkronizasyon ve servisler kapsanmıyor | Orta | `SyncedStorageService` ve `AuthNotifier` için sahte istemciyle test |
| Entegrasyon/uçtan uca | ❌ | `integration_test/` yok | Orta | Kayıt → onboarding → odak akışı için bir uçtan uca test |
| Hata/kenar durumları | ⚠️ | Algoritma testlerinde var | Düşük | — |
| MobSF | ❌ | Rapor yok | Düşük | `.aab` üzerinde bir kez çalıştır |
| RLS otomatik testleri | ❌ | Yok; güvenlik tamamen SQL'e dayandığı için en değerli eksik test | Orta–Yüksek | pgTAP veya iki test kullanıcısıyla betik: başkasının `student_data`'sını okuyamama, `role` yükseltememe, B3 senaryosu |
| Farklı cihaz/OS testi | ❓ | Kayıt yok | Orta | — |
| Güncelleme senaryosu | ❓ | Kayıt yok | Orta | — |
| Temiz kurulum | ❓ | Kayıt yok | Düşük | — |

## 31. Build, Yapılandırma ve Dağıtım

| Madde | Durum | Kanıt | Risk | Düzeltme |
|---|---|---|---|---|
| Dev/staging/prod ayrı | ❌ | Tek Supabase projesi, flavor yok; şema değişiklikleri doğrudan canlıda | Orta | İkinci (ücretsiz) Supabase projesi + `dart_defines.staging.json` |
| Release yapılandırması doğru | ✅ | İmzasız derleme uyarısı, R8, obfuscation (`build.gradle.kts:54-72`) | — | — |
| Sürüm numaralandırması tutarlı | ⚠️ | `pubspec.yaml: 1.0.0+1`; klasörde `app-release_1.3.0+19_eski.aab` ve `ResMuid-1.0.0+1.aab` var. Yeni `applicationId` (`com.DersNet`) yeni mağaza kaydıysa sorun değil; aynı kayda yüklenecekse versionCode 19'un altında reddedilir | Orta | Hangi mağaza kaydına gideceğini netleştir |
| CI/CD | ❌ | `.github/` yok, depo yok | Orta | B1 sonrası GitHub Actions: analyze + test |
| CI secret'ları | ➖ | CI yok | — | — |
| Zorunlu güncelleme | ❌ | Yok | Orta | Düzeltme 5 |
| OTA güncellemeleri | ➖ | Kullanılmıyor | — | — |
| Yapılandırma dosyaları güncel | ⚠️ | AGP 8.11.1, Kotlin 2.2.20, compileSdk 37 ✅; `applicationId` büyük harf içeriyor (geçerli ama alışılmadık), namespace ile uyumsuz; `kotlinOptions` deprecated | Düşük | — |
| Aşamalı yayın | ❓ | Play Console | Düşük | — |

## 32. İzleme, Loglama ve Analitik

| Madde | Durum | Kanıt | Risk | Düzeltme |
|---|---|---|---|---|
| Yapılandırılmış loglama | ⚠️ | Yalnızca `debugPrint`; release'de hiç log yok | Orta | Düzeltme 4 |
| Loglarda token/kişisel veri yok | ✅ | Tarama | — | — |
| Performans izleme | ❌ | Yok | Düşük | — |
| Onaya bağlı analitik | ➖ | Analitik yok | — | — |
| Backend hata uyarıları | ❌ | Yapılandırma kodda yok; Edge Function `console.error` yazıyor ama uyarı kuralı yok | Orta | Supabase log uyarısı veya Anthropic harcama limiti |

## 33. Yapay Zeka Tarafından Üretilen Koda Özgü Kontroller

| Madde | Durum | Kanıt | Risk | Düzeltme |
|---|---|---|---|---|
| Paket ve API'ler dokümantasyonda doğrulandı | ⚠️ | Dart paketleri çözülüyor ve derleniyor ✅. Edge Function'daki `betas: ["server-side-fallback-2026-07-01"]`, `fallbacks: "default"`, `output_config.effort` parametreleri (`index.ts:121-123`) bu denetimde resmi dokümantasyonla **doğrulanmadı** ve fonksiyon henüz deploy edilmediği için hiç çalışmadı | Orta | Deploy öncesi `supabase functions serve` ile gerçek bir çağrı yap |
| Deprecated API yok | ⚠️ | Bkz. bölüm 11 | Düşük | — |
| Güvenlik varsayılan olarak var | ✅ | RLS, yetki iptalleri, kota, rıza | — | — |
| Backend unutulmamış | ⚠️ | Büyük oranda ✅; istisnalar B3 ve B6 | Orta | Düzeltme 1–2 |
| Geçici güvenlik gevşetmeleri geri alındı | ⚠️ | Cleartext/SSL gevşetmesi yok ✅; Android lint kapalı (`build.gradle.kts:22-25`), `android.overridePathCheck=true` | Düşük | Lint'i aç |
| Mimari sapma yok | ⚠️ | Boş `repositories/datasources/l10n`; eski sahte auth akışının kalıntıları (`user_auth_email`, `user_email_verified` bayrakları hâlâ yazılıyor: `auth_provider.dart:182-186, 236-237`) | Düşük | Kalıntıları temizle |
| Yapılandırma değişiklikleri elle gözden geçirildi | ❓ | Sürüm geçmişi olmadığı için izlenemiyor (B1) | Orta | — |
| "Tamamlandı" özellikler uçtan uca çalışıyor | ⚠️ | Proje notlarına göre (3 Ekim 2026) `koc-asistan` Edge Function canlıda deploy edilmemiş: uygulamadaki "yapay zeka yanıtları" şu an çalışmaz. Koç paneli işlevleri (`getMyStudents`, `createCoachTask`) serviste var; ekranlarının varlığı doğrulanmadı | Orta | Deploy et veya özelliği arayüzde gizle |

## 34. Framework'e Özgü Hızlı Kontroller

React Native / Expo (4 madde), Native Android'in Jetpack Security ve LeakCanary maddeleri ile Native iOS `[weak self]` maddesi ➖ (proje Flutter).

| Madde | Durum | Kanıt |
|---|---|---|
| Flutter: `--obfuscate --split-debug-info` | ✅ | `build_release.ps1:58-59` |
| Flutter: `kDebugMode/kReleaseMode` doğru | ✅ | `auth_service.dart:38`, `auth_provider.dart:114` |
| Flutter: `badCertificateCallback` yok | ✅ | Tarama |
| Flutter: controller/stream `dispose` | ✅ | 41 controller oluşturma, 94 `dispose()` çağrısı; timer'ların tümü iptal ediliyor |
| Android: R8, debuggable false, NSC | ⚠️ | R8 ✅, debuggable ✅, NSC dosyası yok (bölüm 6) |
| iOS: ATS aktif, Keychain erişim seviyesi | ✅ | `Info.plist`, `storage_service.dart:145` |
| iOS: Privacy Manifest | ⚠️ | Bölüm 13 |

## 35. Önerilen Araçlar — bu denetimde kullanılanlar

Çalıştırıldı: `flutter analyze` (0 sorun), `flutter test` (78/78), `flutter pub outdated`. Çalıştırılmadı: MobSF, gitleaks (depo yok), OSV/Snyk, mitmproxy, Frida, LeakCanary, profil araçları.

---

## Düzeltme kodları

### Düzeltme 1 — `study_sessions` eklemelerini sunucuda sabitle (B3)

```sql
CREATE OR REPLACE FUNCTION public._study_sessions_before_insert() RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF auth.role() IN ('authenticated', 'anon') AND NOT public.is_admin() THEN
    NEW.started_at     := NOW();
    NEW.ended_at       := NULL;
    NEW.actual_minutes := NULL;
    NEW.stars_awarded  := 0;
    NEW.interrupted    := false;
    NEW.label          := left(trim(NEW.label), 40);
    -- Açık kalmış eski oturumlar yeni oturumla birlikte kapatılır.
    UPDATE public.study_sessions
       SET ended_at = NOW(), actual_minutes = 0, interrupted = true
     WHERE user_id = NEW.user_id AND ended_at IS NULL;
  END IF;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_study_sessions_before_insert ON public.study_sessions;
CREATE TRIGGER trg_study_sessions_before_insert
BEFORE INSERT ON public.study_sessions
FOR EACH ROW EXECUTE FUNCTION public._study_sessions_before_insert();
```

Not: fonksiyon `SECURITY DEFINER` çünkü tabloda UPDATE politikası yok; bu yüzden çağıran rol `current_user` ile değil `auth.role()` ile ayırt ediliyor. Bu SQL bu denetimde çalıştırılmadı; canlıya almadan önce test projesinde dene ve fonksiyonun EXECUTE yetkisini `PUBLIC, anon, authenticated` rollerinden geri al.

### Düzeltme 2 — Görünen ad, talep ve etiket sınırları (B6)

```sql
ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_name_len_chk CHECK (char_length(name) BETWEEN 1 AND 60) NOT VALID;
ALTER TABLE public.user_tickets
  ADD CONSTRAINT tickets_len_chk
  CHECK (char_length(subject) <= 150 AND char_length(description) <= 4000) NOT VALID;

CREATE OR REPLACE FUNCTION public._tickets_rate_limit() RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF (SELECT COUNT(*) FROM public.user_tickets
       WHERE user_id = NEW.user_id AND created_at > NOW() - INTERVAL '1 day') >= 5 THEN
    RAISE EXCEPTION 'Günlük talep sınırına ulaştın.';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER trg_tickets_rate_limit BEFORE INSERT ON public.user_tickets
FOR EACH ROW EXECUTE FUNCTION public._tickets_rate_limit();
```

Ad için kelime filtresi: `_posts_before_insert` içindeki `moderation_words` kontrolünü ortak bir fonksiyona çıkarıp `profiles` üzerinde `BEFORE INSERT OR UPDATE OF name` tetikleyicisinde de çağır.

### Düzeltme 3 — Senkronizasyon çakışması (B4)

Her anahtarın yerel kopyasıyla birlikte son bilinen sunucu `updated_at` değerini sakla; girişte ve ön plana dönüşte bulut daha yeniyse yereli güncelle; başarısız yazmaları kuyruğa al.

```dart
Future<void> hydrateFromCloud() async {
  final rows = await supabase.from('student_data')
      .select('data_key, data_value, updated_at').eq('user_id', _userId);
  for (final row in rows as List) {
    final key = row['data_key'] as String;
    final cloudAt = row['updated_at'] as String;
    final localAt = await _local.getString(_namespaced('${key}__at'));
    final kirli = await _local.getBool(_namespaced('${key}__dirty')) ?? false;
    if (!kirli && (localAt == null || cloudAt.compareTo(localAt) > 0)) {
      await _local.setMap(_namespaced(key), Map<String, dynamic>.from(row['data_value'] as Map));
      await _local.setString(_namespaced('${key}__at'), cloudAt);
    }
  }
  await _kirliAnahtarlariGonder(); // __dirty işaretli anahtarları yeniden dener
}
```

`_pushToCloud` başarısız olursa `__dirty = true` yaz; `updated_at`'i istemciden gönderme, tabloda `BEFORE UPDATE` tetikleyicisiyle `NOW()` ata.

### Düzeltme 4 — Crash raporlama (B5)

```dart
await SentryFlutter.init((o) {
  o.dsn = const String.fromEnvironment('SENTRY_DSN');
  o.sendDefaultPii = false;
}, appRunner: () => runApp(...));

PlatformDispatcher.instance.onError = (error, stack) {
  Sentry.captureException(error, stackTrace: stack);
  return true;
};
```

Eklenince gizlilik politikası (§2) ve mağaza veri beyanları güncellenmeli; `build_release.ps1` sembolleri Sentry'ye yüklemeli.

### Düzeltme 5 — Zorunlu güncelleme

```sql
CREATE TABLE public.app_config (id INT PRIMARY KEY DEFAULT 1, min_build INT NOT NULL, bakim BOOLEAN NOT NULL DEFAULT false);
ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;
CREATE POLICY app_config_read ON public.app_config FOR SELECT USING (true);
```

Açılışta `min_build` > `PackageInfo.buildNumber` ise mağazaya yönlendiren engelleyici ekran göster.

### Düzeltme 6 — Network Security Config

`android/app/src/main/res/xml/network_security_config.xml`:

```xml
<network-security-config>
  <base-config cleartextTrafficPermitted="false">
    <trust-anchors><certificates src="system" /></trust-anchors>
  </base-config>
</network-security-config>
```

Manifest `<application>` etiketine `android:networkSecurityConfig="@xml/network_security_config"` ekle.

### B1 — Sürüm kontrolü ve anahtar hijyeni (kod değil, işlem)

1. Projeyi OneDrive dışına taşı (ör. `C:\dev\DersNet`); bu aynı zamanda `build_release.ps1` içindeki ASCII dışı yol geçici çözümünü gereksiz kılar.
2. `git init`, mevcut `.gitignore` ile ilk commit; özel bir uzak depoya gönder.
3. `upload-keystore.jks` dosyasını şifreli bir yedeğe al, parolaları parola yöneticisine taşı, kök dizindeki `key.properties` kopyasını sil.
4. Play Console'da Play App Signing'in açık olduğunu doğrula (açıksa kaybolan yükleme anahtarı sıfırlanabilir).
