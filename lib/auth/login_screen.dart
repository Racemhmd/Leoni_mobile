import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
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
    if (!mounted) return;
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      body: Stack(
        children: [
          // ── Dark platform background ─────────────────────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(gradient: AppGradients.entry),
            ),
          ),

          // ── Grid texture overlay (tech platform feel) ────────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),

          // ── Cyan radial glow — anchor behind wordmark ────────────────────────
          Positioned(
            right: -60, top: size.height * 0.04,
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Main scrollable content ──────────────────────────────────────────
          Column(
            children: [
              // ─── Dark hero panel ──────────────────────────────────────────────
              SizedBox(
                height: size.height * 0.44,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.l, vertical: AppSpacing.m),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status bar row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // LEONI logo — small in status bar
                            _LeoniLogo(height: 26),
                            // Status indicator — cyan dot
                            Row(
                              children: [
                                Container(
                                  width: 6, height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            AppColors.primary.withOpacity(0.6),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Système actif',
                                  style:
                                      AppTypography.labelBright.copyWith(
                                          fontSize: 9),
                                ),
                              ],
                            ),
                          ],
                        ).animate().fadeIn(duration: 400.ms),

                        const Spacer(),

                        // ── Wordmark ──────────────────────────────────────────
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Split-color "MotivUp" — Syne 700
                            RichText(
                              text: TextSpan(
                                style: AppTypography.displayHero,
                                children: [
                                  const TextSpan(text: 'Motiv'),
                                  TextSpan(
                                    text: 'Up',
                                    style: AppTypography.displayHero.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),

                            // ── LEONI logo sous le nom ────────────────────────
                            _LeoniLogo(height: 32),

                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Vos performances, récompensées.',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.45),
                              ),
                            ),
                          ],
                        )
                            .animate()
                            .fadeIn(delay: 80.ms, duration: 500.ms)
                            .slideY(
                                begin: 0.06,
                                end: 0,
                                delay: 80.ms,
                                duration: 450.ms,
                                curve: Curves.easeOutCubic),

                        const SizedBox(height: AppSpacing.l),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── White card panel — slides up ─────────────────────────────────
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppRadius.xxl),
                      topRight: Radius.circular(AppRadius.xxl),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 40,
                        offset: const Offset(0, -8),
                      ),
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.15),
                        blurRadius: 30,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.l, AppSpacing.l, AppSpacing.l, AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Card handle ───────────────────────────────────────
                        Center(
                          child: Container(
                            width: 36, height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.divider,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.l),

                        // ── Form header ───────────────────────────────────────
                        Row(
                          children: [
                            // Cyan left bar
                            Container(
                              width: 3, height: 20,
                              decoration: BoxDecoration(
                                gradient: AppGradients.brand,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text('Connexion',
                                style: AppTypography.headerMedium),
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
                          style: AppTypography.monoData,
                          decoration: const InputDecoration(
                            labelText: 'Matricule',
                            hintText: 'Ex: 10364838',
                            prefixIcon:
                                Icon(Icons.badge_outlined, size: 20),
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
                            prefixIcon:
                                const Icon(Icons.lock_outline, size: 20),
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
                                  builder: (_) =>
                                      const ForgotPasswordScreen()),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4),
                              foregroundColor: AppColors.primary,
                            ),
                            child: Text(
                              'Mot de passe oublié ?',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.m),

                        // ── Cyan gradient button ──────────────────────────────
                        _PlatformButton(
                          onTap: _isLoading ? null : _login,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5))
                              : Text('Se connecter',
                                  style: AppTypography.button),
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
                              foregroundColor: AppColors.primary,
                              side: BorderSide(
                                  color: AppColors.primary.withOpacity(0.5)),
                              minimumSize:
                                  const Size(double.infinity, 52),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.m)),
                            ),
                          ),
                        ],

                        const SizedBox(height: AppSpacing.l),
                        Center(
                          child: Text(
                            'v1.1.0 · LEONI',
                            style: AppTypography.label.copyWith(
                              color: AppColors.textSecondary
                                  .withOpacity(0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .slideY(
                        begin: 0.15, end: 0,
                        delay: 150.ms, duration: 500.ms,
                        curve: Curves.easeOutCubic)
                    .fadeIn(delay: 150.ms, duration: 400.ms),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Cyan gradient button ──────────────────────────────────────────────────────

class _PlatformButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;

  const _PlatformButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1.0,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: AppGradients.brand,
          borderRadius: BorderRadius.circular(AppRadius.m),
          boxShadow: onTap != null ? AppShadows.primaryGlow : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.m),
            splashColor: Colors.white.withOpacity(0.15),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

// ── LEONI logo — image asset avec fallback branded widget ────────────────────

class _LeoniLogo extends StatelessWidget {
  final double height;

  const _LeoniLogo({this.height = 28});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/leoni_logo.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _LeoniBadge(height: height),
    );
  }
}

// Branded LEONI badge — identique à l'identité visuelle officielle
class _LeoniBadge extends StatelessWidget {
  final double height;
  const _LeoniBadge({this.height = 28});

  @override
  Widget build(BuildContext context) {
    final fontSize = (height * 0.42).clamp(9.0, 16.0);
    final hPad = height * 0.35;
    final vPad = height * 0.18;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A3875), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        'LEONI',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: fontSize,
          letterSpacing: 1.8,
          height: 1.0,
        ),
      ),
    );
  }
}

// ── Subtle grid texture — platform feel ──────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF06B6D4).withOpacity(0.04)
      ..strokeWidth = 0.5;

    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height * 0.44), paint);
    }
    for (double y = 0; y < size.height * 0.44; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => false;
}
