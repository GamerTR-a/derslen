# LiseNET — Güvenlik Denetimi (kontrol.md'nin LiseNET'e uyarlanmış hali)

**Tarih:** 2026-09-29
**Kapsam:** `lib/` (138 Dart dosyası), `supabase_schema.sql` (1217 satır, 17 tablo, 20+ RPC), `supabase_migrations/13-14`, `android/`, `ios/Runner/`, `pubspec.yaml`, `key.properties`, `build_release.ps1`, `PRIVACY_POLICY.md`.
**Çalıştırılan araçlar:** `flutter analyze` → *No issues found*; `flutter pub outdated`.
**Yöntem notu:** Statik inceleme. Canlı Supabase projesine erişim yok; `supabase_schema.sql` canlı veritabanının birebir kopyası kabul edildi. Bu varsayıma dayanan maddeler "canlıda doğrulanmalı" olarak işaretlendi. Proje git deposu olmadığı için geçmişte sızmış secret taraması yapılamadı. Kodda hiçbir değişiklik yapılmadı.

Durum işaretleri: ✅ Geçti · ❌ Kaldı · ⚠️ Kısmen · ➖ Uygulanamaz · ❓ Doğrulanamadı

---

## ✅ Uygulanan düzeltmeler (2026-09-29, aynı gün)

Sunucu tarafı düzeltmeler `supabase_migrations/15_guvenlik_sikilastirma.sql` dosyasında (aynı blok `supabase_schema.sql` sonuna da eklendi). **Bu dosya Supabase SQL Editor'de çalıştırılmadan sunucu açıkları kapanmaz.**

| Bulgu | Durum | Nerede |
|---|---|---|
| K1 profil INSERT ile admin olma | ✅ INSERT'te `role='student' AND xp=0` zorunlu; profil `handle_new_user` tetikleyicisiyle sunucuda oluşuyor; role/xp güncellemesi tetikleyiciyle kilitli | migration §a–b, `supabase_auth_service.dart` |
| Y1 sınırsız XP | ✅ `award_badge_xp(rozet)` — rozet başına bir kez, tutar sunucu kataloğundan; `award_xp` istemciye kapalı | migration §e, `rozet_provider.dart` |
| Y2/Y3 yıldız RPC'leri, anon EXECUTE | ✅ Tüm fonksiyonlar anon/PUBLIC'e kapalı; kullanılmayan/hileye açık 8 fonksiyon authenticated'a da kapalı | migration §j |
| Y4 moderasyon | ✅ Şikâyet et (3 şikâyette otomatik gizleme), kullanıcı engelle, kendi gönderini sil, kelime filtresi; dış görsel kaldırıldı; topluluk adı sunucudan | migration §d, `topluluk_tab.dart`, `create_post_screen.dart` |
| Y5 okuma kapsamı | ✅ Profil: kendisi + aktif koç/öğrenci + aynı topluluk; gönderi/üyelik yalnızca giriş yapmışlara | migration §c–d |
| Y6 çalışma odası Realtime | ✅ `private: true` kanal + `realtime.messages` üyelik politikası; yayındaki ad gösterilmiyor | migration §k, `study_room_screen.dart` |
| Y7 keystore | ❌ Elle yapılmalı (aşağıda) | — |
| Y8 politika özyinelemesi | ✅ `is_admin()` / `my_role()` SECURITY DEFINER; tüm admin politikaları yenilendi | migration §a |
| O1 `update_post_quality` | ✅ istemciye kapalı, `search_path` sabit | migration §i–j |
| O2 davet kodu | ✅ `gen_random_bytes`, 48 saat geçerlilik, saatte 10 hatalı deneme sınırı | migration §g |
| O3 deneme karşılaştırması | ✅ 5 katılımcı altında sonuç yok, girişler sınırlı | migration §f |
| O4 hesap silmede gönderiler | ✅ siliniyor | migration §h |
| O5 gizlilik politikası | ✅ yeniden yazıldı (18 yaş altı, topluluk, koç, yurt dışı aktarım, saklama süreleri); kayıtta açık rıza + veli onayı kutusu | `assets/legal/privacy_policy.md`, `PRIVACY_POLICY.md`, `privacy_policy.html`, `register_screen.dart` |
| O6 sahte giriş | ✅ Release derlemede Supabase yoksa giriş reddedilir | `auth_service.dart`, `auth_provider.dart` |
| O7 şifre sıfırlama | ✅ E-postadaki 6 haneli kodla uygulama içinde yeni şifre | `sifremi_unuttum_screen.dart` |
| D2 student_data boyutu | ✅ 512 KB sınırı | migration §i |
| D3 ham hata metinleri | ✅ | admin sekmeleri, `supabase_auth_service.dart` |
| D4 Privacy Manifest | ✅ `CA92.1` | `PrivacyInfo.xcprivacy` |
| D5 debug imza yedeği | ✅ key.properties yoksa imzasız çıktı + uyarı | `build.gradle.kts` |
| D8 çıkışta fotoğraf | ✅ siliniyor | `auth_provider.dart` |
| iOS Keychain yeniden kurulum | ✅ temiz kurulumda güvenli depo sıfırlanıyor | `main.dart` |
| FLAG_SECURE | ✅ e-posta doğrulama ve şifre sıfırlama ekranlarına da eklendi | — |

