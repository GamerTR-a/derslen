import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/secure_screen_service.dart';
import '../../providers/auth_provider.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> with SecureScreenMixin {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submitVerification() async {
    final code = _codeController.text.trim();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lütfen 6 haneli onay kodunu tam girin.'),
          backgroundColor: context.colors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final success =
        await ref.read(authProvider.notifier).verifyEmailOtp(code);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('E-posta doğrulandı! Kişisel bilgilerinizi girin.'),
          backgroundColor: context.colors.success,
        ),
      );
      context.go('/onboarding');
    } else if (mounted) {
      final error = ref.read(authProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Onay kodu hatalı. Lütfen tekrar deneyin.'),
          backgroundColor: context.colors.danger,
        ),
      );
    }
  }

  Future<void> _resendCode() async {
    if (_isResending) return;
    setState(() => _isResending = true);
    final mesaj = await ref.read(authProvider.notifier).dogrulamaKodunuTekrarGonder();
    if (!mounted) return;
    setState(() => _isResending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mesaj), backgroundColor: context.colors.info),
    );
  }

  void _backToLogin() {
    ref.read(authProvider.notifier).dogrulamadanVazgec();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: context.colors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.mark_email_read_rounded,
                      color: context.colors.primary, size: 44),
                ),
                const SizedBox(height: 24),
                Text(
                  'E-postanızı Onaylayın',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Doğrulama kodu ${authState.email ?? 'e-posta adresinize'} gönderildi.',
                  style: TextStyle(fontSize: 14, color: context.colors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Kod Gelmedi Bilgilendirme Kutusu
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.colors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.colors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: context.colors.primary, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Kod birkaç dakika içinde gelmezse spam/gereksiz klasörüne bak ya da "Tekrar Kod Gönder"e dokun.',
                          style: TextStyle(fontSize: 12, color: context.colors.textSecondary, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // OTP Giriş Kutusu
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 12,
                  ),
                  maxLength: 6,
                  decoration: InputDecoration(
                    hintText: '123456',
                    hintStyle: TextStyle(color: context.colors.textMuted, letterSpacing: 8),
                    filled: true,
                    fillColor: context.colors.surface,
                    counterText: '',
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: context.colors.border, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: context.colors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitVerification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.success,
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
                            'Hesabı Onayla & Devam Et',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: _isResending ? null : _resendCode,
                      icon: Icon(Icons.refresh_rounded, size: 16, color: context.colors.primary),
                      label: Text(
                        'Tekrar Kod Gönder',
                        style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      onPressed: _backToLogin,
                      child: Text(
                        'Giriş Ekranına Dön',
                        style: TextStyle(color: context.colors.textSecondary),
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
}

