import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/algorithms/learning_engine.dart';
import '../../core/constants/app_constants.dart';
import '../providers/plan_provider.dart';
import '../providers/profil_provider.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

class ProfilDuzenleDialog extends ConsumerStatefulWidget {
  const ProfilDuzenleDialog({super.key});

  @override
  ConsumerState<ProfilDuzenleDialog> createState() => _ProfilDuzenleDialogState();
}

class _ProfilDuzenleDialogState extends ConsumerState<ProfilDuzenleDialog> {
  final _hedefUniversiteController = TextEditingController();

  late String _hedefBolum;
  late int _gunlukSaat;
  late OgrenmeMetod _ogrenmeMetod;

  final List<Map<String, dynamic>> _bolumler = [
    {'id': 'sayisal', 'baslik': 'Sayısal', 'ikon': Icons.science_outlined},
    {'id': 'esit_agirlik', 'baslik': 'Eşit Ağırlık', 'ikon': Icons.balance_rounded},
    {'id': 'sozel', 'baslik': 'Sözel', 'ikon': Icons.menu_book_rounded},
    {'id': 'dil', 'baslik': 'Dil', 'ikon': Icons.translate_rounded},
    {'id': 'serbest', 'baslik': 'Serbest', 'ikon': Icons.school_rounded},
  ];

  @override
  void initState() {
    super.initState();
    final profil = ref.read(profilProvider).value;
    _hedefBolum = profil?.hedefBolum ?? 'sayisal';
    _gunlukSaat = profil?.gunlukSaat ?? 4;
    _ogrenmeMetod = profil?.ogrenmeMetod ?? OgrenmeMetod.dengeli;
    _hedefUniversiteController.text = profil?.hedefUniversite ?? '';
  }

  @override
  void dispose() {
    _hedefUniversiteController.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    final alanDegisti = ref.read(profilProvider).value?.hedefBolum != _hedefBolum;
    final program = ref.read(programProvider.notifier);
    await ref.read(profilProvider.notifier).kaydetProfil(
          hedefBolum: _hedefBolum,
          gunlukSaat: _gunlukSaat,
          ogrenmeMetod: _ogrenmeMetod,
          hedefUniversite: _hedefUniversiteController.text.trim().isNotEmpty
              ? _hedefUniversiteController.text.trim()
              : null,
        );
    // Alan değişince müfredat da değişir; program yeni derslere göre yenilenir.
    if (alanDegisti) await program.yenidenOlustur();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profil bilgilerin ve öğrenme metodun güncellendi!'),
        backgroundColor: context.colors.success,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24.0,
          right: 24.0,
          top: 24.0,
          bottom: 24.0 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Profili Düzenle',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: context.colors.textMuted),
                    tooltip: 'Kapat',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Hedef Bölüm Seçimi
              Text(
                'Hedef alan (Serbest: kendi derslerin)',
                style: TextStyle(
                    color: context.colors.textPrimary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: _bolumler.map((b) {
                  final isSelected = _hedefBolum == b['id'];
                  return ChoiceChip(
                    avatar: Icon(b['ikon'] as IconData, size: 18),
                    label: Text(b['baslik']),
                    selected: isSelected,
                    selectedColor: context.colors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : context.colors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _hedefBolum = b['id']);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Günlük Çalışma Saati
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Günlük Çalışma Saati',
                    style: TextStyle(
                        color: context.colors.textPrimary, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$_gunlukSaat SAAT',
                    style: TextStyle(
                        color: context.colors.primary,
                        fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: context.colors.primary,
                  inactiveTrackColor: context.colors.border,
                  thumbColor: context.colors.primary,
                ),
                child: Slider(
                  value: _gunlukSaat.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: (val) => setState(() => _gunlukSaat = val.toInt()),
                ),
              ),
              const SizedBox(height: 16),

              // Öğrenme Metodu
              Text(
                'Öğrenme Metodu',
                style: TextStyle(
                    color: context.colors.textPrimary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<OgrenmeMetod>(
                initialValue: _ogrenmeMetod,
                dropdownColor: context.colors.surface,
                style: TextStyle(color: context.colors.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: context.colors.surface,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: context.colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: context.colors.primary, width: 2),
                  ),
                ),
                items: OgrenmeMetod.values.map((m) {
                  final info = metodBilgi[m] ?? {};
                  return DropdownMenuItem(
                    value: m,
                    child: Text('${info['isim']}'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _ogrenmeMetod = val);
                },
              ),
              const SizedBox(height: 16),

              // Hedef Üniversite
              TextField(
                controller: _hedefUniversiteController,
                style: TextStyle(color: context.colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Hedef Üniversite & Bölüm',
                  labelStyle: TextStyle(color: context.colors.textSecondary),
                  filled: true,
                  fillColor: context.colors.surface,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: context.colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: context.colors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _kaydet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.success,
                    foregroundColor: context.colors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Değişiklikleri Kaydet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

