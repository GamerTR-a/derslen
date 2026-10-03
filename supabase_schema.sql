-- ═════════════════════════════════════════════════════════════════════
-- LiseNET Supabase SQL Veri Tabanı Şeması ve RLS Güvenlik Politikaları
-- ═════════════════════════════════════════════════════════════════════
-- Bu dosyanın TAMAMI Supabase SQL Editor'de tekrar tekrar çalıştırılabilir:
-- tablolar/indeksler "IF NOT EXISTS", fonksiyonlar "CREATE OR REPLACE",
-- politikalar ve tetikleyiciler önce "DROP ... IF EXISTS" ile yenilenir,
-- katalog verileri "ON CONFLICT" ile güncellenir. Mevcut veri SİLİNMEZ.

-- 1. Profiller Tablosu (auth.users ile 1:1 ilişkili)
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

-- 2. Topluluklar / Gruplar Tablosu
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

-- 3. Gönderiler Tablosu
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

-- 4. Talepler ve Şikayetler Tablosu
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

-- ═════════════════════════════════════════════════════════════════════
-- RLS Güvenlik Politikaları
-- ═════════════════════════════════════════════════════════════════════

ALTER TABLE public.profiles     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.communities  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_tickets ENABLE ROW LEVEL SECURITY;

-- Profiles Policies
-- Not: Sadece giriş yapmış kullanıcılar profilleri görebilir; anonim/giriş yapmamış istemciler göremez.
DROP POLICY IF EXISTS "profiles_select_authenticated" ON public.profiles;
CREATE POLICY "profiles_select_authenticated" ON public.profiles FOR SELECT USING (auth.uid() IS NOT NULL);
DROP POLICY IF EXISTS "profiles_insert_own" ON public.profiles;
CREATE POLICY "profiles_insert_own" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
-- Not: `role` VE `xp` alanları burada mevcut değerleriyle kilitlenir; kullanıcı
-- kendi satırını güncelleyebilir ama rolünü veya XP'sini doğrudan REST PATCH ile
-- değiştiremez. XP artışı yalnızca aşağıdaki `award_xp()` SECURITY DEFINER RPC'si
-- ile (sunucu tarafında) yapılabilir.
DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
CREATE POLICY "profiles_update_own" ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id AND
    role = (SELECT p.role FROM public.profiles p WHERE p.id = auth.uid()) AND
    xp = (SELECT p.xp FROM public.profiles p WHERE p.id = auth.uid())
  );
DROP POLICY IF EXISTS "profiles_admin_all" ON public.profiles;
CREATE POLICY "profiles_admin_all" ON public.profiles FOR ALL
  USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'));

-- Communities Policies
DROP POLICY IF EXISTS "communities_select_all" ON public.communities;
CREATE POLICY "communities_select_all" ON public.communities FOR SELECT USING (true);
DROP POLICY IF EXISTS "communities_admin_all" ON public.communities;
CREATE POLICY "communities_admin_all" ON public.communities FOR ALL
  USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'));

-- Posts Policies
DROP POLICY IF EXISTS "posts_select_all" ON public.posts;
CREATE POLICY "posts_select_all" ON public.posts FOR SELECT USING (true);
DROP POLICY IF EXISTS "posts_insert_auth" ON public.posts;
CREATE POLICY "posts_insert_auth" ON public.posts FOR INSERT WITH CHECK (
  auth.uid() IS NOT NULL AND (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role IN ('admin', 'baskan'))
  )
);
DROP POLICY IF EXISTS "posts_admin_all" ON public.posts;
CREATE POLICY "posts_admin_all" ON public.posts FOR ALL
  USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'));

-- User Tickets Policies
DROP POLICY IF EXISTS "tickets_select_own" ON public.user_tickets;
CREATE POLICY "tickets_select_own" ON public.user_tickets FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "tickets_insert_own" ON public.user_tickets;
CREATE POLICY "tickets_insert_own" ON public.user_tickets FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "tickets_admin_all" ON public.user_tickets;
CREATE POLICY "tickets_admin_all" ON public.user_tickets FOR ALL
  USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'));

-- ═════════════════════════════════════════════════════════════════════
-- Database RPC Functions & Triggers
-- ═════════════════════════════════════════════════════════════════════

-- Account Deletion RPC
-- Not: auth.admin.delete_user() bir Postgres SQL fonksiyonundan çağrılamaz (Admin API'ye özgüdür).
-- SECURITY DEFINER sayesinde bu fonksiyon, sahibinin (postgres/supabase_admin) auth.users üzerindeki
-- yetkisiyle çalışır; auth.users satırı silinince public.profiles kaydı ON DELETE CASCADE ile otomatik silinir.
CREATE OR REPLACE FUNCTION public.delete_account()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  DELETE FROM auth.users WHERE id = v_user_id;
END;
$$;

-- XP Award RPC — profiles.xp doğrudan REST PATCH ile güncellenemez (bkz.
-- profiles_update_own WITH CHECK); tek yetkili yol bu SECURITY DEFINER fonksiyondur.
CREATE OR REPLACE FUNCTION public.award_xp(amount INT)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;
  IF amount <= 0 OR amount > 1000 THEN
    RAISE EXCEPTION 'Invalid xp amount: must be between 1 and 1000';
  END IF;

  UPDATE public.profiles SET xp = COALESCE(xp, 0) + amount WHERE id = v_user_id;
END;
$$;

-- Quality score calculation RPC
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

-- ═════════════════════════════════════════════════════════════════════
-- 5. Koç Görevleri Tablosu & RLS Güvenlik Politikaları
-- ═════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.koc_tasks (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id              UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  coach_id                UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  subject                 TEXT NOT NULL,
  topic                   TEXT NOT NULL,
  coach_note              TEXT,
  question_count          INTEGER CHECK (question_count >= 0 AND question_count <= 1000),
  duration_minutes        INTEGER CHECK (duration_minutes >= 0 AND duration_minutes <= 1440),
  book_info               TEXT,
  task_date               DATE NOT NULL DEFAULT CURRENT_DATE,
  status                  TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'approved', 'delayed')),
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.koc_tasks ENABLE ROW LEVEL SECURITY;

-- Öğrenci sadece kendisine atanan görevleri görebilir
DROP POLICY IF EXISTS "koc_tasks_student_select" ON public.koc_tasks;
CREATE POLICY "koc_tasks_student_select" ON public.koc_tasks
  FOR SELECT USING (auth.uid() = student_id);

-- Öğrenci sadece kendi görevinin durumunu güncelleyebilir (tamamlandı yapabilir)
DROP POLICY IF EXISTS "koc_tasks_student_update" ON public.koc_tasks;
CREATE POLICY "koc_tasks_student_update" ON public.koc_tasks
  FOR UPDATE USING (auth.uid() = student_id)
  WITH CHECK (auth.uid() = student_id);

-- Koç kendi atadığı tüm görevleri görebilir, ekleyebilir, güncelleyebilir ve silebilir
DROP POLICY IF EXISTS "koc_tasks_coach_all" ON public.koc_tasks;
CREATE POLICY "koc_tasks_coach_all" ON public.koc_tasks
  FOR ALL USING (auth.uid() = coach_id)
  WITH CHECK (auth.uid() = coach_id);

-- Yönetici (Admin) tüm görevler üzerinde tam yetkiye sahiptir
DROP POLICY IF EXISTS "koc_tasks_admin_all" ON public.koc_tasks;
CREATE POLICY "koc_tasks_admin_all" ON public.koc_tasks
  FOR ALL USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'));

-- ═════════════════════════════════════════════════════════════════════
-- 6. Öğrenci Verisi Tablosu (flashkart/plan/konu/net/checkin senkronizasyonu)
-- ═════════════════════════════════════════════════════════════════════
-- Uygulama içi StorageService (getMap/setMap) soyutlamasını birebir yansıtan
-- genel anahtar-değer tablosu. Her satır bir kullanıcının tek bir veri
-- anahtarına (örn. 'flashkart_durumlari', 'ogrenci_profil_data') karşılık gelir.

CREATE TABLE IF NOT EXISTS public.student_data (
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  data_key    TEXT NOT NULL,
  data_value  JSONB NOT NULL,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, data_key)
);

ALTER TABLE public.student_data ENABLE ROW LEVEL SECURITY;

-- Kullanıcı sadece kendi verisini okuyabilir/yazabilir/silebilir
DROP POLICY IF EXISTS "student_data_owner_all" ON public.student_data;
CREATE POLICY "student_data_owner_all" ON public.student_data FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ═════════════════════════════════════════════════════════════════════
-- 7. Müfredat Kataloğu (Curricula / Subjects / Topics)
-- ═════════════════════════════════════════════════════════════════════
-- Not: TYT/AYT konuları şu an lib/core/constants/yks_data.dart içinde sabit
-- (const) bir Dart listesi olarak tutuluyor. Bu tablolar mevcut listenin
-- yerini almaz; adminin veritabanından konu ekleyebilmesini ve kullanıcının
-- kendi özel müfredatını (bkz. plan §5.2) oluşturup paylaşabilmesini sağlayan
-- katkı-amaçlı (additive) bir katman ekler. Flutter tarafında sabit listeden
-- bu tabloya geçiş ayrı bir iş kalemidir.

CREATE TABLE IF NOT EXISTS public.curricula (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id    UUID REFERENCES public.profiles(id) ON DELETE CASCADE, -- NULL = sistem müfredatı (admin yönetimli)
  kind        TEXT NOT NULL DEFAULT 'custom' CHECK (kind IN ('tyt', 'ayt', 'ydt', 'university', 'custom')),
  name_i18n   JSONB NOT NULL, -- örn. {"tr": "TYT Matematik", "en": "TYT Mathematics"}
  is_public   BOOLEAN NOT NULL DEFAULT false,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.subjects (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  curriculum_id UUID NOT NULL REFERENCES public.curricula(id) ON DELETE CASCADE,
  name_i18n     JSONB NOT NULL,
  sort_order    INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS public.topics (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_id  UUID NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
  parent_id   UUID REFERENCES public.topics(id) ON DELETE CASCADE, -- alt konular için
  name_i18n   JSONB NOT NULL,
  sort_order  INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_subjects_curriculum ON public.subjects(curriculum_id);
CREATE INDEX IF NOT EXISTS idx_topics_subject       ON public.topics(subject_id);
CREATE INDEX IF NOT EXISTS idx_topics_parent        ON public.topics(parent_id);

ALTER TABLE public.curricula ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.topics    ENABLE ROW LEVEL SECURITY;

-- Curricula: herkes sistem müfredatını (owner_id IS NULL) ve herkese açık
-- müfredatları görebilir; kullanıcı kendi özel müfredatını da görebilir.
DROP POLICY IF EXISTS "curricula_select" ON public.curricula;
CREATE POLICY "curricula_select" ON public.curricula FOR SELECT USING (
  owner_id IS NULL OR is_public = true OR owner_id = auth.uid()
);
DROP POLICY IF EXISTS "curricula_insert_own" ON public.curricula;
CREATE POLICY "curricula_insert_own" ON public.curricula FOR INSERT WITH CHECK (owner_id = auth.uid());
DROP POLICY IF EXISTS "curricula_update_own" ON public.curricula;
CREATE POLICY "curricula_update_own" ON public.curricula FOR UPDATE
  USING (owner_id = auth.uid()) WITH CHECK (owner_id = auth.uid());
DROP POLICY IF EXISTS "curricula_delete_own" ON public.curricula;
CREATE POLICY "curricula_delete_own" ON public.curricula FOR DELETE USING (owner_id = auth.uid());
DROP POLICY IF EXISTS "curricula_admin_all" ON public.curricula;
CREATE POLICY "curricula_admin_all" ON public.curricula FOR ALL
  USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'));

-- Subjects / Topics: görünürlük ebeveyn müfredatın görünürlüğüne bağlıdır.
DROP POLICY IF EXISTS "subjects_select" ON public.subjects;
CREATE POLICY "subjects_select" ON public.subjects FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.curricula c WHERE c.id = subjects.curriculum_id
      AND (c.owner_id IS NULL OR c.is_public = true OR c.owner_id = auth.uid())
  )
);
DROP POLICY IF EXISTS "subjects_owner_write" ON public.subjects;
CREATE POLICY "subjects_owner_write" ON public.subjects FOR ALL USING (
  EXISTS (SELECT 1 FROM public.curricula c WHERE c.id = subjects.curriculum_id AND c.owner_id = auth.uid())
) WITH CHECK (
  EXISTS (SELECT 1 FROM public.curricula c WHERE c.id = subjects.curriculum_id AND c.owner_id = auth.uid())
);
DROP POLICY IF EXISTS "subjects_admin_all" ON public.subjects;
CREATE POLICY "subjects_admin_all" ON public.subjects FOR ALL
  USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'));

DROP POLICY IF EXISTS "topics_select" ON public.topics;
CREATE POLICY "topics_select" ON public.topics FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.subjects s JOIN public.curricula c ON c.id = s.curriculum_id
    WHERE s.id = topics.subject_id
      AND (c.owner_id IS NULL OR c.is_public = true OR c.owner_id = auth.uid())
  )
);
DROP POLICY IF EXISTS "topics_owner_write" ON public.topics;
CREATE POLICY "topics_owner_write" ON public.topics FOR ALL USING (
  EXISTS (
    SELECT 1 FROM public.subjects s JOIN public.curricula c ON c.id = s.curriculum_id
    WHERE s.id = topics.subject_id AND c.owner_id = auth.uid()
  )
) WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.subjects s JOIN public.curricula c ON c.id = s.curriculum_id
    WHERE s.id = topics.subject_id AND c.owner_id = auth.uid()
  )
);
DROP POLICY IF EXISTS "topics_admin_all" ON public.topics;
CREATE POLICY "topics_admin_all" ON public.topics FOR ALL
  USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'));

