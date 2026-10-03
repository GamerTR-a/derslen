import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

import '../../../core/services/etut_odasi_service.dart';
import '../../widgets/ui_kit.dart';

/// 10 hazır etüt odası: doluluk (en fazla 30 kişi), şu an çalışan sayısı ve
/// katıl / gir düğmesi. Bir öğrenci aynı anda tek odada bulunur.
class EtutOdalariScreen extends StatefulWidget {
  /// true ise AppBar'sız, başka bir sekmenin içine gömülü çizilir.
  final bool gomulu;

  const EtutOdalariScreen({super.key, this.gomulu = false});

  @override
  State<EtutOdalariScreen> createState() => _EtutOdalariScreenState();
}

class _EtutOdalariScreenState extends State<EtutOdalariScreen> {
  List<EtutOdasi>? _odalar;
  String? _hata;
  int? _islemde;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    try {
      final odalar = await EtutOdasiService.odalar();
      if (!mounted) return;
      setState(() {
        _odalar = odalar;
        _hata = null;
      });
    } on EtutHatasi catch (e) {
      if (!mounted) return;
      setState(() => _hata = e.mesaj);
    }
  }

  void _bildir(String m, {bool hata = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m),
      backgroundColor: hata ? context.colors.danger : null,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _gir(EtutOdasi oda) async {
    await context.push('/etut-odasi/${oda.id}', extra: oda.ad);
    if (mounted) await _yukle();
  }

  Future<void> _katil(EtutOdasi oda) async {
    HapticFeedback.lightImpact();
    if (oda.benim) {
      await _gir(oda);
      return;
    }
    final mevcut = _odalar?.where((o) => o.benim).firstOrNull;
    if (mevcut != null) {
      final onay = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Odayı değiştir'),
          content: Text('“${mevcut.ad}” odasından ayrılıp “${oda.ad}” odasına geçeceksin. Aynı anda tek odada bulunabilirsin; yeni odadaki sıralaman katıldığın andan başlar.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Geç')),
          ],
        ),
      );
      if (onay != true) return;
    }
    setState(() => _islemde = oda.id);
    try {
      final sonuc = await EtutOdasiService.katil(oda.id);
      if (!mounted) return;
      switch (sonuc) {
        case 'ok':
          await _gir(oda);
        case 'dolu':
          _bildir('Bu oda dolu (${oda.kapasite} kişi). Başka bir oda seçebilirsin.', hata: true);
          await _yukle();
        default:
          _bildir('Oda bulunamadı.', hata: true);
      }
    } on EtutHatasi catch (e) {
      _bildir(e.mesaj, hata: true);
    } finally {
      if (mounted) setState(() => _islemde = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final Widget govde;
    if (_odalar == null && _hata == null) {
      govde = const Center(child: CircularProgressIndicator());
    } else if (_odalar == null) {
      govde = ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 40),
          Icon(Icons.cloud_off_rounded, size: 48, color: c.textMuted),
          const SizedBox(height: 12),
          Text(_hata!, textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary, fontSize: 15)),
          const SizedBox(height: 12),
          Center(child: FilledButton.tonal(onPressed: _yukle, child: const Text('Tekrar dene'))),
        ],
      );
    } else {
      final odalar = _odalar!;
      govde = ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
        children: [
          Text(
            '${odalar.length} etüt odası · her odada en fazla ${odalar.isEmpty ? 30 : odalar.first.kapasite} kişi. Odaya katıldığın andan itibaren odak sürene göre sıralanırsın.',
            style: TextStyle(fontSize: 13, color: c.textMuted),
          ),
          const SizedBox(height: 12),
          for (final o in odalar) _odaKarti(context, o),
        ],
      );
    }

    return Scaffold(
      backgroundColor: c.background,
      appBar: widget.gomulu
          ? null
          : AppBar(
              backgroundColor: c.background,
              title: Text('Etüt Odaları', style: context.baslik(20)),
            ),
      body: RefreshIndicator(onRefresh: _yukle, child: govde),
    );
  }

  Widget _odaKarti(BuildContext context, EtutOdasi o) {
    final c = context.colors;
    final oran = o.kapasite == 0 ? 0.0 : o.uyeSayisi / o.kapasite;
    final islemde = _islemde == o.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: YumusakKart(
        onTap: islemde ? null : () => _katil(o),
        renk: o.benim ? c.primarySoft : null,
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: c.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
              child: Text('${o.id}', style: context.baslik(20, color: c.gece ? c.accent : c.primary)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(o.ad, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: c.textPrimary)),
                      ),
                      if (o.benim) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.check_circle_rounded, size: 16, color: c.success),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(o.aciklama, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: c.textMuted)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: oran.clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: c.border,
                            color: o.dolu ? c.danger : (oran > 0.8 ? c.warning : c.success),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${o.uyeSayisi}/${o.kapasite}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: o.calisanSayisi > 0 ? c.success : c.border, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(
                        o.calisanSayisi > 0 ? '${o.calisanSayisi} kişi şu an çalışıyor' : 'Şu an çalışan yok',
                        style: TextStyle(fontSize: 12, color: o.calisanSayisi > 0 ? c.success : c.textMuted, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            islemde
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : FilledButton(
                    onPressed: (o.dolu && !o.benim) ? null : () => _katil(o),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      minimumSize: const Size(64, 40),
                      backgroundColor: o.benim ? c.success : null,
                    ),
                    child: Text(o.benim ? 'Gir' : (o.dolu ? 'Dolu' : 'Katıl'), style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
          ],
        ),
      ),
    );
  }
}
