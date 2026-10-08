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

-- ═════════════════════════════════════════════════════════════════════
-- 20. Koç Asistanı — tüm kullanıcılar için toplam günlük tavan
-- ═════════════════════════════════════════════════════════════════════
-- Supabase SQL Editor'de TEK SEFERLİK çalıştırılmalıdır (idempotent).
-- Migration 16'dan sonra çalıştırılır.
--
-- Bulut yapay zeka yanıtları ücretsiz sunulduğu için fatura, kullanıcı
-- sayısıyla birlikte büyür. Kişi başı günlük sınıra (migration 16) ek
-- olarak burada TÜM kullanıcıların bir günde gönderebileceği toplam mesaj
-- sayısına tavan konur; tavan dolunca asistan cihaz içi yanıtlarla
-- çalışmaya devam eder (uygulama bunu kendiliğinden yapar).
--
-- Sınırları değiştirmek için (yeniden deploy gerekmez):
--   UPDATE public.assistant_settings SET kisi_gunluk = 10, genel_gunluk = 20000;
--
-- Kaba maliyet hesabı: bir mesaj ≈ 3.500 girdi + 400 çıktı token.
--   genel_gunluk × mesaj başı maliyet = bir günde ödenebilecek en yüksek tutar.

CREATE TABLE IF NOT EXISTS public.assistant_settings (
  tek          BOOLEAN PRIMARY KEY DEFAULT TRUE CHECK (tek),
  kisi_gunluk  INTEGER NOT NULL DEFAULT 20 CHECK (kisi_gunluk >= 0),
  genel_gunluk INTEGER NOT NULL DEFAULT 5000 CHECK (genel_gunluk >= 0)
);
INSERT INTO public.assistant_settings (tek) VALUES (TRUE) ON CONFLICT (tek) DO NOTHING;
ALTER TABLE public.assistant_settings ENABLE ROW LEVEL SECURITY;
-- Politika yok: yalnızca SQL Editor (service role) ve aşağıdaki fonksiyonlar okur/yazar.

CREATE TABLE IF NOT EXISTS public.assistant_usage_total (
  gun  DATE PRIMARY KEY DEFAULT CURRENT_DATE,
  adet INTEGER NOT NULL DEFAULT 0
);
ALTER TABLE public.assistant_usage_total ENABLE ROW LEVEL SECURITY;

-- Kişi başı sınır artık ayar tablosundan okunur.
CREATE OR REPLACE FUNCTION public._asistan_gunluk_sinir() RETURNS INTEGER
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT COALESCE((SELECT kisi_gunluk FROM public.assistant_settings LIMIT 1), 20)
$$;

-- Edge Function her mesajdan önce çağırır.
-- Dönüş: 'ok' | 'no_consent' | 'limit' (kişinin hakkı doldu) | 'dolu' (genel tavan doldu).
CREATE OR REPLACE FUNCTION public.asistan_kota_kullan() RETURNS TEXT
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid    UUID := auth.uid();
  v_sinir  INTEGER := public._asistan_gunluk_sinir();
  v_genel  INTEGER := COALESCE((SELECT genel_gunluk FROM public.assistant_settings LIMIT 1), 5000);
  v_adet   INTEGER;
  v_toplam INTEGER;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.assistant_consents WHERE user_id = v_uid) THEN
    RETURN 'no_consent';
  END IF;

  -- Eski kullanım kayıtları 30 günden fazla tutulmaz.
  DELETE FROM public.assistant_usage WHERE gun < CURRENT_DATE - 30;
  DELETE FROM public.assistant_usage_total WHERE gun < CURRENT_DATE - 90;

  -- Kişinin hakkı dolmuşsa genel sayaç hiç artmaz.
  SELECT adet INTO v_adet FROM public.assistant_usage WHERE user_id = v_uid AND gun = CURRENT_DATE;
  IF COALESCE(v_adet, 0) >= v_sinir THEN RETURN 'limit'; END IF;

  INSERT INTO public.assistant_usage_total (gun, adet) VALUES (CURRENT_DATE, 1)
  ON CONFLICT (gun) DO UPDATE SET adet = assistant_usage_total.adet + 1
  RETURNING adet INTO v_toplam;
  IF v_toplam > v_genel THEN
    UPDATE public.assistant_usage_total SET adet = v_genel WHERE gun = CURRENT_DATE;
    RETURN 'dolu';
  END IF;

  INSERT INTO public.assistant_usage (user_id, gun, adet) VALUES (v_uid, CURRENT_DATE, 1)
  ON CONFLICT (user_id, gun) DO UPDATE SET adet = assistant_usage.adet + 1
  RETURNING adet INTO v_adet;
  IF v_adet > v_sinir THEN
    UPDATE public.assistant_usage SET adet = v_sinir WHERE user_id = v_uid AND gun = CURRENT_DATE;
    RETURN 'limit';
  END IF;
  RETURN 'ok';
END $$;

REVOKE EXECUTE ON FUNCTION public._asistan_gunluk_sinir() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.asistan_kota_kullan() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.asistan_kota_kullan() TO authenticated;

-- ═════════════════════════════════════════════════════════════════════
-- 21. Okul Yapısı (okul, şube, öğretmen, veli, müdür)
-- ═════════════════════════════════════════════════════════════════════
-- Supabase SQL Editor'de TEK SEFERLİK çalıştırılmalıdır (idempotent;
-- tekrar çalıştırmak zarar vermez). 15 ve 17 numaralı migration'lardan
-- sonra çalıştırılır.
--
-- * Okulu yalnızca uygulama yöneticisi (admin) açar ve müdür kodunu üretir.
-- * Müdür şubeleri ve öğretmen kodlarını üretir, öğretmeni şubelere atar.
-- * Öğrenci şube koduyla sınıfına katılır; rolü 'student' kalır.
-- * Veli, öğrencinin uygulamadan ürettiği kodla bağlanır.
-- * profiles.role yeni değerler alır: 'teacher' | 'parent' | 'principal'.
--   Rol yalnızca aşağıdaki okul_kodu_kullan() ile değişir; istemci kendi
--   rolünü değiştiremez (bkz. _profiles_protect_fields).
-- * Kod önekleri türü gösterir: S = şube, T = öğretmen, M = müdür, V = veli.
-- * Tablolara doğrudan erişim yoktur; her şey SECURITY DEFINER fonksiyonlarla
--   yapılır.

