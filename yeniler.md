LiseNET — Sistem Mimarisi, Kullanıcı, İçerik ve Yetkilendirme Rehberi

Bu doküman, **LiseNET** uygulamasında yer alan **Giriş, Kayıt Olma, Hesap Oluşturma/Profil Yönetimi, Talep/Şikayet Oluşturma, Gönderi Paylaşımı, Admin Paneli ve Yetki Yükseltme (Rol Yönetimi)** sistemlerinin teknik mimarisini, veri tabanı şemasını, güvenlik kurallarını ve kaynak kod yapılarını detaylandırmak üzere hazırlanmıştır.

LiseNET platformunda tüm kullanıcılar standart e-posta adresleri (normal e-posta) ile kayıt olabilir ve giriş yapabilirler.

---

## 📋 İÇİNDEKİLER

1. 🌐 [Teknoloji Yığını ve Genel Mimari Tasarım](#1-teknoloji-yığını-ve-genel-mimari-tasarım)
2. 🔑 [Giriş Sistemi (Login System)](#2-giriş-sistemi-login-system)
3. 📝 [Kayıt Olma Sistemi (Registration System)](#3-kayıt-olma-sistemi-registration-system)
4. 👤 [Hesap Oluşturma & Profil Yaşam Döngüsü (Account & Profile Lifecycle)](#4-hesap-oluşturma--profil-yaşam-döngüsü-account--profile-lifecycle)
5. 📩 [Talep, Şikayet ve Öneri Sistemi (Ticket System)](#5-talep-şikayet-ve-öneri-sistemi-ticket-system)
6. 📰 [Gönderi Paylaşımı ve Medya Yönetimi (Post & Media Architecture)](#6-gönderi-paylaşımı-ve-medya-yönetimi-post--media-architecture)
7. 🛡️ [Admin Paneli Sistemi (Admin Dashboard System)](#7-admin-paneli-sistemi-admin-dashboard-system)
8. 👑 [Yetki Yükseltme ve Rol Yönetimi (Privilege Elevation & Role Management)](#8-yetki-yükseltme-ve-rol-yönetimi-privilege-elevation--role-management)
9. ⚡ [SQL Veri Tabanı Şeması, RLS ve Fonksiyonlar (Database Reference)](#9-sql-veri-tabanı-şeması-rls-ve-fonksiyonlar-database-reference)
10. 🚀 [LiseNET Üzerinde Bu Yapıyı Kurma Adımları](#10-lisenet-üzerinde-bu-yapıyı-kurma-adımları)

---

## 1. 🌐 Teknoloji Yığını ve Genel Mimari Tasarım

Sistem, istemci tarafta **Flutter (Dart)**, arka planda ise **Supabase (PostgreSQL + Auth + Storage + Realtime + Edge Functions)** kullanılarak inşa edilmiştir.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        FLUTTER MOBİL İSTEMCİ                          │
│                                                                        │
│  [Screens / Views] ──► [AuthGate / Route Guard] ──► [Theme / UI]       │
│          │                                                │            │
│          ▼                                                ▼            │
│  [SupabaseAuthService]                       [SupabaseDataService]     │
│          │                                                │            │
│          ▼                                                ▼            │
│  [LocalStorageService] ◄── (Offline Cache) ──► [Memory / SharedPreferences]
└──────────┬────────────────────────────────────────────────┬────────────┘
           │                                                │
           │ HTTPS / WSS API                                │ RLS Policy & SQL
           ▼                                                ▼
┌────────────────────────────────────────────────────────────────────────┐
│                          SUPABASE BACKEND                              │
│                                                                        │
│  ┌───────────────────────┐             ┌────────────────────────────┐  │
│  │ Supabase Auth         │             │ PostgreSQL Database        │  │
│  │  - auth.users         │             │  - public.profiles         │  │
│  │  - JWT & Sessions     │ ──────────► │  - public.user_tickets     │  │
│  └───────────────────────┘             │  - public.posts            │  │
│  ┌───────────────────────┐             │  - public.communities      │  │
│  │ Supabase Storage      │             │  - public.notifications    │  │
│  │  - Post & User Media  │             └────────────────────────────┘  │
│  └───────────────────────┘             ┌────────────────────────────┐  │
│  ┌───────────────────────┐             │ Postgres Triggers & RPCs   │  │
│  │ Realtime Engine       │             │  - validate_email_format() │  │
│  │  - Post/Chat sockets  │             │  - delete_account() RPC    │  │
│  └───────────────────────┘             └────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────┘
```

### Temel Mimarinin Karakteristik Özellikleri

- **Katmanlı Servis Yapısı**: İstemcide iş mantığı UI'dan tamamen soyutlanmış, `SupabaseAuthService` ve `SupabaseDataService` sınıflarına devredilmiştir.
- **Güvenli Kimlik Doğrulama**: Supabase Auth (JWT bazlı) kullanır. Standard e-posta (normal mail) adresi doğrulaması desteklenir. `AuthUser` modeli istemcide genişletilerek `profiles` tablosundaki rollerle harmanlanır.
- **Çevrimdışı Çalışabilirlik**: Akıllı önbellek mekanizması (`LocalStorageService`) ile internet kesintilerinde bile kullanıcı profili ve veriler gösterilmeye devam eder.
- **Row Level Security (RLS)**: Veri güvenliği sunucu tarafında (PostgreSQL) Row Level Security politikaları ile garanti altına alınmıştır.

---

## 2. 🔑 Giriş Sistemi (Login System)

Giriş yapısı, standart kullanıcı e-posta doğrulaması, hata yönetimi ve çevrimdışı oturum durumlarının yönetilmesini kapsar.

### 2.1 İş Akışı (Flow Diagram)

1. **Form Girişi**: Kullanıcı e-posta (standart e-posta adresi) ve şifresini girer.
2. **Ön Doğrulama (Client-side Validation)**:
   - E-posta boş mu / formatı uygun mu? (Standard regex validation: `name@domain.com`)
3. **Supabase Auth Sorgusu**: `Supabase.instance.client.auth.signInWithPassword(...)` çağrılır.
4. **Profil Eşleştirme**: `auth.users.id` ile `public.profiles` tablosundan rol, ad-soyad ve okul/sınıf bilgisi çekilir.
5. **Önbelleğe Alma**: Oturum açan kullanıcı nesnesi (`AuthUser`) yerel hafızaya kaydedilir (`LocalStorageService`).
6. **Yönlendirme**: Giriş başarılı olduğunda ana ekrana geçiş yapılır.

### 2.2 İstemci Kod Mantığı (`lib/core/services/supabase_auth_service.dart`)

```dart
static Future<AuthUser> login({
  required String email,
  required String password,
}) async {
  try {
    _validateStandardEmail(email); // Standard e-posta format kontrolü
    
    final res = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (res.user == null) {
      throw const SupabaseAuthException('E-posta veya şifre hatalı.');
    }

    // Profil tablosundan rol ve ek verileri çek
    final profile = await _client
        .from('profiles')
        .select()
        .eq('id', res.user!.id)
        .maybeSingle();

    final AuthUser authUser;
    if (profile == null) {
      // Doğrulama sonrasında ilk girişse profil otomatik oluşturulur
      await _insertProfile(
        userId: res.user!.id,
        name: res.user!.email?.split('@').first ?? 'Kullanıcı',
      );
      final newProfile = await _client
          .from('profiles')
          .select()
          .eq('id', res.user!.id)
          .single();
      authUser = AuthUser.fromProfileJson(res.user!, newProfile);
    } else {
      authUser = AuthUser.fromProfileJson(res.user!, profile);
    }
    
    await _cacheAuthUser(authUser); // Çevrimdışı erişim için önbellekle
    return authUser;
  } on SupabaseAuthException {
    rethrow;
  } catch (e) {
    throw SupabaseAuthException(_mapError(e));
  }
}
```

---

## 3. 📝 Kayıt Olma Sistemi (Registration System)

LiseNET kayıt sistemi, standart e-posta adresleriyle (Gmail, Hotmail, Outlook vb.) güvenli kayıt olmayı destekler.

### 3.1 E-posta ve Şifre Kuralları

- **E-posta Kısıtı**: Standart e-posta formatı (`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`) doğrulanır. Herhangi bir özel okul domain kısıtlaması yoktur.
- **Şifre Politikası**:
  - En az 6-8 karakter uzunluğunda olmalı.
- **Profil Bilgileri**: İsim, sınıf (9, 10, 11, 12, Mezun), alan (Sayısal, Eşit Ağırlık, Sözel, Dil).

### 3.2 İstemci Kod Mantığı (`lib/core/services/supabase_auth_service.dart`)

```dart
static Future<AuthUser> register({
  required String name,
  required String email,
  required String password,
  String? grade,
  String? department,
}) async {
  try {
    _validateStandardEmail(email);
    _validatePassword(password);

    // 1. Supabase Auth Kullanıcısı Oluştur
    final res = await _client.auth.signUp(email: email, password: password);

    if (res.user == null) {
      throw const SupabaseAuthException('Kayıt başarısız. Lütfen tekrar deneyin.');
    }

    // 2. Oturum açıldıysa profili oluştur
    if (res.session != null) {
      await _insertProfile(
        userId: res.user!.id,
        name: name,
        grade: grade,
        department: department,
      );
    } else {
      // E-posta doğrulama aktif ise kullanıcı bilgilendirilir
      throw const SupabaseAuthException(
        'Kayıt başarılı! E-posta adresinize doğrulama bağlantısı gönderildi. '
        'Lütfen e-postanızı doğruladıktan sonra giriş yapın.',
      );
    }

    return AuthUser(
      id: res.user!.id,
      name: name,
      email: email,
      grade: grade,
      department: department,
      isAdmin: false,
      createdAt: DateTime.now(),
    );
  } catch (e) {
    throw SupabaseAuthException(_mapError(e));
  }
}
```

---

## 4. 👤 Hesap Oluşturma & Profil Yaşam Döngüsü (Account & Profile Lifecycle)

Hesap mimarisi, PostgreSQL üzerindeki `auth.users` ile `public.profiles` tablolarının `1:1` ilişkisine dayanır.

### 4.1 Veri Tabanı Şeması (`public.profiles`)

```sql
CREATE TABLE IF NOT EXISTS public.profiles (
  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  role          TEXT NOT NULL DEFAULT 'student', -- 'student' | 'baskan' | 'admin'
  department    TEXT[],                          -- Alan seçimi (Sayısal, EA, Sözel, Dil)
  grade         TEXT,                            -- Sınıf (9, 10, 11, 12, Mezun)
  xp            INTEGER NOT NULL DEFAULT 0,
  profile_photo TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 4.2 Sunucu Taraflı E-posta Kontrol Trigger'ı

E-posta formatının geçerli olduğunu doğrulayan varsayılan PostgreSQL regex kontrolü:

```sql
CREATE OR REPLACE FUNCTION public.validate_email_format()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NEW.id IS NOT NULL THEN
    PERFORM email FROM auth.users WHERE id = NEW.id AND (
      email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
    );
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Geçersiz e-posta adresi formatı.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER profiles_validate_email_format
  BEFORE INSERT OR UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.validate_email_format();
```

### 4.3 App Store / Google Play Uyumlu Hesap Silme (Account Deletion)

Kullanıcıların uygulama içerisinden hesaplarını tamamen silebilmesi için `delete_account` RPC fonksiyonu kullanılır.

**Postgres RPC Fonksiyonu (`delete_account`)**:

```sql
CREATE OR REPLACE FUNCTION public.delete_account()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  -- 1. Profil silinir (Foreign Key CASCADE sayesinde ilişkili gönderi, talep vb. silinir)
  DELETE FROM public.profiles WHERE id = v_user_id;

  -- 2. Auth kullanıcısı silinir
  PERFORM auth.admin.delete_user(v_user_id);
END;
$$;
```

---

## 5. 📩 Talep, Şikayet ve Öneri Sistemi (Ticket System)

Kullanıcıların LiseNET yönetimine talep, şikayet ve öneri iletmesini sağlayan destek sistemidir.

### 5.1 Veri Yapısı (`public.user_tickets`)

- **Türler (`type`)**: `complaint` (Şikayet), `request` (Talep), `suggestion` (Öneri)
- **Durumlar (`status`)**: `open` (Açık), `in_progress` (İşlemde), `resolved` (Çözüldü), `closed` (Kapalı)

### 5.2 SQL Şeması ve RLS Politikaları

```sql
CREATE TABLE IF NOT EXISTS public.user_tickets (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type        TEXT NOT NULL CHECK (type IN ('complaint', 'request', 'suggestion')),
  subject     TEXT NOT NULL,
  description TEXT NOT NULL,
  status      TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
  admin_notes TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.user_tickets ENABLE ROW LEVEL SECURITY;

-- Kullanıcı sadece kendi taleplerini görebilir ve oluşturabilir
CREATE POLICY "tickets_select_own" ON public.user_tickets FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "tickets_insert_own" ON public.user_tickets FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Admin tüm talepleri listeleyebilir ve durum/not güncelleyebilir
CREATE POLICY "tickets_admin_all" ON public.user_tickets FOR ALL
  USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'));
```

### 5.3 Talep Oluşturma Servisi (`SupabaseDataService`)

```dart
Future<void> createTicket({
  required String type,
  required String subject,
  required String description,
}) async {
  final uid = _uid;
  if (!UserTicket.validTypes.contains(type)) {
    throw ArgumentError('Geçersiz talep türü: $type');
  }
  await _db.from('user_tickets').insert({
    'user_id': uid,
    'type': type,
    'subject': subject.trim(),
    'description': description.trim(),
    'status': 'open',
  });
}
```

---

## 6. 📰 Gönderi Paylaşımı ve Medya Yönetimi (Post & Media Architecture)

Gönderi sistemi, toplulukların ve liderlerin duyuru, çalışma materyali ve sosyal içerik paylaşmasını sağlar.

### 6.1 Yetkilendirme Kuralları

- **Admin**: Tüm topluluklar/gruplar adına gönderi paylaşabilir, düzenleyebilir ve silebilir.
- **Topluluk Başkanı (`role = 'baskan'`)**: Yalnızca temsil ettiği grup/topluluk adına gönderi paylaşabilir.
- **Öğrenci (`role = 'student'`)**: Gönderileri okuyabilir, beğenebilir ve destek verebilir; yetkisi yoksa doğrudan gönderi yayınlayamaz.

### 6.2 Medya Yükleme Mimarisi

Görsel paylaşımı iki yolla desteklenir:

1. **Galeriden Seçim**: `ImagePicker` ile seçilen dosya `uploadPostImage()` servisiyle Supabase Storage `posts` bucket'ına yüklenir.
2. **Harici URL**: Kullanıcı doğrudan bir HTTP/HTTPS imaj adresi girebilir.

### 6.3 Gönderi Kalite Derecelendirmesi (RPC)

PostgreSQL RPC fonksiyonu ile puanlama atomik olarak yapılır:

```sql
CREATE OR REPLACE FUNCTION public.update_post_quality(post_id BIGINT, new_score REAL)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  IF new_score < 0 OR new_score > 5 THEN
    RAISE EXCEPTION 'Invalid score: must be between 0 and 5';
  END IF;
  UPDATE public.posts
  SET quality_score = (quality_score + new_score) / 2.0
  WHERE id = post_id;
END;
$$;
```

---

## 7. 🛡️ Admin Paneli Sistemi (Admin Dashboard System)

Admin paneli, tüm LiseNET bileşenlerinin yönetildiği merkezi kontrol panelidir.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        LISENET ADMIN PANELİ SEKMELERİ                 │
├─────────────┬──────────────┬──────────────────┬──────────────┬─────────┤
│ Kullanıcılar│ İstatistikler│ Şikayet Modelasyon│ Talepler     │Topluluk │
│ (Users)     │ (Analytics)  │ (Reports)        │ (Tickets)    │ (Clubs) │
└─────────────┴──────────────┴──────────────────┴──────────────┴─────────┘
```

### 7.1 Route Guard (Giriş Engeli Koruması)

Yönetici paneline yetkisiz erişimleri engellemek için ekran açılışında katı rol kontrolü yapılır (`lib/presentation/screens/admin_screen.dart`):

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', uid)
          .single();
      if ((profile['role'] as String?) != 'admin' && mounted) {
        Navigator.of(context).pop(); // Admin değilse ekrandan çıkar
      }
    } catch (_) {
      if (mounted) Navigator.of(context).pop();
    }
  });
}
```

### 7.2 Admin Paneli İşlevleri

1. **Kullanıcı Yönetimi**: Kullanıcıları arama, rolünü görüntüleme, başkan atama ve hesabı silme.
2. **Toplu İstatistikler**: Toplam kullanıcı, aktif topluluk, bu haftaki yeni üyeler ve gönderi sayıları (`Future.wait` sorguları).
3. **Talep Yönetimi**: Talepleri duruma göre filtreleme (`open`, `in_progress`, `resolved`), yanıtlama ve admin notu ekleme.
4. **Topluluk Yönetimi**: Yeni topluluk ekleme, topluluk bilgilerini düzenleme ve başkan belirleme.

---

## 8. 👑 Yetki Yükseltme ve Rol Yönetimi (Privilege Elevation & Role Management)

Rol hiyerarşisi 3 kademeden oluşur:

```
    [ 👑 Admin ]  ─────► Tam Yetki (Tüm kullanıcılar, içerikler ve topluluklar)
         ▲
         │ (Atama)
    [ 👔 Başkan ] ─────► Kısıtlı Yönetim (Yalnızca kendi topluluğu ve gönderileri)
         ▲
         │ (Yetki Yükseltme)
    [ 🎓 Öğrenci ]────► Standart Erişim (İçerik okuma, etkileşim, talep açma)
```

### 8.1 Yetki Yükseltme İşlemi (Assign Chairman)

Bir öğrenciyi **Topluluk Başkanı** yapma ve topluluğa bağlama mantığı (`assignChairman`):

```dart
Future<void> assignChairman({
  required String userId,
  required String userName,
  required int communityId,
}) async {
  // 1. Kullanıcının varsa eski başkanlığını temizle
  await _db
      .from('communities')
      .update({'chairman_id': null, 'chairman_name': null})
      .eq('chairman_id', userId);

  // 2. Yeni topluluğa başkan olarak bağla
  await _db.from('communities').update({
    'chairman_id': userId,
    'chairman_name': userName,
  }).eq('id', communityId);

  // 3. Kullanıcının rolünü 'baskan' olarak güncelle
  await _db.from('profiles').update({'role': 'baskan'}).eq('id', userId);
}
```

### 8.2 Rolün Geri Alınması (Remove Chairman)

```dart
Future<void> removeChairman({
  required int communityId,
  required String chairmanId,
}) async {
  // 1. Topluluğun başkan alanını boşalt
  await _db.from('communities').update({
    'chairman_id': null,
    'chairman_name': null,
  }).eq('id', communityId);

  // 2. Kullanıcı admin değilse rolünü tekrar 'student' yap
  await _db
      .from('profiles')
      .update({'role': 'student'})
      .eq('id', chairmanId)
      .eq('role', 'baskan');
}
```

### 8.3 RLS Tabanlı Rol Koruma Güvenliği

Öğrencilerin kendi rollerini güncelleyerek admin yapmalarını engellemek için PostgreSQL UPDATE RLS politikası kilitlenmiştir:

```sql
-- Kullanıcı kendi profilini güncelleyebilir AMA rolünü DEĞİŞTİREMEZ
CREATE POLICY "profiles_update_own" ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id AND 
    role = (SELECT p.role FROM public.profiles p WHERE p.id = auth.uid())
  );

-- Rol değişikliği SADECE mevcut bir Admin tarafından yapılabilir
CREATE POLICY "profiles_update_admin" ON public.profiles FOR UPDATE
  USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'));
```

---

## 9. ⚡ SQL Veri Tabanı Şeması, RLS ve Fonksiyonlar (Database Reference)

Projenin tamamında kullanılan temel tablolar ve güvenlik kuralları aşağıdaki gibidir:

```sql
-- ── 1. Profiller Tablosu ───────────────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  role          TEXT NOT NULL DEFAULT 'student',
  department    TEXT[],
  grade         TEXT,
  xp            INTEGER NOT NULL DEFAULT 0,
  profile_photo TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 2. Topluluklar Tablosu ──────────────────────────────────
CREATE TABLE IF NOT EXISTS public.communities (
  id             BIGSERIAL PRIMARY KEY,
  name           TEXT NOT NULL,
  logo_path      TEXT,
  category       TEXT NOT NULL,
  score          REAL NOT NULL DEFAULT 0,
  member_count   INTEGER NOT NULL DEFAULT 0,
  description    TEXT,
  chairman_name  TEXT,
  chairman_id    UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 3. Gönderiler Tablosu ───────────────────────────────────
CREATE TABLE IF NOT EXISTS public.posts (
  id              BIGSERIAL PRIMARY KEY,
  community_id    BIGINT REFERENCES public.communities(id) ON DELETE CASCADE,
  community_name  TEXT NOT NULL,
  community_logo  TEXT,
  user_id         UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  content         TEXT NOT NULL CHECK (char_length(content) >= 1 AND char_length(content) <= 5000),
  image_url       TEXT,
  support_count   INTEGER NOT NULL DEFAULT 0,
  quality_score   REAL NOT NULL DEFAULT 0.0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 4. Talepler ve Şikayetler Tablosu ─────────────────────────
CREATE TABLE IF NOT EXISTS public.user_tickets (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type        TEXT NOT NULL CHECK (type IN ('complaint', 'request', 'suggestion')),
  subject     TEXT NOT NULL,
  description TEXT NOT NULL,
  status      TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
  admin_notes TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── RLS Güvenlik Politikalarının Etkinleştirilmesi ───────────
ALTER TABLE public.profiles     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.communities  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_tickets ENABLE ROW LEVEL SECURITY;
```

---

## 10. 🚀 LiseNET Üzerinde Bu Yapıyı Kurma Adımları

LiseNET uygulamasında bu mimariyi adım adım hayata geçirmek için aşağıdaki sırayı takip edebilirsiniz:

1. **Supabase Projesi Oluşturma & SQL Kurulumu**:
   - Supabase panelinde LiseNET projenizi oluşturun.
   - `SQL Editor` bölümüne gelerek Bölüm 9'daki tüm SQL komutlarını ve RLS politikalarını çalıştırın.
2. **Supabase Auth Yapılandırması**:
   - Authentication ayarlarından e-posta ile kaydolmayı aktif edin.
   - Standart e-posta kabul edildiğinden herhangi bir domain kısıtı koymayın.
3. **Storage Bucket Hazırlığı**:
   - Storage menüsünden public erişimli `posts` ve `avatars` adında bucket'lar oluşturun.
4. **Servis Katmanının Entegrasyonu**:
   - `SupabaseAuthService` ve `SupabaseDataService` sınıflarını projenize entegre edip Supabase URL ve Anon Key ile ilklendirin.
5. **Ekranlar ve Yetki Kontrollerinin Sağlanması**:
   - Giriş/Kayıt ekranlarında standart e-posta doğrulama mantığını uygulayın.
   - Admin ekranlarında `Route Guard` mekanizmasını aktif ederek rolü `admin` olmayan kullanıcıların erişimini engelleyin.
   - Talep oluşturma, gönderi paylaşımı ve yetki yükseltme ekranlarını bağlayın.

---
*LiseNET Teknik Mimari ve Rol Yönetim Raporu*
