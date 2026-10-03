import 'package:flutter/material.dart';
import '../../core/services/supabase_data_service.dart';
import '../../data/models/net_kaydi.dart';
import '../cizimler/cizim_widgetlari.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

/// Bir deneme sonucunu, aynı denemeyi giren diğer kullanıcılarla anonim
/// olarak karşılaştıran alt sayfa (bottom sheet). Hiçbir kullanıcı
/// kimliği gösterilmez — sadece toplu ortalama/katılımcı sayısı.
Future<void> denemeKarsilastirSheetGoster(BuildContext context, NetKaydi kayit) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _DenemeKarsilastirSheet(kayit: kayit),
  );
}

class _DenemeKarsilastirSheet extends StatefulWidget {
  final NetKaydi kayit;
  const _DenemeKarsilastirSheet({required this.kayit});

  @override
  State<_DenemeKarsilastirSheet> createState() => _DenemeKarsilastirSheetState();
}

class _DenemeKarsilastirSheetState extends State<_DenemeKarsilastirSheet> {
  ExamBenchmark? _sonuc;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final sonuc = await SupabaseDataService.getExamBenchmark(
      denemeAdi: widget.kayit.denemeAdi ?? '',
      alan: widget.kayit.alan.name,
      ders: widget.kayit.ders,
    );
    if (mounted) setState(() => _sonuc = sonuc);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Topluluk Karşılaştırması',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.colors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.kayit.denemeAdi} • ${widget.kayit.ders}',
              style: TextStyle(fontSize: 13, color: context.colors.textSecondary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            _sonuc == null ? _yukleniyorAlani(context) : _sonucAlani(context, _sonuc!),
          ],
        ),
      ),
    );
  }

  Widget _yukleniyorAlani(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: CircularProgressIndicator(color: context.colors.primary, strokeWidth: 2.5),
      ),
    );
  }

  Widget _sonucAlani(BuildContext context, ExamBenchmark sonuc) {
    if (!sonuc.yeterliVeri) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.colors.primaryLight.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const SaksiliBitki(bitkiId: 'seed_papatya', asama: 1, genislik: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Bu denemeyi ilk giren kişilerdensin. Daha çok kişi eklediğinde topluluk karşılaştırması burada görünecek.',
                style: TextStyle(fontSize: 13.5, color: context.colors.textSecondary, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

    final kullaniciNeti = widget.kayit.net;
    final z = sonuc.zSkoru(kullaniciNeti);
    final ustunde = kullaniciNeti >= sonuc.ortalamaNet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _istatistikKutusu(context, 'Senin Netin', kullaniciNeti.toStringAsFixed(2), context.colors.primary)),
            const SizedBox(width: 10),
            Expanded(child: _istatistikKutusu(context, 'Topluluk Ort.', sonuc.ortalamaNet.toStringAsFixed(2), context.colors.textPrimary)),
            const SizedBox(width: 10),
            Expanded(child: _istatistikKutusu(context, 'Katılımcı', '${sonuc.katilimciSayisi}', context.colors.textSecondary)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (ustunde ? context.colors.success : context.colors.warning).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(ustunde ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 24, color: ustunde ? context.colors.success : context.colors.warning),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _yorumMetni(z, ustunde),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _yorumMetni(double z, bool ustunde) {
    final zMutlak = z.abs();
    if (zMutlak < 0.2) {
      return 'Topluluk ortalamasına çok yakınsın — dengeli gidiyorsun.';
    }
    final seviye = zMutlak >= 1.0 ? 'oldukça' : 'biraz';
    return ustunde
        ? 'Topluluk ortalamasının $seviye üstündesin — harika gidiyorsun!'
        : 'Topluluk ortalamasının $seviye altındasın — bu dersi biraz daha çalışmak fark yaratabilir.';
  }

  Widget _istatistikKutusu(BuildContext context, String etiket, String deger, Color renk) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          Text(
            deger,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: renk),
          ),
          const SizedBox(height: 4),
          Text(
            etiket,
            style: TextStyle(fontSize: 10.5, color: context.colors.textMuted, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