### Sizin yapmanız gerekenler
1. `supabase_migrations/15_guvenlik_sikilastirma.sql` dosyasını SQL Editor'de çalıştırın; ardından dosyadaki kontrol sorgusuyla yetkisiz `admin`/`baskan` hesabı olup olmadığına bakın.
2. Supabase › Realtime › Settings: **"Allow public access"** kapatın.
3. Supabase › Authentication › Email Templates › **Reset Password** şablonuna `{{ .Token }}` ekleyin (kod ile sıfırlama için).
4. Play Console › Uygulama bütünlüğü › **Yükleme anahtarını sıfırla**; yeni keystore'u ve parolasını OneDrive dışında saklayın.
5. Geçiş notu: migration sonrası eski uygulama sürümlerinde çalışma odaları (public kanal) çalışmaz ve hatalı koç kodu "başarılı" görünebilir; kullanıcıları yeni sürüme yönlendirin.

---

## 0. Uyarlama: kontrol.md'den ne çıktı, ne eklendi

LiseNET bir Flutter + Supabase uygulaması; kullanıcıları çoğunlukla **reşit olmayan lise öğrencileri**; kullanıcı içeriği (gönderi, dürtme, çalışma odası) ve bir "yıldız" oyun ekonomisi var. Bu yüzden:

- **Çıkarılanlar (➖):** React Native/Expo, Firebase kuralları, WebView, uygulama içi satın alma (IAP), konum/sensör, OAuth/PKCE, biyometri, yerel SQL (sqflite yok), native iOS/Android özel maddeleri.
- **LiseNET'e özel eklenenler:**
  - **S1** Her Supabase tablosu için RLS + INSERT/UPDATE'te "kilitli alan" kontrolü (role, xp, balance)
  - **S2** `SECURITY DEFINER` RPC'lerin yetki, sınır ve `EXECUTE` izinleri (Supabase `anon`/`authenticated` varsayılan grant'leri)
  - **S3** Yıldız/XP ekonomisinin istemciden şişirilememesi
  - **S4** Supabase Realtime kanallarının yetkilendirmesi (çalışma odası presence/broadcast)
  - **S5** Reşit olmayan kullanıcılara yönelik kullanıcı içeriği (UGC) moderasyonu: şikâyet, engelleme, filtre, dış görsel
  - **S6** Koç–öğrenci veri erişimi (davet kodu gücü, ilişki bitince erişimin kesilmesi)
  - **S7** KVKK: reşit olmayanlar, yurt dışı aktarım (Supabase bölgesi), gizlilik metninin yeni özellikleri kapsaması

---

## 1. ÖNCELİKLİ BULGULAR

### 🔴 KRİTİK

#### K1 — Herkes kendini `admin` yapabilir (profil INSERT'inde rol kilidi yok)
- **Kanıt:** `supabase_schema.sql:75-76`
  ```sql
  CREATE POLICY "profiles_insert_own" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
  ```
  UPDATE politikası `role` ve `xp` alanlarını kilitliyor (satır 82-88), ancak INSERT politikası kilitlemiyor. Profil satırını istemci oluşturuyor (`supabase_auth_service.dart:136-150`, `login()` içinde profil yoksa `_insertProfile`). Profil oluşturan bir `auth.users` tetikleyicisi yok.
- **Saldırı senaryosu:** Anon key APK'dan çıkarılır (zaten public). Saldırgan REST üzerinden kayıt olur, e-postasını doğrular ve uygulamaya **giriş yapmadan önce** şu isteği gönderir:
  `POST /rest/v1/profiles {"id":"<kendi uid>","name":"x","role":"admin","xp":999999}`
  Sonuç: tüm `*_admin_all` politikalarıyla tam yönetici yetkisi. Tüm talepleri/şikâyetleri okur, herkesin rolünü değiştirir, gönderi ve topluluk siler, tüm cüzdanları ve çalışma oturumlarını görür.
- **Düzeltme:** Profil oluşturmayı sunucuya taşıyın ve istemci INSERT'ini kısıtlayın (bkz. §4 SQL, blok 1).

### 🟠 YÜKSEK

#### Y1 — XP sınırsız şişirilebiliyor (önceki "düzeltme" açığı sadece taşımış)
- **Kanıt:** `supabase_schema.sql:149-163`. `award_xp(amount)` her çağrıda 1-1000 XP veriyor; çağrı sayısı, günlük tavan ya da olay kimliği kontrolü yok. İstemci doğrudan çağırıyor: `supabase_data_service.dart:248`.
- **Senaryo:** `for i in 1..1000: rpc('award_xp', {amount:1000})` → 1.000.000 XP.
- **Düzeltme:** XP'yi rozet kimliğine bağlayın. `award_badge_xp(p_badge_id)`: rozet başına bir kez, tutar sunucudaki katalogdan okunur. `award_xp`'nin EXECUTE yetkisini kaldırın (§4 blok 3).

