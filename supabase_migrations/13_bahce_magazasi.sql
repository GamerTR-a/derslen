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
