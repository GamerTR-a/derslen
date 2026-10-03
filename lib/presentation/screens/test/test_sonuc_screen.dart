import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/test_provider.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

class TestSonucScreen extends ConsumerWidget {
  const TestSonucScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testState = ref.watch(aktifTestProvider);
    final sorular = testState.sorular;

    final dakika = (testState.gecenSaniye ~/ 60).toString();
    final saniye = (testState.gecenSaniye % 60).toString().padLeft(2, '0');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          HapticFeedback.lightImpact();
          context.go('/ana');
        }
      },
      child: Scaffold(
        backgroundColor: context.colors.background,
        appBar: AppBar(
          title: Text(
            'Test Sonuç Karnesi',
            style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold),
          ),
          backgroundColor: context.colors.background,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Özet Net Kartı
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [context.colors.primaryLight, context.colors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: context.colors.primaryLight.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Text('HESAPLANAN NET',
                          style: TextStyle(
                              color: context.colors.onPrimary.withValues(alpha: 0.70),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 6),
                      Text(
                        '${testState.net} Net',
                        style: TextStyle(
                            color: context.colors.surface,
                            fontSize: 38,
                            fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStat(context, 'Doğru', '${testState.dogruSayisi}', Colors.greenAccent),
                          _buildStat(context, 'Yanlış', '${testState.yanlisSayisi}', Colors.redAccent),
                          _buildStat(context, 'Boş', '${testState.bosSayisi}', Colors.white70),
                          _buildStat(context, 'Süre', '$dakika dk $saniye sn', Colors.amberAccent),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                Text(
                  'Cevaplar ve Detaylı Çözümler',
                  style: TextStyle(
                      color: context.colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Her Sorunun İnceleme Kartı
                ...List.generate(sorular.length, (index) {
                  final soru = sorular[index];
                  final verilen = testState.cevaplar[index];
                  final isDogru = verilen == soru.dogruSecenek;
                  final isBos = verilen == null;

                  final statusColor = isBos
                      ? context.colors.textMuted
                      : isDogru
                          ? context.colors.success
                          : context.colors.danger;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Soru ${index + 1} • ${isBos ? 'BOŞ' : isDogru ? 'DOĞRU' : 'YANLIŞ'}',
                                style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              soru.ders,
                              style: TextStyle(
                                  color: context.colors.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          soru.soruMetni,
                          style: TextStyle(
                              color: context.colors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text('Sizin Cevabınız: ${verilen ?? "Boş"}',
                                style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                            const SizedBox(width: 16),
                            Text('Doğru Cevap: ${soru.dogruSecenek}',
                                style: TextStyle(
                                    color: context.colors.success,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ],
                        ),
                        Divider(color: context.colors.border, height: 24),
                        Text('Çözüm:',
                            style: TextStyle(
                                color: context.colors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          soru.cozumAciklama,
                          style: TextStyle(
                              color: context.colors.textSecondary, fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // Alt Butonlar
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.go('/ana'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.colors.primary,
                          side: BorderSide(color: context.colors.primary, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text('Plana Dön', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.pushReplacement('/test-olustur'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.primary,
                          foregroundColor: context.colors.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text('Yeni Test Oluştur',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String val, Color col) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: context.colors.onPrimary.withValues(alpha: 0.60), fontSize: 11)),
        const SizedBox(height: 2),
        Text(val,
            style: TextStyle(
                color: col, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
