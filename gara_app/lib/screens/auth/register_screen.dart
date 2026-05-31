import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import '../../widgets/language_toggle.dart';
import '../../widgets/loading_button.dart';
import 'login_screen.dart';
import '../patient/intake_form_screen.dart';
import '../doctor/dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _confirmPasswordCtl = TextEditingController();
  final _firstNameCtl = TextEditingController();
  final _lastNameCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _tokenCtl = TextEditingController();
  bool _isDoctor = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _lang = 'en';

  @override
  void dispose() {
    _usernameCtl.dispose();
    _emailCtl.dispose();
    _passwordCtl.dispose();
    _confirmPasswordCtl.dispose();
    _firstNameCtl.dispose();
    _lastNameCtl.dispose();
    _phoneCtl.dispose();
    _tokenCtl.dispose();
    super.dispose();
  }

  double _calculateStrength(String pwd) {
    if (pwd.isEmpty) return 0;
    double score = 0;
    if (pwd.length >= 6) score += 0.2;
    if (pwd.length >= 10) score += 0.15;
    if (RegExp(r'[A-Z]').hasMatch(pwd)) score += 0.2;
    if (RegExp(r'[a-z]').hasMatch(pwd)) score += 0.15;
    if (RegExp(r'[0-9]').hasMatch(pwd)) score += 0.15;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(pwd)) score += 0.15;
    return score.clamp(0.0, 1.0);
  }

  String _strengthLabel(double score) {
    if (score < 0.35) return LocalizationService.weak;
    if (score < 0.65) return LocalizationService.medium;
    return LocalizationService.strong;
  }

  Color _strengthColor(double score) {
    if (score < 0.35) return Colors.red;
    if (score < 0.65) return Colors.orange;
    return Colors.green;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    bool success;

    if (_isDoctor) {
      success = await auth.registerDoctor(
        username: _usernameCtl.text.trim(),
        email: _emailCtl.text.trim(),
        password: _passwordCtl.text,
        confirmPassword: _confirmPasswordCtl.text,
        registrationToken: _tokenCtl.text.trim(),
        firstName: _firstNameCtl.text.trim(),
        lastName: _lastNameCtl.text.trim(),
      );
    } else {
      success = await auth.registerPatient(
        username: _usernameCtl.text.trim(),
        email: _emailCtl.text.trim(),
        password: _passwordCtl.text,
        confirmPassword: _confirmPasswordCtl.text,
        firstName: _firstNameCtl.text.trim(),
        lastName: _lastNameCtl.text.trim(),
        phoneNumber: _phoneCtl.text.trim(),
        preferredLanguage: _lang,
      );
    }

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => _isDoctor
              ? const DoctorDashboardScreen()
              : const IntakeFormScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService.register),
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
              Row(
                children: [
                  Expanded(
                    child: _roleButton(
                      label: LocalizationService.patient,
                      icon: Icons.person,
                      selected: !_isDoctor,
                      onTap: () => setState(() => _isDoctor = false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _roleButton(
                      label: LocalizationService.doctor,
                      icon: Icons.medical_services,
                      selected: _isDoctor,
                      onTap: () => setState(() => _isDoctor = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _usernameCtl,
                decoration: InputDecoration(
                  labelText: LocalizationService.username,
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return LocalizationService.required;
                  if (!RegExp(r'^[a-zA-Z0-9_]{3,30}$').hasMatch(v)) {
                    return LocalizationService.translate(
                      en: '3-30 chars, letters, numbers, underscore',
                      rw: 'Inyuguti 3-30, inyuguti, numero, underscore',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: LocalizationService.email,
                  prefixIcon: const Icon(Icons.email),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _firstNameCtl,
                decoration: InputDecoration(
                  labelText: LocalizationService.firstName,
                  prefixIcon: const Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastNameCtl,
                decoration: InputDecoration(
                  labelText: LocalizationService.lastName,
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
              ),
              if (!_isDoctor) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtl,
                  decoration: InputDecoration(
                    labelText: LocalizationService.phoneNumber,
                    prefixIcon: const Icon(Icons.phone),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtl,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: LocalizationService.password,
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return LocalizationService.required;
                  if (v.length < 6) return LocalizationService.minChars;
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 4),
              if (_passwordCtl.text.isNotEmpty)
                Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          '${LocalizationService.passwordStrength}: ',
                          style: const TextStyle(fontSize: 11, color: GaraTheme.textSecondary),
                        ),
                        Text(
                          _strengthLabel(_calculateStrength(_passwordCtl.text)),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _strengthColor(_calculateStrength(_passwordCtl.text)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _calculateStrength(_passwordCtl.text),
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation(
                          _strengthColor(_calculateStrength(_passwordCtl.text)),
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordCtl,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: LocalizationService.confirmPassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return LocalizationService.required;
                  if (v != _passwordCtl.text) return LocalizationService.passwordsDoNotMatch;
                  return null;
                },
              ),
              if (_isDoctor) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tokenCtl,
                  decoration: InputDecoration(
                    labelText: LocalizationService.doctorRegistrationToken,
                    prefixIcon: const Icon(Icons.vpn_key),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? LocalizationService.requiredForDoctor : null,
                ),
              ],
              const SizedBox(height: 24),
              Consumer<AuthProvider>(
                builder: (_, auth, __) {
                  if (auth.error != null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(auth.error!,
                          style: const TextStyle(color: GaraTheme.error),
                          textAlign: TextAlign.center),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              Consumer<AuthProvider>(
                builder: (_, auth, __) => LoadingButton(
                  loading: auth.loading,
                  label: _isDoctor ? LocalizationService.registerAsDoctor : LocalizationService.registerAsPatient,
                  onPressed: _register,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: Text(
                  LocalizationService.alreadyHaveAccount,
                  style: const TextStyle(color: GaraTheme.primaryBlue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? GaraTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? GaraTheme.primaryBlue : const Color(0xFFE0E0E0),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: selected ? Colors.white : GaraTheme.primaryBlue,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : GaraTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