CREATE TABLE IF NOT EXISTS public.okullar (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ad         TEXT NOT NULL CHECK (char_length(ad) BETWEEN 3 AND 120),
  il         TEXT NOT NULL DEFAULT '',
  ilce       TEXT NOT NULL DEFAULT '',
  aktif      BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.okullar ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.okul_subeleri (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  okul_id      UUID NOT NULL REFERENCES public.okullar(id) ON DELETE CASCADE,
  sinif        TEXT NOT NULL CHECK (sinif IN ('9', '10', '11', '12', 'Mezun')),
  ad           TEXT NOT NULL CHECK (char_length(ad) BETWEEN 1 AND 12),
  katilim_kodu TEXT NOT NULL UNIQUE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (okul_id, sinif, ad)
);
ALTER TABLE public.okul_subeleri ENABLE ROW LEVEL SECURITY;

-- Bir hesap aynı anda tek bir okulun üyesidir.
CREATE TABLE IF NOT EXISTS public.okul_uyeleri (
  user_id             UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  okul_id             UUID NOT NULL REFERENCES public.okullar(id) ON DELETE CASCADE,
  rol                 TEXT NOT NULL CHECK (rol IN ('mudur', 'ogretmen', 'ogrenci')),
  sube_id             UUID REFERENCES public.okul_subeleri(id) ON DELETE CASCADE, -- yalnızca öğrencide dolu
  rehber              BOOLEAN NOT NULL DEFAULT false,                             -- yalnızca öğretmende anlamlı
  brans               TEXT,                                                       -- branş öğretmeninin dersi
  bilgilendirme_onay  TIMESTAMPTZ,                                                -- öğrencinin bilgilendirme ekranını kabul ettiği an
  katilma             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_okul_uyeleri_okul ON public.okul_uyeleri(okul_id, rol);
CREATE INDEX IF NOT EXISTS idx_okul_uyeleri_sube ON public.okul_uyeleri(sube_id);
ALTER TABLE public.okul_uyeleri ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.ogretmen_subeleri (
  ogretmen_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  sube_id     UUID NOT NULL REFERENCES public.okul_subeleri(id) ON DELETE CASCADE,
  PRIMARY KEY (ogretmen_id, sube_id)
);
CREATE INDEX IF NOT EXISTS idx_ogretmen_subeleri_sube ON public.ogretmen_subeleri(sube_id);
ALTER TABLE public.ogretmen_subeleri ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.okul_davetleri (
  kod            TEXT PRIMARY KEY,
  okul_id        UUID NOT NULL REFERENCES public.okullar(id) ON DELETE CASCADE,
  tur            TEXT NOT NULL CHECK (tur IN ('mudur', 'ogretmen')),
  rehber         BOOLEAN NOT NULL DEFAULT false,
  brans          TEXT,
  olusturan      UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  kullanan       UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  kullanildi     TIMESTAMPTZ,
  son_gecerlilik TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '14 days',
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_okul_davetleri_okul ON public.okul_davetleri(okul_id);
ALTER TABLE public.okul_davetleri ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.veli_baglantilari (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ogrenci_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  veli_id        UUID REFERENCES public.profiles(id) ON DELETE CASCADE, -- kod kullanılana kadar NULL
  kod            TEXT UNIQUE,
  durum          TEXT NOT NULL DEFAULT 'bekliyor' CHECK (durum IN ('bekliyor', 'aktif', 'bitti')),
  son_gecerlilik TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '7 days',
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS veli_baglantilari_aktif_cift_uq
  ON public.veli_baglantilari (ogrenci_id, veli_id) WHERE (durum = 'aktif');
CREATE INDEX IF NOT EXISTS idx_veli_baglantilari_veli ON public.veli_baglantilari(veli_id);
ALTER TABLE public.veli_baglantilari ENABLE ROW LEVEL SECURITY;

-- Yanlış kod denemeleri (kaba kuvvete karşı; 30 günden fazla tutulmaz).
CREATE TABLE IF NOT EXISTS public.okul_kod_denemeleri (
  id         BIGSERIAL PRIMARY KEY,
  user_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_okul_kod_denemeleri_user ON public.okul_kod_denemeleri(user_id, created_at);
ALTER TABLE public.okul_kod_denemeleri ENABLE ROW LEVEL SECURITY;

-- ─── Yardımcılar ─────────────────────────────────────────────────────

-- Karıştırılabilen harfler (0/O, 1/I/L) içermeyen 8 karakterlik kod.
CREATE OR REPLACE FUNCTION public._okul_kod_uret(p_on_ek TEXT) RETURNS TEXT
LANGUAGE plpgsql VOLATILE SET search_path = public AS $$
DECLARE
  v_alfabe CONSTANT TEXT := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  v_bayt   BYTEA := uuid_send(gen_random_uuid()) || uuid_send(gen_random_uuid());
  v_sira   CONSTANT INTEGER[] := ARRAY[0, 1, 2, 3, 4, 5, 16, 17];
  v_kod    TEXT := '';
  i        INTEGER;
BEGIN
  FOREACH i IN ARRAY v_sira LOOP
    v_kod := v_kod || substr(v_alfabe, 1 + (get_byte(v_bayt, i) % length(v_alfabe)), 1);
  END LOOP;
  RETURN p_on_ek || v_kod;
END $$;

CREATE OR REPLACE FUNCTION public._okul_kod_temizle(p_kod TEXT) RETURNS TEXT
LANGUAGE sql IMMUTABLE AS $$
  SELECT upper(regexp_replace(COALESCE(p_kod, ''), '[^A-Za-z0-9]', '', 'g'));
$$;

-- Çağıran müdürse okulunun kimliğini döner; değilse hata verir.
CREATE OR REPLACE FUNCTION public._mudur_okulu() RETURNS UUID
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_okul UUID;
BEGIN
  SELECT u.okul_id INTO v_okul
    FROM public.okul_uyeleri u
    JOIN public.okullar o ON o.id = u.okul_id
   WHERE u.user_id = auth.uid() AND u.rol = 'mudur' AND o.aktif;
  IF v_okul IS NULL THEN RAISE EXCEPTION 'Bu işlem için müdür yetkisi gerekir'; END IF;
  RETURN v_okul;
END $$;

CREATE OR REPLACE FUNCTION public._okul_ogrencisi_mi(p_user UUID) RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.okul_uyeleri WHERE user_id = p_user AND rol = 'ogrenci');
$$;

-- Öğrenci bir okula ya da veliye bağlandığında çağrılır. Raporlama migration'ı
-- (22) bu fonksiyonu geçmiş veriyi özet tablosuna aktaracak şekilde yeniden
-- tanımlar; o kurulana kadar bir şey yapmaz.
DO $$
BEGIN
  IF to_regprocedure('public._okul_katilim_sonrasi(uuid)') IS NULL THEN
    CREATE FUNCTION public._okul_katilim_sonrasi(p_user UUID) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $f$
    BEGIN
      RETURN;
    END $f$;
  END IF;
END $$;

-- Öğrenci sınıftan ayrıldığında ya da veli bağlantısı bittiğinde çağrılır.
-- Raporlama migration'ı (22) bunu, artık kimseyle paylaşılmayan özet
-- kayıtlarını silecek şekilde yeniden tanımlar.
DO $$
BEGIN
  IF to_regprocedure('public._okul_ayrilma_sonrasi(uuid)') IS NULL THEN
    CREATE FUNCTION public._okul_ayrilma_sonrasi(p_user UUID) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $f$
    BEGIN
      RETURN;
    END $f$;
  END IF;
END $$;

-- ─── Durum ───────────────────────────────────────────────────────────

-- Oturum açılışında tek çağrıyla: rol, okul, şube, veli/çocuk bağlantıları.
CREATE OR REPLACE FUNCTION public.okul_durumum() RETURNS JSONB
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid   UUID := auth.uid();
  v_rol   TEXT;
  v_ad    TEXT;
  v_uye   public.okul_uyeleri%rowtype;
  v_sonuc JSONB;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  SELECT p.role, p.name INTO v_rol, v_ad FROM public.profiles p WHERE p.id = v_uid;
  SELECT * INTO v_uye FROM public.okul_uyeleri WHERE user_id = v_uid;

  v_sonuc := jsonb_build_object('rol', COALESCE(v_rol, 'student'), 'ad', COALESCE(v_ad, ''));

  IF v_uye.user_id IS NOT NULL THEN
    v_sonuc := v_sonuc || jsonb_build_object(
      'uye_rol', v_uye.rol,
      'rehber', v_uye.rehber,
      'brans', v_uye.brans,
      'okul', (SELECT jsonb_build_object('id', o.id, 'ad', o.ad, 'il', o.il, 'ilce', o.ilce, 'aktif', o.aktif)
                 FROM public.okullar o WHERE o.id = v_uye.okul_id),
      'sube', (SELECT jsonb_build_object('id', s.id, 'sinif', s.sinif, 'ad', s.ad)
                 FROM public.okul_subeleri s WHERE s.id = v_uye.sube_id)
    );
  END IF;

  v_sonuc := v_sonuc || jsonb_build_object(
    'cocuklar', COALESCE((
      SELECT jsonb_agg(jsonb_build_object('id', p.id, 'ad', COALESCE(NULLIF(p.name, ''), 'Öğrenci'), 'sinif', p.grade)
                       ORDER BY p.name)
        FROM public.veli_baglantilari b
        JOIN public.profiles p ON p.id = b.ogrenci_id
       WHERE b.veli_id = v_uid AND b.durum = 'aktif'), '[]'::jsonb),
    'veli_sayisi', (SELECT COUNT(*) FROM public.veli_baglantilari b WHERE b.ogrenci_id = v_uid AND b.durum = 'aktif')
  );
  RETURN v_sonuc;
END $$;

-- ─── Kod kullanma ────────────────────────────────────────────────────

-- p_tur: 'ogrenci' | 'ogretmen' | 'mudur' | 'veli'. Dönüş: { durum, ... }
--   durum: 'ok' | 'gecersiz' | 'cok_deneme' | 'rol_uyumsuz' | 'zaten_uye' | 'onay_gerekli'
-- Öğrenci için p_onay = false çağrısı yalnızca okul ve şube adını döner
-- (bilgilendirme ekranı); katılım p_onay = true ile yapılır.
CREATE OR REPLACE FUNCTION public.okul_kodu_kullan(p_kod TEXT, p_tur TEXT, p_onay BOOLEAN DEFAULT false)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid    UUID := auth.uid();
  v_kod    TEXT := public._okul_kod_temizle(p_kod);
  v_rol    TEXT;
  v_uye    public.okul_uyeleri%rowtype;
  v_sube   public.okul_subeleri%rowtype;
  v_davet  public.okul_davetleri%rowtype;
  v_bag    public.veli_baglantilari%rowtype;
  v_okul   public.okullar%rowtype;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  IF p_tur NOT IN ('ogrenci', 'ogretmen', 'mudur', 'veli') THEN RAISE EXCEPTION 'invalid tur'; END IF;

  DELETE FROM public.okul_kod_denemeleri WHERE created_at < NOW() - INTERVAL '30 days';
  IF (SELECT COUNT(*) FROM public.okul_kod_denemeleri
       WHERE user_id = v_uid AND created_at > NOW() - INTERVAL '1 hour') >= 10 THEN
    RETURN jsonb_build_object('durum', 'cok_deneme');
  END IF;

  SELECT p.role INTO v_rol FROM public.profiles p WHERE p.id = v_uid;
  v_rol := COALESCE(v_rol, 'student');
  SELECT * INTO v_uye FROM public.okul_uyeleri WHERE user_id = v_uid;

  -- ── Öğrenci: şube kodu ──
  IF p_tur = 'ogrenci' THEN
    IF v_rol IN ('teacher', 'parent', 'principal') OR (v_uye.user_id IS NOT NULL AND v_uye.rol <> 'ogrenci') THEN
      RETURN jsonb_build_object('durum', 'rol_uyumsuz');
    END IF;
    SELECT * INTO v_sube FROM public.okul_subeleri WHERE katilim_kodu = v_kod;
    IF NOT FOUND THEN
      INSERT INTO public.okul_kod_denemeleri (user_id) VALUES (v_uid);
      RETURN jsonb_build_object('durum', 'gecersiz');
    END IF;
    SELECT * INTO v_okul FROM public.okullar WHERE id = v_sube.okul_id;
    IF NOT v_okul.aktif THEN RETURN jsonb_build_object('durum', 'gecersiz'); END IF;

    IF NOT COALESCE(p_onay, false) THEN
      RETURN jsonb_build_object('durum', 'onay_gerekli', 'okul', v_okul.ad, 'sinif', v_sube.sinif, 'sube', v_sube.ad);
    END IF;

    INSERT INTO public.okul_uyeleri (user_id, okul_id, rol, sube_id, bilgilendirme_onay, katilma)
    VALUES (v_uid, v_sube.okul_id, 'ogrenci', v_sube.id, NOW(), NOW())
    ON CONFLICT (user_id) DO UPDATE
      SET okul_id = EXCLUDED.okul_id, sube_id = EXCLUDED.sube_id, rol = 'ogrenci',
          bilgilendirme_onay = NOW(), katilma = NOW();

    -- Okul hesabı herkese açık etüt odalarında yer almaz.
    IF to_regclass('public.etut_odasi_uyeleri') IS NOT NULL THEN
      EXECUTE 'DELETE FROM public.etut_odasi_uyeleri WHERE user_id = $1' USING v_uid;
    END IF;
    PERFORM public._okul_katilim_sonrasi(v_uid);
    RETURN jsonb_build_object('durum', 'ok', 'okul', v_okul.ad, 'sinif', v_sube.sinif, 'sube', v_sube.ad);
  END IF;

  -- ── Öğretmen / müdür: davet kodu ──
  IF p_tur IN ('ogretmen', 'mudur') THEN
    IF v_uye.user_id IS NOT NULL THEN RETURN jsonb_build_object('durum', 'zaten_uye'); END IF;
    IF v_rol <> 'student' THEN RETURN jsonb_build_object('durum', 'rol_uyumsuz'); END IF;

    SELECT * INTO v_davet FROM public.okul_davetleri
     WHERE kod = v_kod AND tur = p_tur AND kullanan IS NULL AND son_gecerlilik > NOW()
     FOR UPDATE;
    IF NOT FOUND THEN
      INSERT INTO public.okul_kod_denemeleri (user_id) VALUES (v_uid);
      RETURN jsonb_build_object('durum', 'gecersiz');
    END IF;
    SELECT * INTO v_okul FROM public.okullar WHERE id = v_davet.okul_id;
    IF NOT v_okul.aktif THEN RETURN jsonb_build_object('durum', 'gecersiz'); END IF;

    UPDATE public.profiles
       SET role = CASE WHEN p_tur = 'mudur' THEN 'principal' ELSE 'teacher' END
     WHERE id = v_uid;
    INSERT INTO public.okul_uyeleri (user_id, okul_id, rol, rehber, brans)
    VALUES (v_uid, v_davet.okul_id, p_tur, v_davet.rehber, v_davet.brans);
    UPDATE public.okul_davetleri SET kullanan = v_uid, kullanildi = NOW() WHERE kod = v_davet.kod;
    RETURN jsonb_build_object('durum', 'ok', 'okul', v_okul.ad);
  END IF;

  -- ── Veli: öğrencinin ürettiği kod ──
  IF v_uye.user_id IS NOT NULL OR v_rol NOT IN ('student', 'parent') THEN
    RETURN jsonb_build_object('durum', 'rol_uyumsuz');
  END IF;
  SELECT * INTO v_bag FROM public.veli_baglantilari
   WHERE kod = v_kod AND durum = 'bekliyor' AND son_gecerlilik > NOW()
   FOR UPDATE;
  IF NOT FOUND OR v_bag.ogrenci_id = v_uid THEN
    INSERT INTO public.okul_kod_denemeleri (user_id) VALUES (v_uid);
    RETURN jsonb_build_object('durum', 'gecersiz');
  END IF;

  IF EXISTS (SELECT 1 FROM public.veli_baglantilari
              WHERE ogrenci_id = v_bag.ogrenci_id AND veli_id = v_uid AND durum = 'aktif') THEN
    UPDATE public.veli_baglantilari SET durum = 'bitti', kod = NULL WHERE id = v_bag.id;
  ELSE
    UPDATE public.veli_baglantilari SET veli_id = v_uid, durum = 'aktif', kod = NULL WHERE id = v_bag.id;
  END IF;
  IF v_rol = 'student' THEN
    UPDATE public.profiles SET role = 'parent' WHERE id = v_uid;
  END IF;
  PERFORM public._okul_katilim_sonrasi(v_bag.ogrenci_id);
  RETURN jsonb_build_object('durum', 'ok',
    'ogrenci', (SELECT COALESCE(NULLIF(p.name, ''), 'Öğrenci') FROM public.profiles p WHERE p.id = v_bag.ogrenci_id));
END $$;

-- ─── Öğrenci işlemleri ───────────────────────────────────────────────

-- Öğrenci velisi için 7 gün geçerli bir kod üretir. Dönüş: kod | 'limit'.
CREATE OR REPLACE FUNCTION public.veli_kodu_uret() RETURNS TEXT
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_kod TEXT;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  IF EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = v_uid AND p.role IN ('teacher', 'parent', 'principal')) THEN
    RAISE EXCEPTION 'Yalnızca öğrenci hesabı veli kodu üretebilir';
  END IF;
  IF (SELECT COUNT(*) FROM public.veli_baglantilari WHERE ogrenci_id = v_uid AND durum = 'aktif') >= 3 THEN
    RETURN 'limit';
  END IF;

  DELETE FROM public.veli_baglantilari WHERE ogrenci_id = v_uid AND durum = 'bekliyor';
  LOOP
    v_kod := public._okul_kod_uret('V');
    EXIT WHEN NOT EXISTS (SELECT 1 FROM public.veli_baglantilari WHERE kod = v_kod);
  END LOOP;
  INSERT INTO public.veli_baglantilari (ogrenci_id, kod) VALUES (v_uid, v_kod);
  RETURN v_kod;
END $$;

-- Öğrencinin velileri ya da velinin çocukları (çağırana göre).
CREATE OR REPLACE FUNCTION public.veli_baglantilarim() RETURNS JSONB
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
           'id', b.id,
           'durum', b.durum,
           'kod', CASE WHEN b.ogrenci_id = auth.uid() AND b.durum = 'bekliyor' THEN b.kod END,
           'son_gecerlilik', b.son_gecerlilik,
           'ben_ogrenci', b.ogrenci_id = auth.uid(),
           'karsi_id', CASE WHEN b.ogrenci_id = auth.uid() THEN b.veli_id ELSE b.ogrenci_id END,
           'karsi_ad', COALESCE(NULLIF(p.name, ''), CASE WHEN b.ogrenci_id = auth.uid() THEN 'Veli' ELSE 'Öğrenci' END)
         ) ORDER BY b.created_at DESC), '[]'::jsonb)
    FROM public.veli_baglantilari b
    LEFT JOIN public.profiles p
      ON p.id = CASE WHEN b.ogrenci_id = auth.uid() THEN b.veli_id ELSE b.ogrenci_id END
   WHERE (b.ogrenci_id = auth.uid() OR b.veli_id = auth.uid())
     AND b.durum IN ('bekliyor', 'aktif')
     AND (b.durum = 'aktif' OR b.son_gecerlilik > NOW());
