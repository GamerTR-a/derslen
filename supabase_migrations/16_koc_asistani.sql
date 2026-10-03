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
