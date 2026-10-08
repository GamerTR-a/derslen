import 'package:flutter/material.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

import '../../../core/services/okul_service.dart';
import '../../../core/utils/tarih.dart';
import '../../../data/models/okul_modelleri.dart';
import '../../widgets/grafikler.dart';
import '../../widgets/ui_kit.dart';
import 'ogrenci_ozet_gorunumu.dart';
import 'okul_ortak.dart';

/// Öğretmenin bir öğrenciye bakışı: haftalık göstergeler, dört haftalık
/// geçmiş ve (rehber öğretmense) görüşme notları. Branş öğretmeni yalnızca
/// kendi dersinin verisini görür; süzme sunucuda yapılır.
class OgrenciDetayScreen extends StatefulWidget {
  final String ogrenciId;
  final String? ad;

  const OgrenciDetayScreen({super.key, required this.ogrenciId, this.ad});

  @override
  State<OgrenciDetayScreen> createState() => _OgrenciDetayScreenState();
}

class _OgrenciDetayScreenState extends State<OgrenciDetayScreen> {
  final _govde = GlobalKey<VeriGovdesiState<OgrenciOzeti>>();

  Future<void> _notEkle() async {
    final not = TextEditingController();
    final hedef = TextEditingController();
    var islemde = false;
    final kaydedildi = await okulSayfasiGoster<bool>(
      context,
      baslik: 'Görüşme notu',
      insa: (ctx) {
        return StatefulBuilder(
          builder: (ctx, guncelle) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: not,
                maxLines: 4,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(color: ctx.colors.textPrimary),
                decoration: okulGirdisi(ctx, ipucu: 'Görüşmede ne konuşuldu?'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: hedef,
                maxLength: 300,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(color: ctx.colors.textPrimary),
                decoration: okulGirdisi(ctx, ipucu: 'Verilen hedef (isteğe bağlı)'),
              ),
              const SizedBox(height: 6),
              Text('Bu notu yalnızca şubenin rehber öğretmenleri görür; öğrenci ve veli göremez.',
                  style: TextStyle(fontSize: 12, color: ctx.colors.textMuted)),
              const SizedBox(height: 14),
              AnaDugme(
                etiket: 'Kaydet',
                yukleniyor: islemde,
                onPressed: () async {
                  if (not.text.trim().isEmpty) return;
                  guncelle(() => islemde = true);
                  try {
                    await OkulService.gorusmeEkle(widget.ogrenciId, not.text, hedef.text);
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  } on OkulHatasi catch (e) {
                    guncelle(() => islemde = false);
                    if (ctx.mounted) okulBildir(ctx, e.mesaj, hata: true);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
    if (kaydedildi == true && mounted) {
      okulBildir(context, 'Görüşme notu kaydedildi.');
      await _govde.currentState?.yenile();
    }
  }

  Future<void> _notSil(Gorusme g) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notu sil'),
        content: const Text('Bu görüşme notu kalıcı olarak silinecek.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
        ],
      ),
    );
    if (onay != true) return;
    try {
      await OkulService.gorusmeSil(g.id);
      await _govde.currentState?.yenile();
    } on OkulHatasi catch (e) {
      if (mounted) okulBildir(context, e.mesaj, hata: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: c.textPrimary),
        title: Text(widget.ad ?? 'Öğrenci', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        top: false,
        child: VeriGovdesi<OgrenciOzeti>(
          key: _govde,
          yukle: () => OkulService.ogrenciOzeti(widget.ogrenciId),
          insa: (context, o, yenile) => [
            Text(
              [if (o.sube != null) o.sube!, if (o.brans != null) 'Yalnızca ${o.brans} verisi'].join('  ·  '),
              style: TextStyle(fontSize: 13.5, color: c.textSecondary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...haftaBolumu(context, o),
            const SizedBox(height: 14),
            ...gecmisBolumu(context, o),
            if (o.gorusmeler != null) ...[
              const SizedBox(height: 18),
              BolumBasligi('Görüşme notları', aksiyon: 'Not ekle', onAksiyon: _notEkle),
              if (o.gorusmeler!.isEmpty)
                const BosGrafikMesaji(metin: 'Henüz görüşme notu yok.')
              else
                for (final g in o.gorusmeler!)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: YumusakKart(
                      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${g.tarih == null ? '' : '${kisaTarih(g.tarih!)} · '}${g.ogretmen}',
                                  style: TextStyle(fontSize: 12, color: c.textMuted, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(g.not, style: TextStyle(color: c.textPrimary, height: 1.4)),
                                if (g.hedef != null && g.hedef!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.flag_outlined, size: 16, color: c.success),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(g.hedef!,
                                            style: TextStyle(fontSize: 13, color: c.textSecondary, height: 1.35)),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (g.benim)
                            IconButton(
                              tooltip: 'Notu sil',
                              onPressed: () => _notSil(g),
                              icon: Icon(Icons.delete_outline_rounded, size: 20, color: c.textMuted),
                            ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