$$;

-- Öğrenci ya da veli bağlantıyı bitirir. Çocuğu kalmayan veli hesabı
-- öğrenci rolüne döner.
CREATE OR REPLACE FUNCTION public.veli_baglantisini_bitir(p_id UUID) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid     UUID := auth.uid();
  v_veli    UUID;
  v_ogrenci UUID;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  UPDATE public.veli_baglantilari
     SET durum = 'bitti', kod = NULL
   WHERE id = p_id AND (ogrenci_id = v_uid OR veli_id = v_uid) AND durum <> 'bitti'
  RETURNING veli_id, ogrenci_id INTO v_veli, v_ogrenci;
  IF NOT FOUND THEN RAISE EXCEPTION 'Bağlantı bulunamadı'; END IF;
  PERFORM public._okul_ayrilma_sonrasi(v_ogrenci);

  IF v_veli IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM public.veli_baglantilari WHERE veli_id = v_veli AND durum = 'aktif') THEN
    UPDATE public.profiles SET role = 'student' WHERE id = v_veli AND role = 'parent';
  END IF;
END $$;

-- Öğrenci sınıfından, öğretmen okulundan ayrılır. Müdür kendi kendine
-- ayrılamaz (okul yöneticisiz kalmasın).
CREATE OR REPLACE FUNCTION public.okuldan_ayril() RETURNS TEXT
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_rol TEXT;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  SELECT rol INTO v_rol FROM public.okul_uyeleri WHERE user_id = v_uid;
  IF v_rol IS NULL THEN RETURN 'yok'; END IF;
  IF v_rol = 'mudur' THEN RETURN 'mudur'; END IF;

  DELETE FROM public.ogretmen_subeleri WHERE ogretmen_id = v_uid;
  DELETE FROM public.okul_uyeleri WHERE user_id = v_uid;
  IF v_rol = 'ogretmen' THEN
    UPDATE public.profiles SET role = 'student' WHERE id = v_uid AND role = 'teacher';
  ELSE
    PERFORM public._okul_ayrilma_sonrasi(v_uid);
  END IF;
  RETURN 'ok';
END $$;

-- ─── Müdür işlemleri ─────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.okul_yonetim_ozeti() RETURNS JSONB
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_okul UUID := public._mudur_okulu();
BEGIN
  RETURN jsonb_build_object(
    'okul', (SELECT jsonb_build_object('id', o.id, 'ad', o.ad, 'il', o.il, 'ilce', o.ilce)
               FROM public.okullar o WHERE o.id = v_okul),
    'subeler', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
               'id', s.id, 'sinif', s.sinif, 'ad', s.ad, 'kod', s.katilim_kodu,
               'ogrenci_sayisi', (SELECT COUNT(*) FROM public.okul_uyeleri u WHERE u.sube_id = s.id AND u.rol = 'ogrenci'),
               'ogretmenler', COALESCE((
                 SELECT jsonb_agg(COALESCE(NULLIF(p.name, ''), 'Öğretmen') ORDER BY p.name)
                   FROM public.ogretmen_subeleri os
                   JOIN public.profiles p ON p.id = os.ogretmen_id
                  WHERE os.sube_id = s.id), '[]'::jsonb)
             ) ORDER BY CASE s.sinif WHEN 'Mezun' THEN 99 ELSE s.sinif::INTEGER END, s.ad)
        FROM public.okul_subeleri s WHERE s.okul_id = v_okul), '[]'::jsonb),
    'ogretmenler', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
               'id', u.user_id,
               'ad', COALESCE(NULLIF(p.name, ''), 'Öğretmen'),
               'rehber', u.rehber,
               'brans', u.brans,
               'sube_ids', COALESCE((SELECT jsonb_agg(os.sube_id) FROM public.ogretmen_subeleri os
                                      WHERE os.ogretmen_id = u.user_id), '[]'::jsonb)
             ) ORDER BY p.name)
        FROM public.okul_uyeleri u
        JOIN public.profiles p ON p.id = u.user_id
       WHERE u.okul_id = v_okul AND u.rol = 'ogretmen'), '[]'::jsonb),
    'davetler', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
               'kod', d.kod, 'rehber', d.rehber, 'brans', d.brans, 'son_gecerlilik', d.son_gecerlilik
             ) ORDER BY d.created_at DESC)
        FROM public.okul_davetleri d
       WHERE d.okul_id = v_okul AND d.tur = 'ogretmen' AND d.kullanan IS NULL AND d.son_gecerlilik > NOW()), '[]'::jsonb)
  );
END $$;

-- Dönüş: { durum: 'ok' | 'var', kod }
CREATE OR REPLACE FUNCTION public.okul_sube_ekle(p_sinif TEXT, p_ad TEXT) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_okul UUID := public._mudur_okulu();
  v_ad   TEXT := upper(left(trim(COALESCE(p_ad, '')), 12));
  v_kod  TEXT;
BEGIN
  IF p_sinif NOT IN ('9', '10', '11', '12', 'Mezun') OR v_ad = '' THEN RAISE EXCEPTION 'Geçersiz şube'; END IF;
  IF EXISTS (SELECT 1 FROM public.okul_subeleri WHERE okul_id = v_okul AND sinif = p_sinif AND ad = v_ad) THEN
    RETURN jsonb_build_object('durum', 'var');
  END IF;
  IF (SELECT COUNT(*) FROM public.okul_subeleri WHERE okul_id = v_okul) >= 80 THEN
    RAISE EXCEPTION 'Şube sayısı sınırına ulaşıldı';
  END IF;
  LOOP
    v_kod := public._okul_kod_uret('S');
    EXIT WHEN NOT EXISTS (SELECT 1 FROM public.okul_subeleri WHERE katilim_kodu = v_kod);
  END LOOP;
  INSERT INTO public.okul_subeleri (okul_id, sinif, ad, katilim_kodu) VALUES (v_okul, p_sinif, v_ad, v_kod);
  RETURN jsonb_build_object('durum', 'ok', 'kod', v_kod);
END $$;

-- Kod sızdıysa yenilenir; eski kodla artık katılım olmaz.
CREATE OR REPLACE FUNCTION public.okul_sube_kodu_yenile(p_sube_id UUID) RETURNS TEXT
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_okul UUID := public._mudur_okulu();
  v_kod  TEXT;
BEGIN
  LOOP
    v_kod := public._okul_kod_uret('S');
    EXIT WHEN NOT EXISTS (SELECT 1 FROM public.okul_subeleri WHERE katilim_kodu = v_kod);
  END LOOP;
  UPDATE public.okul_subeleri SET katilim_kodu = v_kod WHERE id = p_sube_id AND okul_id = v_okul;
  IF NOT FOUND THEN RAISE EXCEPTION 'Şube bulunamadı'; END IF;
  RETURN v_kod;
END $$;

-- Yalnızca öğrencisi olmayan şube silinir. Dönüş: 'ok' | 'dolu'.
CREATE OR REPLACE FUNCTION public.okul_sube_sil(p_sube_id UUID) RETURNS TEXT
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_okul UUID := public._mudur_okulu();
BEGIN
  IF EXISTS (SELECT 1 FROM public.okul_uyeleri WHERE sube_id = p_sube_id AND rol = 'ogrenci') THEN
    RETURN 'dolu';
  END IF;
  DELETE FROM public.okul_subeleri WHERE id = p_sube_id AND okul_id = v_okul;
  IF NOT FOUND THEN RAISE EXCEPTION 'Şube bulunamadı'; END IF;
  RETURN 'ok';
END $$;

CREATE OR REPLACE FUNCTION public.okul_ogretmen_kodu_uret(p_rehber BOOLEAN, p_brans TEXT) RETURNS TEXT
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_okul  UUID := public._mudur_okulu();
  v_brans TEXT := NULLIF(left(trim(COALESCE(p_brans, '')), 40), '');
  v_kod   TEXT;
BEGIN
  IF NOT COALESCE(p_rehber, false) AND v_brans IS NULL THEN
    RAISE EXCEPTION 'Branş öğretmeni için ders seçilmelidir';
  END IF;
  IF (SELECT COUNT(*) FROM public.okul_davetleri
       WHERE okul_id = v_okul AND kullanan IS NULL AND son_gecerlilik > NOW()) >= 50 THEN
    RAISE EXCEPTION 'Bekleyen davet sayısı sınırına ulaşıldı';
  END IF;
  LOOP
    v_kod := public._okul_kod_uret('T');
    EXIT WHEN NOT EXISTS (SELECT 1 FROM public.okul_davetleri WHERE kod = v_kod);
  END LOOP;
  INSERT INTO public.okul_davetleri (kod, okul_id, tur, rehber, brans, olusturan)
  VALUES (v_kod, v_okul, 'ogretmen', COALESCE(p_rehber, false),
          CASE WHEN COALESCE(p_rehber, false) THEN NULL ELSE v_brans END, auth.uid());
  RETURN v_kod;
END $$;

CREATE OR REPLACE FUNCTION public.okul_davet_iptal(p_kod TEXT) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_okul UUID := public._mudur_okulu();
BEGIN
  DELETE FROM public.okul_davetleri
   WHERE kod = public._okul_kod_temizle(p_kod) AND okul_id = v_okul AND tur = 'ogretmen' AND kullanan IS NULL;
END $$;