#### Y2 — Yıldız ekonomisi, uygulamanın kullanmadığı RPC'lerle sınırsız doldurulabiliyor
- **Kanıt:**
  - `award_goal_stars` (`:505`): her yeni `p_goal_ref_id` için 20 yıldız veriyor, günlük tavanı yok. Rastgele ref ile sınırsız yıldız.
  - `award_checkin_stars(p_date)` (`:484`): tarih istemciden geliyor. 1900–2100 arasındaki her tarih için 5 yıldız ≈ 365.000 yıldız.
  - `award_pomodoro_stars` (`:452`): süreyi istemci bildiriyor; günde 200 yıldız.
  - Uygulama bu üç RPC'yi **hiç çağırmıyor** (`lib/` içinde grep sonucu 0). Tamamen gereksiz saldırı yüzeyi.
- **Etki:** Bahçe mağazasındaki sunucu taraflı fiyat kontrolü (`buy_garden_item`) anlamını yitiriyor.
- **Düzeltme:** Üçünün de EXECUTE yetkisini kaldırın (ya da silin). Checkin kullanılacaksa `p_date` yerine `CURRENT_DATE` kullanın (§4 blok 3).

#### Y3 — `REVOKE ... FROM PUBLIC` Supabase'de işe yaramıyor; tüm RPC'ler `anon` rolüne de açık
- **Kanıt:** `supabase_schema.sql:448`. Supabase, `public` şemasındaki fonksiyonlara `anon` ve `authenticated` rollerine **ayrıca** EXECUTE yetkisi verir (default privileges). Bu yüzden PUBLIC'ten geri almak `_stars_earned_today(p_user_id, …)` fonksiyonunu kapatmıyor; herkes başka kullanıcıların günlük yıldız toplamını sorgulayabilir. Aynı durum `get_exam_benchmark` için giriş yapmamış (anon) çağrıları da kapsıyor.
- **Düzeltme:** `REVOKE EXECUTE ... FROM anon, authenticated, PUBLIC` ve yalnızca gerekenlere `GRANT ... TO authenticated` (§4 blok 3).

#### Y4 — Reşit olmayanlara açık topluluk akışında moderasyon yok; dış görsel ve kimlik taklidi mümkün
- **Kanıt:**
  - `posts_insert_own` (`:1151`): her kullanıcı gönderi atabiliyor. **Şikâyet et / engelle / içerik filtresi yok** (`topluluk_tab.dart:198-266`). Apple App Store 1.2 ve Google Play UGC politikası bunları zorunlu tutuyor → mağaza reddi riski.
  - `image_url` serbest metin (`create_post_screen.dart:202`) ve `Image.network` ile gösteriliyor (`topluluk_tab.dart:245`). Saldırganın sunucusundaki bir görsel, akışı açan **her öğrencinin IP adresini** o sunucuya sızdırır (takip pikseli). Ayrıca uygunsuz ya da çok büyük görseller yüklenebilir.
  - `community_name` istemciden geliyor (`supabase_data_service.dart:105`) ve kartta yazar adı gibi gösteriliyor (`topluluk_tab.dart:219`). Bir öğrenci "LiseNET Yönetimi" adıyla sahte duyuru ya da oltalama gönderisi paylaşabilir.
- **Düzeltme:** `image_url`'ü kaldırın ya da yalnızca kendi Supabase Storage alan adınıza izin verin. `community_name`/`community_logo` değerlerini bir tetikleyiciyle `communities` tablosundan doldurun. `post_reports` tablosu, "Şikâyet et" menüsü, eşik aşılınca otomatik gizleme ve kullanıcı engelleme ekleyin (§4 blok 4).

#### Y5 — Öğrenci verisi fazla geniş okunabiliyor
- **Kanıt:**
  - `profiles_select_authenticated` (`:74`): giriş yapmış herkes **tüm** profilleri okuyabiliyor (ad, sınıf, alan, XP, rol, foto). Kayıt serbest olduğu için bu pratikte "tüm öğrenci listesini indir" demek.
  - `posts_select_all` ve `community_members_select_all` `USING (true)`: **giriş yapmamış** istemci bile tüm gönderileri, `user_id`'leri ve kimin hangi toplulukta olduğunu okuyabiliyor.
- **Düzeltme:** Profil SELECT'ini kendi satırı + aktif koç/öğrenci + admin ile sınırlayın. Başkalarının adı gerekiyorsa sadece `id, name` döndüren bir view/RPC kullanın. Gönderi ve üyelik SELECT'ini `auth.uid() IS NOT NULL` yapın (§4 blok 2).

#### Y6 — Çalışma odası Realtime kanalı yetkisiz; sahte dürtme ve taciz mesajı gönderilebilir
- **Kanıt:** `study_room_screen.dart:77-118`. Kanal public (`channel('study_room_<id>')`, `private: true` yok). Presence yükünde `user_id` ve `name` var. `nudge` broadcast'ı sunucu doğrulaması olmadan gösteriliyor: `'${payload['from_name']} seni dürttü!'`.
- **Senaryo:** Anon key'e sahip herhangi biri, üye olmadan herhangi bir odaya bağlanır, kimin çevrimiçi olduğunu görür, sahte presence ekler ve istediği metni `from_name` alanına koyarak hedefin ekranına mesaj bastırır.
- **Düzeltme:** Realtime Authorization kullanın: `channel(..., opts: RealtimeChannelConfig(private: true))` ve `realtime.messages` üzerinde üyeliğe bağlı RLS. İstemcide broadcast'teki `from_name`'i göstermeyin; dürtmeyi yalnızca `nudges` tablosundan okuyun (§4 blok 5).