-- Herkese açık/sistem müfredatını kopyalayıp kendi özel müfredatın yapma.
-- Not: Basitlik için üst seviye konular kopyalanır; iç içe alt konular
-- (parent_id dolu olanlar) bu sürümde kopyalanmaz.
CREATE OR REPLACE FUNCTION public.clone_curriculum(p_curriculum_id UUID)
RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_src RECORD;
  v_new_curriculum_id UUID;
  v_subject RECORD;
  v_new_subject_id UUID;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;

  SELECT * INTO v_src FROM public.curricula
   WHERE id = p_curriculum_id AND (owner_id IS NULL OR is_public = true OR owner_id = v_uid);
  IF NOT FOUND THEN RAISE EXCEPTION 'Curriculum not found or not accessible'; END IF;

  INSERT INTO public.curricula (owner_id, kind, name_i18n, is_public)
  VALUES (v_uid, v_src.kind, v_src.name_i18n, false)
  RETURNING id INTO v_new_curriculum_id;

  FOR v_subject IN SELECT * FROM public.subjects WHERE curriculum_id = p_curriculum_id LOOP
    INSERT INTO public.subjects (curriculum_id, name_i18n, sort_order)
    VALUES (v_new_curriculum_id, v_subject.name_i18n, v_subject.sort_order)
    RETURNING id INTO v_new_subject_id;

    INSERT INTO public.topics (subject_id, parent_id, name_i18n, sort_order)
    SELECT v_new_subject_id, NULL, name_i18n, sort_order
    FROM public.topics WHERE subject_id = v_subject.id AND parent_id IS NULL;
  END LOOP;

  RETURN v_new_curriculum_id;
END;
$$;

-- ═════════════════════════════════════════════════════════════════════
-- 8. Yıldız Ekonomisi (Wallet + Sunucu Taraflı Doğrulama)
-- ═════════════════════════════════════════════════════════════════════
-- Not: profiles.xp şu an SupabaseDataService.addXp() ile istemci tarafından
-- doğrudan artırılıyor — istemcinin sınırsız/tekrarlı XP yazmasına açık bir
-- yöntem. Aşağıdaki cüzdan + RPC seti, hile yapılamayan bir alternatif
-- sağlar; mevcut xp akışını DEĞİŞTİRMİYOR, yanına ekleniyor. İleride
-- addXp() çağrılarının bu RPC'lere yönlendirilmesi ayrı bir iş kalemidir.
--
-- Doğrulama sınırı: Bu RPC'ler şu an sadece günlük tavan + tekilleştirme
-- (aynı ref_id'ye iki kez ödül verilmez) ile hileyi sınırlıyor. Gerçek
-- süre doğrulaması (sunucuda saklanan başlangıç/bitiş zaman damgalarıyla
-- karşılaştırma) için ayrı bir study_sessions tablosu gerekir — o, pomodoro
-- özelliğinin sunucu tarafına taşınmasıyla birlikte ayrı bir iş kalemidir.

CREATE TABLE IF NOT EXISTS public.wallets (
  user_id     UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  balance     INTEGER NOT NULL DEFAULT 0 CHECK (balance >= 0),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.star_transactions (
  id          BIGSERIAL PRIMARY KEY,
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  amount      INTEGER NOT NULL,
  reason      TEXT NOT NULL CHECK (reason IN ('pomodoro', 'checkin', 'goal', 'streak', 'cards', 'test', 'purchase', 'admin_adjust')),
  ref_id      TEXT, -- ilgili oturum/hedef kimliği (varsa) — tekilleştirme için kullanılır
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, reason, ref_id) -- aynı olay için iki kez yıldız verilmesini önler
);

CREATE INDEX IF NOT EXISTS idx_star_tx_user_reason_date ON public.star_transactions(user_id, reason, created_at);

ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.star_transactions ENABLE ROW LEVEL SECURITY;

-- Not: wallets ve star_transactions tablolarına doğrudan INSERT/UPDATE
-- politikası tanımlı DEĞİL — bakiye sadece aşağıdaki SECURITY DEFINER
-- RPC'ler ile değişebilir; istemci satırı doğrudan yazamaz.
DROP POLICY IF EXISTS "wallets_select_own" ON public.wallets;
CREATE POLICY "wallets_select_own" ON public.wallets FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "wallets_admin_all" ON public.wallets;
CREATE POLICY "wallets_admin_all" ON public.wallets FOR ALL
  USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'));

DROP POLICY IF EXISTS "star_tx_select_own" ON public.star_transactions;
CREATE POLICY "star_tx_select_own" ON public.star_transactions FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "star_tx_admin_all" ON public.star_transactions;
CREATE POLICY "star_tx_admin_all" ON public.star_transactions FOR ALL
  USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'));

-- İç yardımcı: kullanıcının bugün belirli bir 'reason' için kazandığı toplam yıldız.
-- DİKKAT: p_user_id parametresi keyfi olduğu için PUBLIC'ten EXECUTE yetkisi
-- alınıyor (aşağıda) — sadece diğer SECURITY DEFINER RPC'ler içeriden çağırabilir,
-- yoksa herkes başka bir kullanıcının günlük yıldız toplamını sorgulayabilirdi.
CREATE OR REPLACE FUNCTION public._stars_earned_today(p_user_id UUID, p_reason TEXT)
RETURNS INTEGER LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT COALESCE(SUM(amount), 0)::INTEGER FROM public.star_transactions
   WHERE user_id = p_user_id AND reason = p_reason AND created_at::date = CURRENT_DATE;
$$;
REVOKE EXECUTE ON FUNCTION public._stars_earned_today(UUID, TEXT) FROM PUBLIC;

-- Pomodoro oturumu tamamlanınca çağrılır: 25 dk = 10 yıldız, çağrı başı tavan
-- 40 yıldız (100 dk), günlük tavan 200 yıldız.
CREATE OR REPLACE FUNCTION public.award_pomodoro_stars(p_ref_id TEXT, p_focus_minutes INTEGER)
RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_stars INTEGER;
  v_today_total INTEGER;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  IF p_focus_minutes IS NULL OR p_focus_minutes <= 0 OR p_focus_minutes > 1440 THEN
    RAISE EXCEPTION 'invalid focus_minutes';
  END IF;

  v_stars := LEAST((p_focus_minutes / 25) * 10, 40);
  v_today_total := public._stars_earned_today(v_uid, 'pomodoro');
  v_stars := GREATEST(0, LEAST(v_stars, 200 - v_today_total));
  IF v_stars <= 0 THEN RETURN 0; END IF;

  INSERT INTO public.star_transactions (user_id, amount, reason, ref_id)
  VALUES (v_uid, v_stars, 'pomodoro', p_ref_id)
  ON CONFLICT (user_id, reason, ref_id) DO NOTHING;
  IF NOT FOUND THEN RETURN 0; END IF; -- bu ref_id için zaten ödül verilmiş

  INSERT INTO public.wallets (user_id, balance, updated_at)
  VALUES (v_uid, v_stars, NOW())
  ON CONFLICT (user_id) DO UPDATE SET balance = wallets.balance + v_stars, updated_at = NOW();

  RETURN v_stars;
END;
$$;

-- Günlük check-in tamamlanınca çağrılır: sabit 5 yıldız, günde en fazla 1 kez
-- (p_date, ref_id olarak kullanılır → aynı gün için tekilleştirme sağlar).
CREATE OR REPLACE FUNCTION public.award_checkin_stars(p_date DATE)
RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;

  INSERT INTO public.star_transactions (user_id, amount, reason, ref_id)
  VALUES (v_uid, 5, 'checkin', p_date::text)
  ON CONFLICT (user_id, reason, ref_id) DO NOTHING;
  IF NOT FOUND THEN RETURN 0; END IF;

  INSERT INTO public.wallets (user_id, balance, updated_at)
  VALUES (v_uid, 5, NOW())
  ON CONFLICT (user_id) DO UPDATE SET balance = wallets.balance + 5, updated_at = NOW();

  RETURN 5;
END;
$$;

-- Bir hedef tamamlanınca çağrılır: hedef başına bir kez, 1-20 yıldız arası.
CREATE OR REPLACE FUNCTION public.award_goal_stars(p_goal_ref_id TEXT, p_amount INTEGER)
RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_amount INTEGER := LEAST(GREATEST(p_amount, 1), 20);
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  IF p_goal_ref_id IS NULL OR length(p_goal_ref_id) = 0 THEN RAISE EXCEPTION 'invalid goal ref'; END IF;

  INSERT INTO public.star_transactions (user_id, amount, reason, ref_id)
  VALUES (v_uid, v_amount, 'goal', p_goal_ref_id)
  ON CONFLICT (user_id, reason, ref_id) DO NOTHING;
  IF NOT FOUND THEN RETURN 0; END IF;

  INSERT INTO public.wallets (user_id, balance, updated_at)
  VALUES (v_uid, v_amount, NOW())
  ON CONFLICT (user_id) DO UPDATE SET balance = wallets.balance + v_amount, updated_at = NOW();

  RETURN v_amount;
END;
$$;

-- Mağazadan/dekorasyondan yıldız harcama. p_ref_id her satın alma denemesi
-- için benzersiz olmalı (örn. istemcide üretilen bir uuid) — aksi halde aynı
-- (reason, ref_id) çifti tekrar kullanılırsa UNIQUE ihlali hatası döner.
CREATE OR REPLACE FUNCTION public.spend_stars(p_amount INTEGER, p_reason TEXT DEFAULT 'purchase', p_ref_id TEXT DEFAULT NULL)
RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_balance INTEGER;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  IF p_amount IS NULL OR p_amount <= 0 THEN RAISE EXCEPTION 'invalid amount'; END IF;

  SELECT balance INTO v_balance FROM public.wallets WHERE user_id = v_uid FOR UPDATE;
  IF v_balance IS NULL OR v_balance < p_amount THEN
    RAISE EXCEPTION 'insufficient balance';
  END IF;

  UPDATE public.wallets SET balance = balance - p_amount, updated_at = NOW() WHERE user_id = v_uid;
  INSERT INTO public.star_transactions (user_id, amount, reason, ref_id)
  VALUES (v_uid, -p_amount, p_reason, p_ref_id);

  RETURN v_balance - p_amount;
END;
$$;

-- ═════════════════════════════════════════════════════════════════════
-- 9. Koç–Öğrenci İlişkisi (Davet + Onay Akışı)
-- ═════════════════════════════════════════════════════════════════════
-- ÖNEMLİ GÜVENLİK NOTU: Şu anki "koc_tasks_coach_all" politikası, coach_id
-- = auth.uid() olan HERHANGİ bir kullanıcının HERHANGİ bir student_id için
-- görev oluşturup güncellemesine izin veriyordu — öğrencinin bu koçu
-- onayladığına dair bir kontrol yoktu (plan §5.25'in gerektirdiği "davet
-- kodu / eşleşme + öğrenci onayı" akışı eksikti). Bu düzeltme, koc_tasks
-- tablosunun Flutter tarafında henüz hiç kullanılmadığı (bkz. koç ekranları
-- şu an sahte/mock veriyle çalışıyor) doğrulandıktan sonra güvenle yapıldı —
-- yani üretimde kırılacak gerçek bir kullanım yok.
--
-- Mevcut koc_tasks satırlarındaki (coach_id, student_id) çiftleri, erişim
-- kaybı olmaması için otomatik olarak 'active' ilişki haline getiriliyor.

CREATE TABLE IF NOT EXISTS public.coach_students (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  student_id  UUID REFERENCES public.profiles(id) ON DELETE CASCADE, -- davet kabul edilene kadar NULL
  status      TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'ended')),
  invite_code TEXT UNIQUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Aynı koç-öğrenci çifti için en fazla bir AKTİF ilişki olabilir
-- (pending/ended durumundaki geçmiş kayıtlarla çakışmaz).
CREATE UNIQUE INDEX IF NOT EXISTS coach_students_active_pair_uq
  ON public.coach_students (coach_id, student_id) WHERE (status = 'active');

CREATE INDEX IF NOT EXISTS idx_coach_students_coach   ON public.coach_students(coach_id);
CREATE INDEX IF NOT EXISTS idx_coach_students_student ON public.coach_students(student_id);

ALTER TABLE public.coach_students ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "coach_students_select_own" ON public.coach_students;
CREATE POLICY "coach_students_select_own" ON public.coach_students FOR SELECT USING (
  auth.uid() = coach_id OR auth.uid() = student_id
);
DROP POLICY IF EXISTS "coach_students_admin_all" ON public.coach_students;
CREATE POLICY "coach_students_admin_all" ON public.coach_students FOR ALL
  USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'));
-- Not: pending/active/ended geçişleri yalnızca aşağıdaki RPC'lerle yapılır;
-- tabloya doğrudan INSERT/UPDATE politikası tanımlı değildir.

-- Koç (rolü 'baskan', 'coach' veya 'admin' olan kullanıcı) bir davet kodu üretir.
CREATE OR REPLACE FUNCTION public.create_coach_invite()
RETURNS TEXT LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_code TEXT;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = v_uid AND p.role IN ('baskan', 'coach', 'admin')) THEN
    RAISE EXCEPTION 'Only coaches can create invites';
  END IF;

  v_code := upper(substr(md5(random()::text || v_uid::text || clock_timestamp()::text), 1, 8));

  INSERT INTO public.coach_students (coach_id, student_id, status, invite_code)
  VALUES (v_uid, NULL, 'pending', v_code);

  RETURN v_code;
END;
$$;