-- Öğretmenin şubelerini, rehberlik durumunu ve branşını ayarlar.
CREATE OR REPLACE FUNCTION public.okul_ogretmen_ayarla(
  p_ogretmen_id UUID, p_sube_ids UUID[], p_rehber BOOLEAN, p_brans TEXT
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_okul  UUID := public._mudur_okulu();
  v_brans TEXT := NULLIF(left(trim(COALESCE(p_brans, '')), 40), '');
BEGIN
  IF NOT COALESCE(p_rehber, false) AND v_brans IS NULL THEN
    RAISE EXCEPTION 'Branş öğretmeni için ders seçilmelidir';
  END IF;
  UPDATE public.okul_uyeleri
     SET rehber = COALESCE(p_rehber, false),
         brans = CASE WHEN COALESCE(p_rehber, false) THEN NULL ELSE v_brans END
   WHERE user_id = p_ogretmen_id AND okul_id = v_okul AND rol = 'ogretmen';
  IF NOT FOUND THEN RAISE EXCEPTION 'Öğretmen bulunamadı'; END IF;

  DELETE FROM public.ogretmen_subeleri WHERE ogretmen_id = p_ogretmen_id;
  INSERT INTO public.ogretmen_subeleri (ogretmen_id, sube_id)
  SELECT p_ogretmen_id, s.id
    FROM public.okul_subeleri s
   WHERE s.okul_id = v_okul AND s.id = ANY(COALESCE(p_sube_ids, ARRAY[]::UUID[]));
END $$;

-- Öğretmeni ya da öğrenciyi okuldan çıkarır.
CREATE OR REPLACE FUNCTION public.okul_uyesini_cikar(p_user_id UUID) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_okul UUID := public._mudur_okulu();
  v_rol  TEXT;
BEGIN
  DELETE FROM public.okul_uyeleri
   WHERE user_id = p_user_id AND okul_id = v_okul AND rol IN ('ogretmen', 'ogrenci')
  RETURNING rol INTO v_rol;
  IF NOT FOUND THEN RAISE EXCEPTION 'Üye bulunamadı'; END IF;
  IF v_rol = 'ogretmen' THEN
    DELETE FROM public.ogretmen_subeleri WHERE ogretmen_id = p_user_id;
    UPDATE public.profiles SET role = 'student' WHERE id = p_user_id AND role = 'teacher';
  ELSE
    PERFORM public._okul_ayrilma_sonrasi(p_user_id);
  END IF;
END $$;

-- ─── Uygulama yöneticisi (admin) işlemleri ───────────────────────────

CREATE OR REPLACE FUNCTION public._admin_mudur_kodu(p_okul_id UUID) RETURNS TEXT
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_kod TEXT;
BEGIN
  DELETE FROM public.okul_davetleri WHERE okul_id = p_okul_id AND tur = 'mudur' AND kullanan IS NULL;
  LOOP
    v_kod := public._okul_kod_uret('M');
    EXIT WHEN NOT EXISTS (SELECT 1 FROM public.okul_davetleri WHERE kod = v_kod);
  END LOOP;
  INSERT INTO public.okul_davetleri (kod, okul_id, tur, olusturan, son_gecerlilik)
  VALUES (v_kod, p_okul_id, 'mudur', auth.uid(), NOW() + INTERVAL '30 days');
  RETURN v_kod;
END $$;

-- Dönüş: { okul_id, kod } — kod müdüre iletilir.
CREATE OR REPLACE FUNCTION public.admin_okul_olustur(p_ad TEXT, p_il TEXT, p_ilce TEXT) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_id UUID;
BEGIN
  IF NOT public.is_admin() THEN RAISE EXCEPTION 'Yetkisiz'; END IF;
  INSERT INTO public.okullar (ad, il, ilce)
  VALUES (left(trim(p_ad), 120), left(trim(COALESCE(p_il, '')), 40), left(trim(COALESCE(p_ilce, '')), 40))
  RETURNING id INTO v_id;
  RETURN jsonb_build_object('okul_id', v_id, 'kod', public._admin_mudur_kodu(v_id));
END $$;

CREATE OR REPLACE FUNCTION public.admin_okul_mudur_kodu(p_okul_id UUID) RETURNS TEXT
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.is_admin() THEN RAISE EXCEPTION 'Yetkisiz'; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.okullar WHERE id = p_okul_id) THEN RAISE EXCEPTION 'Okul bulunamadı'; END IF;
  RETURN public._admin_mudur_kodu(p_okul_id);
END $$;

CREATE OR REPLACE FUNCTION public.admin_okul_aktiflik(p_okul_id UUID, p_aktif BOOLEAN) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.is_admin() THEN RAISE EXCEPTION 'Yetkisiz'; END IF;
  UPDATE public.okullar SET aktif = COALESCE(p_aktif, true) WHERE id = p_okul_id;
END $$;

CREATE OR REPLACE FUNCTION public.admin_okullar() RETURNS JSONB
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.is_admin() THEN RAISE EXCEPTION 'Yetkisiz'; END IF;
  RETURN COALESCE((
    SELECT jsonb_agg(jsonb_build_object(
             'id', o.id, 'ad', o.ad, 'il', o.il, 'ilce', o.ilce, 'aktif', o.aktif, 'created_at', o.created_at,
             'ogrenci', (SELECT COUNT(*) FROM public.okul_uyeleri u WHERE u.okul_id = o.id AND u.rol = 'ogrenci'),
             'ogretmen', (SELECT COUNT(*) FROM public.okul_uyeleri u WHERE u.okul_id = o.id AND u.rol = 'ogretmen'),
             'mudurler', COALESCE((
               SELECT jsonb_agg(COALESCE(NULLIF(p.name, ''), 'Müdür'))
                 FROM public.okul_uyeleri u JOIN public.profiles p ON p.id = u.user_id
                WHERE u.okul_id = o.id AND u.rol = 'mudur'), '[]'::jsonb),
             'bekleyen_kod', (SELECT d.kod FROM public.okul_davetleri d
                               WHERE d.okul_id = o.id AND d.tur = 'mudur' AND d.kullanan IS NULL
                                 AND d.son_gecerlilik > NOW()
                               ORDER BY d.created_at DESC LIMIT 1)
           ) ORDER BY o.created_at DESC)
      FROM public.okullar o), '[]'::jsonb);
END $$;

-- ─── Okul modu: okul öğrencisi açık akışta ve herkese açık odalarda yer almaz ──

CREATE OR REPLACE FUNCTION public._okul_modu_engeli() RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW.user_id IS NOT NULL AND public._okul_ogrencisi_mi(NEW.user_id) THEN
    RAISE EXCEPTION 'Okul hesabıyla açık toplulukta paylaşım yapılamaz';
  END IF;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_posts_okul_modu ON public.posts;
CREATE TRIGGER trg_posts_okul_modu
BEFORE INSERT ON public.posts
FOR EACH ROW EXECUTE FUNCTION public._okul_modu_engeli();

DO $$
BEGIN
  IF to_regclass('public.etut_odasi_uyeleri') IS NOT NULL THEN
    DROP TRIGGER IF EXISTS trg_etut_okul_modu ON public.etut_odasi_uyeleri;
    CREATE TRIGGER trg_etut_okul_modu
    BEFORE INSERT ON public.etut_odasi_uyeleri
    FOR EACH ROW EXECUTE FUNCTION public._okul_modu_engeli();
  END IF;
END $$;

COMMENT ON COLUMN public.profiles.role IS
  'student | baskan | coach | teacher | parent | principal | admin — DB seviyesinde CHECK yok; rol yalnızca SECURITY DEFINER fonksiyonlarla değişir.';

-- ─── Çalıştırma yetkileri ────────────────────────────────────────────
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT p.oid::regprocedure AS imza, p.proname
      FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = 'public'
       AND p.proname IN (
         '_okul_kod_uret', '_okul_kod_temizle', '_mudur_okulu', '_okul_ogrencisi_mi', '_okul_katilim_sonrasi',
         '_okul_ayrilma_sonrasi',
         '_admin_mudur_kodu', '_okul_modu_engeli',
         'okul_durumum', 'okul_kodu_kullan', 'veli_kodu_uret', 'veli_baglantilarim', 'veli_baglantisini_bitir',
         'okuldan_ayril', 'okul_yonetim_ozeti', 'okul_sube_ekle', 'okul_sube_kodu_yenile', 'okul_sube_sil',
         'okul_ogretmen_kodu_uret', 'okul_davet_iptal', 'okul_ogretmen_ayarla', 'okul_uyesini_cikar',
         'admin_okul_olustur', 'admin_okul_mudur_kodu', 'admin_okul_aktiflik', 'admin_okullar'
       )
  LOOP
    EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM PUBLIC, anon', r.imza);
    IF left(r.proname, 1) = '_' THEN
      EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM authenticated', r.imza);
    ELSE
      EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated', r.imza);
    END IF;
  END LOOP;
END $$;


-- ═════════════════════════════════════════════════════════════════════
-- 22. Okul Raporlama (öğretmen, veli ve müdür panellerinin verisi)
-- ═════════════════════════════════════════════════════════════════════
-- Supabase SQL Editor'de TEK SEFERLİK çalıştırılmalıdır (idempotent).
-- 21_okul_yapisi.sql'den SONRA çalıştırılır.
--
-- * Çalışma süresi, sunucunun kendi ölçtüğü odak oturumlarından
--   (study_sessions) hesaplanır; gün sınırı Türkiye saatine göredir.
-- * Program uyumu, konu ilerlemesi ve konu bazlı test sonuçları, öğrencinin
--   eşitlenen kayıtlarından (student_data) bir tetikleyiciyle özet tablolara
--   aktarılır. Yalnızca bir okula ya da veliye bağlı öğrenciler izlenir.
-- * Ruh hâli kayıtları (checkin_log), asistan sohbetleri ve gönderiler hiçbir
--   rapora girmez.
-- * Öğretmen ham tablolara erişemez; her rapor, erişim yetkisini kendi
--   içinde denetleyen SECURITY DEFINER bir fonksiyondan gelir.
-- * Rehber öğretmen şubesindeki öğrencinin tüm derslerini, branş öğretmeni
--   yalnızca kendi dersini görür. Müdür yalnızca şube toplamlarını görür.