#### Y7 — Yükleme (upload) imza anahtarı zayıf parolalı ve OneDrive'da açıkta
- **Kanıt:** `key.properties` ve `android/key.properties` içinde hâlâ zayıf ve birbirinin aynı parola var (önceki denetimdeki değer). `android/app/upload-keystore.jks` + parola dosyası + `app-release.aab` + `mapping.txt`, bulutla senkronize edilen `OneDrive\Masaüstü` klasöründe duruyor.
- **Düzeltme:** Play Console › Uygulama bütünlüğü › "Yükleme anahtarı sıfırlama" ile yeni bir upload key alın. Keystore'u ve parolayı OneDrive dışında bir yerde (parola yöneticisi / CI secret) tutun. `.gitignore` tek başına OneDrive'ı korumaz.

#### Y8 — `profiles` politikaları kendi tablosunu sorguluyor → "infinite recursion" riski (canlıda doğrulanmalı)
- **Kanıt:** `profiles_admin_all` (`:90-92`) ve `profiles_update_own` WITH CHECK (`:86-87`) `public.profiles` tablosunu alt sorguyla okuyor. Postgres, aynı tablonun SELECT politikalarını yeniden değerlendirir ve genellikle `infinite recursion detected in policy for relation "profiles"` hatası verir. Diğer tüm `*_admin_all` politikaları da `profiles`'a baktığı için hata zincirleme yayılabilir.
- **Anlamı:** Uygulama canlıda sorunsuz çalışıyorsa canlı DB bu dosyadan farklı demektir. O durumda bu denetimin sunucu bulgularını canlıdaki politikalarla karşılaştırmanız gerekir (`select * from pg_policies where schemaname='public';`).
- **Düzeltme:** `SECURITY DEFINER` bir `is_admin()` / `my_role()` fonksiyonu kullanın (§4 blok 1).

### 🟡 ORTA

| # | Bulgu | Kanıt | Düzeltme |
|---|---|---|---|
| O1 | `update_post_quality` giriş yapmış herkesin, her gönderinin puanını sınırsız kez değiştirmesine izin veriyor; `search_path` sabitlenmemiş. Uygulama bu RPC'yi UI'dan çağırmıyor. | `schema:166-177`, `supabase_data_service.dart:123` | EXECUTE'u kaldırın; ileride `(user_id, post_id)` tekil puan tablosu kullanın |
| O2 | Koç davet kodu `md5(random())` ile üretiliyor (kriptografik değil); kodların süresi dolmuyor; `accept_coach_invite`'ta deneme sınırı yok | `schema:610`, `:620-638` | `encode(gen_random_bytes(6),'hex')`, 48 saat geçerlilik, başarısız deneme sayacı |
| O3 | `get_exam_benchmark` yetki kontrolü ve sunucu tarafı minimum katılımcı eşiği içermiyor → 1 katılımcılı denemede o kişinin neti açığa çıkıyor; `submit_exam_result` doğru/yanlış için üst sınır koymuyor (ortalamalar zehirlenebilir) | `schema:854-864`, `:832-848` | `HAVING COUNT(*) >= 5`, `auth.uid()` kontrolü, `dogru+yanlis+bos <= 120` |
| O4 | Hesap silinince gönderiler kalıyor (`posts.user_id ON DELETE SET NULL`) → KVKK "silme hakkı" eksik uygulanıyor | `schema:41` | `delete_account` içinde `DELETE FROM posts WHERE user_id = v_user_id` |
| O5 | Gizlilik politikası yeni özellikleri anlatmıyor: topluluk gönderileri, üyelik, dürtme, çalışma odası presence, koçun öğrenci verisini görmesi, anonim deneme karşılaştırması. Ayrıca 18 yaş altı / veli onayı, saklama süreleri, Supabase sunucu konumu (yurt dışı aktarım, KVKK m.9) yok | `PRIVACY_POLICY.md` | Metni güncelleyin; kayıt ekranında 18 yaş altı için veli onayı beyanı ekleyin |
| O6 | Supabase yapılandırılmamışsa `signIn`/`signUp`/`verifyOtp` sahte `success:true` dönüyor. `build_release.ps1` bunu engelliyor ama doğrudan `flutter build` ile alınan bir release'de sahte giriş mümkün | `auth_service.dart:55-62, 97-104, 148-154` | `if (kReleaseMode && _supabase == null) return AuthResult(success:false, …)` |
| O7 | Şifre sıfırlama tamamlanamıyor olabilir: `resetPasswordForEmail` `redirectTo` olmadan çağrılıyor; uygulamada deep link ya da `updateUser(password)` ekranı yok. Uygulama içi şifre değiştirme de yok | `sifremi_unuttum_screen.dart:35` | OTP tabanlı recovery (`verifyOTP(type: recovery)` + `updateUser`) ya da Supabase Site URL'de bir web sayfası. ❓ Supabase panelindeki Site URL kontrol edilmeli |

