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
