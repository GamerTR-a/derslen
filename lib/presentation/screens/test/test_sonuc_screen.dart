import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/tarih.dart';
import '../../providers/test_provider.dart';
import '../../widgets/grafikler.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

class TestSonucScreen extends ConsumerStatefulWidget {
  const TestSonucScreen({super.key});

  @override
  ConsumerState<TestSonucScreen> createState() => _TestSonucScreenState();
}

class _TestSonucScreenState extends ConsumerState<TestSonucScreen> {
  /// Çözüm listesinde yalnızca yanlış ve boş bırakılan sorular gösterilsin mi?
  bool _yalnizHatalar = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final test = ref.watch(aktifTestProvider);
    final sorular = test.sorular;
    final dersler = test.dersSonuclari;
    final basari = sorular.isEmpty ? 0 : (test.dogruSayisi * 100 / sorular.length).round();
    final hataVar = test.yanlisSayisi + test.bosSayisi > 0;
    final yalnizHatalar = _yalnizHatalar && hataVar;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          HapticFeedback.lightImpact();
          context.go('/ana');
        }
      },
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          title: Text(
            test.tur == TestTuru.deneme ? 'Deneme sonucu' : 'Test sonucu',
            style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold),
          ),
          backgroundColor: c.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(color: c.feature, borderRadius: BorderRadius.circular(24)),
                child: Column(
                  children: [
                    Text(
                      test.baslik,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.onFeature.withValues(alpha: 0.85), fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text('${test.net} net', style: context.baslik(36, color: c.onFeature)),
                    Text('%$basari başarı', style: TextStyle(color: c.onFeature.withValues(alpha: 0.85), fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _ozet(context, 'Doğru', '${test.dogruSayisi}'),
                        _ozet(context, 'Yanlış', '${test.yanlisSayisi}'),
                        _ozet(context, 'Boş', '${test.bosSayisi}'),
                        _ozet(context, 'Süre', sureMetni((test.gecenSaniye / 60).ceil())),
                      ],
                    ),
                  ],
                ),
              ),
              if (dersler.length > 1) ...[
                const SizedBox(height: 14),
                GrafikKarti(
                  baslik: 'Derslere göre sonuç',
                  aciklama: 'Doğru · yanlış · boş ve net',
                  child: Column(
                    children: [
                      for (final e in dersler.entries)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Container(width: 10, height: 10, decoration: BoxDecoration(color: grafikDersRengi(context, e.key), shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(dersKisaAdi(e.key), style: TextStyle(fontWeight: FontWeight.w700, color: c.textPrimary))),
                              Text('${e.value[0]} · ${e.value[1]} · ${e.value[2]}', style: TextStyle(color: c.textSecondary)),
                              SizedBox(
                                width: 64,
                                child: Text(
                                  (e.value[0] - e.value[1] * 0.25).toStringAsFixed(2),
                                  textAlign: TextAlign.end,
                                  style: TextStyle(fontWeight: FontWeight.w800, color: c.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.go('/ana'),
                      child: const Text('Ana sayfa'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => context.pushReplacement('/test-olustur'),
                      child: const Text('Yeni test'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Text('Cevaplar ve çözümler', style: context.baslik(18))),
                  if (hataVar)
                    FilterChip(
                      label: const Text('Yalnız hatalar'),
                      selected: yalnizHatalar,
                      onSelected: (v) => setState(() => _yalnizHatalar = v),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              for (var index = 0; index < sorular.length; index++)
                if (!yalnizHatalar || test.cevaplar[index] != sorular[index].dogruSecenek) _soruKarti(context, test, index),
            ],
          ),
        ),
      ),
    );
  }

  Widget _soruKarti(BuildContext context, AktifTestState test, int index) {
    final c = context.colors;
    final soru = test.sorular[index];
    final verilen = test.cevaplar[index];
    final isDogru = verilen == soru.dogruSecenek;
    final isBos = verilen == null;
    final statusColor = isBos
        ? c.textMuted
        : isDogru
            ? c.success
            : c.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  'Soru ${index + 1} • ${isBos ? 'BOŞ' : isDogru ? 'DOĞRU' : 'YANLIŞ'}',
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${soru.ders} • ${soru.konu}',
                  maxLines: 1,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(soru.soruMetni, style: TextStyle(color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w600, height: 1.4)),
          const SizedBox(height: 12),
          if (!isBos && !isDogru)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Senin cevabın: $verilen) ${soru.secenekler[verilen] ?? ''}',
                style: TextStyle(color: c.danger, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          Text(
            'Doğru cevap: ${soru.dogruSecenek}) ${soru.secenekler[soru.dogruSecenek] ?? ''}',
            style: TextStyle(color: c.success, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Divider(color: c.border, height: 24),
          Text('Çözüm', style: TextStyle(color: c.gece ? c.accent : c.primary, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Text(soru.cozumAciklama, style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  Widget _ozet(BuildContext context, String label, String val) {
    final c = context.colors;
    return Column(
      children: [
        Text(val, style: TextStyle(color: c.onFeature, fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: c.onFeature.withValues(alpha: 0.75), fontSize: 11.5)),
      ],
    );
  }
}