### 🟢 DÜŞÜK

- **D1** Bahçe envanteri (`envanter`, `dekorlar`, `saksilar`) istemcinin yazabildiği `student_data` tablosunda (`bahce_provider.dart:201`). Yıldız harcamadan ürün eklenebilir. Etkisi yalnızca kişinin kendi bahçesi.
- **D2** `student_data.data_value` JSONB için boyut sınırı yok → depolama kötüye kullanımı. `CHECK (pg_column_size(data_value) < 256000)` eklenebilir.
- **D3** Kullanıcıya ham hata metni gösteriliyor: `supabase_auth_service.dart:207`, `admin_users_tab.dart:57,113,133`, `admin_tickets_tab.dart:118`, `AuthService` içinde `e.message` aynen aktarılıyor.
- **D4** `PrivacyInfo.xcprivacy`: UserDefaults gerekçe kodu `1C8F.1` (App Group içindir). Tek uygulama için doğrusu `CA92.1`.
- **D5** `key.properties` yoksa release build **debug anahtarıyla** imzalanıyor (`build.gradle.kts:65-69`). Sessizce yanlış imza yerine build'in hata vermesi daha güvenli.
- **D6** `lint { checkReleaseBuilds = false; abortOnError = false }` (`build.gradle.kts:22-25`).
- **D7** Bağımlılıklar: `flutter_secure_storage` 11.0.0 → 11.2.0 aynı sürüm aralığında yükseltilebilir; `flutter_local_notifications` 19 → 22. Bilinen CVE taraması yapılmadı; `osv-scanner --lockfile=pubspec.lock` önerilir.
- **D8** Seçilen özel arka plan fotoğrafı ve `ortam` ayarı logout'ta silinmiyor (isim alanı dışında). Paylaşılan cihazda bir sonraki kullanıcı görebilir.

---

## 2. BÖLÜM BÖLÜM KONTROL LİSTESİ (LiseNET'e uyarlanmış)

### 1. Gizli Bilgi ve Anahtar Yönetimi
| Madde | Durum | Kanıt |
|---|---|---|
| Kodda gömülü secret yok | ✅ | `main.dart:41-42` `String.fromEnvironment`; `lib/` içinde tek dış URL örnek metin |
| Ücretli 3. taraf API proxy | ➖ | Dış API yok ("Yapay zeka koçu" yerel algoritma) |
| `--dart-define` değerlerinde gerçek secret yok | ✅ | Yalnızca URL ve anon key (zaten public olabilir) |
| `service_role` anahtarı uygulamada yok | ✅ | Grep: 0 |
| `.gitignore`: key.properties, jks, aab, mapping, symbols | ✅ | `.gitignore` |
| Git geçmişinde secret | ❓ | Git deposu yok |
| Keystore güçlü parolalı ve güvenli yerde | ❌ | **Y7** |
| Staging/iç URL release'de yok | ✅ | |

### 2. Yerel Veri Depolama
| Madde | Durum | Kanıt |
|---|---|---|
| Oturum token'ı güvenli depoda | ✅ | `SecureSupabaseLocalStorage` → `main.dart:52-54` |
| Keychain erişim seviyesi | ✅ | `first_unlock_this_device` (`storage_service.dart:145`) |
| `allowBackup=false` | ✅ | `AndroidManifest.xml:11` |
| Logout'ta temizlik | ⚠️ | Kullanıcı verisi, secure storage ve önbellek temizleniyor; özel fotoğraf kalıyor (**D8**) |
| iOS yeniden kurulumda Keychain'de eski oturum | ⚠️ | Keychain silinmez; ilk açılışta "first run" bayrağıyla `deleteAll()` önerilir |
| Harici depolamaya yazma | ✅ | Yalnızca `getApplicationDocumentsDirectory` |

### 3. Kriptografi
| Madde | Durum | Kanıt |
|---|---|---|
| Kendi yazılmış şifreleme yok | ✅ | |
| Güvenlik amaçlı rastgele değerler CSPRNG ile | ❌ | Davet kodu `md5(random())` (**O2**). İstemcideki `Random()` kullanımları oyun/UI için, sorun yok |
| Parola hash'i | ✅ | Supabase Auth (bcrypt) |

### 4. Kimlik Doğrulama ve Oturum
| Madde | Durum | Kanıt |
|---|---|---|
| Doğrulama sunucuda | ⚠️ | Supabase Auth; ancak offline fallback (**O6**) |
| Logout sunucuda oturumu kapatıyor | ✅ | `auth.signOut()` |
| Min. 8 karakter şifre | ⚠️ | İstemcide kontrol var; Supabase panelinde "Minimum password length" ayarı ❓ |
| Brute-force / rate limit | ✅ | Supabase Auth rate limit; hata doğru eşleniyor |
| Hata mesajı kullanıcı varlığını sızdırmıyor | ⚠️ | Login jenerik; kayıtta "zaten kayıtlı" mesajı var |
| Şifre sıfırlama uçtan uca | ⚠️ | **O7** |
| Rol/yetki istemci bayrağına bağlı değil | ❌ | Sunucuda INSERT açığı (**K1**) |

