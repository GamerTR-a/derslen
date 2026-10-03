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
