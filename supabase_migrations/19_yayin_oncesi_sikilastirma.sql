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