### 5. Yetkilendirme ve Backend (Supabase) — en kritik bölüm
| Madde | Durum | Kanıt |
|---|---|---|
| 17/17 tabloda RLS etkin | ✅ | profiles, communities, posts, user_tickets, koc_tasks, student_data, curricula, subjects, topics, wallets, star_transactions, coach_students, study_sessions, exam_results, community_members, nudges, garden_items |
| Kullanıcı rolünü/XP'sini değiştiremiyor (mass assignment) | ❌ | UPDATE'te kilitli, **INSERT'te açık (K1)** |
| Bakiye/puan sunucuda hesaplanıyor | ⚠️ | `buy_garden_item` ve `complete_study_session` örnek iyi tasarım ✅; ancak `award_xp` ve yıldız RPC'leri açık (**Y1, Y2**) |
| SECURITY DEFINER fonksiyonlarda `search_path` sabit | ⚠️ | `update_post_quality` hariç hepsinde var |
| RPC EXECUTE izinleri en az yetki ilkesine uygun | ❌ | **Y3** |
| IDOR: `auth.uid()` kontrolleri | ✅ | Tüm sahiplik politikaları ve RPC'ler tutarlı |
| Okuma kapsamı (veri minimizasyonu) | ❌ | **Y5** |
| Koç yalnızca aktif ilişkideki öğrenciyi görüyor | ✅ | `coach_students` + `status='active'` politikaları; `_koc_tasks_student_guard` tetikleyicisi |
| Sunucu tarafı rate limit | ⚠️ | Gönderi (saatte 5) ve dürtme (saatte 1) var; davet kabulü ve RPC'lerde yok |
| Politika özyinelemesi | ❓ | **Y8** — canlıda doğrulanmalı |
| Dosya yükleme / Storage | ➖ | Storage kullanılmıyor (fotoğraf yalnızca cihazda) |

### 6. Ağ Güvenliği
| Madde | Durum | Kanıt |
|---|---|---|
| Yalnızca HTTPS/WSS | ✅ | `usesCleartextTraffic=false`; iOS ATS varsayılan |
| SSL doğrulamasını kapatan kod yok | ✅ | Grep: 0 |
| İstek zaman aşımı | ✅ | `TimeoutHttpClient` 15 sn |
| Sertifika pinning | ❌ (bilinçli) | Supabase için düşük öncelik; kabul edilebilir risk |
| Dış görsel yükleme | ❌ | **Y4** (`Image.network` ile kullanıcıdan gelen URL) |
| Realtime kanal yetkilendirmesi | ❌ | **Y6** |

### 7. Platform Etkileşimi
| Madde | Durum | Kanıt |
|---|---|---|
| Gereksiz exported bileşen yok | ✅ | Yalnızca launcher activity; boot receiver `exported=false` |
| Deep link saldırı yüzeyi | ✅ | Custom scheme veya App Link yok |
| FLAG_SECURE hassas ekranlarda | ⚠️ | Login/kayıtta var; e-posta doğrulama ve şifre sıfırlama ekranlarında yok |
| İzinler minimum | ✅ | Android: INTERNET, NETWORK_STATE, POST_NOTIFICATIONS, BOOT; iOS: yalnızca Fotoğraf (Photo Picker, gerekçeli) |
| WebView | ➖ | |

### 8. Kod Düzeyi
| Madde | Durum | Kanıt |
|---|---|---|
| SQL injection | ✅ | PostgREST parametreli; `ilike` değeri parametre olarak gidiyor |
| Path traversal | ✅ | Dosya yolu sunucudan değil, uygulama tarafından üretiliyor |
| İstemci saatine güven | ⚠️ | Yıldız sunucu saatiyle ✅; streak/SM-2 cihaz saatiyle (yalnızca kişisel, düşük risk) |

### 9. Tersine Mühendislik
| Madde | Durum | Kanıt |
|---|---|---|
| R8 + shrinkResources | ✅ | `build.gradle.kts:56-57` |
| `--obfuscate --split-debug-info` | ✅ | `build_release.ps1` |
| Release'de log | ✅ | Tüm `debugPrint` çağrıları `kDebugMode` ile sarılı |
| Play Integrity / App Attest | ❌ | Ekonomi RPC'leri korunacaksa değerlendirilebilir; asıl önlem sunucu kuralları (**Y1/Y2**) |

### 10. Ödeme — ➖ Gerçek para yok. Sanal yıldız ekonomisi **S3** olarak Bölüm 5'te denetlendi.

### 11. Bağımlılıklar
| Madde | Durum | Kanıt |
|---|---|---|
| Paketler resmi ve bilinen | ✅ | 18 doğrudan bağımlılığın tamamı pub.dev'de yaygın |
| Kullanılmayan paket | ⚠️ | `audioplayers` tekrar eklenmiş; kullanımı `ambiyans_service.dart` üzerinden doğrulanmalı |
| Güncellik / CVE | ⚠️ | **D7**; CVE taraması yapılmadı |
| Lock dosyası | ✅ | `pubspec.lock` mevcut |