-- Öğrenci bir davet kodunu kabul eder → ilişki 'active' olur.
-- (§15 bu fonksiyonu TEXT döndüren sürümüyle değiştirir; dönüş tipi farklı
-- olduğu için dosya tekrar çalıştırılırken önce silinmelidir.)
DROP FUNCTION IF EXISTS public.accept_coach_invite(TEXT);
CREATE OR REPLACE FUNCTION public.accept_coach_invite(p_invite_code TEXT)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_row public.coach_students%rowtype;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;

  SELECT * INTO v_row FROM public.coach_students
   WHERE invite_code = p_invite_code AND status = 'pending'
   FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Invalid or already used invite code'; END IF;
  IF v_row.coach_id = v_uid THEN RAISE EXCEPTION 'Cannot coach yourself'; END IF;

  UPDATE public.coach_students
     SET student_id = v_uid, status = 'active', updated_at = NOW()
   WHERE id = v_row.id;
END;
$$;

-- Koç veya öğrenci, ilişkiyi sonlandırır.
CREATE OR REPLACE FUNCTION public.end_coach_relationship(p_relationship_id UUID)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;

  UPDATE public.coach_students
     SET status = 'ended', updated_at = NOW()
   WHERE id = p_relationship_id AND (coach_id = v_uid OR student_id = v_uid);
  IF NOT FOUND THEN RAISE EXCEPTION 'Relationship not found or unauthorized'; END IF;
END;
$$;

-- Geriye dönük uyumluluk: koc_tasks içindeki mevcut çiftleri aktif ilişkiye dönüştür.
-- Not: coach_students_active_pair_uq kısmi (partial) bir indeks olduğundan,
-- ON CONFLICT'in bunu doğru şekilde bulabilmesi için WHERE koşulu tekrar edilir.
INSERT INTO public.coach_students (coach_id, student_id, status)
SELECT DISTINCT coach_id, student_id, 'active'
FROM public.koc_tasks
ON CONFLICT (coach_id, student_id) WHERE (status = 'active') DO NOTHING;

-- koc_tasks politikasını, artık zorunlu olan aktif ilişkiyle sıkılaştır.
DROP POLICY IF EXISTS "koc_tasks_coach_all" ON public.koc_tasks;
CREATE POLICY "koc_tasks_coach_all" ON public.koc_tasks FOR ALL USING (
  auth.uid() = coach_id AND EXISTS (
    SELECT 1 FROM public.coach_students cs
     WHERE cs.coach_id = auth.uid() AND cs.student_id = koc_tasks.student_id AND cs.status = 'active'
  )
) WITH CHECK (
  auth.uid() = coach_id AND EXISTS (
    SELECT 1 FROM public.coach_students cs
     WHERE cs.coach_id = auth.uid() AND cs.student_id = koc_tasks.student_id AND cs.status = 'active'
  )
);

COMMENT ON COLUMN public.profiles.role IS 'student | baskan | coach | admin — DB seviyesinde CHECK yok; uygulama ve RLS rol davranışını yönetir.';

-- ═════════════════════════════════════════════════════════════════════
-- 10. Çalışma Oturumları (Sunucu Taraflı Süre Doğrulaması)
-- ═════════════════════════════════════════════════════════════════════
-- §8'deki not burada karşılığını buluyor: pomodoro yıldızları artık
-- istemcinin bildirdiği dakikaya değil, sunucunun kendi ölçtüğü
-- (NOW() - started_at) süresine göre veriliyor. İstemci bir oturumu
-- başlatabilir (INSERT) ve kendi oturumlarını görebilir (SELECT), ama
-- UPDATE politikası KASITLI OLARAK yok — bir oturumu bitirip yıldız
-- kazanmanın tek yolu aşağıdaki complete_study_session() RPC'sidir
-- (tablo sahibi olarak çalıştığından RLS'yi atlar).
--
-- award_pomodoro_stars() (§8) kaldırılmadı; toplu/geçmiş veri aktarımı
-- gibi istisnai durumlar için hâlâ mevcut. Uygulamanın pomodoro akışı
-- BUNDAN SONRA complete_study_session() kullanmalı.

CREATE TABLE IF NOT EXISTS public.study_sessions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  label           TEXT NOT NULL,
  planned_minutes INTEGER NOT NULL CHECK (planned_minutes > 0 AND planned_minutes <= 240),
  started_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ended_at        TIMESTAMPTZ,
  actual_minutes  INTEGER,
  stars_awarded   INTEGER NOT NULL DEFAULT 0,
  interrupted     BOOLEAN NOT NULL DEFAULT false
);

CREATE INDEX IF NOT EXISTS idx_study_sessions_user_date ON public.study_sessions(user_id, started_at);

ALTER TABLE public.study_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "study_sessions_select_own" ON public.study_sessions;
CREATE POLICY "study_sessions_select_own" ON public.study_sessions FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "study_sessions_insert_own" ON public.study_sessions;
CREATE POLICY "study_sessions_insert_own" ON public.study_sessions FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "study_sessions_admin_all" ON public.study_sessions;
CREATE POLICY "study_sessions_admin_all" ON public.study_sessions FOR ALL
  USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'));
-- Koç, kendisiyle AKTİF ilişkisi olan öğrencinin çalışma oturumlarını okuyabilir
-- (koç paneli haftalık istatistik kartı için — bkz. kontrol.md denetimi).
DROP POLICY IF EXISTS "study_sessions_coach_select" ON public.study_sessions;
CREATE POLICY "study_sessions_coach_select" ON public.study_sessions FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.coach_students cs
     WHERE cs.coach_id = auth.uid() AND cs.student_id = study_sessions.user_id AND cs.status = 'active'
  )
);

-- Bir oturumu bitirir: süreyi sunucu saatiyle hesaplar, yıldızı buna göre
-- verir (§8'deki günlük tavan ve tekilleştirme kuralları burada da geçerli),
-- ve oturumu kaydeder. planned_minutes'in %60'ından azı tamamlanmışsa
-- 'interrupted' olarak işaretlenir (Forest tarzı dürüstlük göstergesi).
CREATE OR REPLACE FUNCTION public.complete_study_session(p_session_id UUID)
RETURNS TABLE(actual_minutes INTEGER, stars_awarded INTEGER)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_session public.study_sessions%rowtype;
  v_minutes INTEGER;
  v_stars INTEGER;
  v_today_total INTEGER;
  v_awarded INTEGER := 0;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;

  SELECT * INTO v_session FROM public.study_sessions
   WHERE id = p_session_id AND user_id = v_uid AND ended_at IS NULL
   FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Session not found or already completed'; END IF;

  v_minutes := LEAST(
    GREATEST(FLOOR(EXTRACT(EPOCH FROM (NOW() - v_session.started_at)) / 60)::INTEGER, 0),
    240
  );

  v_stars := LEAST((v_minutes / 25) * 10, 40);
  v_today_total := public._stars_earned_today(v_uid, 'pomodoro');
  v_stars := GREATEST(0, LEAST(v_stars, 200 - v_today_total));

  IF v_stars > 0 THEN
    INSERT INTO public.star_transactions (user_id, amount, reason, ref_id)
    VALUES (v_uid, v_stars, 'pomodoro', p_session_id::text)
    ON CONFLICT (user_id, reason, ref_id) DO NOTHING;

    IF FOUND THEN
      v_awarded := v_stars;
      INSERT INTO public.wallets (user_id, balance, updated_at)
      VALUES (v_uid, v_stars, NOW())
      ON CONFLICT (user_id) DO UPDATE SET balance = wallets.balance + v_stars, updated_at = NOW();
    END IF;
  END IF;

  UPDATE public.study_sessions
     SET ended_at = NOW(),
         actual_minutes = v_minutes,
         stars_awarded = v_awarded,
         interrupted = (v_minutes < v_session.planned_minutes * 0.6)
   WHERE id = p_session_id;

  RETURN QUERY SELECT v_minutes, v_awarded;
END;
$$;

-- ═════════════════════════════════════════════════════════════════════
-- 11. Deneme Normalizasyonu (Göreli Performans / Anonim Karşılaştırma)
-- ═════════════════════════════════════════════════════════════════════
-- Kullanıcılar "Deneme Adı / Yayın" alanına aynı ismi (örn. "3D Deneme 5")
-- yazdığında, o denemeyi çözen diğer kullanıcılarla ANONİM olarak
-- karşılaştırma yapılabilir. Ham satırlar (exam_results) her kullanıcı
-- sadece kendi satırını görebilecek şekilde RLS ile korunuyor; toplu
-- ortalama/standart sapma ise SECURITY DEFINER bir RPC üzerinden, hiçbir
-- kullanıcı adı/kimliği açığa çıkmadan hesaplanıp döndürülüyor. Yetersiz
-- katılımcı olan denemelerde (bkz. get_exam_benchmark) sonuç istemci
-- tarafında "tahmini/gösterilmez" olarak ele alınmalı.

CREATE TABLE IF NOT EXISTS public.exam_results (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  deneme_adi   TEXT NOT NULL,
  alan         TEXT NOT NULL CHECK (alan IN ('TYT', 'AYT')),
  ders         TEXT NOT NULL,
  dogru        INTEGER NOT NULL DEFAULT 0 CHECK (dogru >= 0),
  yanlis       INTEGER NOT NULL DEFAULT 0 CHECK (yanlis >= 0),
  bos          INTEGER NOT NULL DEFAULT 0 CHECK (bos >= 0),
  net          NUMERIC GENERATED ALWAYS AS (dogru - yanlis * 0.25) STORED,
  submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, deneme_adi, alan, ders) -- aynı deneme+dersi tekrar gönderince günceller, çift satır oluşmaz
);

CREATE INDEX IF NOT EXISTS idx_exam_results_lookup
  ON public.exam_results (lower(deneme_adi), alan, ders);

ALTER TABLE public.exam_results ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "exam_results_select_own" ON public.exam_results;
CREATE POLICY "exam_results_select_own" ON public.exam_results FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "exam_results_admin_all" ON public.exam_results;
CREATE POLICY "exam_results_admin_all" ON public.exam_results FOR ALL
  USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'));
-- Koç, kendisiyle AKTİF ilişkisi olan öğrencinin deneme netlerini okuyabilir
-- (koç paneli deneme geçmişi kartı için — bkz. kontrol.md denetimi).
DROP POLICY IF EXISTS "exam_results_coach_select" ON public.exam_results;
CREATE POLICY "exam_results_coach_select" ON public.exam_results FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.coach_students cs
     WHERE cs.coach_id = auth.uid() AND cs.student_id = exam_results.user_id AND cs.status = 'active'
  )
);
-- Not: INSERT/UPDATE politikası kasıtlı olarak yok — tek yazma yolu
-- aşağıdaki submit_exam_result() RPC'sidir (deneme adını normalize eder).

