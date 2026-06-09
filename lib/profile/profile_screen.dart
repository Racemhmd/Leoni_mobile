import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../services/points_service.dart';
import '../services/biometric_service.dart';
import '../providers/user_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';
import '../auth/login_screen.dart';
import '../theme/design_system.dart';
import '../utils/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _apiService = ApiService();
  final _pointsService = PointsService();
  final _biometricService = BiometricService();
  final _storage = const FlutterSecureStorage();
  final _picker = ImagePicker();

  bool _isLoading = true;
  bool _isUploadingPhoto = false;
  String _fullName = '';
  String _matricule = '';
  String _role = '';
  String _personalEmail = '';
  String _phoneNumber = '';
  String? _avatarUrl;

  double _totalGained = 0;
  double _totalLost = 0;
  double _balance = 0;

  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _notifPushPoints = true;
  bool _notifPushLiquidation = true;
  bool _notifSmsPoints = false;
  bool _notifSmsLiquidation = false;
  bool _keepPointsAtLiquidation = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final userData = await _apiService.get('/auth/me');
      if (mounted) {
        setState(() {
          _fullName = userData['fullName'] ?? userData['full_name'] ?? 'Employé';
          _matricule = userData['matricule'] ?? '';
          final roleName = userData['role'] is Map
              ? userData['role']['name']
              : userData['role'];
          _role = roleName ?? '';
          _personalEmail = userData['personalEmail'] ?? '';
          _phoneNumber = userData['phoneNumber'] ?? '';
          _avatarUrl = userData['avatarUrl'] as String?;
          _notifPushPoints = userData['notifPushPoints'] ?? true;
          _notifPushLiquidation = userData['notifPushLiquidation'] ?? true;
          _notifSmsPoints = userData['notifSmsPoints'] ?? false;
          _notifSmsLiquidation = userData['notifSmsLiquidation'] ?? false;
          _keepPointsAtLiquidation = userData['keepPointsAtLiquidation'] ?? false;
        });
      }

      if (_role == 'EMPLOYEE' || _role == 'OPERATOR') {
        final summary = await _pointsService.getSummary();
        if (mounted) {
          setState(() {
            _balance = (summary['balance'] as num?)?.toDouble() ?? 0;
            _totalGained =
                (summary['totalGainedYearly'] as num?)?.toDouble() ?? 0;
            _totalLost =
                (summary['totalLostYearly'] as num?)?.toDouble() ?? 0;
          });
        }
      }

      final available = await _biometricService.isAvailable();
      final enabled = await _biometricService.isEnabled();
      if (mounted) {
        setState(() {
          _biometricAvailable = available;
          _biometricEnabled = enabled;
        });
      }
    } catch (e) {
      debugPrint('Profile load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Photo management ────────────────────────────────────────────────────────

  Future<void> _showPhotoOptions() async {
    final l = AppLocalizations.of(context);
    HapticFeedback.lightImpact();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.bottomSheet,
        ),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.l,
          AppSpacing.m,
          AppSpacing.l,
          AppSpacing.l + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            _PhotoOption(
              icon: Icons.camera_alt_outlined,
              label: l.t('takePhoto'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            const Divider(height: 1),
            _PhotoOption(
              icon: Icons.photo_library_outlined,
              label: l.t('chooseGallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_avatarUrl != null) ...[
              const Divider(height: 1),
              _PhotoOption(
                icon: Icons.delete_outline,
                label: l.t('deletePhoto'),
                color: AppColors.error,
                onTap: () {
                  Navigator.pop(ctx);
                  _deletePhoto();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      // Crop to square
      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 85,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Recadrer',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
          ),
          IOSUiSettings(title: 'Recadrer', aspectRatioLockEnabled: true),
        ],
      );
      if (cropped == null) return;

      // Compress to max 500 KB
      final compressed = await FlutterImageCompress.compressWithFile(
        cropped.path,
        minWidth: 400,
        minHeight: 400,
        quality: 85,
        format: CompressFormat.jpeg,
      );
      if (compressed == null) return;

      // Write compressed bytes to temp file
      final tmpPath = '${cropped.path}_compressed.jpg';
      await File(tmpPath).writeAsBytes(compressed);

      await _uploadPhoto(File(tmpPath));
    } catch (e) {
      _showSnack('Erreur: ${e.toString()}', isError: true);
    }
  }

  Future<void> _uploadPhoto(File file) async {
    setState(() => _isUploadingPhoto = true);
    try {
      final res = await _apiService.uploadFile('/users/me/photo', file,
          method: 'PUT', fieldName: 'photo');
      final url = res['avatarUrl'] as String?;
      if (mounted) {
        setState(() => _avatarUrl = url);
        context.read<UserProvider>().updateAvatar(url);
        _showSnack(AppLocalizations.of(context).t('photoUpdated'));
      }
    } catch (e) {
      _showSnack('Erreur upload: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _deletePhoto() async {
    try {
      await _apiService.delete('/users/me/photo');
      if (mounted) {
        setState(() => _avatarUrl = null);
        context.read<UserProvider>().updateAvatar(null);
        _showSnack('Photo supprimée');
      }
    } catch (e) {
      _showSnack('Erreur: $e', isError: true);
    }
  }

  // ── Auth / prefs ─────────────────────────────────────────────────────────

  Future<void> _logout() async {
    context.read<UserProvider>().clear();
    await _apiService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final ok = await _biometricService.authenticate(
        reason: 'Confirmez votre identité pour activer la biométrie',
      );
      if (!ok) return;
      await _biometricService.enable();
    } else {
      await _biometricService.disable();
    }
    if (mounted) setState(() => _biometricEnabled = value);
  }

  Future<void> _updateNotifPrefs({
    bool? pushPoints,
    bool? pushLiquidation,
    bool? smsPoints,
    bool? smsLiquidation,
  }) async {
    final body = <String, bool>{};
    if (pushPoints != null) body['notifPushPoints'] = pushPoints;
    if (pushLiquidation != null) body['notifPushLiquidation'] = pushLiquidation;
    if (smsPoints != null) body['notifSmsPoints'] = smsPoints;
    if (smsLiquidation != null) body['notifSmsLiquidation'] = smsLiquidation;
    try {
      await _apiService.patch('/users/me/notification-prefs', body);
    } catch (_) {
      _showSnack(AppLocalizations.of(context).t('errorSaving'), isError: true);
    }
  }

  Future<void> _toggleKeepPoints(bool value) async {
    setState(() => _keepPointsAtLiquidation = value);
    try {
      await _apiService.patch(
        '/users/me/liquidation-preference',
        {'keepPointsAtLiquidation': value},
      );
    } catch (_) {
      setState(() => _keepPointsAtLiquidation = !value);
      _showSnack(AppLocalizations.of(context).t('errorSaving'), isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
    ));
  }

  Future<void> _showUpdateEmailDialog() async {
    final controller = TextEditingController(text: _personalEmail);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).t('recoveryEmail')),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email', hintText: 'user@gmail.com'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).t('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _apiService.patch(
                    '/users/me/recovery-email', {'email': controller.text.trim()});
                if (mounted) {
                  setState(() => _personalEmail = controller.text.trim());
                  Navigator.pop(context);
                }
              } catch (e) {
                _showSnack(e.toString().replaceAll('Exception: ', ''), isError: true);
              }
            },
            child: Text(AppLocalizations.of(context).t('save')),
          ),
        ],
      ),
    );
  }

  Future<void> _showUpdatePhoneDialog() async {
    final controller = TextEditingController(text: _phoneNumber);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).t('smsNumber')),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(hintText: '+21698765432'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).t('cancel'))),
          ElevatedButton(
            onPressed: () async {
              try {
                await _apiService.patch(
                    '/users/me/phone', {'phoneNumber': controller.text.trim()});
                if (mounted) {
                  setState(() => _phoneNumber = controller.text.trim());
                  Navigator.pop(context);
                }
              } catch (e) {
                _showSnack(e.toString().replaceAll('Exception: ', ''), isError: true);
              }
            },
            child: Text(AppLocalizations.of(context).t('save')),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker() {
    final localeProvider = context.read<LocaleProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.bottomSheet,
        ),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.l, AppSpacing.m, AppSpacing.l, AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            ...LocaleProvider.supportedLocales.map((loc) {
              final label = LocaleProvider.languageLabels[loc.languageCode]!;
              final selected =
                  localeProvider.locale.languageCode == loc.languageCode;
              return ListTile(
                title: Text(label),
                trailing: selected
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  localeProvider.setLocale(loc.languageCode);
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: AppSpacing.s),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l.t('myProfile'), style: AppTypography.headerMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                children: [
                  _buildAvatarSection(l),
                  const SizedBox(height: AppSpacing.m),

                  if (_role == 'EMPLOYEE' || _role == 'OPERATOR') ...[
                    const SizedBox(height: AppSpacing.l),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(l.t('annualStats'), style: AppTypography.label),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Row(
                      children: [
                        Expanded(
                            child: _buildStatCard(
                                l.t('earned'),
                                '+${_totalGained.toStringAsFixed(1)}',
                                AppColors.success)),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                            child: _buildStatCard(
                                l.t('lost'),
                                '-${_totalLost.toStringAsFixed(1)}',
                                AppColors.error)),
                      ],
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xl),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(l.t('settings'), style: AppTypography.label),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  _buildSettingsCard(l),

                  const SizedBox(height: AppSpacing.xxl),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.errorLight,
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _logout,
                      child: Text(l.t('logout')),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAvatarSection(AppLocalizations l) {
    final baseUrl = AppConstants.baseUrl.replaceAll('/api', '');
    final fullAvatarUrl = _avatarUrl != null
        ? (_avatarUrl!.startsWith('http') ? _avatarUrl! : '$baseUrl$_avatarUrl')
        : null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              // Avatar
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.1),
                ),
                child: _isUploadingPhoto
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : ClipOval(
                        child: fullAvatarUrl != null
                            ? CachedNetworkImage(
                                imageUrl: fullAvatarUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const CircularProgressIndicator(strokeWidth: 2),
                                errorWidget: (_, __, ___) => _AvatarInitials(name: _fullName),
                              )
                            : _AvatarInitials(name: _fullName),
                      ),
              ),
              // Camera button
              GestureDetector(
                onTap: _isUploadingPhoto ? null : _showPhotoOptions,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt,
                      color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Text(_fullName, style: AppTypography.headerSmall),
          const SizedBox(height: 2),
          Text('Matricule: $_matricule',
              style: AppTypography.bodySmall),
          const SizedBox(height: AppSpacing.s),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              _role,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(AppLocalizations l) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          if (_biometricAvailable) ...[
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint, color: AppColors.primary),
              title: Text(l.t('biometricLogin'), style: AppTypography.bodyMedium),
              subtitle: Text(l.t('biometricSub'),
                  style: const TextStyle(fontSize: 12)),
              value: _biometricEnabled,
              activeColor: AppColors.primary,
              onChanged: _toggleBiometric,
            ),
            const Divider(height: 1),
          ],

          _buildSectionHeader(
              Icons.notifications_outlined, l.t('pushNotif')),
          SwitchListTile(
            title: Text(l.t('pointsNotif'), style: AppTypography.bodyMedium),
            value: _notifPushPoints,
            activeColor: AppColors.primary,
            contentPadding: const EdgeInsets.only(left: 32, right: 16),
            onChanged: (val) {
              setState(() => _notifPushPoints = val);
              _updateNotifPrefs(pushPoints: val);
            },
          ),
          SwitchListTile(
            title: Text(l.t('liquidationReminder'),
                style: AppTypography.bodyMedium),
            value: _notifPushLiquidation,
            activeColor: AppColors.primary,
            contentPadding: const EdgeInsets.only(left: 32, right: 16),
            onChanged: (val) {
              setState(() => _notifPushLiquidation = val);
              _updateNotifPrefs(pushLiquidation: val);
            },
          ),
          const Divider(height: 1),

          _buildSectionHeader(Icons.sms_outlined, l.t('smsNotif')),
          SwitchListTile(
            title: Text(l.t('pointsNotif'), style: AppTypography.bodyMedium),
            value: _notifSmsPoints,
            activeColor: AppColors.primary,
            contentPadding: const EdgeInsets.only(left: 32, right: 16),
            onChanged: (val) {
              if (val && _phoneNumber.isEmpty) {
                _showUpdatePhoneDialog();
                return;
              }
              setState(() => _notifSmsPoints = val);
              _updateNotifPrefs(smsPoints: val);
            },
          ),
          SwitchListTile(
            title: Text(l.t('liquidationReminder'),
                style: AppTypography.bodyMedium),
            value: _notifSmsLiquidation,
            activeColor: AppColors.primary,
            contentPadding: const EdgeInsets.only(left: 32, right: 16),
            onChanged: (val) {
              if (val && _phoneNumber.isEmpty) {
                _showUpdatePhoneDialog();
                return;
              }
              setState(() => _notifSmsLiquidation = val);
              _updateNotifPrefs(smsLiquidation: val);
            },
          ),
          ListTile(
            contentPadding: const EdgeInsets.only(left: 32, right: 16),
            leading: const Icon(Icons.phone_outlined,
                size: 20, color: AppColors.textSecondary),
            title: Text(l.t('smsNumber'), style: AppTypography.bodyMedium),
            subtitle: Text(
              _phoneNumber.isEmpty ? l.t('notDefined') : _phoneNumber,
              style: AppTypography.bodySmall.copyWith(
                color: _phoneNumber.isEmpty
                    ? AppColors.error
                    : AppColors.textSecondary,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showUpdatePhoneDialog,
          ),
          const Divider(height: 1),

          _buildSectionHeader(Icons.savings_outlined, 'Liquidation'),
          SwitchListTile(
            secondary: const Icon(Icons.savings_outlined, color: AppColors.primary),
            title: const Text('Garder mes points'),
            subtitle: const Text(
              'Conserver mes points lors de la liquidation trimestrielle au lieu de les convertir en DT.',
              style: TextStyle(fontSize: 12),
            ),
            value: _keepPointsAtLiquidation,
            activeColor: AppColors.primary,
            onChanged: _toggleKeepPoints,
          ),
          const Divider(height: 1),

          // Language
          ListTile(
            leading: const Icon(Icons.language_outlined,
                color: AppColors.primary, size: 20),
            title: Text(l.t('language'), style: AppTypography.bodyMedium),
            subtitle: Text(
              LocaleProvider.languageLabels[
                      context.watch<LocaleProvider>().locale.languageCode] ??
                  'Français',
              style: AppTypography.bodySmall,
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showLanguagePicker,
          ),
          const Divider(height: 1),

          ListTile(
            title: Text(l.t('changePassword'),
                style: AppTypography.bodyMedium),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          const Divider(height: 1),
          ListTile(
            title: Text(l.t('recoveryEmail'),
                style: AppTypography.bodyMedium),
            subtitle: Text(
              _personalEmail.isEmpty
                  ? l.t('notDefined')
                  : _personalEmail,
              style: AppTypography.bodySmall,
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showUpdateEmailDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(label,
              style: AppTypography.label
                  .copyWith(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          Text(label.toUpperCase(),
              style: AppTypography.label.copyWith(fontSize: 10)),
          const SizedBox(height: 8),
          Text(value,
              style: AppTypography.headerMedium.copyWith(color: color)),
        ],
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _AvatarInitials extends StatelessWidget {
  final String name;
  const _AvatarInitials({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Container(
      color: AppColors.primary.withOpacity(0.1),
      child: Center(
        child: Text(
          initials,
          style: AppTypography.headerLarge
              .copyWith(color: AppColors.primary, fontSize: 28),
        ),
      ),
    );
  }
}

class _PhotoOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _PhotoOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(label, style: TextStyle(color: c)),
      onTap: onTap,
    );
  }
}
