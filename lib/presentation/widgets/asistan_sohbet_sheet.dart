/// Koç Asistanı sohbet paneli — maskota dokununca açılır.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

import '../../core/algorithms/asistan_motoru.dart';
import '../cizimler/cizim_widgetlari.dart';
import '../providers/asistan_provider.dart';
import '../providers/ortam_provider.dart';

/// Sekme kökleri `go`, alt sayfalar `push` ile açılır.
const _sekmeRotalari = {'/ana', '/calis', '/flashkart', '/bahce', '/topluluk'};

Future<void> asistanSohbetiniAc(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.colors.background,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    builder: (_) => const AsistanSohbetSheet(),
  );
}

class AsistanSohbetSheet extends ConsumerStatefulWidget {
  const AsistanSohbetSheet({super.key});

  @override
  ConsumerState<AsistanSohbetSheet> createState() => _AsistanSohbetSheetState();
}

class _AsistanSohbetSheetState extends ConsumerState<AsistanSohbetSheet> {
  final _metin = TextEditingController();
  final _kaydirma = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(asistanProvider.notifier).bulutDurumunuYenile());
  }

  @override
  void dispose() {
    _metin.dispose();
    _kaydirma.dispose();
    super.dispose();
  }

  void _asagiKaydir() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_kaydirma.hasClients) {
        _kaydirma.animateTo(_kaydirma.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  void _gonder() {
    final m = _metin.text;
    if (m.trim().isEmpty) return;
    _metin.clear();
    HapticFeedback.selectionClick();
    ref.read(asistanProvider.notifier).gonder(m);
  }

  Future<void> _aksiyon(AsistanAksiyon a) async {
    final n = ref.read(asistanProvider.notifier);
    if (a.komut != null) {
      HapticFeedback.selectionClick();
      final router = GoRouter.of(context);
      final navigator = Navigator.of(context);
      final rota = await n.komutCalistir(a.komut!);
      if (rota == null || !mounted) return;
      navigator.pop();
      if (_sekmeRotalari.contains(rota)) {
        router.go(rota);
      } else {
        router.push(rota);
      }
    } else if (a.bulutSorusu != null) {
      n.gonder(a.bulutSorusu!, bulutZorla: true);
    } else if (a.programAyari != null) {
      n.programiUygula(a.programAyari!);
    } else if (a.niyet != null) {
      n.niyetCalistir(a.niyet!);
    } else if (a.rota != null) {
      final router = GoRouter.of(context);
      Navigator.of(context).pop();
      if (_sekmeRotalari.contains(a.rota)) {
        router.go(a.rota!);
      } else {
        router.push(a.rota!);
      }
    }
  }

  Future<void> _bulutDegistir(bool ac) async {
    final n = ref.read(asistanProvider.notifier);
    if (!ac) {
      await n.bulutuKapat();
      return;
    }
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yapay zeka yanıtları'),
        content: const SingleChildScrollView(
          child: Text(
            'Açarsan sorduğun sorular ve çalışma özetin (deneme netlerin, konu durumun, çalışma süren ve ders programın) '
            'yanıt üretmesi için yurt dışındaki yapay zeka sağlayıcısına (Anthropic, Claude) gönderilir. '
            'Adın, e-postan ve okulun gönderilmez; sohbet sunucuda saklanmaz. Günde 20 soru hakkın olur.\n\n'
            'Kapalıyken asistan yalnızca cihazındaki analizlerle çalışır. İstediğin an kapatabilirsin.\n\n'
            '18 yaşından küçüksen bu kararı velinle birlikte ver.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Onaylıyorum')),
        ],
      ),
    );
    if (onay != true || !mounted) return;
    final basarili = await n.bulutuAc();
    if (!mounted) return;
    if (!basarili) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Yapay zeka yanıtları şu an açılamadı. İnternet bağlantını kontrol edip tekrar dene.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(asistanProvider);
    final ortam = ref.watch(ortamProvider);
    final c = context.colors;
    ref.listen(asistanProvider.select((x) => (x.mesajlar.length, x.yaziyor)), (_, _) => _asagiKaydir());

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
              child: Row(
                children: [
                  Maskot(
                    karakter: ortam.asistan.name,
                    ruh: s.yaziyor ? MaskotRuh.dusunceli : MaskotRuh.mutlu,
                    boyut: 56,
                    yuruyor: s.yaziyor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ortam.asistan.ad, style: context.baslik(18)),
                        Text(
                          s.bulutAcik
                              ? 'Koç asistanı · yapay zeka açık${s.kalanHak != null ? ' · bugün ${s.kalanHak} hak' : ''}'
                              : 'Koç asistanı · cihaz içi analiz',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: c.textMuted),
                        ),
                      ],
                    ),
                  ),
                  if (s.bulutOnay != null)
                    Tooltip(
                      message: 'Yapay zeka (bulut) yanıtları',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 18, color: s.bulutAcik ? c.accent : c.textMuted),
                          Switch(value: s.bulutAcik, onChanged: _bulutDegistir),
                        ],
                      ),
                    ),
                  IconButton(
                    tooltip: 'Kapat',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: c.textSecondary),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: c.border),
            Expanded(
              child: ListView.builder(
                controller: _kaydirma,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                itemCount: s.mesajlar.length + (s.yaziyor ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i >= s.mesajlar.length) return _yaziyor(context);
                  return _balon(context, s.mesajlar[i], s.yaziyor);
                },
              ),
            ),
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final n in AsistanNotifier.hizliNiyetler)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(AsistanNotifier.niyetEtiketi(n)),
                        onPressed: s.yaziyor ? null : () => ref.read(asistanProvider.notifier).niyetCalistir(n),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _metin,
                      maxLength: 800,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _gonder(),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: s.bulutAcik ? 'Bir soru sor…' : 'Konu sorusu, deneme, test, odak…',
                        filled: true,
                        fillColor: c.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide(color: c.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide(color: c.border)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton.filled(
                    tooltip: 'Gönder',
                    onPressed: s.yaziyor ? null : _gonder,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _komutIkonu(AsistanAksiyon a) => switch (a.komut?.tur) {
        AsistanKomutTur.testBaslat => Icons.quiz_rounded,
        AsistanKomutTur.desteAc => Icons.style_rounded,
        AsistanKomutTur.odakBaslat => Icons.play_arrow_rounded,
        AsistanKomutTur.sesCal => Icons.graphic_eq_rounded,
        null => a.bulutSorusu != null ? Icons.auto_awesome_rounded : Icons.auto_fix_high_rounded,
      };

  Widget _yaziyor(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.primary)),
            const SizedBox(width: 8),
            Text('Düşünüyorum…', style: TextStyle(color: context.colors.textMuted, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _balon(BuildContext context, AsistanMesaji m, bool mesgul) {
    final c = context.colors;
    if (m.kullanici) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: c.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(6),
            ),
          ),
          child: Text(m.metin, style: TextStyle(color: c.onPrimary, fontSize: 14.5, height: 1.35)),
        ),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, right: 28),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.border),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(m.metin, style: TextStyle(color: c.textPrimary, fontSize: 14.5, height: 1.45)),
            for (final madde in m.maddeler)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 7, right: 8),
                      child: Container(width: 5, height: 5, decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle)),
                    ),
                    Expanded(child: Text(madde, style: TextStyle(color: c.textPrimary, fontSize: 13.5, height: 1.4))),
                  ],
                ),
              ),
            if (m.not != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(m.not!, style: TextStyle(fontSize: 12, color: c.textMuted, fontStyle: FontStyle.italic)),
              ),
            if (m.aksiyonlar.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final a in m.aksiyonlar)
                      a.programAyari != null || a.komut != null
                          ? FilledButton.icon(
                              onPressed: mesgul ? null : () => _aksiyon(a),
                              icon: Icon(_komutIkonu(a), size: 18),
                              label: Text(a.etiket),
                            )
                          : OutlinedButton(onPressed: mesgul ? null : () => _aksiyon(a), child: Text(a.etiket)),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(m.bulut ? Icons.auto_awesome_rounded : Icons.phone_android_rounded, size: 12, color: c.textMuted),
                  const SizedBox(width: 4),
                  Text(m.bulut ? 'Yapay zeka yanıtı · hatalı olabilir' : 'Cihaz içi analiz',
                      style: TextStyle(fontSize: 10.5, color: c.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
