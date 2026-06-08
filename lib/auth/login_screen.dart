import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:local_auth/local_auth.dart';
import '../services/api_service.dart';
import '../services/biometric_service.dart';
import '../screens/main_screen.dart';
import '../theme/design_system.dart';
import 'change_password_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _matriculeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  final _biometricService = BiometricService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _biometricVisible = false;
  List<BiometricType> _biometrics = [];

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  @override
  void dispose() {
    _matriculeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometric() async {
    final enabled = await _biometricService.isEnabled();
    final hasToken = await _biometricService.hasStoredToken();
    if (!enabled || !hasToken) return;
    final available = await _biometricService.isAvailable();
    if (!available || !mounted) return;
    final biometrics = await _biometricService.getAvailableBiometrics();
    setState(() {
      _biometricVisible = true;
      _biometrics = biometrics;
    });
    _loginWithBiometric();
  }

  Future<void> _login() async {
    final matricule = _matriculeController.text.trim();
    final password = _passwordController.text;
    if (matricule.isEmpty || password.isEmpty) {
      _showError('Veuillez remplir tous les champs');
      return;
    }
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();
    try {
      final response = await _apiService.login(matricule, password);
      if (!mounted) return;
      if (response['user']?['mustChangePassword'] == true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithBiometric() async {
    setState(() => _isLoading = true);
    try {
      final authenticated = await _biometricService.authenticate(
        reason: 'Connectez-vous à MotivUp',
      );
      if (authenticated && mounted) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      _showError('Erreur biométrique: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Background gradient top strip ─────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            height: MediaQuery.of(context).size.height * 0.46,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A56DB), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
            ),
          ),
          // ── Main content ──────────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  // ── Logo / wordmark ────────────────────────────────────────
                  Column(
                    children: [
                      // Outer ring + inner glass circle
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withOpacity(0.25), width: 2),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.12),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.emoji_events_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      Text(
                        'LEONI GROUP',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(0.55),
                          letterSpacing: 3.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'MotivUp',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Vos performances, récompensées',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.78),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 500.ms),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Login card ─────────────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      boxShadow: AppShadows.card,
                      border: Border(
                        top: BorderSide(
                            color: AppColors.primary.withOpacity(0.35),
                            width: 3),
                      ),
                    ),
                    padding: const EdgeInsets.all(AppSpacing.l),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 22,
                              decoration: BoxDecoration(
                                gradient: AppGradients.brand,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text('Connexion', style: AppTypography.headerMedium),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Entrez votre matricule et mot de passe',
                          style: AppTypography.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.l),

                        // Matricule
                        TextField(
                          controller: _matriculeController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Matricule',
                            hintText: 'Ex: 10364838',
                            prefixIcon: Icon(Icons.badge_outlined, size: 20),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.m),

                        // Password
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _login(),
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: const Icon(Icons.lock_outline, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.s),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen()),
                            ),
                            style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4)),
                            child: const Text('Mot de passe oublié ?'),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.m),

                        // Primary login button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.m)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5))
                              : const Text('Se connecter'),
                        ),

                        // Biometric button
                        if (_biometricVisible) ...[
                          const SizedBox(height: AppSpacing.m),
                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : _loginWithBiometric,
                            icon: Icon(
                              _biometrics.contains(BiometricType.face)
                                  ? Icons.face_unlock_outlined
                                  : Icons.fingerprint,
                              size: 20,
                            ),
                            label: Text(
                              _biometrics.contains(BiometricType.face)
                                  ? 'Face ID'
                                  : 'Empreinte digitale',
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 52),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.m)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ).animate().fadeIn(delay: 150.ms, duration: 500.ms).slideY(
                        begin: 0.1, end: 0, delay: 150.ms, duration: 400.ms),

                  const SizedBox(height: AppSpacing.l),
                  Text(
                    'MotivUp v1.1 — LEONI',
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
