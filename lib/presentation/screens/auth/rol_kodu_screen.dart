import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

import '../../../core/algorithms/okul_hesaplari.dart';
import '../../../core/services/okul_service.dart';
import '../../../data/models/okul_modelleri.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/ui_kit.dart';
import '../okul/okul_ortak.dart';

/// Veli, öğretmen ve müdür hesabı açıldıktan sonra: ad ve yetki kodu girilir.
/// Kod sunucuda doğrulanınca rol atanır ve ilgili panel açılır.
class RolKoduScreen extends ConsumerStatefulWidget {
  const RolKoduScreen({super.key});

  @override
  ConsumerState<RolKoduScreen> createState() => _RolKoduScreenState();
}

class _RolKoduScreenState extends ConsumerState<RolKoduScreen> {
  final _ad = TextEditingController();
  final _kod = TextEditingController();
  late KullaniciRolu _tur =
      KullaniciRolu.turden(ref.read(authProvider.notifier).kayitTuru) ?? KullaniciRolu.veli;
  bool _islemde = false;
  String? _hata;

  static const Map<KullaniciRolu, (String, String)> _aciklamalar = {
    KullaniciRolu.veli: (
      'Veli kodu',
      'Çocuğun DersNet\'te Profil › Okulum ve velim bölümünden bir veli kodu üretir. Kod 7 gün geçerlidir.',
    ),
    KullaniciRolu.ogretmen: (
      'Öğretmen kodu',
      'Kodu okul müdürün verir. Müdür seni şubelerine atadıktan sonra sınıfların burada görünür.',
    ),
    KullaniciRolu.mudur: (
      'Okul kodu',
      'Okulunu DersNet ekibi açar ve sana bir okul kodu iletir. Kod yoksa bizimle iletişime geç.',
    ),
  };

  @override
  void dispose() {
    _ad.dispose();
    _kod.dispose();
    super.dispose();
  }

  Future<void> _gonder() async {
    final ad = _ad.text.trim();
    final kod = kodTemizle(_kod.text);
    if (ad.length < 3) {
      setState(() => _hata = 'Adını ve soyadını yaz.');
      return;
    }
    if (kod.length != 9) {
      setState(() => _hata = 'Kod 9 karakterdir (ör. T-ABCD-2345).');
      return;
    }
    // Kodun öneki türü gösterir; yanlış sekmede yazılmış kod yine çalışır.
    final tur = kodTuru(kod) ?? _tur;
    if (tur == KullaniciRolu.ogrenci) {
      setState(() => _hata = 'Bu bir şube kodu. Öğrenciysen aşağıdan "Öğrenci olarak devam et" seçeneğini kullan.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _islemde = true;
      _hata = null;
    });
    try {
      await OkulService.adGuncelle(ad);
      final sonuc = await OkulService.koduKullan(kod, tur);
      if (!mounted) return;
      if (!sonuc.basarili) {
        setState(() => _hata = kodHataMetni(sonuc.durum, tur));
        return;
      }
      final tamam = await ref.read(authProvider.notifier).rolTamamlandi();
      if (!mounted) return;
      if (!tamam) {
        setState(() => _hata = 'Kod kabul edildi ama panel açılamadı. İnternetini kontrol edip tekrar dene.');
      }
      // Başarılıysa yönlendirici kullanıcıyı kendi paneline götürür.
    } on OkulHatasi catch (e) {
      if (mounted) setState(() => _hata = e.mesaj);
    } finally {
      if (mounted) setState(() => _islemde = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (kodEtiketi, aciklama) = _aciklamalar[_tur]!;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_tur.etiket} paneli', style: context.baslik(27)),
                  const SizedBox(height: 4),
                  Text('Hesabın açıldı. Panelini açmak için bir adım kaldı.',
                      style: TextStyle(fontSize: 14, color: c.textSecondary)),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final r in const [KullaniciRolu.veli, KullaniciRolu.ogretmen, KullaniciRolu.mudur])
                        HapSecim(
                          etiket: r.etiket,
                          secili: _tur == r,
                          onTap: _islemde
                              ? null
                              : () {
                                  setState(() {
                                    _tur = r;
                                    _hata = null;
                                  });
                                  ref.read(authProvider.notifier).kayitTuruAyarla(r.tur);
                                },
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Ad Soyad', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ad,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    maxLength: 60,
                    style: TextStyle(color: c.textPrimary),
                    decoration: okulGirdisi(context, ipucu: 'Adın ve soyadın', ikon: Icons.person_outline_rounded)
                        .copyWith(counterText: '', fillColor: c.surface),
                  ),
                  const SizedBox(height: 16),
                  Text(kodEtiketi, style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _kod,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _islemde ? null : _gonder(),
                    maxLength: 14,
                    style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                    decoration: okulGirdisi(context, ipucu: 'X-XXXX-XXXX', ikon: Icons.key_rounded)
                        .copyWith(counterText: '', fillColor: c.surface),
                  ),
                  const SizedBox(height: 8),
                  Text(aciklama, style: TextStyle(fontSize: 12.5, color: c.textMuted, height: 1.4)),
                  if (_hata != null) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      liveRegion: true,
                      child: Text(_hata!, style: TextStyle(color: c.danger, fontWeight: FontWeight.w600, height: 1.35)),
                    ),
                  ],
                  const SizedBox(height: 20),
                  AnaDugme(etiket: 'Paneli aç', onPressed: _gonder, yukleniyor: _islemde),
                  const SizedBox(height: 18),
                  Center(
                    child: TextButton(
                      onPressed: _islemde ? null : () => ref.read(authProvider.notifier).kayitTuruAyarla(null),
                      child: Text('Öğrenci olarak devam et', style: TextStyle(color: c.primary, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: _islemde ? null : () => ref.read(authProvider.notifier).logout(),
                      child: Text('Çıkış yap', style: TextStyle(color: c.textMuted)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
