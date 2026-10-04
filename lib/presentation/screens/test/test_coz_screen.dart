import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/test_provider.dart';
import '../../widgets/empty_state_widget.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

class TestCozScreen extends ConsumerStatefulWidget {
  const TestCozScreen({super.key});

  @override
  ConsumerState<TestCozScreen> createState() => _TestCozScreenState();
}

class _TestCozScreenState extends ConsumerState<TestCozScreen> {
  int _currentIndex = 0;
  Timer? _timer;
  bool _bitiyor = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      ref.read(aktifTestProvider.notifier).saniyeArtir();
      // Süreli denemede süre dolunca test kendiliğinden biter.
      if (ref.read(aktifTestProvider).kalanSaniye == 0) _bitir(sureDoldu: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _bitir({bool sureDoldu = false}) async {
    if (_bitiyor) return;
    _bitiyor = true;
    _timer?.cancel();
    HapticFeedback.mediumImpact();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final eklenen = await ref.read(aktifTestProvider.notifier).bitirVeKaydet();
    if (sureDoldu || eklenen > 0) {
      messenger.showSnackBar(SnackBar(
        content: Text([
          if (sureDoldu) 'Süre doldu, deneme tamamlandı.',
          if (eklenen > 0) '$eklenen yanlış soru “Yanlışlarım” kart destene eklendi.',
        ].join(' ')),
        behavior: SnackBarBehavior.floating,
      ));
    }
    router.pushReplacement('/test-sonuc');
  }

  void _testiBitirOnay() {
    HapticFeedback.lightImpact();
    final bos = ref.read(aktifTestProvider).bosSayisi;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Test bitirilsin mi?', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          bos > 0 ? '$bos soruyu boş bıraktın. Testi bitirip sonuçlarını görmek istiyor musun?' : 'Testi bitirip sonuçlarını görmek istiyor musun?',
          style: TextStyle(color: context.colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Çözmeye devam et', style: TextStyle(color: context.colors.textMuted)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _bitir();
            },
            child: const Text('Testi bitir'),
          ),
        ],
      ),
    );
  }

  String _sure(int saniye) => '${(saniye ~/ 60).toString().padLeft(2, '0')}:${(saniye % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final testState = ref.watch(aktifTestProvider);
    final sorular = testState.sorular;

    if (sorular.isEmpty) {
      return Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          backgroundColor: c.background,
          title: Text('Test', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold)),
        ),
        body: EmptyStateWidget(
          icon: '🧪',
          baslik: 'Soru bulunamadı',
          aciklama: 'Seçilen ders, konu ve zorluğa uygun soru bulunamadı.',
          butonMetni: 'Seçime dön',
          onButonPressed: () => context.pop(),
        ),
      );
    }

    if (_currentIndex >= sorular.length) _currentIndex = sorular.length - 1;
    final soru = sorular[_currentIndex];
    final isaretlenen = testState.cevaplar[_currentIndex];
    final kalan = testState.kalanSaniye;
    final azKaldi = kalan != null && kalan <= 60;
    final seciliZemin = c.primary.withValues(alpha: c.gece ? 0.28 : 0.10);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _testiBitirOnay();
      },
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          backgroundColor: c.background,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          elevation: 0,
          title: Row(
            children: [
              Expanded(
                child: Text(
                  testState.baslik,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                label: kalan != null ? 'Kalan süre ${_sure(kalan)}' : 'Geçen süre ${_sure(testState.gecenSaniye)}',
                excludeSemantics: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (azKaldi ? c.danger : c.primary).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(kalan != null ? Icons.hourglass_bottom_rounded : Icons.timer_outlined, color: azKaldi ? c.danger : c.primary, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _sure(kalan ?? testState.gecenSaniye),
                        style: TextStyle(color: azKaldi ? c.danger : c.primary, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _testiBitirOnay,
                style: FilledButton.styleFrom(
                  backgroundColor: c.danger,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  minimumSize: const Size(0, 40),
                ),
                child: const Text('Bitir', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              LinearProgressIndicator(
                value: testState.cevaplar.length / sorular.length,
                minHeight: 4,
                backgroundColor: c.border,
                color: c.success,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: c.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                '${soru.ders} • ${soru.konu}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: c.gece ? c.accent : c.primary, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: soru.zorluk.renk.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: soru.zorluk.renk.withValues(alpha: 0.3)),
                            ),
                            child: Text(soru.zorluk.etiket, style: TextStyle(color: soru.zorluk.renk, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: c.border),
                        ),
                        child: Text(
                          soru.soruMetni,
                          style: TextStyle(color: c.textPrimary, fontSize: 16, height: 1.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 20),
                      for (final entry in soru.secenekler.entries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Semantics(
                            button: true,
                            selected: isaretlenen == entry.key,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                ref.read(aktifTestProvider.notifier).secenekIsaretle(_currentIndex, entry.key);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: isaretlenen == entry.key ? seciliZemin : c.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isaretlenen == entry.key ? c.primary : c.border,
                                    width: isaretlenen == entry.key ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: isaretlenen == entry.key ? c.primary : c.background,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          entry.key,
                                          style: TextStyle(
                                            color: isaretlenen == entry.key ? c.onPrimary : c.textSecondary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        entry.value,
                                        style: TextStyle(
                                          color: c.textPrimary,
                                          fontSize: 14,
                                          fontWeight: isaretlenen == entry.key ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.border))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _currentIndex > 0 ? () => setState(() => _currentIndex--) : null,
                      tooltip: 'Önceki soru',
                      icon: Icon(Icons.arrow_back_ios_new_rounded, color: _currentIndex > 0 ? c.textPrimary : c.border),
                    ),
                    TextButton.icon(
                      onPressed: () => _showQuestionGridModal(context, sorular.length),
                      icon: Icon(Icons.grid_view_rounded, color: c.primary),
                      label: Text(
                        'Soru ${_currentIndex + 1} / ${sorular.length}',
                        style: TextStyle(color: c.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: _currentIndex < sorular.length - 1 ? () => setState(() => _currentIndex++) : null,
                      tooltip: 'Sonraki soru',
                      icon: Icon(Icons.arrow_forward_ios_rounded, color: _currentIndex < sorular.length - 1 ? c.textPrimary : c.border),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuestionGridModal(BuildContext context, int soruSayisi) {
    final testState = ref.read(aktifTestProvider);
    final c = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Soru paleti', style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Yeşil: cevaplanan · Gri: boş', style: TextStyle(color: c.textMuted, fontSize: 12.5)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(soruSayisi, (idx) {
                    final isAnswered = testState.cevaplar.containsKey(idx);
                    final isCurrent = _currentIndex == idx;
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() => _currentIndex = idx);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? c.primary
                              : isAnswered
                                  ? c.success
                                  : c.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: c.border),
                        ),
                        child: Center(
                          child: Text(
                            '${idx + 1}',
                            style: TextStyle(color: (isCurrent || isAnswered) ? Colors.white : c.textSecondary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
