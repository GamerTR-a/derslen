import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../cizimler/cizim_widgetlari.dart';
import '../../providers/ortam_provider.dart';
import '../../providers/settings_provider.dart';

class AyarlarScreen extends ConsumerWidget {
  const AyarlarScreen({super.key});

  static const _textScaleOptions = [
    (0.85, 'Küçük'),
    (1.0, 'Normal'),
    (1.15, 'Büyük'),
    (1.3, 'Çok Büyük'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final ortam = ref.watch(ortamProvider);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionCard(
            title: 'Görünüm',
            icon: Icons.palette_outlined,
            children: [
              Text('Tema', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary)),
              const SizedBox(height: 10),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.light, label: Text('Sabah'), icon: Icon(Icons.wb_sunny_outlined)),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Gece'), icon: Icon(Icons.nightlight_outlined)),
                  ButtonSegment(value: ThemeMode.system, label: Text('Otomatik'), icon: Icon(Icons.brightness_auto_outlined)),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (selection) {
                  ref.read(settingsProvider.notifier).setThemeMode(selection.first);
                },
              ),
              const SizedBox(height: 10),
              Text(
                'Sabah Bahçesi açık, Gece Kütüphanesi koyu görünümdür. Otomatik seçilirse telefonun karanlık mod ayarını izler.',
                style: TextStyle(fontSize: 12.5, color: colors.textMuted, height: 1.4),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Asistan Karakterin',
            icon: Icons.pets_rounded,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Ekranda göster', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                subtitle: Text('Sağ altta durur; dokununca koç asistanın açılır.', style: TextStyle(fontSize: 12, color: colors.textMuted)),
                value: ortam.asistanGorunur,
                onChanged: (v) => ref.read(ortamProvider.notifier).asistanGorunurluk(v),
              ),
              if (ortam.asistanGorunur) ...[
                const SizedBox(height: 6),
                LayoutBuilder(builder: (context, kutu) {
                  const aralik = 8.0;
                  final genislik = (kutu.maxWidth - aralik * 2) / 3;
                  return Wrap(
                    spacing: aralik,
                    runSpacing: aralik,
                    children: [
                      for (final k in AsistanKarakter.values)
                        Semantics(
                          button: true,
                          selected: ortam.asistan == k,
                          label: '${k.ad} karakterini seç',
                          excludeSemantics: true,
                          child: InkWell(
                            onTap: () => ref.read(ortamProvider.notifier).asistanSec(k),
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: genislik,
                              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                              decoration: BoxDecoration(
                                color: ortam.asistan == k ? colors.primarySoft : colors.background,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: ortam.asistan == k ? colors.primary : colors.border,
                                  width: ortam.asistan == k ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Maskot(karakter: k.name, boyut: min(72, genislik - 12), yuruyor: ortam.asistan == k),
                                  const SizedBox(height: 4),
                                  Text(k.ad,
                                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }),
                const SizedBox(height: 14),
                Text('Hareket', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary)),
                const SizedBox(height: 8),
                SegmentedButton<AsistanHareket>(
                  segments: [
                    for (final h in AsistanHareket.values) ButtonSegment(value: h, label: Text(h.etiket, style: const TextStyle(fontSize: 12))),
                  ],
                  selected: {ortam.hareket},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => ref.read(ortamProvider.notifier).hareketSec(s.first),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Yazı Boyutu',
            icon: Icons.text_fields_rounded,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _textScaleOptions.map((option) {
                  final (scale, label) = option;
                  final isSelected = (settings.textScale - scale).abs() < 0.01;
                  return ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) => ref.read(settingsProvider.notifier).setTextScale(scale),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Text(
                'Örnek metin önizlemesi',
                style: TextStyle(fontSize: 15, color: colors.textPrimary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Günlük Hatırlatma',
            icon: Icons.notifications_outlined,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Hatırlatma Bildirimi', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  'Her gün ${settings.reminderHour.toString().padLeft(2, '0')}:${settings.reminderMinute.toString().padLeft(2, '0')} saatinde çalışma planını hatırlat.',
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
                value: settings.dailyReminderEnabled,
                onChanged: (val) {
                  ref.read(settingsProvider.notifier).setDailyReminder(
                        enabled: val,
                        hour: settings.reminderHour,
                        minute: settings.reminderMinute,
                      );
                },
              ),
              if (settings.dailyReminderEnabled)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      final secilen = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(hour: settings.reminderHour, minute: settings.reminderMinute),
                      );
                      if (secilen != null) {
                        ref.read(settingsProvider.notifier).setDailyReminder(
                              enabled: true,
                              hour: secilen.hour,
                              minute: secilen.minute,
                            );
                      }
                    },
                    icon: const Icon(Icons.schedule_rounded),
                    label: const Text('Saati Değiştir'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colors.textPrimary),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}