### 12. Gizlilik ve KVKK
| Madde | Durum | Kanıt |
|---|---|---|
| Aydınlatma metni uygulama içinde | ✅ | `/gizlilik-politikasi` her oturum durumunda erişilebilir |
| Metin tüm veri işlemeyi kapsıyor | ❌ | **O5** |
| Reşit olmayanlar / veli onayı | ❌ | **O5** |
| Silme hakkı eksiksiz | ⚠️ | RPC bağlı ✅; gönderiler kalıyor (**O4**) |
| Yurt dışı aktarım (Supabase bölgesi) | ❓ | Metinde yok; panelden bölge kontrol edilmeli |
| Analitik/crash SDK onayı | ➖ | SDK yok |

### 13. Mağaza Gereksinimleri
| Madde | Durum | Kanıt |
|---|---|---|
| Uygulama içi hesap silme | ✅ | `profil_sos_tab.dart:44`, `koc_profil_tab.dart:65` |
| UGC: şikâyet, engelleme, filtre (Apple 1.2 / Play UGC) | ❌ | **Y4** — yeni ve en olası ret sebebi |
| Privacy Manifest | ⚠️ | Var; gerekçe kodu **D4**; "OtherUserContent" beyanı doğru |
| Play Veri Güvenliği formu | ❓ | Gönderi, topluluk ve presence verileri artık beyan edilmeli |
| Hedef kitle / aile politikası | ❓ | 13-17 yaş hedefleniyorsa Play "Hedef kitle ve içerik" beyanı ile UGC gereksinimleri birlikte ele alınmalı |

### 33. Yapay Zekâ Üretimi Koda Özgü
- ⚠️ "Güvenlik önlemi varsayılan olarak var mı": önceki denetimin XP düzeltmesi açığı ortadan kaldırmadı, yalnızca RPC'ye taşıdı (**Y1**). Yorumlarda "hile yapılamaz" denen yıldız sisteminin yanında sınırsız veren RPC'ler duruyor (**Y2**). Kod yorumları güvenlik garantisi olarak alınmamalı.
- ⚠️ Şema dosyası "tek seferlik migration" blokları biriktiriyor; canlı DB ile uyumu belirsiz (**Y8**).

### 34. Flutter Hızlı Kontroller
✅ obfuscate · ✅ `kDebugMode` · ✅ `badCertificateCallback` yok · ✅ controller/stream dispose (study room kanalı kontrol edildi)

---

## 3. Düzeltme Sırası (önerilen)

1. **Bugün:** K1 (§4 blok 1) + Y3 ve Y2 (§4 blok 3). SQL Editor'de 10 dakikalık iş, istemci değişikliği gerektirmez (`award_xp` dışında).
2. **Bu hafta:** Y1 (rozet bazlı XP), Y5 (okuma kapsamı), Y8 (canlı politikaları karşılaştırma), Y7 (upload key sıfırlama).
3. **Mağaza gönderiminden önce:** Y4 (şikâyet/engelle, `image_url`), Y6 (private kanal), O5 (gizlilik metni + veli onayı), O7 (şifre sıfırlama).
4. **Sonra:** Orta ve düşük maddeler.

---

## 4. Hazır SQL (uygulanmadı — önce staging'de deneyin)

