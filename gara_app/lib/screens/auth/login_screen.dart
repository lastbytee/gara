import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import '../../widgets/language_toggle.dart';
import '../../widgets/loading_button.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../patient/patient_dashboard_screen.dart';
import '../doctor/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _lang = 'en';

  @override
  void initState() {
    super.initState();
    _loadSavedUsername();
  }

  Future<void> _loadSavedUsername() async {
    final saved = await context.read<AuthProvider>().getSavedUsername();
    if (saved.isNotEmpty) {
      _usernameController.text = saved;
      context.read<AuthProvider>().setRememberMe(true);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );
    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => auth.isDoctor
              ? const DoctorDashboardScreen()
              : const PatientDashboardScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(
                  LocalizationService.appTitle,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: GaraTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  LocalizationService.tagline,
                  style: const TextStyle(
                    fontSize: 11,
                    color: GaraTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 60),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: LocalizationService.username,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (v) => v == null || v.isEmpty ? LocalizationService.required : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: LocalizationService.password,
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  validator: (v) => v == null || v.isEmpty ? LocalizationService.required : null,
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: auth.rememberMe,
                            onChanged: (v) => auth.setRememberMe(v ?? false),
                            activeColor: GaraTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => auth.setRememberMe(!auth.rememberMe),
                          child: Text(
                            LocalizationService.rememberMe,
                            style: const TextStyle(fontSize: 13, color: GaraTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                      ),
                      child: Text(
                        LocalizationService.forgotPassword,
                        style: const TextStyle(
                          fontSize: 13,
                          color: GaraTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Consumer<AuthProvider>(
                  builder: (_, a, __) {
                    if (a.error != null) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          a.error!,
                          style: const TextStyle(color: GaraTheme.error),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                Consumer<AuthProvider>(
                  builder: (_, a, __) => LoadingButton(
                    loading: a.loading,
                    label: LocalizationService.login,
                    onPressed: _login,
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  child: Text(
                    LocalizationService.newPatientRegister,
                    style: const TextStyle(color: GaraTheme.primaryBlue),
                  ),
                ),
                Text(
                  LocalizationService.doctorLabel,
                  style: const TextStyle(
                      color: GaraTheme.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  child: Text(
                    LocalizationService.registerAsDoctor,
                    style: const TextStyle(
                      color: GaraTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