CREATE OR REPLACE FUNCTION public.submit_exam_result(
  p_deneme_adi TEXT, p_alan TEXT, p_ders TEXT,
  p_dogru INTEGER, p_yanlis INTEGER, p_bos INTEGER
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  IF p_alan NOT IN ('TYT', 'AYT') THEN RAISE EXCEPTION 'invalid alan'; END IF;
  IF p_deneme_adi IS NULL OR length(trim(p_deneme_adi)) = 0 THEN RAISE EXCEPTION 'invalid deneme_adi'; END IF;

  INSERT INTO public.exam_results (user_id, deneme_adi, alan, ders, dogru, yanlis, bos)
  VALUES (v_uid, trim(p_deneme_adi), p_alan, p_ders, GREATEST(p_dogru, 0), GREATEST(p_yanlis, 0), GREATEST(p_bos, 0))
  ON CONFLICT (user_id, deneme_adi, alan, ders)
  DO UPDATE SET dogru = EXCLUDED.dogru, yanlis = EXCLUDED.yanlis, bos = EXCLUDED.bos, submitted_at = NOW();
END;
$$;

-- Bir denemenin ders bazlı topluluk ortalaması/standart sapması. Sadece
-- toplu sayılar döner — hangi kullanıcıların katıldığı asla açığa çıkmaz.
-- Katılımcı sayısı 5'in altındaysa istemci bu sonucu "yetersiz veri" olarak
-- ele almalı (eşik burada MIN_KATILIMCI ile kolayca değiştirilebilir).
CREATE OR REPLACE FUNCTION public.get_exam_benchmark(p_deneme_adi TEXT, p_alan TEXT, p_ders TEXT)
RETURNS TABLE(katilimci_sayisi INTEGER, ortalama_net NUMERIC, standart_sapma NUMERIC)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT
    COUNT(*)::INTEGER,
    ROUND(AVG(net), 2),
    ROUND(COALESCE(STDDEV_SAMP(net), 0), 2)
  FROM public.exam_results
  WHERE lower(deneme_adi) = lower(trim(p_deneme_adi))
    AND alan = p_alan AND ders = p_ders;
$$;

-- ═════════════════════════════════════════════════════════════════════
-- 12. Gruplar / Çalışma Odaları (Üyelik + Haftalık Sıralama + Dürtme)
-- ═════════════════════════════════════════════════════════════════════
-- "communities" tablosu bugüne kadar sadece gönderi paylaşırken seçilen
-- bir kategori gibi kullanılıyordu — gerçek bir üyelik kavramı yoktu.
-- Bu bölüm üyeliği ekliyor ve mevcut §10'daki study_sessions verisini
-- (sunucuda doğrulanmış gerçek odak süresi) kullanarak toplulukların
-- kendi içinde haftalık bir çalışma sıralaması sunuyor. "Şu an kim
-- çalışıyor" canlı listesi ayrı bir tablo GEREKTİRMİYOR — Flutter
-- tarafında Supabase Realtime Presence ile (bkz. study_room_screen.dart)
-- doğrudan channel üzerinden yönetiliyor; sadece dürtme (nudge) kalıcı
-- olduğu için (çevrimdışıyken de görülebilsin) bir tabloya yazılıyor.

CREATE TABLE IF NOT EXISTS public.community_members (
  community_id BIGINT NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  joined_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (community_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_community_members_user ON public.community_members(user_id);

ALTER TABLE public.community_members ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "community_members_select_all" ON public.community_members;
CREATE POLICY "community_members_select_all" ON public.community_members FOR SELECT USING (true);
DROP POLICY IF EXISTS "community_members_join_own" ON public.community_members;
CREATE POLICY "community_members_join_own" ON public.community_members FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "community_members_leave_own" ON public.community_members;
CREATE POLICY "community_members_leave_own" ON public.community_members FOR DELETE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "community_members_admin_all" ON public.community_members;
CREATE POLICY "community_members_admin_all" ON public.community_members FOR ALL
  USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'));

-- communities.member_count'u üyelik değişince otomatik güncelle (admin
-- paneli bu alanı zaten gösteriyor — artık gerçek üye sayısını yansıtır).
CREATE OR REPLACE FUNCTION public._sync_community_member_count()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.communities SET member_count = member_count + 1 WHERE id = NEW.community_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.communities SET member_count = GREATEST(member_count - 1, 0) WHERE id = OLD.community_id;
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_community_member_count ON public.community_members;
CREATE TRIGGER trg_community_member_count
AFTER INSERT OR DELETE ON public.community_members
FOR EACH ROW EXECUTE FUNCTION public._sync_community_member_count();

-- Bir topluluğun üyeleri arasında, son p_days gündeki toplam odak
-- dakikasına göre sıralama. Sadece üyeler kendi topluluklarının
-- sıralamasını görebilir (fonksiyon içinde kontrol edilir).
CREATE OR REPLACE FUNCTION public.get_community_leaderboard(p_community_id BIGINT, p_days INTEGER DEFAULT 7)
RETURNS TABLE(user_id UUID, name TEXT, profile_photo TEXT, total_minutes INTEGER)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.community_members
     WHERE community_id = p_community_id AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Bu topluluğun üyesi değilsin';
  END IF;

  RETURN QUERY
  SELECT p.id, p.name, p.profile_photo,
         COALESCE(SUM(s.actual_minutes), 0)::INTEGER AS total_minutes
  FROM public.community_members cm
  JOIN public.profiles p ON p.id = cm.user_id
  LEFT JOIN public.study_sessions s
    ON s.user_id = cm.user_id AND s.ended_at IS NOT NULL
   AND s.started_at >= NOW() - (p_days::text || ' days')::INTERVAL
  WHERE cm.community_id = p_community_id
  GROUP BY p.id, p.name, p.profile_photo
  ORDER BY total_minutes DESC, p.name ASC;
END;
$$;

-- Dürtme (nudge): aynı kişiye saatte en fazla 1 kez, sadece aynı toplulukta
-- üye olan iki kullanıcı arasında. Kalıcı — hedef o an çevrimdışıysa bile
-- odaya bir dahaki girişinde görür (bkz. mark_nudges_seen).
CREATE TABLE IF NOT EXISTS public.nudges (
  id           BIGSERIAL PRIMARY KEY,
  community_id BIGINT NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
  from_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  to_user_id   UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  seen         BOOLEAN NOT NULL DEFAULT false
);

CREATE INDEX IF NOT EXISTS idx_nudges_to_user ON public.nudges(to_user_id, created_at);

ALTER TABLE public.nudges ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "nudges_select_involved" ON public.nudges;
CREATE POLICY "nudges_select_involved" ON public.nudges FOR SELECT USING (
  auth.uid() = from_user_id OR auth.uid() = to_user_id
);
DROP POLICY IF EXISTS "nudges_admin_all" ON public.nudges;
CREATE POLICY "nudges_admin_all" ON public.nudges FOR ALL
  USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'));
-- Not: INSERT politikası yok — saatlik limit kontrolü gerektiği için tek
-- yazma yolu send_nudge() RPC'sidir.

CREATE OR REPLACE FUNCTION public.send_nudge(p_community_id BIGINT, p_to_user_id UUID)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  IF v_uid = p_to_user_id THEN RAISE EXCEPTION 'Kendine dürtme gönderemezsin'; END IF;

  IF NOT EXISTS (SELECT 1 FROM public.community_members WHERE community_id = p_community_id AND user_id = v_uid) THEN
    RAISE EXCEPTION 'Bu topluluğun üyesi değilsin';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.community_members WHERE community_id = p_community_id AND user_id = p_to_user_id) THEN
    RAISE EXCEPTION 'Alıcı bu topluluğun üyesi değil';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.nudges
     WHERE from_user_id = v_uid AND to_user_id = p_to_user_id
       AND created_at > NOW() - INTERVAL '1 hour'
  ) THEN
    RAISE EXCEPTION 'Bu kişiyi az önce dürttün, bir süre sonra tekrar deneyebilirsin';
  END IF;

  INSERT INTO public.nudges (community_id, from_user_id, to_user_id) VALUES (p_community_id, v_uid, p_to_user_id);
END;
$$;

-- Alınan dürtmeleri "görüldü" olarak işaretler (bir topluluğa girildiğinde çağrılır).
CREATE OR REPLACE FUNCTION public.mark_nudges_seen(p_community_id BIGINT)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  UPDATE public.nudges SET seen = true
   WHERE to_user_id = auth.uid() AND community_id = p_community_id AND seen = false;
END;
$$;

-- ═════════════════════════════════════════════════════════════════════
-- MIGRATION: profiles.xp RLS Sıkılaştırması (kontrol.md denetim bulgusu)
-- ═════════════════════════════════════════════════════════════════════
-- Bu blok, dosyanın üst kısımlarındaki `profiles_update_own` politikası ve
-- `award_xp()` fonksiyonu ZATEN CANLI bir Supabase projesine önceki haliyle
-- uygulanmışsa, o projeyi güncellemek için Supabase SQL Editor'de TEK SEFERLİK
-- çalıştırılmalıdır (idempotent — birden fazla çalıştırılması güvenlidir).
-- Öncesinde: `profiles.xp` alanı istemciden doğrudan PATCH ile değiştirilebiliyordu
-- (herhangi bir kullanıcı kendi XP'sini keyfi değere yükseltebilirdi).
DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
CREATE POLICY "profiles_update_own" ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id AND
    role = (SELECT p.role FROM public.profiles p WHERE p.id = auth.uid()) AND
    xp = (SELECT p.xp FROM public.profiles p WHERE p.id = auth.uid())
  );

CREATE OR REPLACE FUNCTION public.award_xp(amount INT)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;
  IF amount <= 0 OR amount > 1000 THEN
    RAISE EXCEPTION 'Invalid xp amount: must be between 1 and 1000';
  END IF;

  UPDATE public.profiles SET xp = COALESCE(xp, 0) + amount WHERE id = v_user_id;
END;
$$;


-- ═════════════════════════════════════════════════════════════════════
-- MIGRATION: Koç Paneli Gerçek Veri Erişimi (kontrol.md denetim bulgusu)
-- ═════════════════════════════════════════════════════════════════════
-- Öncesinde: study_sessions ve exam_results yalnızca sahibi (öğrenci)
-- tarafından okunabiliyordu; koç paneli bu yüzden mock veriyle çalışıyordu.
-- Bu blok Supabase SQL Editor'de TEK SEFERLİK çalıştırılmalıdır (idempotent).
DROP POLICY IF EXISTS "study_sessions_coach_select" ON public.study_sessions;
CREATE POLICY "study_sessions_coach_select" ON public.study_sessions FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.coach_students cs
     WHERE cs.coach_id = auth.uid() AND cs.student_id = study_sessions.user_id AND cs.status = 'active'
  )
);

DROP POLICY IF EXISTS "exam_results_coach_select" ON public.exam_results;
CREATE POLICY "exam_results_coach_select" ON public.exam_results FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.coach_students cs
     WHERE cs.coach_id = auth.uid() AND cs.student_id = exam_results.user_id AND cs.status = 'active'
  )
);


-- ═════════════════════════════════════════════════════════════════════
-- 13. Bahçe Mağazası (Yıldız Harcama — Sunucu Taraflı Fiyat)
-- ═════════════════════════════════════════════════════════════════════
-- Fiyatlar istemciden ALINMAZ: istemci sadece ürün kimliğini gönderir,
-- fiyat bu katalog tablosundan okunur. p_purchase_id idempotency anahtarıdır;
-- aynı satın alma iki kez gönderilirse ikinci çağrı yıldız düşmez.
-- Bu blok Supabase SQL Editor'de TEK SEFERLİK çalıştırılmalıdır (idempotent).
CREATE TABLE IF NOT EXISTS public.garden_items (
  id     TEXT PRIMARY KEY,
  name   TEXT NOT NULL,
  price  INTEGER NOT NULL CHECK (price > 0)
);

ALTER TABLE public.garden_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "garden_items_select_all" ON public.garden_items;
CREATE POLICY "garden_items_select_all" ON public.garden_items FOR SELECT USING (auth.uid() IS NOT NULL);

INSERT INTO public.garden_items (id, name, price) VALUES
  ('seed_papatya',  'Papatya Tohumu',    20),
  ('seed_lale',     'Lale Soğanı',       30),
  ('seed_limon',    'Limon Fidesi',      45),
  ('seed_kaktus',   'Kaktüs',            40),
  ('seed_gunebakan','Ayçiçeği Tohumu',   35),
  ('seed_hus',      'Gümüş Huş',         60),
  ('seed_kiraz',    'Kiraz Fidanı',      80),
  ('seed_cam',      'Çam Fidanı',        70),
  ('deco_bank',     'Ahşap Bank',        50),
  ('deco_fener',    'Bahçe Feneri',      40),
  ('deco_gol',      'Küçük Gölet',      120),
  ('deco_kus',      'Kuş Evi',           60),
  ('pot_extra',     'Yeni Saksı',       100)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, price = EXCLUDED.price;

CREATE OR REPLACE FUNCTION public.buy_garden_item(p_item_id TEXT, p_purchase_id TEXT)
RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid     UUID := auth.uid();
  v_price   INTEGER;
  v_balance INTEGER;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  IF p_purchase_id IS NULL OR length(p_purchase_id) > 64 THEN
    RAISE EXCEPTION 'Invalid purchase id';
  END IF;

  SELECT price INTO v_price FROM public.garden_items WHERE id = p_item_id;
  IF v_price IS NULL THEN RAISE EXCEPTION 'Unknown item'; END IF;

  IF EXISTS (SELECT 1 FROM public.star_transactions
              WHERE user_id = v_uid AND reason = 'purchase' AND ref_id = p_purchase_id) THEN
    SELECT balance INTO v_balance FROM public.wallets WHERE user_id = v_uid;
    RETURN COALESCE(v_balance, 0);
  END IF;

  UPDATE public.wallets SET balance = balance - v_price, updated_at = NOW()
   WHERE user_id = v_uid AND balance >= v_price
   RETURNING balance INTO v_balance;
  IF v_balance IS NULL THEN RAISE EXCEPTION 'Insufficient stars'; END IF;

  INSERT INTO public.star_transactions (user_id, amount, reason, ref_id)
  VALUES (v_uid, -v_price, 'purchase', p_purchase_id);

  RETURN v_balance;
END;
$$;


-- ═════════════════════════════════════════════════════════════════════
-- 14. Öğrenci Gönderileri (Topluluk Akışı) + Koç Görevi Sıkılaştırması
-- ═════════════════════════════════════════════════════════════════════
-- Bu blok Supabase SQL Editor'de TEK SEFERLİK çalıştırılmalıdır (idempotent).
--
-- a) Topluluk → Akış ekranında öğrenciler soru / rutin / "koç arıyorum"
--    gönderisi paylaşır. Önceki politika gönderiyi sadece admin/baskan
--    rollerine açıyordu. Artık her giriş yapmış kullanıcı YALNIZCA kendi
--    adına (user_id = auth.uid()) gönderi ekleyebilir; kendi gönderisini
--    silebilir. Spam'e karşı saatte en fazla 5 gönderi sınırı sunucuda
--    uygulanır. support_count / quality_score istemciden yazılamaz.

DROP POLICY IF EXISTS "posts_insert_auth" ON public.posts;
DROP POLICY IF EXISTS "posts_insert_own" ON public.posts;
CREATE POLICY "posts_insert_own" ON public.posts FOR INSERT WITH CHECK (
  auth.uid() IS NOT NULL
  AND user_id = auth.uid()
  AND support_count = 0
  AND quality_score = 0
);

DROP POLICY IF EXISTS "posts_delete_own" ON public.posts;
CREATE POLICY "posts_delete_own" ON public.posts FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_posts_user_date ON public.posts(user_id, created_at);

CREATE OR REPLACE FUNCTION public._posts_rate_limit()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role IN ('admin', 'baskan')) THEN
    RETURN NEW;
  END IF;
  IF (SELECT COUNT(*) FROM public.posts
       WHERE user_id = NEW.user_id AND created_at > NOW() - INTERVAL '1 hour') >= 5 THEN
    RAISE EXCEPTION 'Çok sık gönderi paylaşıyorsun, biraz sonra tekrar dene.';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_posts_rate_limit ON public.posts;
CREATE TRIGGER trg_posts_rate_limit
BEFORE INSERT ON public.posts
FOR EACH ROW EXECUTE FUNCTION public._posts_rate_limit();

-- b) koc_tasks_student_update politikası öğrencinin kendi görev satırındaki
--    HER sütunu (konu, koç notu, soru sayısı, hatta coach_id) değiştirmesine
--    izin veriyordu. RLS sütun bazlı kısıt koyamadığı için bir tetikleyici,
--    öğrencinin yalnızca `status` alanını 'pending' ↔ 'completed' arasında
--    değiştirebilmesini sağlar ('approved' koçun işidir).

