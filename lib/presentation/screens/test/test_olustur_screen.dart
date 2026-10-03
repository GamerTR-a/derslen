import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/soru_havuzu.dart';
import '../../providers/test_provider.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

class TestOlusturScreen extends ConsumerWidget {
  const TestOlusturScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtre = ref.watch(testFiltreProvider);
    final harita = dersKonuAltBaslikHaritasi;
    final uyanSayisi = filtreliSorular(ders: filtre.ders, konu: filtre.konu, altBaslik: filtre.altBaslik, zorluk: filtre.zorluk).length;

    final dersler = ['hepsi', ...harita.keys];
    final konular = filtre.ders == 'hepsi'
        ? ['hepsi']
        : ['hepsi', ...(harita[filtre.ders]?.keys ?? [])];
    final altBasliklar = (filtre.ders == 'hepsi' || filtre.konu == 'hepsi')
        ? ['hepsi']
        : ['hepsi', ...(harita[filtre.ders]?[filtre.konu] ?? [])];

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(
          'Test Oluştur',
          style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: context.colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.colors.textPrimary),
          tooltip: 'Geri',
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
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
                child: Row(
                  children: [
                    Icon(Icons.verified_user_outlined, size: 28, color: context.colors.primary),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${soruHavuzu.length} soruluk havuz · ${harita.length} ders',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: context.colors.textPrimary),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Sorular DersNet tarafından YKS müfredatına göre özgün olarak hazırlanmıştır. Ders, konu ve zorluk seç; testin hemen hazırlansın.',
                            style: TextStyle(fontSize: 12, color: context.colors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 1. Ders Seçimi
              Text(
                '1. Ders Seçin',
                style: TextStyle(
                    color: context.colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: dersler.contains(filtre.ders) ? filtre.ders : 'hepsi',
                dropdownColor: context.colors.surface,
                style: TextStyle(color: context.colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: context.colors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: context.colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: context.colors.primary, width: 2),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                items: dersler.map((d) {
                  return DropdownMenuItem<String>(
                    value: d,
                    child: Text(d == 'hepsi' ? 'Tüm Dersler' : d),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(testFiltreProvider.notifier).dersDegistir(val);
                  }
                },
              ),
              const SizedBox(height: 20),

              // 2. Konu Seçimi
              Text(
                '2. Konu Seçin',
                style: TextStyle(
                    color: context.colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: konular.contains(filtre.konu) ? filtre.konu : 'hepsi',
                dropdownColor: context.colors.surface,
                style: TextStyle(color: context.colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: context.colors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: context.colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: context.colors.primary, width: 2),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                items: konular.map((k) {
                  return DropdownMenuItem<String>(
                    value: k,
                    child: Text(k == 'hepsi' ? 'Tüm Konular' : k),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(testFiltreProvider.notifier).konuDegistir(val);
                  }
                },
              ),
              const SizedBox(height: 20),

              // 3. Alt Başlık Seçimi
              if (altBasliklar.length > 1) ...[
                Text(
                  '3. Alt Başlık Seçin',
                  style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: altBasliklar.contains(filtre.altBaslik)
                      ? filtre.altBaslik
                      : 'hepsi',
                  dropdownColor: context.colors.surface,
                  style: TextStyle(color: context.colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: context.colors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: context.colors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: context.colors.primary, width: 2),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  items: altBasliklar.map((ab) {
                    return DropdownMenuItem<String>(
                      value: ab,
                      child: Text(ab == 'hepsi' ? 'Tüm Alt Başlıklar' : ab),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      ref
                          .read(testFiltreProvider.notifier)
                          .altBaslikDegistir(val);
                    }
                  },
                ),
                const SizedBox(height: 20),
              ],

              // 4. Zorluk Seviyesi
              Text(
                '4. Zorluk Seviyesi',
                style: TextStyle(
                    color: context.colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildZorlukChip(context, ref, 'hepsi', 'Karışık', filtre.zorluk),
                    const SizedBox(width: 8),
                    _buildZorlukChip(context, ref, 'kolay', 'Kolay', filtre.zorluk),
                    const SizedBox(width: 8),
                    _buildZorlukChip(context, ref, 'orta', 'Orta', filtre.zorluk),
                    const SizedBox(width: 8),
                    _buildZorlukChip(context, ref, 'zor', 'Zor', filtre.zorluk),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 5. Soru Sayısı
              Text(
                '5. Soru Sayısı',
                style: TextStyle(
                    color: context.colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [5, 10, 15, 20].map((sayi) {
                  final isSelected = filtre.soruSayisi == sayi;
                  return ChoiceChip(
                    label: Text(
                      '$sayi Soru',
                      style: TextStyle(
                        color: isSelected ? context.colors.onPrimary : context.colors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: context.colors.primary,
                    backgroundColor: context.colors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? context.colors.primary : context.colors.border,
                      ),
                    ),
                    onSelected: (val) {
                      if (val) {
                        ref
                            .read(testFiltreProvider.notifier)
                            .soruSayisiDegistir(sayi);
                      }
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(uyanSayisi == 0 ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                      size: 18, color: uyanSayisi == 0 ? context.colors.warning : context.colors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      uyanSayisi == 0
                          ? 'Bu seçime uyan soru yok. Zorluğu “Karışık” yapmayı ya da konuyu genişletmeyi dene.'
                          : uyanSayisi < filtre.soruSayisi
                              ? 'Bu seçime uyan $uyanSayisi soru var; testin $uyanSayisi sorudan oluşacak.'
                              : 'Bu seçime uyan $uyanSayisi soru var.',
                      style: TextStyle(fontSize: 12.5, color: context.colors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Testi Başlat Butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: uyanSayisi == 0
                      ? null
                      : () {
                    ref.read(aktifTestProvider.notifier).testOlustur(filtre);
                    context.push('/test-coz');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.success,
                    foregroundColor: context.colors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    elevation: 3,
                  ),
                  child: Text(
                    'Özel Testi Oluştur & Başla',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZorlukChip(BuildContext context,
      WidgetRef ref, String value, String label, String currentZorluk) {
    final isSelected = currentZorluk == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: isSelected ? context.colors.onPrimary : context.colors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedColor: context.colors.primary,
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? context.colors.primary : context.colors.border,
        ),
      ),
      onSelected: (val) {
        if (val) {
          ref.read(testFiltreProvider.notifier).zorlukDegistir(value);
        }
      },
    );
  }
}
