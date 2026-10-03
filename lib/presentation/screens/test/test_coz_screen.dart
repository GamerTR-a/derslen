import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/storage_provider.dart';
import '../../providers/flashkart_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      ref.read(aktifTestProvider.notifier).saniyeArtir();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _testiBitirOnay() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Testi Bitir?', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          'Testi sonlandırıp sonuçlarınızı ve netlerinizi görmek istiyor musunuz?',
          style: TextStyle(color: context.colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Çözmeye Devam Et',
                style: TextStyle(color: context.colors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();
              ref.read(aktifTestProvider.notifier).testiBitir();
              final test = ref.read(aktifTestProvider);
              unawaited(testGecmisineEkle(ref.read(storageServiceProvider), test));
              final yanlislar = [
                for (var i = 0; i < test.sorular.length; i++)
                  if (test.cevaplar.containsKey(i) && test.cevaplar[i] != test.sorular[i].dogruSecenek) test.sorular[i],
              ];
              final messenger = ScaffoldMessenger.of(context);
              ref.read(flashkartProvider.notifier).yanlislardanKartEkle(yanlislar).then((eklenen) {
                if (eklenen > 0) {
                  messenger.showSnackBar(SnackBar(
                    content: Text('$eklenen yanlış soru "Yanlışlarım" kart destene eklendi'),
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              });
              context.pushReplacement('/test-sonuc');
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.success),
            child: Text('Testi Bitir',
                style: TextStyle(color: context.colors.onPrimary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final testState = ref.watch(aktifTestProvider);
    final sorular = testState.sorular;

    if (sorular.isEmpty) {
      return Scaffold(
        backgroundColor: context.colors.background,
        appBar: AppBar(
          backgroundColor: context.colors.background,
          title: Text('Test', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
        ),
        body: EmptyStateWidget(
          icon: '🧪',
          baslik: 'Soru Bulunamadı',
          aciklama: 'Seçilen ders ve zorluk kriterlerine uygun soru bulunamadı.',
          butonMetni: 'Filtrelere Dön',
          onButonPressed: () => context.pop(),
        ),
      );
    }

    final soru = sorular[_currentIndex];
    final isaretlenen = testState.cevaplar[_currentIndex];

    final dakika = (testState.gecenSaniye ~/ 60).toString().padLeft(2, '0');
    final saniye = (testState.gecenSaniye % 60).toString().padLeft(2, '0');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _testiBitirOnay();
        }
      },
      child: Scaffold(
        backgroundColor: context.colors.background,
        appBar: AppBar(
          backgroundColor: context.colors.background,
          automaticallyImplyLeading: false,
          elevation: 0,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Soru ${_currentIndex + 1} / ${sorular.length}',
                style: TextStyle(
                    color: context.colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.colors.primaryLight),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined,
                        color: context.colors.primary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '$dakika:$saniye',
                      style: TextStyle(
                          color: context.colors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _testiBitirOnay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.danger,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Bitir',
                    style: TextStyle(color: context.colors.onPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Soru Künyesi & Kaynak
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${soru.ders} • ${soru.konu}',
                              style: TextStyle(
                                  color: context.colors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: soru.zorluk.renk.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: soru.zorluk.renk.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              soru.zorluk.etiket,
                              style: TextStyle(
                                  color: soru.zorluk.renk,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Künye: ${soru.kaynak}',
                        style: TextStyle(
                            color: context.colors.textMuted,
                            fontSize: 11,
                            fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 16),

                      // Soru Metni Kartı
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: context.colors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          soru.soruMetni,
                          style: TextStyle(
                              color: context.colors.textPrimary,
                              fontSize: 16,
                              height: 1.5,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Şıklar (A, B, C, D, E)
                      ...soru.secenekler.entries.map((entry) {
                        final key = entry.key; // 'A', 'B', 'C', 'D', 'E'
                        final value = entry.value;
                        final isSelected = isaretlenen == key;

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ref
                                .read(aktifTestProvider.notifier)
                                .secenekIsaretle(_currentIndex, key);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFEEF2FF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? context.colors.primary
                                    : context.colors.border,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? context.colors.primary
                                        : context.colors.background,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      key,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : context.colors.textSecondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    value,
                                    style: TextStyle(
                                        color: isSelected
                                            ? const Color(0xFF1E1B4B)
                                            : context.colors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Alt Navigasyon Çubuğu (Önceki, Soru Paleti, Sonraki)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  border: Border(top: BorderSide(color: context.colors.border)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _currentIndex > 0
                          ? () => setState(() => _currentIndex--)
                          : null,
                      tooltip: 'Önceki soru',
                      icon: Icon(Icons.arrow_back_ios,
                          color: _currentIndex > 0
                              ? context.colors.textPrimary
                              : context.colors.border),
                    ),

                    // Soru Izgarası Modal Açma
                    TextButton.icon(
                      onPressed: () => _showQuestionGridModal(context, sorular),
                      icon: Icon(Icons.grid_view_rounded,
                          color: context.colors.primary),
                      label: Text(
                        'Soru ${_currentIndex + 1} / ${sorular.length}',
                        style: TextStyle(
                            color: context.colors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),

                    IconButton(
                      onPressed: _currentIndex < sorular.length - 1
                          ? () => setState(() => _currentIndex++)
                          : null,
                      tooltip: 'Sonraki soru',
                      icon: Icon(Icons.arrow_forward_ios,
                          color: _currentIndex < sorular.length - 1
                              ? context.colors.textPrimary
                              : context.colors.border),
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

  void _showQuestionGridModal(BuildContext context, List<dynamic> sorular) {
    final testState = ref.read(aktifTestProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Soru Paleti',
              style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(sorular.length, (idx) {
                final isAnswered = testState.cevaplar.containsKey(idx);
                final isCurrent = _currentIndex == idx;
                return GestureDetector(
                  onTap: () {
                    setState(() => _currentIndex = idx);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? context.colors.primary
                          : isAnswered
                              ? context.colors.success
                              : context.colors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${idx + 1}',
                        style: TextStyle(
                            color: (isCurrent || isAnswered)
                                ? Colors.white
                                : context.colors.textSecondary,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