```sql
-- ── Blok 1: K1 + Y8 — rol yardımcıları ve güvenli profil oluşturma ──
CREATE OR REPLACE FUNCTION public.my_role() RETURNS TEXT
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS
$$ SELECT role FROM public.profiles WHERE id = auth.uid() $$;

CREATE OR REPLACE FUNCTION public.is_admin() RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS
$$ SELECT COALESCE(public.my_role() = 'admin', false) $$;

DROP POLICY IF EXISTS "profiles_insert_own" ON public.profiles;
CREATE POLICY "profiles_insert_own" ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id AND role = 'student' AND xp = 0);

DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
CREATE POLICY "profiles_update_own" ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id
              AND role = public.my_role()
              AND xp = (SELECT xp FROM public.profiles WHERE id = auth.uid()));
-- Not: xp alt sorgusu da özyineleme riski taşıyorsa bir BEFORE UPDATE tetikleyicisiyle
-- (NEW.xp := OLD.xp; NEW.role := OLD.role; — admin değilse) değiştirin.

DROP POLICY IF EXISTS "profiles_admin_all" ON public.profiles;
CREATE POLICY "profiles_admin_all" ON public.profiles FOR ALL
  USING (public.is_admin()) WITH CHECK (public.is_admin());
-- Diğer tablolardaki "EXISTS (SELECT 1 FROM profiles ... 'admin')" ifadeleri de public.is_admin() ile değiştirilmeli.

-- Profili sunucu oluştursun (istemci _insertProfile yalnızca name/grade günceller)
CREATE OR REPLACE FUNCTION public.handle_new_user() RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.profiles (id, name, role, xp)
  VALUES (NEW.id, split_part(NEW.email, '@', 1), 'student', 0)
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Mevcut yetkisiz adminleri kontrol edin:
-- SELECT id, name, role, created_at FROM public.profiles WHERE role IN ('admin','baskan','coach');

-- ── Blok 2: Y5 — okuma kapsamı ──
DROP POLICY IF EXISTS "posts_select_all" ON public.posts;
CREATE POLICY "posts_select_auth" ON public.posts FOR SELECT USING (auth.uid() IS NOT NULL);
DROP POLICY IF EXISTS "community_members_select_all" ON public.community_members;
CREATE POLICY "community_members_select_auth" ON public.community_members FOR SELECT USING (auth.uid() IS NOT NULL);
-- profiles: kendi satırı + admin + aktif koç/öğrenci
DROP POLICY IF EXISTS "profiles_select_authenticated" ON public.profiles;
CREATE POLICY "profiles_select_scoped" ON public.profiles FOR SELECT USING (
  auth.uid() = id OR public.is_admin() OR EXISTS (
    SELECT 1 FROM public.coach_students cs WHERE cs.status = 'active'
      AND ((cs.coach_id = auth.uid() AND cs.student_id = profiles.id)
        OR (cs.student_id = auth.uid() AND cs.coach_id = profiles.id))));
-- Dürtme listesindeki isim join'i için ayrı, yalnızca (id, name) döndüren bir RPC gerekir.

-- ── Blok 3: Y1/Y2/Y3/O1 — fonksiyon yetkileri ──
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM anon, PUBLIC;
REVOKE EXECUTE ON FUNCTION public._stars_earned_today(UUID, TEXT) FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.award_goal_stars(TEXT, INTEGER)     FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.award_checkin_stars(DATE)           FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.award_pomodoro_stars(TEXT, INTEGER) FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.update_post_quality(BIGINT, REAL)   FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.award_xp(INT)                       FROM authenticated; -- rozet RPC'si yazılınca
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE EXECUTE ON FUNCTIONS FROM anon, PUBLIC;
-- Kontrol: SELECT routine_name, grantee FROM information_schema.routine_privileges
--          WHERE routine_schema='public' ORDER BY 1;

-- ── Blok 4: Y4 — gönderi kimlik taklidi ve dış görsel ──
CREATE OR REPLACE FUNCTION public._posts_fill_community() RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  SELECT name, logo_path INTO NEW.community_name, NEW.community_logo
    FROM public.communities WHERE id = NEW.community_id;
  NEW.community_name := COALESCE(NEW.community_name, 'LiseNET Topluluğu');
  NEW.image_url := NULL;  -- ya da kendi Storage alan adınızla sınırlayın
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS trg_posts_fill_community ON public.posts;
CREATE TRIGGER trg_posts_fill_community BEFORE INSERT ON public.posts
FOR EACH ROW EXECUTE FUNCTION public._posts_fill_community();
-- + post_reports(post_id, reporter_id, reason, UNIQUE(post_id, reporter_id)) ve
--   3 şikâyette otomatik gizleme; user_blocks(blocker_id, blocked_id).

-- ── Blok 5: Y6 — Realtime yetkilendirme (Supabase Realtime Authorization) ──
-- İstemci: channel('study_room_$id', opts: const RealtimeChannelConfig(private: true))
CREATE POLICY "study_room_members_read" ON realtime.messages FOR SELECT TO authenticated USING (
  realtime.topic() LIKE 'study_room_%' AND EXISTS (
    SELECT 1 FROM public.community_members cm
     WHERE cm.user_id = auth.uid()
       AND cm.community_id = substring(realtime.topic() FROM 'study_room_(\d+)')::BIGINT));
CREATE POLICY "study_room_members_write" ON realtime.messages FOR INSERT TO authenticated WITH CHECK (
  realtime.topic() LIKE 'study_room_%' AND EXISTS (
    SELECT 1 FROM public.community_members cm
     WHERE cm.user_id = auth.uid()
       AND cm.community_id = substring(realtime.topic() FROM 'study_room_(\d+)')::BIGINT));
-- Supabase panelinde Realtime › Settings › "Allow public access" kapatılmalı.

-- ── O4 — hesap silmede gönderiler ──
-- delete_account() içine, DELETE FROM auth.users satırından önce:
--   DELETE FROM public.posts WHERE user_id = v_user_id;
```

---

## 5. Önceki denetimden (2026-09-27) doğrulananlar

| Önceki düzeltme | Bugünkü durum |
|---|---|
| Hesap silme RPC'ye bağlandı | ✅ İki ekranda da doğrulandı |
| `xp` UPDATE kilidi | ⚠️ UPDATE kilitli, ama INSERT (K1) ve `award_xp` (Y1) üzerinden hâlâ şişirilebiliyor |
| Secure session storage | ✅ |
| Logout temizliği | ✅ (D8 hariç) |
| 15 sn timeout | ✅ |
| Gizlilik politikası ekranı | ✅ (metin güncel değil: O5) |
| Şifre sıfırlama | ⚠️ E-posta gidiyor, tamamlama akışı belirsiz (O7) |
| Privacy Manifest | ⚠️ D4 |
| Obfuscation | ✅ |
| FLAG_SECURE | ✅ login/kayıt |
| `kDebugMode` sarmalama | ✅ |
| Keystore parolası | ❌ Değişmemiş (Y7) |
