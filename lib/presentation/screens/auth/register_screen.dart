import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/services/secure_screen_service.dart';
import '../../../data/models/okul_modelleri.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  /// Karşılama ekranında seçilen tür: 'ogrenci' | 'veli' | 'ogretmen' | 'mudur'.
  final String? tur;

  const RegisterScreen({super.key, this.tur});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> with SecureScreenMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late final TapGestureRecognizer _politikaTik = TapGestureRecognizer()
    ..onTap = () => context.push('/gizlilik-politikasi');

  KullaniciRolu get _rol => KullaniciRolu.turden(widget.tur) ?? KullaniciRolu.ogrenci;

  String get _altBaslik => switch (_rol) {
        KullaniciRolu.ogrenci => 'E-posta ve şifreni yaz, hemen başla',
        KullaniciRolu.veli => 'Hesabını aç; ardından çocuğunun verdiği veli kodunu gireceksin',
        KullaniciRolu.ogretmen => 'Hesabını aç; ardından müdürünün verdiği öğretmen kodunu gireceksin',
        KullaniciRolu.mudur => 'Hesabını aç; ardından DersNet ekibinin verdiği okul kodunu gireceksin',
      };

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _politikaTik.dispose();
    super.dispose();
  }

  void _submitRegister() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      setState(() => _isLoading = true);
      // Bağlantıyla doğrudan gelinmişse de seçilen tür hatırlansın.
      await ref.read(authProvider.notifier).kayitTuruAyarla(_rol == KullaniciRolu.ogrenci ? null : _rol.tur);
      final success = await ref.read(authProvider.notifier).register(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
      if (mounted) setState(() => _isLoading = false);

      if (success && mounted) {
        // Yönlendirme oturum durumuna göre: doğrudan profil kurulumu ya da
        // (sunucu hâlâ e-posta onayı istiyorsa) kod ekranı.
        final bekliyor = ref.read(authProvider).status == AuthStatus.emailVerificationPending;
        context.go(bekliyor ? '/verify-email' : (_rol == KullaniciRolu.ogrenci ? '/onboarding' : '/rol-kodu'));
      } else if (mounted) {
        final error = ref.read(authProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Kayıt yapılamadı. Tekrar deneyin.'),
            backgroundColor: context.colors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      _rol == KullaniciRolu.ogrenci ? 'Kayıt Ol' : '${_rol.etiket} Kaydı',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _altBaslik,
                      style: TextStyle(fontSize: 13, color: colors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 36),

                  Text(
                    'E-posta Adresi',
                    style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'ornek@email.com',
                      hintStyle: TextStyle(color: colors.textMuted),
                      filled: true,
                      fillColor: colors.surface,
                      prefixIcon: Icon(Icons.email_outlined, color: colors.textMuted),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: colors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: colors.primary, width: 2),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Lütfen e-posta adresinizi girin';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(val.trim())) {
                        return 'Geçerli bir e-posta adresi girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Şifre Belirleyin',
                    style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    enableSuggestions: false,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.newPassword],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _isLoading ? null : _submitRegister(),
                    style: TextStyle(color: colors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'En az 8 karakter',
                      hintStyle: TextStyle(color: colors.textMuted),
                      filled: true,
                      fillColor: colors.surface,
                      prefixIcon: Icon(Icons.lock_outline, color: colors.textMuted),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: colors.textMuted,
                        ),
                        tooltip: _obscurePassword ? 'Şifreyi göster' : 'Şifreyi gizle',
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: colors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: colors.primary, width: 2),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.length < 8) {
                        return 'Şifre en az 8 karakter olmalıdır';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  FormField<bool>(
                    initialValue: false,
                    validator: (v) => v == true ? null : 'Devam etmek için onay vermelisin',
                    builder: (alan) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: alan.value ?? false,
                              onChanged: (v) => alan.didChange(v ?? false),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text.rich(
                                  TextSpan(
                                    style: TextStyle(fontSize: 12.5, color: colors.textSecondary, height: 1.4),
                                    children: [
                                      TextSpan(
                                        text: 'Gizlilik Politikası',
                                        style: TextStyle(color: colors.primary, fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
                                        recognizer: _politikaTik,
                                      ),
                                      const TextSpan(
                                        text: '\'nı (aydınlatma metni) okudum. 18 yaşından küçüksem velimin onayı ile kaydoluyorum.',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (alan.hasError)
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Text(alan.errorText!, style: TextStyle(color: colors.danger, fontSize: 12)),
                          ),
                      ],
                    ),
                  ),
                  // Açık rıza, aydınlatma metninin onayından ayrı alınır (KVKK m.9).
                  FormField<bool>(
                    initialValue: false,
                    validator: (v) => v == true ? null : 'Verilerin yurt dışındaki sunucularda saklandığı için bu onay gerekli',
                    builder: (alan) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: alan.value ?? false,
                              onChanged: (v) => alan.didChange(v ?? false),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  'Verilerimin yurt dışındaki sunucularda saklanmasına ve işlenmesine açık rıza veriyorum.',
                                  style: TextStyle(fontSize: 12.5, color: colors.textSecondary, height: 1.4),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (alan.hasError)
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Text(alan.errorText!, style: TextStyle(color: colors.danger, fontSize: 12)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: context.colors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  color: context.colors.onPrimary, strokeWidth: 2.5),
                            )
                          : Text(
                              'Hesabımı Oluştur',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Zaten bir hesabın var mı? ',
                        style: TextStyle(color: colors.textMuted),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          'Giriş Yap',
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