CREATE TABLE IF NOT EXISTS public.ogrenci_gunluk_ozet (
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  gun         DATE NOT NULL,
  beyan_dk    INTEGER NOT NULL DEFAULT 0,          -- öğrencinin kendi kaydındaki süre
  ders_dk     JSONB NOT NULL DEFAULT '{}'::jsonb,  -- { ders: dakika } (kendi kaydı)
  plan_blok   INTEGER NOT NULL DEFAULT 0,
  plan_tamam  INTEGER NOT NULL DEFAULT 0,
  plan_dk     INTEGER NOT NULL DEFAULT 0,
  tamam_dk    INTEGER NOT NULL DEFAULT 0,
  konu_tamam  INTEGER,
  konu_zayif  INTEGER,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, gun)
);
ALTER TABLE public.ogrenci_gunluk_ozet ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.ogrenci_test_ozet (
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  gun     DATE NOT NULL,
  ders    TEXT NOT NULL,
  konu    TEXT NOT NULL,
  dogru   INTEGER NOT NULL DEFAULT 0,
  yanlis  INTEGER NOT NULL DEFAULT 0,
  bos     INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (user_id, gun, ders, konu)
);
ALTER TABLE public.ogrenci_test_ozet ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.rehber_gorusmeleri (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ogretmen_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  ogrenci_id  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  not_metni   TEXT NOT NULL CHECK (char_length(not_metni) BETWEEN 1 AND 1000),
  hedef       TEXT CHECK (hedef IS NULL OR char_length(hedef) <= 300),
  tarih       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_rehber_gorusmeleri_ogrenci ON public.rehber_gorusmeleri(ogrenci_id, tarih DESC);
ALTER TABLE public.rehber_gorusmeleri ENABLE ROW LEVEL SECURITY;

-- Öğretmenin şubeye yaptığı çalışma önerisi (zorunlu ödev değildir).
CREATE TABLE IF NOT EXISTS public.ogretmen_onerileri (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ogretmen_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  sube_id     UUID NOT NULL REFERENCES public.okul_subeleri(id) ON DELETE CASCADE,
  ders        TEXT NOT NULL CHECK (char_length(ders) BETWEEN 1 AND 60),
  konu        TEXT NOT NULL CHECK (char_length(konu) BETWEEN 1 AND 120),
  not_metni   TEXT CHECK (not_metni IS NULL OR char_length(not_metni) <= 400),
  sure_dk     INTEGER NOT NULL DEFAULT 30 CHECK (sure_dk BETWEEN 10 AND 240),
  bitis       DATE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_ogretmen_onerileri_sube ON public.ogretmen_onerileri(sube_id, created_at DESC);
ALTER TABLE public.ogretmen_onerileri ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.oneri_durumlari (
  oneri_id   UUID NOT NULL REFERENCES public.ogretmen_onerileri(id) ON DELETE CASCADE,
  ogrenci_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  durum      TEXT NOT NULL CHECK (durum IN ('eklendi', 'tamamlandi')),
  guncelleme TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (oneri_id, ogrenci_id)
);
ALTER TABLE public.oneri_durumlari ENABLE ROW LEVEL SECURITY;

-- ─── Yardımcılar ─────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public._bugun_tr() RETURNS DATE
LANGUAGE sql STABLE AS $$
  SELECT (NOW() AT TIME ZONE 'Europe/Istanbul')::date;
$$;

CREATE OR REPLACE FUNCTION public._guvenli_tarih(p TEXT) RETURNS DATE
LANGUAGE plpgsql IMMUTABLE AS $$
BEGIN
  RETURN p::date;
EXCEPTION WHEN OTHERS THEN
  RETURN NULL;
END $$;

-- JSON sayısını [0, p_ust] aralığında tam sayıya çevirir; sayı değilse 0.
CREATE OR REPLACE FUNCTION public._jsayi(p JSONB, p_ust INTEGER) RETURNS INTEGER
LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE WHEN jsonb_typeof(p) = 'number'
              THEN LEAST(GREATEST(round((p #>> '{}')::numeric), 0), p_ust)::integer
              ELSE 0 END;
$$;

-- Branş süzgeci: p_brans NULL ise her ders eşleşir. Matematik öğretmeni
-- geometriyi de görür.
CREATE OR REPLACE FUNCTION public._brans_eslesir(p_ders TEXT, p_brans TEXT) RETURNS BOOLEAN
LANGUAGE sql IMMUTABLE AS $$
  SELECT p_brans IS NULL
      OR position(lower(trim(p_brans)) IN lower(COALESCE(p_ders, ''))) > 0
      OR (lower(trim(p_brans)) = 'matematik' AND position('geometri' IN lower(COALESCE(p_ders, ''))) > 0);
$$;

CREATE OR REPLACE FUNCTION public._ozet_izlenen_mi(p_user UUID) RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.okul_uyeleri WHERE user_id = p_user AND rol = 'ogrenci')
      OR EXISTS (SELECT 1 FROM public.veli_baglantilari WHERE ogrenci_id = p_user AND durum = 'aktif');
$$;

-- Öğrencinin eşitlenen bir kaydını (son 45 gün) özet tablolara aktarır.
CREATE OR REPLACE FUNCTION public._ogrenci_ozet_isle(p_user UUID, p_key TEXT, p_val JSONB) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_sinir TEXT := to_char(public._bugun_tr() - 45, 'YYYY-MM-DD');
BEGIN
  IF p_val IS NULL OR jsonb_typeof(p_val) <> 'object' THEN RETURN; END IF;

  IF p_key = 'calisma_gunluk_log' THEN
    INSERT INTO public.ogrenci_gunluk_ozet (user_id, gun, beyan_dk)
    SELECT p_user, g.gun, public._jsayi(g.deger, 1440)
      FROM (SELECT public._guvenli_tarih(e.key) AS gun, e.value AS deger
              FROM jsonb_each(p_val) e
             WHERE e.key ~ '^\d{4}-\d{2}-\d{2}$' AND e.key >= v_sinir) g
     WHERE g.gun IS NOT NULL
    ON CONFLICT (user_id, gun) DO UPDATE SET beyan_dk = EXCLUDED.beyan_dk, updated_at = NOW();

  ELSIF p_key = 'calisma_ders_log' THEN
    INSERT INTO public.ogrenci_gunluk_ozet (user_id, gun, ders_dk)
    SELECT p_user, g.gun, g.deger
      FROM (SELECT public._guvenli_tarih(e.key) AS gun, e.value AS deger
              FROM jsonb_each(p_val) e
             WHERE e.key ~ '^\d{4}-\d{2}-\d{2}$' AND e.key >= v_sinir
               AND jsonb_typeof(e.value) = 'object' AND pg_column_size(e.value) < 4096) g
     WHERE g.gun IS NOT NULL
    ON CONFLICT (user_id, gun) DO UPDATE SET ders_dk = EXCLUDED.ders_dk, updated_at = NOW();

  ELSIF p_key = 'plan_uyum_log' THEN
    INSERT INTO public.ogrenci_gunluk_ozet (user_id, gun, plan_blok, plan_tamam, plan_dk, tamam_dk)
    SELECT p_user, g.gun,
           public._jsayi(g.deger -> 0, 100), public._jsayi(g.deger -> 1, 100),
           public._jsayi(g.deger -> 2, 1440), public._jsayi(g.deger -> 3, 1440)
      FROM (SELECT public._guvenli_tarih(e.key) AS gun, e.value AS deger
              FROM jsonb_each(p_val) e
             WHERE e.key ~ '^\d{4}-\d{2}-\d{2}$' AND e.key >= v_sinir AND jsonb_typeof(e.value) = 'array') g
     WHERE g.gun IS NOT NULL
    ON CONFLICT (user_id, gun) DO UPDATE
      SET plan_blok = EXCLUDED.plan_blok, plan_tamam = EXCLUDED.plan_tamam,
          plan_dk = EXCLUDED.plan_dk, tamam_dk = EXCLUDED.tamam_dk, updated_at = NOW();

  ELSIF p_key = 'konu_ilerleme_log' THEN
    INSERT INTO public.ogrenci_gunluk_ozet (user_id, gun, konu_tamam, konu_zayif)
    SELECT p_user, g.gun, public._jsayi(g.deger -> 0, 5000), public._jsayi(g.deger -> 1, 5000)
      FROM (SELECT public._guvenli_tarih(e.key) AS gun, e.value AS deger
              FROM jsonb_each(p_val) e
             WHERE e.key ~ '^\d{4}-\d{2}-\d{2}$' AND e.key >= v_sinir AND jsonb_typeof(e.value) = 'array') g
     WHERE g.gun IS NOT NULL
    ON CONFLICT (user_id, gun) DO UPDATE
      SET konu_tamam = EXCLUDED.konu_tamam, konu_zayif = EXCLUDED.konu_zayif, updated_at = NOW();

  ELSIF p_key = 'test_konu_log' THEN
    DELETE FROM public.ogrenci_test_ozet WHERE user_id = p_user AND gun >= public._bugun_tr() - 45;
    INSERT INTO public.ogrenci_test_ozet (user_id, gun, ders, konu, dogru, yanlis, bos)
    SELECT p_user, x.gun, x.ders, x.konu, SUM(x.dogru)::integer, SUM(x.yanlis)::integer, SUM(x.bos)::integer
      FROM (
        SELECT g.gun,
               left(COALESCE(NULLIF(trim(split_part(t.key, '>', 1)), ''), 'Genel'), 60) AS ders,
               left(CASE WHEN strpos(t.key, '>') > 0
                         THEN COALESCE(NULLIF(trim(substr(t.key, strpos(t.key, '>') + 1)), ''), 'Genel')
                         ELSE 'Genel' END, 120) AS konu,
               public._jsayi(t.value -> 0, 1000) AS dogru,
               public._jsayi(t.value -> 1, 1000) AS yanlis,
               public._jsayi(t.value -> 2, 1000) AS bos
          FROM (SELECT public._guvenli_tarih(e.key) AS gun, e.value AS deger
                  FROM jsonb_each(p_val) e
                 WHERE e.key ~ '^\d{4}-\d{2}-\d{2}$' AND e.key >= v_sinir AND jsonb_typeof(e.value) = 'object') g
          CROSS JOIN LATERAL jsonb_each(g.deger) t
         WHERE g.gun IS NOT NULL AND jsonb_typeof(t.value) = 'array'
      ) x
     GROUP BY x.gun, x.ders, x.konu;
  END IF;
END $$;

-- Kayıt eşitlendikçe özet güncellenir. Özet hatası öğrencinin kaydını asla
-- engellemez.
CREATE OR REPLACE FUNCTION public._student_data_ozet_tetik() RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW.data_key IN ('calisma_gunluk_log', 'calisma_ders_log', 'plan_uyum_log', 'konu_ilerleme_log', 'test_konu_log')
     AND public._ozet_izlenen_mi(NEW.user_id) THEN
    BEGIN
      PERFORM public._ogrenci_ozet_isle(NEW.user_id, NEW.data_key, NEW.data_value);
    EXCEPTION WHEN OTHERS THEN
      NULL;
    END;
  END IF;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_student_data_ozet ON public.student_data;
CREATE TRIGGER trg_student_data_ozet
AFTER INSERT OR UPDATE ON public.student_data
FOR EACH ROW EXECUTE FUNCTION public._student_data_ozet_tetik();

-- Öğrenci bir okula ya da veliye bağlandığında geçmiş kayıtları aktarılır
-- (21'deki boş tanımın yerini alır).
CREATE OR REPLACE FUNCTION public._okul_katilim_sonrasi(p_user UUID) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT data_key, data_value FROM public.student_data
     WHERE user_id = p_user
       AND data_key IN ('calisma_gunluk_log', 'calisma_ders_log', 'plan_uyum_log', 'konu_ilerleme_log', 'test_konu_log')
  LOOP
    BEGIN
      PERFORM public._ogrenci_ozet_isle(p_user, r.data_key, r.data_value);
    EXCEPTION WHEN OTHERS THEN
      NULL;
    END;
  END LOOP;
END $$;

-- Öğrenci artık ne bir okula ne de bir veliye bağlıysa, paylaşım için
-- tutulan özet kayıtları silinir (21'deki boş tanımın yerini alır). Öğrencinin
-- kendi verisi (student_data) etkilenmez.
CREATE OR REPLACE FUNCTION public._okul_ayrilma_sonrasi(p_user UUID) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF p_user IS NULL THEN RETURN; END IF;
  -- Okuldan ayrılan öğrencinin öneri işaretleri ve görüşme notları kalmaz.
  IF NOT EXISTS (SELECT 1 FROM public.okul_uyeleri WHERE user_id = p_user AND rol = 'ogrenci') THEN
    DELETE FROM public.oneri_durumlari WHERE ogrenci_id = p_user;
    DELETE FROM public.rehber_gorusmeleri WHERE ogrenci_id = p_user;
  END IF;
  IF NOT public._ozet_izlenen_mi(p_user) THEN
    DELETE FROM public.ogrenci_gunluk_ozet WHERE user_id = p_user;
    DELETE FROM public.ogrenci_test_ozet WHERE user_id = p_user;
  END IF;
END $$;

-- ─── Erişim denetimi ─────────────────────────────────────────────────

-- Çağıran öğretmen bu şubeye atanmış mı? Rehber değilse branşı döner.
CREATE OR REPLACE FUNCTION public._ogretmen_sube_erisimi(
  p_sube_id UUID, OUT o_izin BOOLEAN, OUT o_rehber BOOLEAN, OUT o_brans TEXT
) LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
BEGIN
  SELECT true, u.rehber, CASE WHEN u.rehber THEN NULL ELSE u.brans END
    INTO o_izin, o_rehber, o_brans
    FROM public.okul_uyeleri u
    JOIN public.okullar o ON o.id = u.okul_id AND o.aktif
    JOIN public.ogretmen_subeleri os ON os.ogretmen_id = u.user_id AND os.sube_id = p_sube_id
    JOIN public.okul_subeleri s ON s.id = os.sube_id AND s.okul_id = u.okul_id
   WHERE u.user_id = auth.uid() AND u.rol = 'ogretmen';
  o_izin := COALESCE(o_izin, false);
  o_rehber := COALESCE(o_rehber, false);
END $$;

-- Çağıranın bu öğrenciye erişim türü: 'kendi' | 'veli' | 'rehber' | 'brans' | NULL.
CREATE OR REPLACE FUNCTION public._ogrenci_erisimi(
  p_ogrenci UUID, OUT o_tur TEXT, OUT o_brans TEXT
) LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid    UUID := auth.uid();
  v_rehber BOOLEAN;
  v_brans  TEXT;
BEGIN
  IF v_uid IS NULL THEN RETURN; END IF;
  IF v_uid = p_ogrenci THEN o_tur := 'kendi'; RETURN; END IF;

  IF EXISTS (SELECT 1 FROM public.veli_baglantilari
              WHERE veli_id = v_uid AND ogrenci_id = p_ogrenci AND durum = 'aktif') THEN
    o_tur := 'veli'; RETURN;
  END IF;

  SELECT u.rehber, u.brans INTO v_rehber, v_brans
    FROM public.okul_uyeleri u
    JOIN public.okullar o ON o.id = u.okul_id AND o.aktif
    JOIN public.okul_uyeleri og ON og.user_id = p_ogrenci AND og.rol = 'ogrenci' AND og.okul_id = u.okul_id
    JOIN public.ogretmen_subeleri os ON os.ogretmen_id = u.user_id AND os.sube_id = og.sube_id
   WHERE u.user_id = v_uid AND u.rol = 'ogretmen';
  IF NOT FOUND THEN RETURN; END IF;

  IF v_rehber THEN
    o_tur := 'rehber';
  ELSE
    o_tur := 'brans';
    o_brans := v_brans;
  END IF;
END $$;

-- ─── Şube özeti (iç fonksiyon) ───────────────────────────────────────
-- dk0: son 7 gün, dk1: önceki 7 gün (p_brans verilmişse yalnızca o ders).
-- Risk yalnızca tüm derslere bakılırken (p_brans NULL) hesaplanır:
--   'pasif'  : 14 gündür hiç çalışma yok
--   'dusus'  : çalışma süresi iki hafta üst üste düştü ve yarıya indi
--   'yeni'   : şubeye yeni katıldı, henüz kayıt yok
CREATE OR REPLACE FUNCTION public._sube_ogrenci_ozeti(p_sube_id UUID, p_brans TEXT)
RETURNS TABLE(
  ogr_id UUID, ogr_ad TEXT, dk0 INTEGER, dk1 INTEGER, dk2 INTEGER, aktif_gun INTEGER,
  plan_blok INTEGER, plan_tamam INTEGER, son_aktif TIMESTAMPTZ, risk TEXT
)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  WITH b AS (SELECT public._bugun_tr() AS d),
  uye AS (
    SELECT u.user_id, u.katilma, COALESCE(NULLIF(p.name, ''), 'Öğrenci') AS ad
      FROM public.okul_uyeleri u
      JOIN public.profiles p ON p.id = u.user_id
     WHERE u.sube_id = p_sube_id AND u.rol = 'ogrenci'
  ),
  seans AS (
    SELECT s.user_id,
           (s.started_at AT TIME ZONE 'Europe/Istanbul')::date AS gun,
           LEAST(COALESCE(s.actual_minutes, 0), 240) AS dk,
           s.started_at,
           public._brans_eslesir(s.label, p_brans) AS eslesir
      FROM public.study_sessions s
      JOIN uye ON uye.user_id = s.user_id
     WHERE s.ended_at IS NOT NULL AND s.started_at > NOW() - INTERVAL '23 days'
  ),
  t AS (
    SELECT uye.user_id,
           COALESCE(SUM(seans.dk) FILTER (WHERE seans.eslesir AND seans.gun > b.d - 7), 0)::integer AS dk0,
           COALESCE(SUM(seans.dk) FILTER (WHERE seans.eslesir AND seans.gun <= b.d - 7 AND seans.gun > b.d - 14), 0)::integer AS dk1,
           COALESCE(SUM(seans.dk) FILTER (WHERE seans.eslesir AND seans.gun <= b.d - 14 AND seans.gun > b.d - 21), 0)::integer AS dk2,
           (COUNT(DISTINCT seans.gun) FILTER (WHERE seans.eslesir AND seans.dk > 0 AND seans.gun > b.d - 7))::integer AS aktif_gun,
           MAX(seans.started_at) FILTER (WHERE seans.eslesir) AS son_seans
      FROM uye CROSS JOIN b
      LEFT JOIN seans ON seans.user_id = uye.user_id
     GROUP BY uye.user_id
  ),
  o AS (
    SELECT uye.user_id,
           COALESCE(SUM(g.plan_blok) FILTER (WHERE g.gun > b.d - 7), 0)::integer AS plan_blok,
           COALESCE(SUM(g.plan_tamam) FILTER (WHERE g.gun > b.d - 7), 0)::integer AS plan_tamam,
           COALESCE(SUM(g.beyan_dk) FILTER (WHERE g.gun > b.d - 14), 0)::integer AS beyan14,
           MAX(g.gun) FILTER (WHERE g.beyan_dk > 0 OR g.plan_tamam > 0) AS son_gun
      FROM uye CROSS JOIN b
      LEFT JOIN public.ogrenci_gunluk_ozet g ON g.user_id = uye.user_id AND g.gun > b.d - 22
     GROUP BY uye.user_id
  )
  SELECT uye.user_id, uye.ad, t.dk0, t.dk1, t.dk2, t.aktif_gun,
         CASE WHEN p_brans IS NULL THEN o.plan_blok ELSE 0 END,
         CASE WHEN p_brans IS NULL THEN o.plan_tamam ELSE 0 END,
         CASE WHEN p_brans IS NULL
              THEN GREATEST(t.son_seans, (o.son_gun::timestamp AT TIME ZONE 'Europe/Istanbul'))
              ELSE t.son_seans END,
         CASE
           WHEN p_brans IS NOT NULL THEN 'yok'
           WHEN t.dk0 = 0 AND t.dk1 = 0 AND o.beyan14 = 0 AND uye.katilma < NOW() - INTERVAL '14 days' THEN 'pasif'
           WHEN t.dk0 = 0 AND t.dk1 = 0 AND o.beyan14 = 0 THEN 'yeni'
           WHEN t.dk2 >= 60 AND t.dk1 < t.dk2 AND t.dk0 < t.dk1 AND t.dk0 * 2 <= t.dk2 THEN 'dusus'
           ELSE 'yok'
         END
    FROM uye
    JOIN t ON t.user_id = uye.user_id
    JOIN o ON o.user_id = uye.user_id;
$$;

-- ─── Öğretmen raporları ──────────────────────────────────────────────

-- { rehber, brans, okul, siniflar: [ { sube_id, sinif, ad, ogrenci_sayisi, aktif_7g, ort_dk_7g, risk_sayisi } ] }
CREATE OR REPLACE FUNCTION public.ogretmen_siniflarim() RETURNS JSONB
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_uye public.okul_uyeleri%rowtype;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  SELECT u.* INTO v_uye
    FROM public.okul_uyeleri u JOIN public.okullar o ON o.id = u.okul_id AND o.aktif
   WHERE u.user_id = v_uid AND u.rol = 'ogretmen';
  IF NOT FOUND THEN RAISE EXCEPTION 'Bu işlem için öğretmen yetkisi gerekir'; END IF;

  RETURN jsonb_build_object(
    'rehber', v_uye.rehber,
    'brans', v_uye.brans,
    'okul', (SELECT o.ad FROM public.okullar o WHERE o.id = v_uye.okul_id),
    'siniflar', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
               'sube_id', s.id, 'sinif', s.sinif, 'ad', s.ad,
               'ogrenci_sayisi', x.n, 'aktif_7g', x.aktif, 'ort_dk_7g', x.ort, 'risk_sayisi', x.risk
             ) ORDER BY CASE s.sinif WHEN 'Mezun' THEN 99 ELSE s.sinif::INTEGER END, s.ad)
        FROM public.ogretmen_subeleri os
        JOIN public.okul_subeleri s ON s.id = os.sube_id AND s.okul_id = v_uye.okul_id
        CROSS JOIN LATERAL (
          SELECT COUNT(*)::integer AS n,
                 (COUNT(*) FILTER (WHERE z.dk0 > 0))::integer AS aktif,
                 COALESCE(round(AVG(z.dk0)), 0)::integer AS ort,
                 (COUNT(*) FILTER (WHERE z.risk IN ('pasif', 'dusus')))::integer AS risk
            FROM public._sube_ogrenci_ozeti(s.id, CASE WHEN v_uye.rehber THEN NULL ELSE v_uye.brans END) z
        ) x
       WHERE os.ogretmen_id = v_uid), '[]'::jsonb)
  );
END $$;

-- { sube, rehber, brans, ogrenciler: [ { id, ad, dk_7g, dk_onceki_7g, aktif_gun, plan_blok, plan_tamam, son_aktif, risk } ] }
CREATE OR REPLACE FUNCTION public.sube_ozeti(p_sube_id UUID) RETURNS JSONB
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_izin   BOOLEAN;
  v_rehber BOOLEAN;
  v_brans  TEXT;
BEGIN
  SELECT e.o_izin, e.o_rehber, e.o_brans INTO v_izin, v_rehber, v_brans
    FROM public._ogretmen_sube_erisimi(p_sube_id) e;
  IF NOT COALESCE(v_izin, false) THEN RAISE EXCEPTION 'Bu şubeye erişim yetkin yok'; END IF;

  RETURN jsonb_build_object(
    'sube', (SELECT jsonb_build_object('id', s.id, 'sinif', s.sinif, 'ad', s.ad)
               FROM public.okul_subeleri s WHERE s.id = p_sube_id),
    'rehber', v_rehber,
    'brans', v_brans,
    'ogrenciler', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
               'id', z.ogr_id, 'ad', z.ogr_ad, 'dk_7g', z.dk0, 'dk_onceki_7g', z.dk1,
               'aktif_gun', z.aktif_gun, 'plan_blok', z.plan_blok, 'plan_tamam', z.plan_tamam,
               'son_aktif', z.son_aktif, 'risk', z.risk
             ) ORDER BY CASE z.risk WHEN 'pasif' THEN 0 WHEN 'dusus' THEN 1 ELSE 2 END, z.ogr_ad)
        FROM public._sube_ogrenci_ozeti(p_sube_id, v_brans) z), '[]'::jsonb)
  );
