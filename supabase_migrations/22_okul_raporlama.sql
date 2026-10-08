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
