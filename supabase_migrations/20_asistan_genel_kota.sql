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
