import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../theme/design_system.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _matriculeController = TextEditingController();
  final _emailController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;

  @override
  void dispose() {
    _matriculeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (_matriculeController.text.isEmpty || _emailController.text.isEmpty) {
      _showSnack('Veuillez remplir tous les champs', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _apiService.forgotPassword(
        _matriculeController.text.trim(),
        _emailController.text.trim(),
      );

      if (!mounted) return;
      _showSnack(
          response['message'] ?? 'Si les informations sont correctes, un code a été envoyé.');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              ResetPasswordScreen(matricule: _matriculeController.text.trim()),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: AppTypography.bodySmall.copyWith(color: Colors.white)),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      body: Stack(
        children: [
          // Background gradient
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppGradients.entry),
            ),
          ),
          // Cyan radial glow
          Positioned(
            right: -50, top: 40,
            child: Container(
              width: 240, height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primary.withOpacity(0.15),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Column(
            children: [
              // Dark hero panel
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.l, AppSpacing.m, AppSpacing.l, AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              Colors.white.withOpacity(0.08),
                          padding: const EdgeInsets.all(10),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'LEONI GROUP',
                        style: AppTypography.labelBright
                            .copyWith(fontSize: 9, letterSpacing: 4.0),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Récupération\nde compte',
                          style: AppTypography.displayHero
                              .copyWith(fontSize: 38, height: 1.1)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Entrez votre matricule et email personnel.',
                        style: AppTypography.bodySmall
                            .copyWith(color: Colors.white.withOpacity(0.45)),
                      ),
                    ],
                  ).animate().fadeIn(duration: 500.ms).slideY(
                      begin: 0.05, end: 0, duration: 450.ms),
                ),
              ),

              // White form card
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
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.l,
                        AppSpacing.l, AppSpacing.l, AppSpacing.xxl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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

                        Row(
                          children: [
                            Container(
                              width: 3, height: 20,
                              decoration: BoxDecoration(
                                gradient: AppGradients.brand,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text('Vérification d\'identité',
                                style: AppTypography.headerMedium),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Utilisez l\'email enregistré dans votre profil.',
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

                        // Email
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submitRequest(),
                          decoration: const InputDecoration(
                            labelText: 'Email personnel',
                            hintText: 'votre.email@gmail.com',
                            prefixIcon:
                                Icon(Icons.email_outlined, size: 20),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Submit button
                        _PlatformButton(
                          onTap: _isLoading ? null : _submitRequest,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5))
                              : Text('Envoyer le code',
                                  style: AppTypography.button),
                        ),

                        const SizedBox(height: AppSpacing.l),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline,
                                size: 14,
                                color: AppColors.textSecondary
                                    .withOpacity(0.5)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Contactez l\'admin RH pour mettre à jour votre email.',
                                style: AppTypography.caption
                                    .copyWith(
                                        color: AppColors.textSecondary
                                            .withOpacity(0.55)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ).animate().slideY(
                    begin: 0.12, end: 0,
                    delay: 150.ms, duration: 450.ms,
                    curve: Curves.easeOutCubic),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
