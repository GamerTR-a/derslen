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