CREATE OR REPLACE FUNCTION public._koc_tasks_student_guard()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF auth.uid() = OLD.student_id AND auth.uid() IS DISTINCT FROM OLD.coach_id
     AND NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin') THEN
    IF NEW.student_id IS DISTINCT FROM OLD.student_id
       OR NEW.coach_id IS DISTINCT FROM OLD.coach_id
       OR NEW.subject IS DISTINCT FROM OLD.subject
       OR NEW.topic IS DISTINCT FROM OLD.topic
       OR NEW.coach_note IS DISTINCT FROM OLD.coach_note
       OR NEW.question_count IS DISTINCT FROM OLD.question_count
       OR NEW.duration_minutes IS DISTINCT FROM OLD.duration_minutes
       OR NEW.book_info IS DISTINCT FROM OLD.book_info
       OR NEW.task_date IS DISTINCT FROM OLD.task_date
       OR NEW.created_at IS DISTINCT FROM OLD.created_at THEN
      RAISE EXCEPTION 'Öğrenci yalnızca görevin durumunu güncelleyebilir.';
    END IF;
    IF NEW.status NOT IN ('pending', 'completed') THEN
      RAISE EXCEPTION 'Geçersiz görev durumu.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_koc_tasks_student_guard ON public.koc_tasks;
CREATE TRIGGER trg_koc_tasks_student_guard
BEFORE UPDATE ON public.koc_tasks
FOR EACH ROW EXECUTE FUNCTION public._koc_tasks_student_guard();


-- ═════════════════════════════════════════════════════════════════════
-- 15. Güvenlik Sıkılaştırması (guvenlik_denetimi.md — 2026-09-29)
-- ═════════════════════════════════════════════════════════════════════
-- Supabase SQL Editor'de TEK SEFERLİK çalıştırılmalıdır (idempotent — tekrar
-- çalıştırmak güvenlidir). Bu blok olmadan uygulamanın yeni sürümündeki
-- rozet XP'si, gönderi şikâyet/engelleme ve koç davet akışı çalışmaz.
--
-- Kapsanan bulgular: K1 (profil INSERT ile admin olma), Y1 (sınırsız XP),
-- Y2/Y3 (yıldız RPC'leri ve anon EXECUTE yetkisi), Y4 (moderasyon, dış görsel,
-- topluluk adı taklidi), Y5 (okuma kapsamı), Y6 (çalışma odası Realtime),
-- Y8 (profiles politika özyinelemesi), O1-O4, D2.

-- ─── a) Rol yardımcıları (Y8) ────────────────────────────────────────
-- Politikaların profiles tablosunu doğrudan sorgulaması "infinite recursion"
-- hatasına yol açar. SECURITY DEFINER fonksiyon tablo sahibinin yetkisiyle
-- çalıştığı için RLS'yi yeniden tetiklemez.
CREATE OR REPLACE FUNCTION public.my_role() RETURNS TEXT
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS
$$ SELECT role FROM public.profiles WHERE id = auth.uid() $$;

CREATE OR REPLACE FUNCTION public.is_admin() RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS
$$ SELECT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin') $$;

DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN SELECT * FROM (VALUES
    ('profiles', 'profiles_admin_all'),
    ('communities', 'communities_admin_all'),
    ('posts', 'posts_admin_all'),
    ('user_tickets', 'tickets_admin_all'),
    ('koc_tasks', 'koc_tasks_admin_all'),
    ('curricula', 'curricula_admin_all'),
    ('subjects', 'subjects_admin_all'),
    ('topics', 'topics_admin_all'),
    ('wallets', 'wallets_admin_all'),
    ('star_transactions', 'star_tx_admin_all'),
    ('coach_students', 'coach_students_admin_all'),
    ('study_sessions', 'study_sessions_admin_all'),
    ('exam_results', 'exam_results_admin_all'),
    ('community_members', 'community_members_admin_all'),
    ('nudges', 'nudges_admin_all')
  ) AS t(tbl, pol) LOOP
    IF to_regclass('public.' || r.tbl) IS NOT NULL THEN
      EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', r.pol, r.tbl);
      EXECUTE format('CREATE POLICY %I ON public.%I FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin())', r.pol, r.tbl);
    END IF;
  END LOOP;
END $$;

-- ─── b) Profil oluşturma ve kilitli alanlar (K1) ─────────────────────
-- İstemci artık yalnızca role='student' ve xp=0 ile profil ekleyebilir.
DROP POLICY IF EXISTS "profiles_insert_own" ON public.profiles;
CREATE POLICY "profiles_insert_own" ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id AND role = 'student' AND xp = 0);

-- Kendi satırını güncelleyebilir; role/xp/id/created_at değişiklikleri aşağıdaki
-- tetikleyici tarafından yok sayılır (alt sorgulu WITH CHECK özyineleme yapıyordu).
DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
CREATE POLICY "profiles_update_own" ON public.profiles FOR UPDATE
  USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- current_user REST isteklerinde 'authenticated'/'anon'dur; SECURITY DEFINER
-- fonksiyonların (award_badge_xp vb.) içinde ise fonksiyon sahibidir.
CREATE OR REPLACE FUNCTION public._profiles_protect_fields() RETURNS TRIGGER
LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
  IF current_user IN ('authenticated', 'anon') AND NOT public.is_admin() THEN
    NEW.id := OLD.id;
    NEW.role := OLD.role;
    NEW.xp := OLD.xp;
    NEW.created_at := OLD.created_at;
  END IF;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_profiles_protect_fields ON public.profiles;
CREATE TRIGGER trg_profiles_protect_fields
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public._profiles_protect_fields();

-- Profil, kayıt anında sunucuda oluşturulur (istemci ilk girişten önce
-- kendi profilini keyfi değerlerle ekleyemesin diye).
CREATE OR REPLACE FUNCTION public.handle_new_user() RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_name  TEXT := NULLIF(trim(COALESCE(NEW.raw_user_meta_data->>'name', '')), '');
  v_grade TEXT := NULLIF(trim(COALESCE(NEW.raw_user_meta_data->>'grade', '')), '');
  v_dept  TEXT := NULLIF(trim(COALESCE(NEW.raw_user_meta_data->>'department', '')), '');
BEGIN
  INSERT INTO public.profiles (id, name, role, xp, grade, department)
  VALUES (
    NEW.id,
    left(COALESCE(v_name, NULLIF(split_part(COALESCE(NEW.email, ''), '@', 1), ''), 'Öğrenci'), 60),
    'student',
    0,
    left(v_grade, 20),
    CASE WHEN v_dept IS NULL THEN '{}'::TEXT[] ELSE ARRAY[left(v_dept, 40)] END
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Profili olmayan mevcut kullanıcılar için geriye dönük doldurma.
INSERT INTO public.profiles (id, name, role, xp)
SELECT u.id, left(COALESCE(NULLIF(split_part(COALESCE(u.email, ''), '@', 1), ''), 'Öğrenci'), 60), 'student', 0
FROM auth.users u
WHERE NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = u.id);

-- ÖNEMLİ: Bu migration'dan önce yetkisiz admin oluşturulmuş olabilir. Kontrol edin:
--   SELECT id, name, role, created_at FROM public.profiles
--    WHERE role IN ('admin', 'baskan', 'coach') ORDER BY created_at DESC;

-- ─── c) Okuma kapsamı (Y5) ───────────────────────────────────────────
-- Profil: kendisi, aktif koç/öğrencisi, aynı topluluktaki üyeler (+ admin).
DROP POLICY IF EXISTS "profiles_select_authenticated" ON public.profiles;
DROP POLICY IF EXISTS "profiles_select_scoped" ON public.profiles;
CREATE POLICY "profiles_select_scoped" ON public.profiles FOR SELECT USING (
  auth.uid() = id
  OR EXISTS (
    SELECT 1 FROM public.coach_students cs
     WHERE cs.status = 'active'
       AND ((cs.coach_id = auth.uid() AND cs.student_id = profiles.id)
         OR (cs.student_id = auth.uid() AND cs.coach_id = profiles.id))
  )
  OR EXISTS (
    SELECT 1 FROM public.community_members me
      JOIN public.community_members them ON them.community_id = me.community_id
     WHERE me.user_id = auth.uid() AND them.user_id = profiles.id
  )
);

DROP POLICY IF EXISTS "community_members_select_all" ON public.community_members;
DROP POLICY IF EXISTS "community_members_select_auth" ON public.community_members;
CREATE POLICY "community_members_select_auth" ON public.community_members
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- ─── d) Moderasyon: şikâyet, engelleme, kelime filtresi (Y4) ─────────
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS hidden BOOLEAN NOT NULL DEFAULT false;

CREATE TABLE IF NOT EXISTS public.user_blocks (
  blocker_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  blocked_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (blocker_id, blocked_id),
  CHECK (blocker_id <> blocked_id)
);
ALTER TABLE public.user_blocks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "user_blocks_own" ON public.user_blocks;
CREATE POLICY "user_blocks_own" ON public.user_blocks FOR ALL
  USING (auth.uid() = blocker_id) WITH CHECK (auth.uid() = blocker_id);

CREATE TABLE IF NOT EXISTS public.post_reports (
  post_id     BIGINT NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  reporter_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  reason      TEXT NOT NULL CHECK (reason IN ('uygunsuz', 'taciz', 'spam', 'kisisel_bilgi', 'diger')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (post_id, reporter_id)
);
ALTER TABLE public.post_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "post_reports_insert_own" ON public.post_reports;
CREATE POLICY "post_reports_insert_own" ON public.post_reports FOR INSERT
  WITH CHECK (auth.uid() = reporter_id);
DROP POLICY IF EXISTS "post_reports_select_own" ON public.post_reports;
CREATE POLICY "post_reports_select_own" ON public.post_reports FOR SELECT
  USING (auth.uid() = reporter_id);
DROP POLICY IF EXISTS "post_reports_admin_all" ON public.post_reports;
CREATE POLICY "post_reports_admin_all" ON public.post_reports FOR ALL
  USING (public.is_admin()) WITH CHECK (public.is_admin());

-- 3 farklı kullanıcı şikâyet ederse gönderi admin incelemesine kadar gizlenir.
CREATE OR REPLACE FUNCTION public._post_reports_autohide() RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF (SELECT COUNT(*) FROM public.post_reports WHERE post_id = NEW.post_id) >= 3 THEN
    UPDATE public.posts SET hidden = true WHERE id = NEW.post_id;
  END IF;
  RETURN NULL;
END $$;
DROP TRIGGER IF EXISTS trg_post_reports_autohide ON public.post_reports;
CREATE TRIGGER trg_post_reports_autohide
AFTER INSERT ON public.post_reports
FOR EACH ROW EXECUTE FUNCTION public._post_reports_autohide();

CREATE TABLE IF NOT EXISTS public.moderation_words (word TEXT PRIMARY KEY);
ALTER TABLE public.moderation_words ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "moderation_words_admin_all" ON public.moderation_words;
CREATE POLICY "moderation_words_admin_all" ON public.moderation_words FOR ALL
  USING (public.is_admin()) WITH CHECK (public.is_admin());
-- Başlangıç listesi; admin panelinden/SQL'den genişletilebilir (küçük harf, tek kelime).
INSERT INTO public.moderation_words (word) VALUES
  ('amk'), ('aq'), ('orospu'), ('siktir'), ('sikerim'), ('yavşak'), ('piç'), ('ananı'), ('gavat'), ('pezevenk')
ON CONFLICT (word) DO NOTHING;

-- Gönderi eklenirken: topluluk adı/logosu sunucudaki kayıttan doldurulur
-- (istemci "LiseNET Yönetimi" gibi sahte bir ad yazamaz), dış görsel bağlantısı
-- kabul edilmez (izleyenlerin IP adresi sızmasın) ve kelime filtresi uygulanır.
CREATE OR REPLACE FUNCTION public._posts_before_insert() RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_name TEXT;
  v_logo TEXT;
BEGIN
  IF NEW.community_id IS NOT NULL THEN
    SELECT name, logo_path INTO v_name, v_logo FROM public.communities WHERE id = NEW.community_id;
    IF v_name IS NULL THEN RAISE EXCEPTION 'Topluluk bulunamadı.'; END IF;
  END IF;
  NEW.community_name := COALESCE(v_name, 'LiseNET Topluluğu');
  NEW.community_logo := v_logo;
  NEW.image_url := NULL;
  NEW.hidden := false;

  IF EXISTS (
    SELECT 1 FROM public.moderation_words w
     WHERE lower(NEW.content) ~ ('(^|[^[:alnum:]])' || w.word || '($|[^[:alnum:]])')
  ) THEN
    RAISE EXCEPTION 'Gönderin topluluk kurallarına uymayan ifadeler içeriyor.';
  END IF;
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS trg_posts_before_insert ON public.posts;
CREATE TRIGGER trg_posts_before_insert
BEFORE INSERT ON public.posts
FOR EACH ROW EXECUTE FUNCTION public._posts_before_insert();

-- Giriş yapmamış istemci gönderi okuyamaz; gizlenen gönderileri yalnızca
-- sahibi (ve admin) görür; engellediğin kişilerin gönderileri gelmez.
DROP POLICY IF EXISTS "posts_select_all" ON public.posts;
DROP POLICY IF EXISTS "posts_select_auth" ON public.posts;
CREATE POLICY "posts_select_auth" ON public.posts FOR SELECT USING (
  auth.uid() IS NOT NULL
  AND (hidden = false OR user_id = auth.uid())
  AND NOT EXISTS (
    SELECT 1 FROM public.user_blocks b
     WHERE b.blocker_id = auth.uid() AND b.blocked_id = posts.user_id
  )
);

DROP POLICY IF EXISTS "posts_insert_own" ON public.posts;
CREATE POLICY "posts_insert_own" ON public.posts FOR INSERT WITH CHECK (
  auth.uid() IS NOT NULL
  AND user_id = auth.uid()
  AND support_count = 0
  AND quality_score = 0
);

-- Engellediğin biri seni dürtemez.
CREATE OR REPLACE FUNCTION public.send_nudge(p_community_id BIGINT, p_to_user_id UUID)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  IF v_uid = p_to_user_id THEN RAISE EXCEPTION 'Kendine dürtme gönderemezsin'; END IF;

  IF NOT EXISTS (SELECT 1 FROM public.community_members WHERE community_id = p_community_id AND user_id = v_uid) THEN
    RAISE EXCEPTION 'Bu topluluğun üyesi değilsin';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.community_members WHERE community_id = p_community_id AND user_id = p_to_user_id) THEN
    RAISE EXCEPTION 'Alıcı bu topluluğun üyesi değil';
  END IF;
  IF EXISTS (SELECT 1 FROM public.user_blocks WHERE blocker_id = p_to_user_id AND blocked_id = v_uid) THEN
    RAISE EXCEPTION 'Bu kişiye dürtme gönderilemiyor';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.nudges
     WHERE from_user_id = v_uid AND to_user_id = p_to_user_id
       AND created_at > NOW() - INTERVAL '1 hour'
  ) THEN
    RAISE EXCEPTION 'Bu kişiyi az önce dürttün, bir süre sonra tekrar deneyebilirsin';
  END IF;

  INSERT INTO public.nudges (community_id, from_user_id, to_user_id) VALUES (p_community_id, v_uid, p_to_user_id);