END $$;

-- Rehber öğretmenin tüm şubelerindeki uyarılar. Branş öğretmeni için boş döner.
CREATE OR REPLACE FUNCTION public.ogretmen_uyarilari() RETURNS JSONB
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_uye public.okul_uyeleri%rowtype;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  SELECT u.* INTO v_uye
    FROM public.okul_uyeleri u JOIN public.okullar o ON o.id = u.okul_id AND o.aktif
   WHERE u.user_id = v_uid AND u.rol = 'ogretmen';
  IF NOT FOUND THEN RAISE EXCEPTION 'Bu işlem için öğretmen yetkisi gerekir'; END IF;
  IF NOT v_uye.rehber THEN RETURN '[]'::jsonb; END IF;

  RETURN COALESCE((
    SELECT jsonb_agg(jsonb_build_object(
             'id', z.ogr_id, 'ad', z.ogr_ad, 'sube_id', s.id, 'sube', s.sinif || '-' || s.ad,
             'risk', z.risk, 'dk_7g', z.dk0, 'dk_onceki_7g', z.dk1, 'dk_2onceki_7g', z.dk2, 'son_aktif', z.son_aktif
           ) ORDER BY CASE z.risk WHEN 'pasif' THEN 0 ELSE 1 END, z.dk0, z.ogr_ad)
      FROM public.ogretmen_subeleri os
      JOIN public.okul_subeleri s ON s.id = os.sube_id AND s.okul_id = v_uye.okul_id
      CROSS JOIN LATERAL public._sube_ogrenci_ozeti(s.id, NULL) z
     WHERE os.ogretmen_id = v_uid AND z.risk IN ('pasif', 'dusus')), '[]'::jsonb);
