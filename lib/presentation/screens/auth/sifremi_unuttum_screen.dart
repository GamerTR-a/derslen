import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/secure_screen_service.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/app_theme.dart';

/// Şifre sıfırlama: e-postaya 6 haneli kurtarma kodu gönderilir, kullanıcı
/// kodu ve yeni şifresini uygulama içinde girer. Hesap var/yok bilgisini
/// ifşa etmemek için kod gönderme adımı her durumda aynı mesajı gösterir.
///
/// Not: Supabase › Authentication › Email Templates › "Reset Password"
/// şablonunda `{{ .Token }}` bulunmalıdır.
class SifremiUnuttumScreen extends StatefulWidget {
  const SifremiUnuttumScreen({super.key});

  @override
  State<SifremiUnuttumScreen> createState() => _SifremiUnuttumScreenState();
}

class _SifremiUnuttumScreenState extends State<SifremiUnuttumScreen> with SecureScreenMixin {
  final _formKey = GlobalKey<FormState>();
  final _kodFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _kodController = TextEditingController();
  final _sifreController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _sent = false;
  bool _sifreGizli = true;
  String? _hata;

  @override
  void dispose() {
    _emailController.dispose();
    _kodController.dispose();
    _sifreController.dispose();
    // ignore: discarded_futures
    _authService.kurtarmaOturumunuKapat();
    super.dispose();
  }

  Future<void> _kodGonder() async {
    if (!_sent && !(_formKey.currentState?.validate() ?? false)) return;
    final tekrar = _sent;
    setState(() => _isLoading = true);
    await _authService.sifreSifirlamaKoduGonder(_emailController.text);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _sent = true;
      _hata = null;
    });
    if (tekrar) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Yeni kod istendi. Gelmezse bir dakika bekleyip tekrar dene; spam klasörüne de bak.'),
      ));
    }
  }

  Future<void> _sifreyiYenile() async {
    if (!_kodFormKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _hata = null;
    });
    final sonuc = await _authService.sifreyiKodlaYenile(
      email: _emailController.text,
      kod: _kodController.text,
      yeniSifre: _sifreController.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (sonuc.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(sonuc.message ?? 'Şifren güncellendi.'),
        backgroundColor: context.colors.success,
      ));
      context.go('/login');
    } else {
      setState(() => _hata = sonuc.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Şifremi Unuttum')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28.0),
            child: _sent ? _buildKodFormu(colors) : _buildForm(colors),
          ),
        ),
      ),
    );
  }

  InputDecoration _alan(AppTheme colors, String ipucu, IconData ikon, {Widget? sonEk}) {
    return InputDecoration(
      hintText: ipucu,
      hintStyle: TextStyle(color: colors.textMuted),
      filled: true,
      fillColor: colors.surface,
      prefixIcon: Icon(ikon, color: colors.textMuted),
      suffixIcon: sonEk,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
    );
  }

  Widget _anaButon(AppTheme colors, String metin, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: colors.onPrimary, strokeWidth: 2.5),
              )
            : Text(metin, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildForm(AppTheme colors) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Şifreni mi unuttun?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Kayıtlı e-posta adresini gir, şifreni yenilemen için 6 haneli bir kod gönderelim.',
            style: TextStyle(fontSize: 14, color: colors.textMuted),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            style: TextStyle(color: colors.textPrimary),
            decoration: _alan(colors, 'ornek@email.com', Icons.email_outlined),
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
          const SizedBox(height: 24),
          _anaButon(colors, 'Kod Gönder', _kodGonder),
        ],
      ),
    );
  }

  Widget _buildKodFormu(AppTheme colors) {
    return Form(
      key: _kodFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.mark_email_read_outlined, color: colors.primary, size: 56),
          const SizedBox(height: 16),
          Text(
            'E-postanı kontrol et',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Eğer ${_emailController.text.trim()} adresiyle kayıtlı bir hesap varsa 6 haneli bir kod gönderdik. Kodu ve yeni şifreni gir.',
            style: TextStyle(fontSize: 14, color: colors.textMuted),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _kodController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofillHints: const [AutofillHints.oneTimeCode],
            style: TextStyle(color: colors.textPrimary, letterSpacing: 4, fontWeight: FontWeight.bold),
            decoration: _alan(colors, '6 haneli kod', Icons.pin_outlined),
            validator: (v) => (v == null || !RegExp(r'^\d{6}$').hasMatch(v.trim())) ? '6 haneli kodu gir' : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _sifreController,
            obscureText: _sifreGizli,
            enableSuggestions: false,
            autocorrect: false,
            autofillHints: const [AutofillHints.newPassword],
            style: TextStyle(color: colors.textPrimary),
            decoration: _alan(
              colors,
              'Yeni şifre (en az 8 karakter)',
              Icons.lock_outline_rounded,
              sonEk: IconButton(
                tooltip: _sifreGizli ? 'Şifreyi göster' : 'Şifreyi gizle',
                icon: Icon(_sifreGizli ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: colors.textMuted),
                onPressed: () => setState(() => _sifreGizli = !_sifreGizli),
              ),
            ),
            validator: (v) => (v == null || v.length < 8) ? 'Şifren en az 8 karakter olmalı' : null,
          ),
          if (_hata != null) ...[
            const SizedBox(height: 12),
            Text(_hata!, style: TextStyle(color: colors.danger, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 24),
          _anaButon(colors, 'Şifremi Yenile', _sifreyiYenile),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _isLoading ? null : _kodGonder,
                child: const Text('Kodu tekrar gönder'),
              ),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Girişe dön'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
