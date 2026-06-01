import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import '../../services/google_sign_in/gis.dart';
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

  static bool _googleInitialized = false;

  Future<void> _googleSignIn() async {
    try {
      String? idToken;

      if (kIsWeb) {
        idToken = await WebGoogleSignIn.signIn();
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn.instance;
        if (!_googleInitialized && ApiConfig.googleClientId.isNotEmpty) {
          await googleSignIn.initialize(
            clientId: ApiConfig.googleClientId,
            serverClientId: ApiConfig.googleClientId,
          );
          _googleInitialized = true;
        }
        final account = await googleSignIn.authenticate();
        final authentication = account.authentication;
        idToken = authentication.idToken;
      }

      if (idToken == null || idToken.isEmpty) return;

      final auth = context.read<AuthProvider>();
      final success = await auth.googleSignIn(idToken, preferredLanguage: _lang);
      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => auth.isDoctor
                ? const DoctorDashboardScreen()
                : const PatientDashboardScreen(),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService.googleSignInFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final err = e.toString();
        String msg;
        if (err.contains('client_id') || err.contains('google-services')) {
          msg = 'Google Sign-In not configured. Register app in Google Cloud Console, then rebuild APK.';
        } else if (err.contains('10:') || err.contains('SIGN_IN_FAILED') || err.contains('sign_in_failed')) {
          msg = 'Google Sign-In failed (10). Ensure you have a Web client ID in Google Cloud Console (not just Android). Add your SHA-1 too:\n8D:C2:85:A5:25:20:47:DF:8B:E6:9B:9B:D4:FF:88:F5:D8:5E:31:7E';
        } else if (err.contains('12500') || err.contains('12501')) {
          msg = 'Google Sign-In cancelled or misconfigured. Create a Web client ID in Google Cloud Console — the Android client ID is not enough.';
        } else if (err.contains('configuration') || err.contains('popup_closed')) {
          msg = 'Google Sign-In popup was closed or not configured for this domain. Add this domain to authorized JavaScript origins in Google Cloud Console.';
        } else if (err.contains('TimeoutException')) {
          msg = 'Google Sign-In timed out. Please try again.';
        } else {
          msg = 'Google Sign-In error: $e';
        }
        debugPrint('GoogleSignIn error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red, duration: const Duration(seconds: 5)),
        );
      }
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
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        LocalizationService.orContinueWith,
                        style: const TextStyle(color: GaraTheme.textSecondary, fontSize: 12),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _googleSignIn,
                  icon: const Icon(Icons.login, color: Colors.black54),
                  label: Text(LocalizationService.continueWithGoogle),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Colors.black26),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  LocalizationService.allUsersLogin,
                  style: const TextStyle(
                    color: GaraTheme.textSecondary,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
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
