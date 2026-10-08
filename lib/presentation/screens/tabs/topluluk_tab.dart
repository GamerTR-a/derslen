import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/supabase_data_service.dart';
import '../../../data/models/post.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/ui_kit.dart';
import '../../cizimler/sahne_boyaci.dart';
import '../etut/etut_odalari_screen.dart';
import '../okul/okulum_screen.dart';
import '../../providers/okul_provider.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

class ToplulukTab extends ConsumerWidget {
  const ToplulukTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Okul hesabında açık topluluk kapalıdır; yerine sınıf bölümü gelir.
    if (ref.watch(okulModuProvider)) return const OkulumScreen(gomulu: true);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.colors.background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Topluluk', style: context.baslik(28)),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: EdgeInsets.all(context.colors.gece ? 0 : 4),
                decoration: BoxDecoration(
                  color: context.colors.gece ? Colors.transparent : context.colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: context.colors.gece ? Border(bottom: BorderSide(color: context.colors.border)) : null,
                ),
                child: TabBar(
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: context.colors.gece
                      ? UnderlineTabIndicator(borderSide: BorderSide(color: context.colors.accent, width: 3))
                      : BoxDecoration(color: context.colors.primary, borderRadius: BorderRadius.circular(12)),
                  labelColor: context.colors.gece ? context.colors.textPrimary : context.colors.onPrimary,
                  unselectedLabelColor: context.colors.textSecondary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  tabs: const [
                    Tab(text: 'Etüt Odaları'),
                    Tab(text: 'Akış'),
                  ],
                ),
              ),
              const Expanded(
                child: TabBarView(
                  children: [
                    _EtutOdalari(),
                    _Akis(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sosyal Akış ─────────────────────────────────────────────

const List<(String, String)> _akisFiltreleri = [
  ('', 'Tümü'),
  ('#soru', 'Sorular'),
  ('#rutin', 'Rutinler'),
  ('#koçarıyorum', 'Koç arayanlar'),
];

class _Akis extends StatefulWidget {
  const _Akis();

  @override
  State<_Akis> createState() => _AkisState();
}

class _AkisState extends State<_Akis> with AutomaticKeepAliveClientMixin {
  List<Post> _postlar = [];
  bool _yukleniyor = true;
  bool _hata = false;
  String _filtre = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = false;
    });
    try {
      final p = await SupabaseDataService.getPosts(limit: 50);
      if (!mounted) return;
      setState(() {
        _postlar = p;
        _yukleniyor = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _yukleniyor = false;
        _hata = true;
      });
    }
  }

  Widget _gonderiMenusu(BuildContext context, Post p) {
    final benim = p.userId != null && p.userId == SupabaseDataService.currentUserId;
    return PopupMenuButton<String>(
      tooltip: 'Gönderi seçenekleri',
      icon: Icon(Icons.more_vert_rounded, color: context.colors.textMuted),
      onSelected: (secim) {
        switch (secim) {
          case 'sil':
            _sil(p);
          case 'sikayet':
            _sikayetEt(p);
          case 'engelle':
            _engelle(p);
        }
      },
      itemBuilder: (_) => [
        if (benim)
          const PopupMenuItem(value: 'sil', child: Text('Gönderimi sil'))
        else ...[
          const PopupMenuItem(value: 'sikayet', child: Text('Şikâyet et')),
          if (p.userId != null) const PopupMenuItem(value: 'engelle', child: Text('Bu kullanıcıyı engelle')),
        ],
      ],
    );
  }

  void _bildir(String mesaj, {bool hata = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mesaj),
      backgroundColor: hata ? context.colors.danger : null,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _sikayetEt(Post p) async {
    final sebep = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Text('Bu gönderide sorun ne?', style: ctx.baslik(18)),
            ),
            for (final e in SupabaseDataService.sikayetSebepleri.entries)
              ListTile(
                title: Text(e.value, style: TextStyle(color: ctx.colors.textPrimary)),
                onTap: () => Navigator.pop(ctx, e.key),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (sebep == null) return;
    try {
      await SupabaseDataService.reportPost(postId: p.id, reason: sebep);
      setState(() => _postlar = _postlar.where((x) => x.id != p.id).toList());
      _bildir('Teşekkürler, şikâyetin incelemeye alındı. Bu gönderiyi artık görmeyeceksin.');
    } catch (e) {
      _bildir(e.toString().replaceAll('Exception: ', ''), hata: true);
    }
  }

  Future<void> _engelle(Post p) async {
    final uid = p.userId;
    if (uid == null) return;
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kullanıcıyı engelle'),
        content: const Text('Bu kişinin gönderilerini artık görmeyeceksin ve seni dürtemeyecek.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Engelle')),
        ],
      ),
    );
    if (onay != true) return;
    try {
      await SupabaseDataService.blockUser(uid);
      setState(() => _postlar = _postlar.where((x) => x.userId != uid).toList());
      _bildir('Kullanıcı engellendi.');
    } catch (e) {
      _bildir(e.toString().replaceAll('Exception: ', ''), hata: true);
    }
  }

  Future<void> _sil(Post p) async {
    try {
      await SupabaseDataService.deleteOwnPost(p.id);
      setState(() => _postlar = _postlar.where((x) => x.id != p.id).toList());
      _bildir('Gönderin silindi.');
    } catch (_) {
      _bildir('Gönderi silinemedi.', hata: true);
    }
  }

  String _zaman(DateTime t) {
    final f = DateTime.now().difference(t);
    if (f.inMinutes < 1) return 'şimdi';
    if (f.inHours < 1) return '${f.inMinutes} dk önce';
    if (f.inDays < 1) return '${f.inHours} sa önce';
    if (f.inDays < 7) return '${f.inDays} gün önce';
    return '${t.day}.${t.month}.${t.year}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final gorunen = _filtre.isEmpty ? _postlar : _postlar.where((p) => p.content.contains(_filtre)).toList();

    return Scaffold(
      backgroundColor: context.colors.background,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'paylas',
        onPressed: () async {
          await context.push('/create-post');
          _yukle();
        },
        icon: const Icon(Icons.edit_rounded),
        label: const Text('Paylaş', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: RefreshIndicator(
        onRefresh: _yukle,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
          children: [
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _akisFiltreleri.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final (id, ad) = _akisFiltreleri[i];
                  return HapSecim(etiket: ad, secili: _filtre == id, onTap: () => setState(() => _filtre = id));
                },
              ),
            ),
            const SizedBox(height: 14),
            if (_yukleniyor)
              const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
            else if (_hata)
              EmptyStateWidget(
                icon: '📡',
                baslik: 'Akış yüklenemedi',
                aciklama: 'İnternet bağlantını kontrol edip tekrar dene.',
                butonMetni: 'Tekrar dene',
                onButonPressed: _yukle,
              )
            else if (gorunen.isEmpty)
              const EmptyStateWidget(
                icon: '💬',
                baslik: 'Burada henüz gönderi yok',
                aciklama: 'İlk soruyu ya da çalışma rutinini sen paylaş!',
              )
            else
              for (final p in gorunen) _postKarti(context, p),
          ],
        ),
      ),
    );
  }

  Widget _postKarti(BuildContext context, Post p) {
    final koc = p.content.contains('#koçarıyorum');
    final soru = p.content.contains('#soru');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: YumusakKart(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: context.colors.primary.withValues(alpha: 0.12),
                  child: Icon(Icons.groups_rounded, size: 18, color: context.colors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.communityName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w800, color: context.colors.textPrimary)),
                      Text(_zaman(p.createdAt), style: TextStyle(fontSize: 12, color: context.colors.textMuted)),
                    ],
                  ),
                ),
                if (koc || soru)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (koc ? context.colors.success : context.colors.primary).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(koc ? 'Koç arıyor' : 'Soru',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: koc ? (context.colors.gece ? context.colors.success : const Color(0xFF1F5A3E)) : (context.colors.gece ? context.colors.primaryLight : const Color(0xFF3A2F7A)))),
                  ),
                _gonderiMenusu(context, p),
              ],
            ),
            const SizedBox(height: 12),
            Text(p.content, style: TextStyle(fontSize: 15, color: context.colors.textPrimary, height: 1.45)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.favorite_border_rounded, size: 18, color: context.colors.textMuted),
                const SizedBox(width: 4),
                Text('${p.supportCount} destek', style: TextStyle(fontSize: 12.5, color: context.colors.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EtutOdalari extends StatelessWidget {
  const _EtutOdalari();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Semantics(
            label: c.gece ? 'Lambaların altında çalışan öğrenciler' : 'Masalarında çalışan öğrenciler',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 130,
                width: double.infinity,
                child: HareketliSahne(dongu: const Duration(seconds: 10), boyaci: (t) => EtutSalonuBoyaci(c.gece, t)),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Text(
            c.gece ? 'Bir salona katıl, lambanı yak; kimin çalıştığını canlı gör.' : 'Bir odaya katıl; kim şu an çalışıyor, kim ne kadar odaklandı gör.',
            style: TextStyle(fontSize: 13, color: c.textMuted),
          ),
        ),
        const Expanded(child: EtutOdalariScreen(gomulu: true)),
      ],
    );
  }
}
