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