END $$;

-- Şubenin son 30 günde en çok zorlandığı konular. En az 3 öğrencinin test
-- çözdüğü konular listelenir (tek öğrencinin sonucu sınıf verisi gibi görünmesin).
CREATE OR REPLACE FUNCTION public.sube_konu_ozeti(p_sube_id UUID) RETURNS JSONB
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_izin   BOOLEAN;
  v_rehber BOOLEAN;
  v_brans  TEXT;
BEGIN
  SELECT e.o_izin, e.o_rehber, e.o_brans INTO v_izin, v_rehber, v_brans
    FROM public._ogretmen_sube_erisimi(p_sube_id) e;
  IF NOT COALESCE(v_izin, false) THEN RAISE EXCEPTION 'Bu şubeye erişim yetkin yok'; END IF;

  RETURN COALESCE((
    SELECT jsonb_agg(jsonb_build_object(
             'ders', k.ders, 'konu', k.konu, 'dogru', k.dogru, 'yanlis', k.yanlis, 'bos', k.bos, 'ogrenci', k.ogrenci
           ) ORDER BY k.oran, k.toplam DESC)
      FROM (
        SELECT t.ders, t.konu,
               SUM(t.dogru)::integer AS dogru, SUM(t.yanlis)::integer AS yanlis, SUM(t.bos)::integer AS bos,
               COUNT(DISTINCT t.user_id)::integer AS ogrenci,
               SUM(t.dogru + t.yanlis + t.bos) AS toplam,
               SUM(t.dogru)::numeric / NULLIF(SUM(t.dogru + t.yanlis + t.bos), 0) AS oran
          FROM public.ogrenci_test_ozet t
          JOIN public.okul_uyeleri u ON u.user_id = t.user_id AND u.sube_id = p_sube_id AND u.rol = 'ogrenci'
         WHERE t.gun > public._bugun_tr() - 30 AND public._brans_eslesir(t.ders, v_brans)
         GROUP BY t.ders, t.konu
        HAVING COUNT(DISTINCT t.user_id) >= 3 AND SUM(t.dogru + t.yanlis + t.bos) >= 10
         ORDER BY 8, 7 DESC
         LIMIT 40
      ) k), '[]'::jsonb);
END $$;

-- ─── Öğrenci özeti (öğretmen, veli ve öğrencinin kendisi) ────────────

CREATE OR REPLACE FUNCTION public.ogrenci_ozeti(p_ogrenci_id UUID) RETURNS JSONB
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_tur   TEXT;
  v_brans TEXT;
  v_bugun DATE := public._bugun_tr();
BEGIN
  SELECT e.o_tur, e.o_brans INTO v_tur, v_brans FROM public._ogrenci_erisimi(p_ogrenci_id) e;
  IF v_tur IS NULL THEN RAISE EXCEPTION 'Bu öğrencinin verisine erişim yetkin yok'; END IF;

  RETURN jsonb_build_object(
    'erisim', v_tur,
    'brans', v_brans,
    'ad', (SELECT COALESCE(NULLIF(p.name, ''), 'Öğrenci') FROM public.profiles p WHERE p.id = p_ogrenci_id),
    'sinif', (SELECT p.grade FROM public.profiles p WHERE p.id = p_ogrenci_id),
    'sube', (SELECT s.sinif || '-' || s.ad
               FROM public.okul_uyeleri u JOIN public.okul_subeleri s ON s.id = u.sube_id
              WHERE u.user_id = p_ogrenci_id AND u.rol = 'ogrenci'),
    'okul', (SELECT o.ad FROM public.okul_uyeleri u JOIN public.okullar o ON o.id = u.okul_id
              WHERE u.user_id = p_ogrenci_id AND u.rol = 'ogrenci'),
    'gunler', (
      SELECT jsonb_agg(jsonb_build_object(
               'gun', to_char(d.gun, 'YYYY-MM-DD'),
               'dk', COALESCE(s.dk, 0),
               'beyan_dk', CASE WHEN v_brans IS NULL THEN COALESCE(g.beyan_dk, 0) ELSE 0 END,
               'plan_blok', CASE WHEN v_brans IS NULL THEN COALESCE(g.plan_blok, 0) ELSE 0 END,
               'plan_tamam', CASE WHEN v_brans IS NULL THEN COALESCE(g.plan_tamam, 0) ELSE 0 END
             ) ORDER BY d.gun)
        FROM (SELECT generate_series(v_bugun - 27, v_bugun, INTERVAL '1 day')::date AS gun) d
        LEFT JOIN (
          SELECT (ss.started_at AT TIME ZONE 'Europe/Istanbul')::date AS gun,
                 SUM(LEAST(COALESCE(ss.actual_minutes, 0), 240))::integer AS dk
            FROM public.study_sessions ss
           WHERE ss.user_id = p_ogrenci_id AND ss.ended_at IS NOT NULL
             AND ss.started_at > NOW() - INTERVAL '30 days'
             AND public._brans_eslesir(ss.label, v_brans)
           GROUP BY 1
        ) s ON s.gun = d.gun
        LEFT JOIN public.ogrenci_gunluk_ozet g ON g.user_id = p_ogrenci_id AND g.gun = d.gun),
    'ders_dk', COALESCE((
      SELECT jsonb_object_agg(x.ders, x.dk)
        FROM (
          SELECT COALESCE(NULLIF(trim(ss.label), ''), 'Genel') AS ders,
                 SUM(LEAST(COALESCE(ss.actual_minutes, 0), 240))::integer AS dk
            FROM public.study_sessions ss
           WHERE ss.user_id = p_ogrenci_id AND ss.ended_at IS NOT NULL
             AND (ss.started_at AT TIME ZONE 'Europe/Istanbul')::date > v_bugun - 28
             AND public._brans_eslesir(ss.label, v_brans)
           GROUP BY 1
          HAVING SUM(LEAST(COALESCE(ss.actual_minutes, 0), 240)) > 0
        ) x), '{}'::jsonb),
    'netler', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
               'deneme', n.deneme_adi, 'alan', n.alan, 'net', n.net, 'tarih', n.tarih
             ) ORDER BY n.tarih DESC)
        FROM (
          SELECT er.deneme_adi, er.alan, round(SUM(er.net), 2) AS net, MAX(er.submitted_at) AS tarih
            FROM public.exam_results er
           WHERE er.user_id = p_ogrenci_id AND public._brans_eslesir(er.ders, v_brans)
           GROUP BY er.deneme_adi, er.alan
           ORDER BY MAX(er.submitted_at) DESC
           LIMIT 8
        ) n), '[]'::jsonb),
    'konu', CASE WHEN v_brans IS NULL THEN (
      SELECT jsonb_build_object('tamam', g.konu_tamam, 'zayif', g.konu_zayif, 'gun', to_char(g.gun, 'YYYY-MM-DD'))
        FROM public.ogrenci_gunluk_ozet g
       WHERE g.user_id = p_ogrenci_id AND g.konu_tamam IS NOT NULL
       ORDER BY g.gun DESC LIMIT 1) END,
    'testler', COALESCE((
      SELECT jsonb_agg(jsonb_build_object('ders', t.ders, 'dogru', t.dogru, 'yanlis', t.yanlis, 'bos', t.bos)
                       ORDER BY t.ders)
        FROM (
          SELECT tt.ders, SUM(tt.dogru)::integer AS dogru, SUM(tt.yanlis)::integer AS yanlis, SUM(tt.bos)::integer AS bos
            FROM public.ogrenci_test_ozet tt
           WHERE tt.user_id = p_ogrenci_id AND tt.gun > v_bugun - 30 AND public._brans_eslesir(tt.ders, v_brans)
           GROUP BY tt.ders
        ) t), '[]'::jsonb),
    'gorusmeler', CASE WHEN v_tur = 'rehber' THEN COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
               'id', r.id, 'not', r.not_metni, 'hedef', r.hedef, 'tarih', r.tarih, 'benim', r.ogretmen_id = auth.uid(),
               'ogretmen', (SELECT COALESCE(NULLIF(p.name, ''), 'Öğretmen') FROM public.profiles p WHERE p.id = r.ogretmen_id)
             ) ORDER BY r.tarih DESC)
        FROM (SELECT * FROM public.rehber_gorusmeleri
               WHERE ogrenci_id = p_ogrenci_id ORDER BY tarih DESC LIMIT 20) r), '[]'::jsonb) END
  );
END $$;

-- ─── Görüşme notları (yalnızca rehber öğretmen) ──────────────────────

CREATE OR REPLACE FUNCTION public.gorusme_ekle(p_ogrenci_id UUID, p_not TEXT, p_hedef TEXT) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_tur TEXT;
BEGIN
  SELECT e.o_tur INTO v_tur FROM public._ogrenci_erisimi(p_ogrenci_id) e;
  IF v_tur IS DISTINCT FROM 'rehber' THEN RAISE EXCEPTION 'Görüşme notunu yalnızca rehber öğretmen ekleyebilir'; END IF;
  IF length(trim(COALESCE(p_not, ''))) = 0 THEN RAISE EXCEPTION 'Not boş olamaz'; END IF;
  INSERT INTO public.rehber_gorusmeleri (ogretmen_id, ogrenci_id, not_metni, hedef)
  VALUES (auth.uid(), p_ogrenci_id, left(trim(p_not), 1000), NULLIF(left(trim(COALESCE(p_hedef, '')), 300), ''));
END $$;

CREATE OR REPLACE FUNCTION public.gorusme_sil(p_id UUID) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  DELETE FROM public.rehber_gorusmeleri WHERE id = p_id AND ogretmen_id = auth.uid();
END $$;