END;
$$;

-- ─── e) Rozet tabanlı XP (Y1) ────────────────────────────────────────
-- Her rozet kullanıcı başına bir kez XP verir; tutar sunucudaki katalogdan
-- okunur. award_xp(amount) aşağıda istemciye kapatılıyor.
CREATE TABLE IF NOT EXISTS public.badge_catalog (
  id TEXT PRIMARY KEY,
  xp INTEGER NOT NULL CHECK (xp > 0 AND xp <= 500)
);
ALTER TABLE public.badge_catalog ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "badge_catalog_select_auth" ON public.badge_catalog;
CREATE POLICY "badge_catalog_select_auth" ON public.badge_catalog FOR SELECT USING (auth.uid() IS NOT NULL);

-- lib/data/models/rozet.dart → rozetKatalogu ile aynı tutulmalı.
INSERT INTO public.badge_catalog (id, xp) VALUES
  ('ilk_adim', 10), ('bes_deneme', 25), ('yedi_gun_seri', 30), ('otuz_gun_seri', 100),
  ('ilk_konu', 10), ('on_konu', 50), ('elli_tekrar', 40)
ON CONFLICT (id) DO UPDATE SET xp = EXCLUDED.xp;

CREATE TABLE IF NOT EXISTS public.badge_awards (
  user_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  badge_id   TEXT NOT NULL REFERENCES public.badge_catalog(id) ON DELETE CASCADE,
  awarded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, badge_id)
);
ALTER TABLE public.badge_awards ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "badge_awards_select_own" ON public.badge_awards;
CREATE POLICY "badge_awards_select_own" ON public.badge_awards FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "badge_awards_admin_all" ON public.badge_awards;
CREATE POLICY "badge_awards_admin_all" ON public.badge_awards FOR ALL
  USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE OR REPLACE FUNCTION public.award_badge_xp(p_badge_id TEXT)
RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_xp  INTEGER;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  SELECT xp INTO v_xp FROM public.badge_catalog WHERE id = p_badge_id;
  IF v_xp IS NULL THEN RAISE EXCEPTION 'Unknown badge'; END IF;

  INSERT INTO public.badge_awards (user_id, badge_id) VALUES (v_uid, p_badge_id)
  ON CONFLICT (user_id, badge_id) DO NOTHING;
  IF NOT FOUND THEN RETURN 0; END IF;

  UPDATE public.profiles SET xp = COALESCE(xp, 0) + v_xp WHERE id = v_uid;
  RETURN v_xp;
END $$;

-- ─── f) Deneme karşılaştırması (O3) ──────────────────────────────────
CREATE OR REPLACE FUNCTION public.submit_exam_result(
  p_deneme_adi TEXT, p_alan TEXT, p_ders TEXT,
  p_dogru INTEGER, p_yanlis INTEGER, p_bos INTEGER
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  IF p_alan NOT IN ('TYT', 'AYT') THEN RAISE EXCEPTION 'invalid alan'; END IF;
  IF p_deneme_adi IS NULL OR length(trim(p_deneme_adi)) = 0 OR length(p_deneme_adi) > 80 THEN
    RAISE EXCEPTION 'invalid deneme_adi';
  END IF;
  IF p_ders IS NULL OR length(trim(p_ders)) = 0 OR length(p_ders) > 40 THEN RAISE EXCEPTION 'invalid ders'; END IF;
  IF p_dogru IS NULL OR p_yanlis IS NULL OR p_bos IS NULL
     OR p_dogru < 0 OR p_yanlis < 0 OR p_bos < 0 OR p_dogru + p_yanlis + p_bos > 50 THEN
    RAISE EXCEPTION 'invalid counts';
  END IF;

  INSERT INTO public.exam_results (user_id, deneme_adi, alan, ders, dogru, yanlis, bos)
  VALUES (v_uid, trim(p_deneme_adi), p_alan, trim(p_ders), p_dogru, p_yanlis, p_bos)
  ON CONFLICT (user_id, deneme_adi, alan, ders)
  DO UPDATE SET dogru = EXCLUDED.dogru, yanlis = EXCLUDED.yanlis, bos = EXCLUDED.bos, submitted_at = NOW();
END;
$$;

-- 5'ten az katılımcı varsa hiç satır dönmez (tek kişinin neti açığa çıkmasın).
CREATE OR REPLACE FUNCTION public.get_exam_benchmark(p_deneme_adi TEXT, p_alan TEXT, p_ders TEXT)
RETURNS TABLE(katilimci_sayisi INTEGER, ortalama_net NUMERIC, standart_sapma NUMERIC)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT
    COUNT(*)::INTEGER,
    ROUND(AVG(net), 2),
    ROUND(COALESCE(STDDEV_SAMP(net), 0), 2)
  FROM public.exam_results
  WHERE auth.uid() IS NOT NULL
    AND lower(deneme_adi) = lower(trim(p_deneme_adi))
    AND alan = p_alan AND ders = p_ders
  HAVING COUNT(*) >= 5;
$$;

-- ─── g) Koç davet kodu (O2) ──────────────────────────────────────────
ALTER TABLE public.coach_students ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ;
UPDATE public.coach_students
   SET expires_at = NOW() + INTERVAL '48 hours'
 WHERE status = 'pending' AND expires_at IS NULL;

CREATE TABLE IF NOT EXISTS public.coach_invite_attempts (
  id         BIGSERIAL PRIMARY KEY,
  user_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_coach_invite_attempts_user ON public.coach_invite_attempts(user_id, created_at);
ALTER TABLE public.coach_invite_attempts ENABLE ROW LEVEL SECURITY;
-- Politika yok: yalnızca SECURITY DEFINER fonksiyon yazar/okur.

CREATE OR REPLACE FUNCTION public.create_coach_invite()
RETURNS TEXT LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid  UUID := auth.uid();
  v_code TEXT;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = v_uid AND p.role IN ('baskan', 'coach', 'admin')) THEN
    RAISE EXCEPTION 'Only coaches can create invites';
  END IF;
  IF (SELECT COUNT(*) FROM public.coach_students
       WHERE coach_id = v_uid AND status = 'pending' AND expires_at > NOW()) >= 20 THEN
    RAISE EXCEPTION 'Çok fazla bekleyen davet kodun var; önce mevcut kodların kullanılmasını bekle.';
  END IF;

  v_code := upper(encode(extensions.gen_random_bytes(5), 'hex'));

  INSERT INTO public.coach_students (coach_id, student_id, status, invite_code, expires_at)
  VALUES (v_uid, NULL, 'pending', v_code, NOW() + INTERVAL '48 hours');

  RETURN v_code;
END;
$$;

-- Dönüş: 'ok' | 'invalid' | 'self' | 'rate_limited'. Hatalı denemeler kaydedilir
-- (saatte 10 deneme) — RAISE yerine değer döndürülür ki kayıt geri alınmasın.
DROP FUNCTION IF EXISTS public.accept_coach_invite(TEXT);
CREATE FUNCTION public.accept_coach_invite(p_invite_code TEXT)
RETURNS TEXT LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_row public.coach_students%rowtype;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;

  -- Kötüye kullanım kayıtları 30 günden fazla tutulmaz (gizlilik politikası §5).
  DELETE FROM public.coach_invite_attempts WHERE created_at < NOW() - INTERVAL '30 days';

  IF (SELECT COUNT(*) FROM public.coach_invite_attempts
       WHERE user_id = v_uid AND created_at > NOW() - INTERVAL '1 hour') >= 10 THEN
    RETURN 'rate_limited';
  END IF;

  SELECT * INTO v_row FROM public.coach_students
   WHERE invite_code = upper(trim(p_invite_code))
     AND status = 'pending'
     AND expires_at > NOW()
   FOR UPDATE;
  IF NOT FOUND THEN
    INSERT INTO public.coach_invite_attempts (user_id) VALUES (v_uid);
    RETURN 'invalid';
  END IF;
  IF v_row.coach_id = v_uid THEN RETURN 'self'; END IF;

  UPDATE public.coach_students
     SET student_id = v_uid, status = 'active', updated_at = NOW()
   WHERE id = v_row.id;
  RETURN 'ok';
END;
$$;

-- ─── h) Hesap silmede gönderiler de silinir (O4) ─────────────────────
CREATE OR REPLACE FUNCTION public.delete_account()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  DELETE FROM public.posts WHERE user_id = v_user_id;
  DELETE FROM auth.users WHERE id = v_user_id;
END;
$$;

-- ─── i) Diğer sıkılaştırmalar (O1, D2) ───────────────────────────────
ALTER FUNCTION public.update_post_quality(BIGINT, REAL) SET search_path = public;

ALTER TABLE public.student_data DROP CONSTRAINT IF EXISTS student_data_size_chk;
ALTER TABLE public.student_data
  ADD CONSTRAINT student_data_size_chk CHECK (pg_column_size(data_value) < 524288) NOT VALID;

-- ─── j) Fonksiyon çalıştırma yetkileri (Y2, Y3) ──────────────────────
-- Supabase, public şemasındaki fonksiyonlara anon ve authenticated rollerine
-- ayrıca EXECUTE verir; "REVOKE ... FROM PUBLIC" tek başına yetmez.
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC, anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC, anon;

-- Politikalarda kullanıldıkları için her rol çağırabilmeli.
GRANT EXECUTE ON FUNCTION public.is_admin() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.my_role() TO anon, authenticated;

-- Uygulamanın kullanmadığı ya da hileye açık fonksiyonlar istemciye kapatılır.
DO $$
DECLARE f TEXT;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'public._stars_earned_today(uuid, text)',
    'public.award_goal_stars(text, integer)',
    'public.award_checkin_stars(date)',
    'public.award_pomodoro_stars(text, integer)',
    'public.spend_stars(integer, text, text)',
    'public.update_post_quality(bigint, real)',
    'public.award_xp(integer)',
    'public.clone_curriculum(uuid)',
    'public._sync_community_member_count()',
    'public._posts_rate_limit()',
    'public._posts_before_insert()',
    'public._post_reports_autohide()',
    'public._koc_tasks_student_guard()',
    'public._profiles_protect_fields()',
    'public.handle_new_user()'
  ] LOOP
    IF to_regprocedure(f) IS NOT NULL THEN
      EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM PUBLIC, anon, authenticated', f);
    END IF;
  END LOOP;
END $$;

-- Kontrol sorgusu:
--   SELECT routine_name, grantee FROM information_schema.routine_privileges
--    WHERE routine_schema = 'public' AND grantee IN ('anon', 'authenticated') ORDER BY 1, 2;

-- ─── k) Çalışma odası Realtime yetkilendirmesi (Y6) ──────────────────
-- İstemci kanalı `private: true` ile açar; yalnızca o topluluğun üyeleri
-- presence/broadcast okuyup yazabilir. Supabase panelinde Realtime ›
-- Settings › "Allow public access" KAPATILMALIDIR.
DO $$
BEGIN
  IF to_regclass('realtime.messages') IS NOT NULL THEN
    EXECUTE 'DROP POLICY IF EXISTS "lisenet_study_room_read" ON realtime.messages';
    EXECUTE $p$
      CREATE POLICY "lisenet_study_room_read" ON realtime.messages
      FOR SELECT TO authenticated USING (
        (SELECT realtime.topic()) LIKE 'study_room_%'
        AND EXISTS (
          SELECT 1 FROM public.community_members cm
           WHERE cm.user_id = (SELECT auth.uid())
             AND cm.community_id::TEXT = substring((SELECT realtime.topic()) FROM 12)
        )
      )$p$;
    EXECUTE 'DROP POLICY IF EXISTS "lisenet_study_room_write" ON realtime.messages';
    EXECUTE $p$
      CREATE POLICY "lisenet_study_room_write" ON realtime.messages
      FOR INSERT TO authenticated WITH CHECK (
        (SELECT realtime.topic()) LIKE 'study_room_%'
        AND EXISTS (
          SELECT 1 FROM public.community_members cm
           WHERE cm.user_id = (SELECT auth.uid())
             AND cm.community_id::TEXT = substring((SELECT realtime.topic()) FROM 12)
        )
      )$p$;
  END IF;
END $$;


-- ═════════════════════════════════════════════════════════════════════
-- 16. Koç Asistanı (bulut yanıtları: açık rıza + günlük kota)
-- ═════════════════════════════════════════════════════════════════════
-- Supabase SQL Editor'de TEK SEFERLİK çalıştırılmalıdır (idempotent).
-- Asistanın cihaz içi analizleri bu tabloya ihtiyaç duymaz; yalnızca
-- `koc-asistan` Edge Function'ı (Claude API) kullanılırken gerekir.
--
-- Bulut yanıtları öğrencinin çalışma özetini yurt dışındaki bir yapay zeka
-- sağlayıcısına (Anthropic) gönderdiği için AÇIK RIZA ile açılır; rıza
-- zamanı kaydedilir ve öğrenci istediği an geri alabilir.

