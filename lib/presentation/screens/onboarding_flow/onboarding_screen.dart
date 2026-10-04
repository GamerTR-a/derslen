import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/algorithms/learning_engine.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/mufredat_provider.dart';
import '../../providers/profil_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bahce_provider.dart';
import '../../widgets/tohum_kutusu_dialog.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;

  final _adSoyadController = TextEditingController();
  final _hedefUniversiteController = TextEditingController();
  String _hedefBolum = 'sayisal';
  int _gunlukSaat = 4;
  OgrenmeMetod _ogrenmeMetod = OgrenmeMetod.dengeli;
  String _sinif = '12. Sınıf';
  bool _kaydediliyor = false;

  static const List<String> _siniflar = [
    '9. Sınıf', '10. Sınıf', '11. Sınıf', '12. Sınıf', 'Mezun', 'Üniversite', 'Bağımsız',
  ];

  final List<Map<String, dynamic>> _bolumler = [
    {'id': 'sayisal', 'baslik': 'Sayısal', 'ikon': Icons.science_outlined, 'sub': 'Mat, Fizik, Kimya, Biyo'},
    {'id': 'esit_agirlik', 'baslik': 'Eşit Ağırlık', 'ikon': Icons.balance_rounded, 'sub': 'Mat, Türkçe, Edb, Tarih'},
    {'id': 'sozel', 'baslik': 'Sözel', 'ikon': Icons.menu_book_rounded, 'sub': 'Edb, Tarih, Coğ, Sosyal'},
    {'id': 'dil', 'baslik': 'Dil', 'ikon': Icons.translate_rounded, 'sub': 'İngilizce / Yabancı Dil'},
    {'id': 'serbest', 'baslik': 'Üniversite / Serbest', 'ikon': Icons.school_rounded, 'sub': 'YKS dışı: derslerini ve konularını sen eklersin'},
  ];

  // Serbest müfredat için
  final _dersController = TextEditingController();
  final _hedefAdController = TextEditingController();
  final List<String> _dersler = [];
  DateTime? _hedefTarih;

  bool get _serbest => _hedefBolum == serbestMufredat;

  void _dersEkle() {
    final yeni = _dersController.text.split(RegExp(r'[\n,;]')).map((s) => s.trim()).where((s) => s.isNotEmpty);
    setState(() {
      for (final d in yeni) {
        if (!_dersler.any((x) => x.toLowerCase() == d.toLowerCase())) _dersler.add(d);
      }
      _dersController.clear();
    });
  }

  @override
  void dispose() {
    _adSoyadController.dispose();
    _hedefUniversiteController.dispose();
    _dersController.dispose();
    _hedefAdController.dispose();
    super.dispose();
  }

  void _tamamla() async {
    if (_kaydediliyor) return;
    setState(() => _kaydediliyor = true);
    if (_serbest) {
      final mufredat = ref.read(mufredatProvider.notifier);
      for (final d in _dersler) {
        await mufredat.dersEkle(d);
      }
      await mufredat.hedefAyarla(ad: _hedefAdController.text, tarih: _hedefTarih);
    }
    await ref.read(profilProvider.notifier).kaydetProfil(
          sinifSeviyesi: _sinif,
          hedefBolum: _hedefBolum,
          gunlukSaat: _gunlukSaat,
          ogrenmeMetod: _ogrenmeMetod,
          hedefUniversite: _hedefUniversiteController.text.trim().isNotEmpty
              ? _hedefUniversiteController.text.trim()
              : null,
        );

    // Sürpriz kutu, oturum durumu değişmeden (yönlendirme dialog'u kapatmadan) gösterilir.
    final tohum = await ref.read(bahceProvider.notifier).hediyeKutusuAc();
    if (tohum != null && mounted) {
      await TohumKutusuDialog.goster(context, tohum);
    }

    ref.read(authProvider.notifier).setAuthenticated();
    if (mounted) {
      context.go('/ana');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // Üst İlerleme Çubuğu
              Row(
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Container(
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: index <= _step
                            ? context.colors.primary
                            : context.colors.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 28),

              // Adım İçerikleri
              Expanded(
                child: SingleChildScrollView(
                  child: _buildStepContent(),
                ),
              ),

              // Alt Butonlar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_step > 0)
                    TextButton(
                      onPressed: () => setState(() => _step--),
                      child: Text(
                        'Geri',
                        style: TextStyle(color: context.colors.textSecondary, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  ElevatedButton(
                    onPressed: _kaydediliyor ? null : () {
                      if (_step == 0 && _serbest) {
                        _dersEkle();
                        if (_dersler.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Devam etmek için en az bir ders ekle.')),
                          );
                          return;
                        }
                      }
                      if (_step < 2) {
                        setState(() => _step++);
                      } else {
                        _tamamla();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.primary,
                      foregroundColor: context.colors.onPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      _step == 2 ? 'Hesabımı Tamamla' : 'Devam Et',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _serbestMufredatAlani() {
    final c = context.colors;
    return [
      Text('Derslerin', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
      const SizedBox(height: 4),
      Text('Bu dönem çalışacağın dersleri ekle. Konularını sonra Müfredatım ekranından yazabilirsin; dersleri istediğin zaman ekleyip çıkarabilirsin.',
          style: TextStyle(fontSize: 12.5, color: c.textSecondary, height: 1.35)),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _dersController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _dersEkle(),
              style: TextStyle(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: 'Örn: Anatomi, Lineer Cebir',
                hintStyle: TextStyle(color: c.textMuted),
                filled: true,
                fillColor: c.surface,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.primary, width: 2)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(onPressed: _dersEkle, tooltip: 'Dersi ekle', icon: const Icon(Icons.add_rounded)),
        ],
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final d in _dersler) InputChip(label: Text(d), onDeleted: () => setState(() => _dersler.remove(d))),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _hedefAdController,
              maxLength: 30,
              style: TextStyle(color: c.textPrimary),
              decoration: InputDecoration(
                counterText: '',
                hintText: 'Hedef sınav (isteğe bağlı): Finaller, KPSS…',
                hintStyle: TextStyle(color: c.textMuted),
                filled: true,
                fillColor: c.surface,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.primary, width: 2)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final simdi = DateTime.now();
              final secim = await showDatePicker(
                context: context,
                initialDate: _hedefTarih ?? simdi.add(const Duration(days: 30)),
                firstDate: simdi,
                lastDate: simdi.add(const Duration(days: 365 * 3)),
                helpText: 'Sınav tarihi',
              );
              if (secim != null) setState(() => _hedefTarih = secim);
            },
            icon: const Icon(Icons.event_rounded, size: 18),
            label: Text(_hedefTarih == null ? 'Tarih' : '${_hedefTarih!.day}.${_hedefTarih!.month}.${_hedefTarih!.year}'),
          ),
        ],
      ),
    ];
  }

  Widget _buildStepContent() {
    if (_step == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kişisel Bilgilerin & Hedefin',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w900, color: context.colors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Alanını seç; çalışma planın buna göre hazırlanır. YKS dışında çalışıyorsan “Üniversite / Serbest”i seç.',
            style: TextStyle(fontSize: 14, color: context.colors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Ad Soyad Girişi
          TextField(
            controller: _adSoyadController,
            style: TextStyle(color: context.colors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Adınız Soyadınız',
              labelStyle: TextStyle(color: context.colors.textSecondary),
              hintText: 'Örn: Ahmet Yılmaz',
              hintStyle: TextStyle(color: context.colors.textMuted),
              filled: true,
              fillColor: context.colors.surface,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: context.colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: context.colors.primary, width: 2),
              ),
              prefixIcon: Icon(Icons.person_outline, color: context.colors.textMuted),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Hedef Bölüm / Alan',
            style: TextStyle(
                color: context.colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),

          ..._bolumler.map((bolum) {
            final isSelected = _hedefBolum == bolum['id'];
            return GestureDetector(
              onTap: () => setState(() {
                _hedefBolum = bolum['id'];
                if (_serbest && _sinif == '12. Sınıf') _sinif = 'Üniversite';
              }),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.colors.primary.withValues(alpha: 0.08)
                      : context.colors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? context.colors.primary
                        : context.colors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(bolum['ikon'] as IconData, size: 28, color: context.colors.primary),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bolum['baslik'],
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: context.colors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            bolum['sub'],
                            style: TextStyle(
                                fontSize: 12, color: context.colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded,
                          color: context.colors.primary, size: 24),
                  ],
                ),
              ),
            );
          }),
          if (_serbest) ..._serbestMufredatAlani(),
          const SizedBox(height: 12),
          TextField(
            controller: _hedefUniversiteController,
            style: TextStyle(color: context.colors.textPrimary),
            decoration: InputDecoration(
              hintText: _serbest ? 'Üniversiten & bölümün (isteğe bağlı)' : 'Hedef Üniversite & Bölüm (İsteğe bağlı)',
              hintStyle: TextStyle(color: context.colors.textMuted),
              filled: true,
              fillColor: context.colors.surface,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: context.colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: context.colors.primary, width: 2),
              ),
              prefixIcon: Icon(Icons.school_outlined, color: context.colors.textMuted),
            ),
          ),
        ],
      );
    }

    if (_step == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sınıfın ve Rutinin',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w900, color: context.colors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Hangi aşamadasın? 9, 10 ve 11. sınıfı seçersen konuların, testlerin ve kartların o sınıfın müfredatına (Maarif Modeli) göre hazırlanır.',
            style: TextStyle(fontSize: 14, color: context.colors.textSecondary),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in _siniflar)
                ChoiceChip(
                  label: Text(s),
                  selected: _sinif == s,
                  onSelected: (_) => setState(() => _sinif = s),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _sinif == s ? Colors.white : context.colors.textSecondary,
                  ),
                  selectedColor: context.colors.primary,
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Günde kaç saatini çalışmaya ayırabilirsin?',
            style: TextStyle(fontSize: 14, color: context.colors.textSecondary),
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.colors.primary, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: context.colors.primary.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    '$_gunlukSaat SAAT',
                    style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: context.colors.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Günde ${_gunlukSaat * 60} dakika odaklanmış çalışma',
                    style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 36),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: context.colors.primary,
              inactiveTrackColor: context.colors.border,
              thumbColor: context.colors.primary,
              overlayColor: context.colors.primary.withValues(alpha: 0.15),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
            ),
            child: Slider(
              value: _gunlukSaat.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '$_gunlukSaat saat',
              onChanged: (val) {
                setState(() => _gunlukSaat = val.toInt());
              },
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Öğrenme Metodunu Seç',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w900, color: context.colors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'Ders programın bu metodun prensiplerine göre hazırlanacak; koç asistanın ilerledikçe iyileştirme önerecek.',
          style: TextStyle(fontSize: 14, color: context.colors.textSecondary),
        ),
        const SizedBox(height: 24),
        ...OgrenmeMetod.values.map((metod) {
          final info = metodBilgi[metod] ?? {};
          final isSelected = _ogrenmeMetod == metod;
          return GestureDetector(
            onTap: () => setState(() => _ogrenmeMetod = metod),
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? context.colors.primary.withValues(alpha: 0.08)
                    : context.colors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? context.colors.primary
                      : context.colors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.psychology_alt_rounded, size: 30, color: context.colors.primary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              info['isim'] ?? '',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: context.colors.textPrimary),
                            ),
                            if (metod == OgrenmeMetod.dengeli)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: context.colors.success,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Önerilen',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: context.colors.onPrimary),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          info['aciklama'] ?? '',
                          style: TextStyle(
                              fontSize: 12, color: context.colors.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle_rounded,
                        color: context.colors.primary, size: 26),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