-- ─── Öğretmen önerileri ──────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.oneri_olustur(
  p_sube_id UUID, p_ders TEXT, p_konu TEXT, p_not TEXT, p_sure_dk INTEGER, p_bitis DATE
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_izin   BOOLEAN;
  v_rehber BOOLEAN;
  v_brans  TEXT;
  v_ders   TEXT := left(trim(COALESCE(p_ders, '')), 60);
  v_konu   TEXT := left(trim(COALESCE(p_konu, '')), 120);
  v_id     UUID;
BEGIN
  SELECT e.o_izin, e.o_rehber, e.o_brans INTO v_izin, v_rehber, v_brans
    FROM public._ogretmen_sube_erisimi(p_sube_id) e;
  IF NOT COALESCE(v_izin, false) THEN RAISE EXCEPTION 'Bu şubeye erişim yetkin yok'; END IF;
  IF v_brans IS NOT NULL THEN v_ders := v_brans; END IF;
  IF v_ders = '' OR v_konu = '' THEN RAISE EXCEPTION 'Ders ve konu gerekli'; END IF;
  IF (SELECT COUNT(*) FROM public.ogretmen_onerileri
       WHERE ogretmen_id = auth.uid() AND sube_id = p_sube_id AND created_at > NOW() - INTERVAL '7 days') >= 20 THEN
    RAISE EXCEPTION 'Bu şubeye bir haftada en fazla 20 öneri gönderilebilir';
  END IF;

  INSERT INTO public.ogretmen_onerileri (ogretmen_id, sube_id, ders, konu, not_metni, sure_dk, bitis)
  VALUES (auth.uid(), p_sube_id, v_ders, v_konu, NULLIF(left(trim(COALESCE(p_not, '')), 400), ''),
          LEAST(GREATEST(COALESCE(p_sure_dk, 30), 10), 240), p_bitis)
  RETURNING id INTO v_id;
  RETURN v_id;
END $$;

CREATE OR REPLACE FUNCTION public.oneri_sil(p_id UUID) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  DELETE FROM public.ogretmen_onerileri WHERE id = p_id AND ogretmen_id = auth.uid();
END $$;

CREATE OR REPLACE FUNCTION public.ogretmen_onerilerim() RETURNS JSONB
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
           'id', o.id, 'sube_id', s.id, 'sube', s.sinif || '-' || s.ad,
           'ders', o.ders, 'konu', o.konu, 'not', o.not_metni, 'sure_dk', o.sure_dk,
           'bitis', o.bitis, 'created_at', o.created_at,
           'ogrenci_sayisi', (SELECT COUNT(*) FROM public.okul_uyeleri u WHERE u.sube_id = s.id AND u.rol = 'ogrenci'),
           'eklendi', (SELECT COUNT(*) FROM public.oneri_durumlari d WHERE d.oneri_id = o.id),
           'tamamlandi', (SELECT COUNT(*) FROM public.oneri_durumlari d WHERE d.oneri_id = o.id AND d.durum = 'tamamlandi')
         ) ORDER BY o.created_at DESC), '[]'::jsonb)
    FROM public.ogretmen_onerileri o
    JOIN public.okul_subeleri s ON s.id = o.sube_id
   WHERE o.ogretmen_id = auth.uid() AND o.created_at > NOW() - INTERVAL '60 days';
$$;

-- Öğrencinin şubesine yapılmış güncel öneriler.
CREATE OR REPLACE FUNCTION public.onerilerim() RETURNS JSONB
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
           'id', o.id, 'ders', o.ders, 'konu', o.konu, 'not', o.not_metni, 'sure_dk', o.sure_dk,
           'bitis', o.bitis, 'created_at', o.created_at, 'durum', d.durum,
           'ogretmen', COALESCE(NULLIF(p.name, ''), 'Öğretmenin')
         ) ORDER BY o.created_at DESC), '[]'::jsonb)
    FROM public.okul_uyeleri u
    JOIN public.ogretmen_onerileri o ON o.sube_id = u.sube_id
    LEFT JOIN public.profiles p ON p.id = o.ogretmen_id
    LEFT JOIN public.oneri_durumlari d ON d.oneri_id = o.id AND d.ogrenci_id = u.user_id
   WHERE u.user_id = auth.uid() AND u.rol = 'ogrenci'
     AND o.created_at > NOW() - INTERVAL '45 days'
     AND (o.bitis IS NULL OR o.bitis >= public._bugun_tr() - 3);
$$;

CREATE OR REPLACE FUNCTION public.oneri_isaretle(p_id UUID, p_durum TEXT) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  IF p_durum NOT IN ('eklendi', 'tamamlandi') THEN RAISE EXCEPTION 'invalid durum'; END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.ogretmen_onerileri o
      JOIN public.okul_uyeleri u ON u.sube_id = o.sube_id AND u.user_id = v_uid AND u.rol = 'ogrenci'
     WHERE o.id = p_id) THEN
    RAISE EXCEPTION 'Öneri bulunamadı';
  END IF;
  INSERT INTO public.oneri_durumlari (oneri_id, ogrenci_id, durum) VALUES (p_id, v_uid, p_durum)
  ON CONFLICT (oneri_id, ogrenci_id) DO UPDATE SET durum = EXCLUDED.durum, guncelleme = NOW();
END $$;

-- ─── Öğrenci: sınıfım ────────────────────────────────────────────────
-- Kişi sıralaması yoktur; yalnızca şubenin toplamı ve öğrencinin kendi süresi.
CREATE OR REPLACE FUNCTION public.sinif_durumum() RETURNS JSONB
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid   UUID := auth.uid();
  v_uye   public.okul_uyeleri%rowtype;
  v_hafta DATE := public._bugun_tr() - (EXTRACT(ISODOW FROM public._bugun_tr())::integer - 1);
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  SELECT * INTO v_uye FROM public.okul_uyeleri WHERE user_id = v_uid AND rol = 'ogrenci';
  IF NOT FOUND THEN RETURN NULL; END IF;

  RETURN (
    WITH uye AS (
      SELECT u.user_id, u.katilma FROM public.okul_uyeleri u WHERE u.sube_id = v_uye.sube_id AND u.rol = 'ogrenci'
    ),
    seans AS (
      SELECT s.user_id, LEAST(COALESCE(s.actual_minutes, 0), 240) AS dk,
             (s.started_at AT TIME ZONE 'Europe/Istanbul')::date AS gun,
             s.started_at >= uye.katilma AS uyelikte
        FROM public.study_sessions s JOIN uye ON uye.user_id = s.user_id
       WHERE s.ended_at IS NOT NULL
    )
    SELECT jsonb_build_object(
      'okul', (SELECT o.ad FROM public.okullar o WHERE o.id = v_uye.okul_id),
      'sube', (SELECT s.sinif || '-' || s.ad FROM public.okul_subeleri s WHERE s.id = v_uye.sube_id),
      'uye', (SELECT COUNT(*) FROM uye),
      'calisan', (SELECT COUNT(*) FROM uye
                   WHERE EXISTS (SELECT 1 FROM public.study_sessions a
                                  WHERE a.user_id = uye.user_id AND a.ended_at IS NULL
                                    AND a.started_at > NOW() - make_interval(mins => a.planned_minutes + 10))),
      'hafta_dk', COALESCE((SELECT SUM(dk) FROM seans WHERE gun >= v_hafta), 0),
      'toplam_dk', COALESCE((SELECT SUM(dk) FROM seans WHERE uyelikte), 0),
      'benim_hafta_dk', COALESCE((SELECT SUM(dk) FROM seans WHERE gun >= v_hafta AND user_id = v_uid), 0),
      'katilan', (SELECT COUNT(DISTINCT user_id) FROM seans WHERE gun >= v_hafta AND dk > 0)
    )
  );
END $$;

-- ─── Müdür: okul özeti (yalnızca toplamlar, öğrenci adı yok) ─────────
CREATE OR REPLACE FUNCTION public.okul_ozeti() RETURNS JSONB
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_okul  UUID := public._mudur_okulu();
  v_bugun DATE := public._bugun_tr();
  v_hafta DATE := public._bugun_tr() - (EXTRACT(ISODOW FROM public._bugun_tr())::integer - 1);
  v_subeler JSONB;
BEGIN
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
           'id', s.id, 'sinif', s.sinif, 'ad', s.ad,
           'ogrenci', x.n, 'aktif_7g', x.aktif, 'ort_dk_7g', x.ort, 'toplam_dk_7g', x.toplam, 'risk', x.risk,
           'plan_blok', x.plan_blok, 'plan_tamam', x.plan_tamam
         ) ORDER BY CASE s.sinif WHEN 'Mezun' THEN 99 ELSE s.sinif::INTEGER END, s.ad), '[]'::jsonb)
    INTO v_subeler
    FROM public.okul_subeleri s
    CROSS JOIN LATERAL (
      SELECT COUNT(*)::integer AS n,
             (COUNT(*) FILTER (WHERE z.dk0 > 0))::integer AS aktif,
             COALESCE(round(AVG(z.dk0)), 0)::integer AS ort,
             COALESCE(SUM(z.dk0), 0)::integer AS toplam,
             (COUNT(*) FILTER (WHERE z.risk IN ('pasif', 'dusus')))::integer AS risk,
             COALESCE(SUM(z.plan_blok), 0)::integer AS plan_blok,
             COALESCE(SUM(z.plan_tamam), 0)::integer AS plan_tamam
        FROM public._sube_ogrenci_ozeti(s.id, NULL) z
    ) x
   WHERE s.okul_id = v_okul;

  RETURN jsonb_build_object(
    'okul', (SELECT o.ad FROM public.okullar o WHERE o.id = v_okul),
    'tarih', to_char(v_bugun, 'YYYY-MM-DD'),
    'ogrenci', (SELECT COUNT(*) FROM public.okul_uyeleri u WHERE u.okul_id = v_okul AND u.rol = 'ogrenci'),
    'ogretmen', (SELECT COUNT(*) FROM public.okul_uyeleri u WHERE u.okul_id = v_okul AND u.rol = 'ogretmen'),
    'veli', (SELECT COUNT(DISTINCT b.veli_id)
               FROM public.veli_baglantilari b
               JOIN public.okul_uyeleri u ON u.user_id = b.ogrenci_id AND u.okul_id = v_okul AND u.rol = 'ogrenci'
              WHERE b.durum = 'aktif'),
    'subeler', v_subeler,
    'haftalar', (
      SELECT jsonb_agg(jsonb_build_object(
               'bas', to_char(h.bas, 'YYYY-MM-DD'),
               'toplam_dk', COALESCE(w.toplam, 0),
               'aktif', COALESCE(w.aktif, 0)
             ) ORDER BY h.bas)
        FROM (SELECT generate_series(v_hafta - 49, v_hafta, INTERVAL '7 days')::date AS bas) h
        LEFT JOIN (
          SELECT (date_trunc('week', (ss.started_at AT TIME ZONE 'Europe/Istanbul')))::date AS bas,
                 SUM(LEAST(COALESCE(ss.actual_minutes, 0), 240))::integer AS toplam,
                 COUNT(DISTINCT ss.user_id)::integer AS aktif
            FROM public.study_sessions ss
            JOIN public.okul_uyeleri u ON u.user_id = ss.user_id AND u.okul_id = v_okul AND u.rol = 'ogrenci'
           WHERE ss.ended_at IS NOT NULL AND ss.started_at > NOW() - INTERVAL '60 days'
             AND COALESCE(ss.actual_minutes, 0) > 0
           GROUP BY 1
        ) w ON w.bas = h.bas)
  );
END $$;

-- Hâlihazırda bir okula ya da veliye bağlı öğrencilerin geçmiş kayıtlarını aktar.
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT user_id FROM public.okul_uyeleri WHERE rol = 'ogrenci'
    UNION
    SELECT ogrenci_id FROM public.veli_baglantilari WHERE durum = 'aktif'
  LOOP
    PERFORM public._okul_katilim_sonrasi(r.user_id);
  END LOOP;
END $$;

-- ─── Çalıştırma yetkileri ────────────────────────────────────────────
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT p.oid::regprocedure AS imza, p.proname
      FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = 'public'
       AND p.proname IN (
         '_bugun_tr', '_guvenli_tarih', '_jsayi', '_brans_eslesir', '_ozet_izlenen_mi', '_ogrenci_ozet_isle',
         '_student_data_ozet_tetik', '_okul_katilim_sonrasi', '_okul_ayrilma_sonrasi', '_ogretmen_sube_erisimi',
         '_ogrenci_erisimi',
         '_sube_ogrenci_ozeti',
         'ogretmen_siniflarim', 'sube_ozeti', 'ogretmen_uyarilari', 'sube_konu_ozeti', 'ogrenci_ozeti',
         'gorusme_ekle', 'gorusme_sil', 'oneri_olustur', 'oneri_sil', 'ogretmen_onerilerim', 'onerilerim',
         'oneri_isaretle', 'sinif_durumum', 'okul_ozeti'
       )
  LOOP
    EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM PUBLIC, anon', r.imza);
    IF left(r.proname, 1) = '_' THEN
      EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM authenticated', r.imza);
    ELSE
      EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated', r.imza);
    END IF;
  END LOOP;
END $$;