CREATE TABLE IF NOT EXISTS public.assistant_consents (
  user_id      UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  consented_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.assistant_consents ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "assistant_consents_select_own" ON public.assistant_consents;
CREATE POLICY "assistant_consents_select_own" ON public.assistant_consents
  FOR SELECT USING (auth.uid() = user_id);
-- Yazma yalnızca aşağıdaki fonksiyonlarla.

CREATE TABLE IF NOT EXISTS public.assistant_usage (
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  gun     DATE NOT NULL DEFAULT CURRENT_DATE,
  adet    INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (user_id, gun)
);
ALTER TABLE public.assistant_usage ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "assistant_usage_select_own" ON public.assistant_usage;
CREATE POLICY "assistant_usage_select_own" ON public.assistant_usage
  FOR SELECT USING (auth.uid() = user_id);

-- Günlük mesaj sınırı (maliyet ve kötüye kullanım koruması).
CREATE OR REPLACE FUNCTION public._asistan_gunluk_sinir() RETURNS INTEGER
LANGUAGE sql IMMUTABLE AS $$ SELECT 20 $$;

CREATE OR REPLACE FUNCTION public.asistan_onay_ver() RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  INSERT INTO public.assistant_consents (user_id) VALUES (auth.uid())
  ON CONFLICT (user_id) DO UPDATE SET consented_at = NOW();
END $$;

CREATE OR REPLACE FUNCTION public.asistan_onay_geri_al() RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  DELETE FROM public.assistant_consents WHERE user_id = auth.uid();
END $$;

-- Rıza ve bugünkü kalan hak.
CREATE OR REPLACE FUNCTION public.asistan_durum()
RETURNS TABLE(onay BOOLEAN, kalan INTEGER)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT
    EXISTS (SELECT 1 FROM public.assistant_consents WHERE user_id = auth.uid()),
    GREATEST(0, public._asistan_gunluk_sinir() - COALESCE(
      (SELECT adet FROM public.assistant_usage WHERE user_id = auth.uid() AND gun = CURRENT_DATE), 0))
  WHERE auth.uid() IS NOT NULL;
$$;

-- Edge Function her mesajdan önce çağırır. Dönüş: 'ok' | 'no_consent' | 'limit'.
CREATE OR REPLACE FUNCTION public.asistan_kota_kullan() RETURNS TEXT
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid  UUID := auth.uid();
  v_adet INTEGER;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.assistant_consents WHERE user_id = v_uid) THEN
    RETURN 'no_consent';
  END IF;

  -- Eski kullanım kayıtları 30 günden fazla tutulmaz.
  DELETE FROM public.assistant_usage WHERE gun < CURRENT_DATE - 30;

  INSERT INTO public.assistant_usage (user_id, gun, adet) VALUES (v_uid, CURRENT_DATE, 1)
  ON CONFLICT (user_id, gun) DO UPDATE SET adet = assistant_usage.adet + 1
  RETURNING adet INTO v_adet;

  IF v_adet > public._asistan_gunluk_sinir() THEN
    UPDATE public.assistant_usage SET adet = public._asistan_gunluk_sinir()
     WHERE user_id = v_uid AND gun = CURRENT_DATE;
    RETURN 'limit';
  END IF;
  RETURN 'ok';
END $$;

REVOKE EXECUTE ON FUNCTION public._asistan_gunluk_sinir() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.asistan_onay_ver() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.asistan_onay_geri_al() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.asistan_durum() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.asistan_kota_kullan() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.asistan_onay_ver() TO authenticated;
GRANT EXECUTE ON FUNCTION public.asistan_onay_geri_al() TO authenticated;
GRANT EXECUTE ON FUNCTION public.asistan_durum() TO authenticated;
GRANT EXECUTE ON FUNCTION public.asistan_kota_kullan() TO authenticated;


-- ═════════════════════════════════════════════════════════════════════
-- 17. Etüt Odaları (10 hazır oda, oda başına en fazla 30 kişi)
-- ═════════════════════════════════════════════════════════════════════
-- Supabase SQL Editor'de TEK SEFERLİK çalıştırılmalıdır (idempotent;
-- tekrar çalıştırmak zarar vermez).
--
-- * Bir öğrenci aynı anda tek bir etüt odasında bulunur; başka odaya
--   geçince katılma zamanı yenilenir.
-- * Sıralama, öğrencinin odaya KATILDIĞI andan sonra biten odak
--   oturumlarının (study_sessions, sunucunun ölçtüğü süre) toplamına ve o an
--   sürmekte olan oturumun katılmadan sonraki kısmına göre yapılır.
-- * "Çalışıyor": bitmemiş ve planlanan süresi aşılmamış bir odak oturumu var.
--   "Çevrimiçi": oda ekranı açık (istemci ~30 sn'de bir nabız gönderir).
-- * 14 gün odaya uğramayan üyeler, yer açmak için otomatik çıkarılır.
-- * Tablolara doğrudan erişim yoktur; her şey aşağıdaki SECURITY DEFINER
--   fonksiyonlarla yapılır (kapasite kontrolü yarışa karşı kilitlenir).

CREATE TABLE IF NOT EXISTS public.etut_odalari (
  id        SMALLINT PRIMARY KEY,
  ad        TEXT NOT NULL,
  aciklama  TEXT NOT NULL DEFAULT '',
  kapasite  SMALLINT NOT NULL DEFAULT 30 CHECK (kapasite BETWEEN 1 AND 30),
  sira      SMALLINT NOT NULL DEFAULT 0
);
ALTER TABLE public.etut_odalari ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "etut_odalari_select" ON public.etut_odalari;
CREATE POLICY "etut_odalari_select" ON public.etut_odalari FOR SELECT TO authenticated USING (true);

INSERT INTO public.etut_odalari (id, ad, aciklama, kapasite, sira) VALUES
  (1,  'Sabah Kuşları',        'Güne erken başlayanların sessiz etüdü',            30, 1),
  (2,  'Sayısal Kampı',        'Matematik, fizik, kimya ve biyoloji çalışanlar',   30, 2),
  (3,  'Eşit Ağırlık Masası',  'Matematik, edebiyat, tarih ve coğrafya',           30, 3),
  (4,  'Sözel Salonu',         'Edebiyat, tarih, coğrafya ve felsefe grubu',       30, 4),
  (5,  'TYT Temel',            'Türkçe ve temel matematik ağırlıklı çalışma',      30, 5),
  (6,  'Deneme Maratonu',      'Deneme çözüp yanlışlarını analiz edenler',         30, 6),
  (7,  'Pomodoro Kulübü',      '25-50 dakikalık odak turlarıyla ilerleyenler',     30, 7),
  (8,  'Gece Kütüphanesi',     'Akşam ve gece saatlerinde çalışanlar',             30, 8),
  (9,  'Mezunlar Odası',       'Mezun ve yeniden hazırlanan öğrenciler',           30, 9),
  (10, 'Sessiz Kütüphane',     'Tam odak: sadece çalışma, dikkat dağıtıcı yok',    30, 10)
ON CONFLICT (id) DO UPDATE
  SET ad = EXCLUDED.ad, aciklama = EXCLUDED.aciklama, kapasite = EXCLUDED.kapasite, sira = EXCLUDED.sira;

CREATE TABLE IF NOT EXISTS public.etut_odasi_uyeleri (
  user_id     UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  oda_id      SMALLINT NOT NULL REFERENCES public.etut_odalari(id) ON DELETE CASCADE,
  katilma     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  son_gorulme TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_etut_odasi_uyeleri_oda ON public.etut_odasi_uyeleri(oda_id);
ALTER TABLE public.etut_odasi_uyeleri ENABLE ROW LEVEL SECURITY;
-- Politika yok: yalnızca aşağıdaki fonksiyonlar okur/yazar.

CREATE OR REPLACE FUNCTION public._etut_pasifleri_temizle() RETURNS void
LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  DELETE FROM public.etut_odasi_uyeleri WHERE son_gorulme < NOW() - INTERVAL '14 days';
$$;

-- Tüm odalar: doluluk, şu an çalışan üye sayısı ve kullanıcının odası.
CREATE OR REPLACE FUNCTION public.etut_odalari_listesi()
RETURNS TABLE(id INTEGER, ad TEXT, aciklama TEXT, kapasite INTEGER, uye_sayisi INTEGER, calisan_sayisi INTEGER, benim BOOLEAN)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
#variable_conflict use_column
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  PERFORM public._etut_pasifleri_temizle();
  RETURN QUERY
  SELECT o.id::INTEGER, o.ad, o.aciklama, o.kapasite::INTEGER,
         (SELECT COUNT(*)::INTEGER FROM public.etut_odasi_uyeleri u WHERE u.oda_id = o.id),
         (SELECT COUNT(*)::INTEGER FROM public.etut_odasi_uyeleri u
           WHERE u.oda_id = o.id
             AND EXISTS (SELECT 1 FROM public.study_sessions s
                          WHERE s.user_id = u.user_id AND s.ended_at IS NULL
                            AND s.started_at > NOW() - make_interval(mins => s.planned_minutes + 10))),
         EXISTS (SELECT 1 FROM public.etut_odasi_uyeleri u WHERE u.oda_id = o.id AND u.user_id = v_uid)
    FROM public.etut_odalari o
   ORDER BY o.sira, o.id;
END $$;

-- Odaya katılır. Dönüş: 'ok' | 'dolu' | 'yok'. Başka bir odadaysa oradan
-- ayrılıp bu odaya geçer (katılma zamanı, yani sıralama başlangıcı yenilenir).
CREATE OR REPLACE FUNCTION public.etut_odasina_katil(p_oda_id INTEGER)
RETURNS TEXT LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid      UUID := auth.uid();
  v_kapasite SMALLINT;
  v_sayi     INTEGER;
  v_mevcut   SMALLINT;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;

  -- Aynı odaya eşzamanlı katılımlar sırayla işlenir; kapasite aşılmaz.
  SELECT kapasite INTO v_kapasite FROM public.etut_odalari WHERE id = p_oda_id FOR UPDATE;
  IF NOT FOUND THEN RETURN 'yok'; END IF;

  SELECT oda_id INTO v_mevcut FROM public.etut_odasi_uyeleri WHERE user_id = v_uid;
  IF v_mevcut = p_oda_id THEN
    UPDATE public.etut_odasi_uyeleri SET son_gorulme = NOW() WHERE user_id = v_uid;
    RETURN 'ok';
  END IF;

  PERFORM public._etut_pasifleri_temizle();
  SELECT COUNT(*) INTO v_sayi FROM public.etut_odasi_uyeleri WHERE oda_id = p_oda_id;
  IF v_sayi >= v_kapasite THEN RETURN 'dolu'; END IF;

  INSERT INTO public.etut_odasi_uyeleri (user_id, oda_id, katilma, son_gorulme)
  VALUES (v_uid, p_oda_id, NOW(), NOW())
  ON CONFLICT (user_id) DO UPDATE
    SET oda_id = EXCLUDED.oda_id, katilma = NOW(), son_gorulme = NOW();
  RETURN 'ok';
END $$;

CREATE OR REPLACE FUNCTION public.etut_odasindan_ayril() RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  DELETE FROM public.etut_odasi_uyeleri WHERE user_id = auth.uid();
END $$;

-- Oda ekranı: üyeler, katıldıktan sonraki çalışma dakikaları, şu an çalışıp
-- çalışmadıkları ve çevrimiçi olup olmadıkları. Çağıranın nabzını da günceller.
-- Yalnızca odanın üyeleri çağırabilir.
CREATE OR REPLACE FUNCTION public.etut_odasi_durum(p_oda_id INTEGER)
RETURNS TABLE(
  user_id UUID,
  ad TEXT,
  katilma TIMESTAMPTZ,
  tamamlanan_dk INTEGER,
  aktif_dk INTEGER,
  calisiyor BOOLEAN,
  aktif_ders TEXT,
  cevrimici BOOLEAN,
  ben BOOLEAN
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
#variable_conflict use_column
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  UPDATE public.etut_odasi_uyeleri SET son_gorulme = NOW() WHERE user_id = v_uid AND oda_id = p_oda_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Bu etüt odasının üyesi değilsin'; END IF;

  RETURN QUERY
  SELECT u.user_id,
         COALESCE(NULLIF(p.name, ''), 'Öğrenci'),
         u.katilma,
         COALESCE((
           SELECT SUM(GREATEST(0, LEAST(s.actual_minutes,
                    FLOOR(EXTRACT(EPOCH FROM (s.ended_at - u.katilma)) / 60)::INTEGER)))
             FROM public.study_sessions s
            WHERE s.user_id = u.user_id AND s.ended_at IS NOT NULL AND s.ended_at > u.katilma
         ), 0)::INTEGER,
         CASE WHEN a.started_at IS NULL THEN 0
              ELSE LEAST(a.planned_minutes,
                         GREATEST(0, FLOOR(EXTRACT(EPOCH FROM (NOW() - GREATEST(a.started_at, u.katilma))) / 60)::INTEGER))
         END,
         a.started_at IS NOT NULL,
         a.label,
         u.son_gorulme > NOW() - INTERVAL '75 seconds',
         u.user_id = v_uid
    FROM public.etut_odasi_uyeleri u
    JOIN public.profiles p ON p.id = u.user_id
    LEFT JOIN LATERAL (
      SELECT s.label, s.started_at, s.planned_minutes
        FROM public.study_sessions s
       WHERE s.user_id = u.user_id AND s.ended_at IS NULL
         AND s.started_at > NOW() - make_interval(mins => s.planned_minutes + 10)
       ORDER BY s.started_at DESC
       LIMIT 1
    ) a ON true
   WHERE u.oda_id = p_oda_id;
END $$;

REVOKE EXECUTE ON FUNCTION public._etut_pasifleri_temizle() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.etut_odalari_listesi() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.etut_odasina_katil(INTEGER) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.etut_odasindan_ayril() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.etut_odasi_durum(INTEGER) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.etut_odalari_listesi() TO authenticated;
GRANT EXECUTE ON FUNCTION public.etut_odasina_katil(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.etut_odasindan_ayril() TO authenticated;
GRANT EXECUTE ON FUNCTION public.etut_odasi_durum(INTEGER) TO authenticated;


-- ═════════════════════════════════════════════════════════════════════
-- 18. Yıldız sistemi düzeltmeleri
-- ═════════════════════════════════════════════════════════════════════
-- Supabase SQL Editor'de TEK SEFERLİK çalıştırılmalıdır (idempotent;
-- tekrar çalıştırmak zarar vermez).
--
-- * Duraklatılan süre artık yıldıza sayılmaz: istemci gerçekten odaklanılan
--   dakikayı bildirir, sunucu bunu kendi ölçtüğü süreyle SINIRLAR
--   (LEAST). İstemci süreyi yalnızca küçültebilir, büyütemez; hile kapısı
--   açılmaz.
-- * Tam 25 dakikalık seansın, oturum kaydı ile bitirme isteği arasındaki ağ
--   gecikmesi yüzünden 24 dk sayılıp yıldızsız kalması önlendi (10 sn pay).
-- * "Vazgeç" ile bırakılan seans (0 dk bildirilir) yıldız ve süre kazandırmaz.
-- * Günlük 200 yıldız tavanı artık Türkiye saatine göre gece yarısı sıfırlanır
--   (önceden UTC'ye göre, yani 03.00'te sıfırlanıyordu).
--
-- Eski uygulama sürümleri fonksiyonu tek parametreyle çağırmaya devam eder;
-- p_focus_minutes verilmezse önceki davranış (sunucu süresi) geçerlidir.

CREATE OR REPLACE FUNCTION public._stars_earned_today(p_user_id UUID, p_reason TEXT)
RETURNS INTEGER LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT COALESCE(SUM(amount), 0)::INTEGER FROM public.star_transactions
   WHERE user_id = p_user_id AND reason = p_reason AND amount > 0
     AND (created_at AT TIME ZONE 'Europe/Istanbul')::date = (NOW() AT TIME ZONE 'Europe/Istanbul')::date;
$$;
REVOKE EXECUTE ON FUNCTION public._stars_earned_today(UUID, TEXT) FROM PUBLIC, anon, authenticated;

-- İki imza yan yana kalırsa tek parametreli çağrı belirsizleşir.
DROP FUNCTION IF EXISTS public.complete_study_session(UUID);

CREATE OR REPLACE FUNCTION public.complete_study_session(p_session_id UUID, p_focus_minutes INTEGER DEFAULT NULL)
RETURNS TABLE(actual_minutes INTEGER, stars_awarded INTEGER)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_session public.study_sessions%rowtype;
  v_wall INTEGER;
  v_minutes INTEGER;
  v_stars INTEGER;
  v_today_total INTEGER;
  v_awarded INTEGER := 0;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;

  SELECT * INTO v_session FROM public.study_sessions
   WHERE id = p_session_id AND user_id = v_uid AND ended_at IS NULL
   FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Session not found or already completed'; END IF;

  -- Sunucunun ölçtüğü süre (üst sınır). 10 saniyelik pay, oturum satırının
  -- istemcideki sayaçtan biraz sonra oluşmasını telafi eder.
  v_wall := LEAST(
    GREATEST(FLOOR((EXTRACT(EPOCH FROM (NOW() - v_session.started_at)) + 10) / 60)::INTEGER, 0),
    240
  );
  v_minutes := CASE
    WHEN p_focus_minutes IS NULL THEN v_wall
    ELSE LEAST(GREATEST(p_focus_minutes, 0), v_wall)
  END;

  v_stars := LEAST((v_minutes / 25) * 10, 40);
  v_today_total := public._stars_earned_today(v_uid, 'pomodoro');
  v_stars := GREATEST(0, LEAST(v_stars, 200 - v_today_total));

  IF v_stars > 0 THEN
    INSERT INTO public.star_transactions (user_id, amount, reason, ref_id)
    VALUES (v_uid, v_stars, 'pomodoro', p_session_id::text)
    ON CONFLICT (user_id, reason, ref_id) DO NOTHING;

    IF FOUND THEN
      v_awarded := v_stars;
      INSERT INTO public.wallets (user_id, balance, updated_at)
      VALUES (v_uid, v_stars, NOW())
      ON CONFLICT (user_id) DO UPDATE SET balance = wallets.balance + v_stars, updated_at = NOW();
    END IF;
  END IF;

  UPDATE public.study_sessions
     SET ended_at = NOW(),
         actual_minutes = v_minutes,
         stars_awarded = v_awarded,
         interrupted = (v_minutes < v_session.planned_minutes * 0.6)
   WHERE id = p_session_id;

  RETURN QUERY SELECT v_minutes, v_awarded;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.complete_study_session(UUID, INTEGER) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.complete_study_session(UUID, INTEGER) TO authenticated;

-- PostgREST şema önbelleğini yenile (yeni imza hemen görünsün).
NOTIFY pgrst, 'reload schema';


-- ═════════════════════════════════════════════════════════════════════
-- 19. Yayın Öncesi Sıkılaştırma (DENETIM_RAPORU_2026-10-03.md — B3, B4, B5, B6)
-- ═════════════════════════════════════════════════════════════════════
-- Supabase SQL Editor'de TEK SEFERLİK çalıştırılmalıdır (idempotent; tekrar
-- çalıştırmak zarar vermez). 15–18 numaralı migration'lar kurulu olmalıdır.
--
-- a) Çalışma oturumu satırları istemcinin gönderdiği zaman/süre değerleriyle
--    eklenemez (yıldız ve sıralama hilesi).
-- b) Başkalarına görünen ad ve oturum etiketi kısaltılır, kelime filtresinden
--    geçer; destek talepleri uzunluk ve günlük adet sınırına tabidir.
-- c) student_data.updated_at sunucu saatinden atanır (cihazlar arası eşitleme
--    bu damgaya göre karar verir); anahtar sayısı sınırlanır.
-- d) Uygulama hata kayıtları (çökme/istisna) — 30 gün saklanır.
-- e) Zorunlu güncelleme / bakım modu yapılandırması.

