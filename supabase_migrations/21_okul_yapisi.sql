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
