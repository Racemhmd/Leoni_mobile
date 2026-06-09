import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../theme/design_system.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String matricule;
  const ResetPasswordScreen({super.key, required this.matricule});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _codeController         = TextEditingController();
  final _newPasswordController  = TextEditingController();
  final _confirmController      = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm  = true;

  @override
  void dispose() {
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submitReset() async {
    if (_codeController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmController.text.isEmpty) {
      _showSnack('Tous les champs sont requis', isError: true);
      return;
    }
    if (_newPasswordController.text != _confirmController.text) {
      _showSnack('Les mots de passe ne correspondent pas', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _apiService.resetPassword(
        widget.matricule,
        _codeController.text.trim(),
        _newPasswordController.text,
        _confirmController.text,
      );

      if (!mounted) return;
      _showSnack(response['message'] ?? 'Mot de passe réinitialisé avec succès');
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: AppTypography.bodySmall.copyWith(color: Colors.white)),
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
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppGradients.entry),
            ),
          ),
          Positioned(
            left: -50, top: 60,
            child: Container(
              width: 220, height: 220,
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
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.l, AppSpacing.m, AppSpacing.l, AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      Text('Nouveau\nmot de passe',
                          style: AppTypography.displayHero
                              .copyWith(fontSize: 38, height: 1.1)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Entrez le code reçu par email et choisissez un nouveau mot de passe.',
                        style: AppTypography.bodySmall
                            .copyWith(color: Colors.white.withOpacity(0.45)),
                      ),
                    ],
                  ).animate().fadeIn(duration: 500.ms),
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
                            Text('Code de vérification',
                                style: AppTypography.headerMedium),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.l),

                        // 6-digit code field
                        TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: AppTypography.amountLarge.copyWith(
                            fontSize: 28,
                            color: AppColors.textPrimary,
                            letterSpacing: 12,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Code à 6 chiffres',
                            counterText: '',
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.m),
                              borderSide: BorderSide(
                                  color: AppColors.primary, width: 2),
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
                            Text('Nouveau mot de passe',
                                style: AppTypography.headerMedium),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.m),

                        // New password
                        TextField(
                          controller: _newPasswordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Nouveau mot de passe',
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
                        const SizedBox(height: AppSpacing.m),

                        // Confirm password
                        TextField(
                          controller: _confirmController,
                          obscureText: _obscureConfirm,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submitReset(),
                          decoration: InputDecoration(
                            labelText: 'Confirmer le mot de passe',
                            prefixIcon: const Icon(
                                Icons.lock_reset_outlined, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.m),

                        // Password requirements hint
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius:
                                BorderRadius.circular(AppRadius.s),
                            border: Border.all(
                                color:
                                    AppColors.primary.withOpacity(0.25)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline,
                                  size: 14,
                                  color: AppColors.primary),
                              const SizedBox(width: AppSpacing.s),
                              Expanded(
                                child: Text(
                                  'Minimum 8 caractères, avec des lettres et des chiffres.',
                                  style: AppTypography.caption.copyWith(
                                      color: AppColors.primaryDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        _PlatformButton(
                          onTap: _isLoading ? null : _submitReset,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5))
                              : Text('Mettre à jour le mot de passe',
                                  style: AppTypography.button),
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
