import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

import '../../../core/services/etut_odasi_service.dart';
import '../../../core/utils/tarih.dart';
import '../../widgets/ui_kit.dart';

/// Bir etüt odasının içi: şu an çalışanlar, çevrimiçi olanlar ve odaya
/// katılındıktan sonraki çalışma süresine göre sıralama. Ekran açıkken
/// 30 saniyede bir yenilenir (bu aynı zamanda "odadayım" nabzıdır).
class EtutOdasiScreen extends StatefulWidget {
  final int odaId;
  final String odaAdi;

  const EtutOdasiScreen({super.key, required this.odaId, required this.odaAdi});

  @override
  State<EtutOdasiScreen> createState() => _EtutOdasiScreenState();
}

class _EtutOdasiScreenState extends State<EtutOdasiScreen> with WidgetsBindingObserver {
  List<EtutUyesi>? _uyeler;
  String? _hata;
  Timer? _nabiz;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _yukle();
    _nabziBaslat();
  }

  void _nabziBaslat() {
    _nabiz?.cancel();
    _nabiz = Timer.periodic(const Duration(seconds: 30), (_) => _yukle());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nabiz?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _yukle();
      _nabziBaslat();
    } else if (state == AppLifecycleState.paused) {
      _nabiz?.cancel();
    }
  }

  Future<void> _yukle() async {
    try {
      final uyeler = await EtutOdasiService.durum(widget.odaId);
      if (!mounted) return;
      setState(() {
        _uyeler = uyeler;
        _hata = null;
      });
    } on EtutHatasi catch (e) {
      if (!mounted) return;
      setState(() => _hata = e.mesaj);
    }
  }

  Future<void> _ayril() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Odadan ayrıl'),
        content: const Text('Odadan ayrılırsan bu odadaki sıralaman silinir. Tekrar katıldığında sayım yeniden başlar.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ayrıl')),
        ],
      ),
    );
    if (onay != true) return;
    try {
      await EtutOdasiService.ayril();
      if (mounted) context.pop();
    } on EtutHatasi catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mesaj)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final uyeler = _uyeler;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        title: Text(widget.odaAdi, style: context.baslik(19)),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Oda seçenekleri',
            onSelected: (_) => _ayril(),
            itemBuilder: (_) => const [PopupMenuItem(value: 'ayril', child: Text('Odadan ayrıl'))],
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _yukle,
          child: uyeler == null
              ? ListView(
                  children: [
                    const SizedBox(height: 120),
                    if (_hata == null)
                      const Center(child: CircularProgressIndicator())
                    else
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(_hata!, textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary)),
                      ),
                  ],
                )
              : _icerik(context, uyeler),
        ),
      ),
    );
  }

  Widget _icerik(BuildContext context, List<EtutUyesi> uyeler) {
    final c = context.colors;
    final ben = uyeler.where((u) => u.ben).firstOrNull;
    final sira = ben == null ? null : uyeler.indexOf(ben) + 1;
    final calisanlar = uyeler.where((u) => u.calisiyor).toList();
    final cevrimici = uyeler.where((u) => u.cevrimici && !u.calisiyor).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: c.feature, borderRadius: BorderRadius.circular(22)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${uyeler.length}/30 üye · ${calisanlar.length} çalışıyor · $cevrimici çevrimiçi',
                  style: TextStyle(color: c.onFeature.withValues(alpha: 0.85), fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                ben == null ? 'Odadasın' : 'Katıldığından beri ${sureMetni(ben.toplamDk)} · $sira. sıradasın',
                style: context.baslik(20, color: c.onFeature),
              ),
              const SizedBox(height: 12),
              if (ben != null && !ben.calisiyor)
                FilledButton.icon(
                  onPressed: () => context.go('/calis'),
                  style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: c.gece ? const Color(0xFF111629) : c.onPrimary),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Odak seansı başlat'),
                )
              else if (ben != null)
                Text('Şu an ${ben.aktifDers ?? 'çalışıyorsun'} · ${ben.aktifDk} dk. Seansı bitirince süren sıralamaya eklenir.',
                    style: TextStyle(color: c.onFeature.withValues(alpha: 0.9), fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        BolumBasligi('Şu an çalışanlar (${calisanlar.length})'),
        if (calisanlar.isEmpty)
          YumusakKart(
            child: Text('Şu an odak seansında kimse yok. İlk başlatan sen ol!', style: TextStyle(color: c.textMuted)),
          )
        else
          YumusakKart(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(
              children: [
                for (final u in calisanlar)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: _avatar(context, u),
                    title: Text(u.ben ? '${u.ad} (sen)' : u.ad, style: TextStyle(fontWeight: FontWeight.w700, color: c.textPrimary)),
                    subtitle: Text('${u.aktifDers ?? 'Odak'} · ${u.aktifDk} dk', maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 18),
        const BolumBasligi('Sıralama (katıldığından beri)'),
        YumusakKart(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            children: [
              for (var i = 0; i < uyeler.length; i++) _siraSatiri(context, i + 1, uyeler[i]),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Sıralama, odaya katıldığın andan sonra Çalış sekmesindeki odak zamanlayıcısı ya da ders programı blokları ile yaptığın çalışmaların süresine göre hesaplanır. Yeşil nokta: çalışıyor, mavi nokta: odada çevrimiçi.',
          style: TextStyle(fontSize: 12, color: c.textMuted, height: 1.4),
        ),
      ],
    );
  }

  Widget _avatar(BuildContext context, EtutUyesi u) {
    final c = context.colors;
    final durum = u.calisiyor ? c.success : (u.cevrimici ? c.info : c.border);
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: c.primary.withValues(alpha: 0.14),
            child: Text(u.ad.isEmpty ? '?' : u.ad.characters.first.toUpperCase(),
                style: TextStyle(color: c.gece ? c.accent : c.primary, fontWeight: FontWeight.w800)),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: durum, shape: BoxShape.circle, border: Border.all(color: c.surface, width: 2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _siraSatiri(BuildContext context, int sira, EtutUyesi u) {
    final c = context.colors;
    final madalya = sira == 1
        ? const Color(0xFFE9A23B)
        : sira == 2
            ? const Color(0xFF9AA3B5)
            : sira == 3
                ? const Color(0xFFB87333)
                : null;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: u.ben ? c.primary.withValues(alpha: 0.08) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: madalya != null && u.toplamDk > 0
                ? Icon(Icons.emoji_events_rounded, size: 22, color: madalya)
                : Text('$sira', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, color: c.textMuted)),
          ),
          const SizedBox(width: 6),
          _avatar(context, u),
          const SizedBox(width: 10),
          Expanded(
            child: Text(u.ben ? '${u.ad} (sen)' : u.ad,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, color: c.textPrimary)),
          ),
          Text(sureMetni(u.toplamDk), style: TextStyle(fontWeight: FontWeight.w900, color: c.gece ? c.accent : c.primary)),
        ],
      ),
    );
  }
}