-- ─── Ortak: kelime filtresi ──────────────────────────────────────────
CREATE OR REPLACE FUNCTION public._icerik_uygunsuz(p_metin TEXT) RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.moderation_words w
     WHERE lower(COALESCE(p_metin, '')) ~ (
       '(^|[^[:alnum:]])'
       || regexp_replace(w.word, '([.^$*+?()\[\]{}|\\-])', '\\\1', 'g')
       || '($|[^[:alnum:]])')
  );
$$;

-- ─── a) Çalışma oturumları ───────────────────────────────────────────
CREATE OR REPLACE FUNCTION public._study_sessions_before_insert() RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  -- Yalnızca kullanıcı oturumuyla (REST) gelen eklemeler; SQL Editor ve
  -- servis rolü etkilenmez.
  IF auth.uid() IS NOT NULL AND NOT public.is_admin() THEN
    NEW.started_at     := NOW();
    NEW.ended_at       := NULL;
    NEW.actual_minutes := NULL;
    NEW.stars_awarded  := 0;
    NEW.interrupted    := false;

    -- Yarım kalmış eski oturumlar süresiz ve yıldızsız kapatılır.
    UPDATE public.study_sessions
       SET ended_at = NOW(), actual_minutes = 0, interrupted = true
     WHERE user_id = NEW.user_id AND ended_at IS NULL;
  END IF;

  NEW.label := left(COALESCE(NULLIF(trim(NEW.label), ''), 'Genel'), 40);
  IF public._icerik_uygunsuz(NEW.label) THEN NEW.label := 'Genel'; END IF;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_study_sessions_before_insert ON public.study_sessions;
CREATE TRIGGER trg_study_sessions_before_insert
BEFORE INSERT ON public.study_sessions
FOR EACH ROW EXECUTE FUNCTION public._study_sessions_before_insert();

-- ─── b) Görünen ad ve destek talepleri ───────────────────────────────
-- Hata fırlatılmaz (kayıt akışı kesilmesin); uygunsuz ad nötr adla değiştirilir.
CREATE OR REPLACE FUNCTION public._profiles_name_guard() RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  NEW.name := left(COALESCE(NULLIF(trim(NEW.name), ''), 'Öğrenci'), 60);
  IF public._icerik_uygunsuz(NEW.name) THEN NEW.name := 'Öğrenci'; END IF;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_profiles_name_guard ON public.profiles;
CREATE TRIGGER trg_profiles_name_guard
BEFORE INSERT OR UPDATE OF name ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public._profiles_name_guard();

CREATE OR REPLACE FUNCTION public._tickets_before_insert() RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  NEW.subject     := left(trim(NEW.subject), 150);
  NEW.description := left(trim(NEW.description), 4000);
  IF auth.uid() IS NOT NULL AND NOT public.is_admin() THEN
    NEW.status      := 'open';
    NEW.admin_notes := NULL;
    IF (SELECT COUNT(*) FROM public.user_tickets
         WHERE user_id = NEW.user_id AND created_at > NOW() - INTERVAL '1 day') >= 5 THEN
      RAISE EXCEPTION 'Günlük talep sınırına ulaştın. Yarın tekrar deneyebilirsin.';
    END IF;
  END IF;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_tickets_before_insert ON public.user_tickets;
CREATE TRIGGER trg_tickets_before_insert
BEFORE INSERT ON public.user_tickets
FOR EACH ROW EXECUTE FUNCTION public._tickets_before_insert();

-- ─── c) student_data: sunucu zaman damgası ve anahtar sınırı ─────────
CREATE OR REPLACE FUNCTION public._student_data_before_write() RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  NEW.updated_at := NOW();
  IF TG_OP = 'INSERT' THEN
    IF char_length(NEW.data_key) > 100 THEN RAISE EXCEPTION 'invalid data_key'; END IF;
    IF (SELECT COUNT(*) FROM public.student_data WHERE user_id = NEW.user_id) >= 1000 THEN
      RAISE EXCEPTION 'student_data key limit reached';
    END IF;
  END IF;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_student_data_before_write ON public.student_data;
CREATE TRIGGER trg_student_data_before_write
BEFORE INSERT OR UPDATE ON public.student_data
FOR EACH ROW EXECUTE FUNCTION public._student_data_before_write();

-- ─── d) Uygulama hata kayıtları ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.client_errors (
  id         BIGSERIAL PRIMARY KEY,
  user_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  mesaj      TEXT NOT NULL,
  yigin      TEXT,
  surum      TEXT,
  platform   TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_client_errors_date ON public.client_errors(created_at);
CREATE INDEX IF NOT EXISTS idx_client_errors_user ON public.client_errors(user_id, created_at);
ALTER TABLE public.client_errors ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "client_errors_admin_all" ON public.client_errors;
CREATE POLICY "client_errors_admin_all" ON public.client_errors FOR ALL
  USING (public.is_admin()) WITH CHECK (public.is_admin());
-- Yazma yalnızca aşağıdaki fonksiyonla (kullanıcı başına günde 20 kayıt).

CREATE OR REPLACE FUNCTION public.hata_bildir(p_mesaj TEXT, p_yigin TEXT, p_surum TEXT, p_platform TEXT)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  IF p_mesaj IS NULL OR length(trim(p_mesaj)) = 0 THEN RETURN; END IF;

  DELETE FROM public.client_errors WHERE created_at < NOW() - INTERVAL '30 days';

  IF (SELECT COUNT(*) FROM public.client_errors
       WHERE user_id = v_uid AND created_at > NOW() - INTERVAL '1 day') >= 20 THEN
    RETURN;
  END IF;

  INSERT INTO public.client_errors (user_id, mesaj, yigin, surum, platform)
  VALUES (v_uid, left(p_mesaj, 500), left(p_yigin, 6000), left(p_surum, 40), left(p_platform, 20));
END $$;

-- Sık görülen hatalar (admin, SQL Editor):
--   SELECT left(mesaj, 120) AS hata, surum, COUNT(*), COUNT(DISTINCT user_id) AS kullanici, MAX(created_at)
--     FROM public.client_errors GROUP BY 1, 2 ORDER BY 3 DESC LIMIT 30;

-- ─── e) Zorunlu güncelleme / bakım modu ──────────────────────────────
-- min_build: bundan küçük derleme numarasına (pubspec `+N`) sahip uygulama
-- sürümleri güncelleme ekranında durdurulur. Kritik bir açıkta yükseltilir:
--   UPDATE public.app_config SET min_build = 25 WHERE id = 1;
CREATE TABLE IF NOT EXISTS public.app_config (
  id        INTEGER PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  min_build INTEGER NOT NULL DEFAULT 1,
  bakim     BOOLEAN NOT NULL DEFAULT false,
  mesaj     TEXT
);
INSERT INTO public.app_config (id) VALUES (1) ON CONFLICT (id) DO NOTHING;
ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "app_config_select_all" ON public.app_config;
CREATE POLICY "app_config_select_all" ON public.app_config FOR SELECT USING (true);
DROP POLICY IF EXISTS "app_config_admin_all" ON public.app_config;
CREATE POLICY "app_config_admin_all" ON public.app_config FOR ALL
  USING (public.is_admin()) WITH CHECK (public.is_admin());

-- ─── f) Çalıştırma yetkileri ─────────────────────────────────────────
REVOKE EXECUTE ON FUNCTION public._icerik_uygunsuz(TEXT) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public._study_sessions_before_insert() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public._profiles_name_guard() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public._tickets_before_insert() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public._student_data_before_write() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.hata_bildir(TEXT, TEXT, TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.hata_bildir(TEXT, TEXT, TEXT, TEXT) TO authenticated;
