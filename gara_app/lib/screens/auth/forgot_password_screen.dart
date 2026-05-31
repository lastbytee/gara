import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import '../../widgets/language_toggle.dart';
import '../../widgets/loading_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _codeCtl = TextEditingController();
  final _newPasswordCtl = TextEditingController();
  final _confirmNewPasswordCtl = TextEditingController();
  bool _stepEmail = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String _lang = 'en';

  @override
  void dispose() {
    _emailCtl.dispose();
    _codeCtl.dispose();
    _newPasswordCtl.dispose();
    _confirmNewPasswordCtl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.forgotPassword(_emailCtl.text.trim());
    if (success && mounted) {
      setState(() => _stepEmail = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService.resetCodeSent),
          backgroundColor: GaraTheme.accent,
        ),
      );
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.resetPassword(
      email: _emailCtl.text.trim(),
      code: _codeCtl.text.trim(),
      newPassword: _newPasswordCtl.text,
      confirmNewPassword: _confirmNewPasswordCtl.text,
    );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService.passwordResetSuccess),
          backgroundColor: GaraTheme.accent,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService.forgotPasswordTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: LanguageToggle(
              currentLanguage: _lang,
              onChanged: (lang) {
                setState(() {
                  _lang = lang;
                  LocalizationService.setLocale(lang);
                });
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Icon(Icons.lock_reset, size: 64, color: GaraTheme.primaryBlue),
              const SizedBox(height: 16),
              Text(
                _stepEmail ? LocalizationService.forgotPasswordSubtitle : LocalizationService.enterResetCode,
                textAlign: TextAlign.center,
                style: const TextStyle(color: GaraTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 32),
              if (_stepEmail) ...[
                TextFormField(
                  controller: _emailCtl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: LocalizationService.email,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return LocalizationService.required;
                    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)) {
                      return LocalizationService.translate(
                        en: 'Enter a valid email address',
                        rw: 'Shyiramu imeri ikora',
                      );
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
              ] else ...[
                TextFormField(
                  controller: _codeCtl,
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: LocalizationService.enterResetCode,
                    prefixIcon: const Icon(Icons.pin),
                  ),
                  validator: (v) => v == null || v.isEmpty ? LocalizationService.required : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _newPasswordCtl,
                  obscureText: _obscureNew,
                  decoration: InputDecoration(
                    labelText: LocalizationService.newPassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return LocalizationService.required;
                    if (v.length < 6) return LocalizationService.minChars;
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmNewPasswordCtl,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: LocalizationService.confirmNewPassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return LocalizationService.required;
                    if (v != _newPasswordCtl.text) return LocalizationService.passwordsDoNotMatch;
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ],
              if (auth.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    auth.error!,
                    style: const TextStyle(color: GaraTheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              Consumer<AuthProvider>(
                builder: (_, a, __) => LoadingButton(
                  loading: a.loading,
                  label: _stepEmail ? LocalizationService.send : LocalizationService.resetPassword,
                  onPressed: _stepEmail ? _sendCode : _resetPassword,
                ),
              ),
              if (!_stepEmail) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() => _stepEmail = true),
                  child: Text(LocalizationService.back),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
