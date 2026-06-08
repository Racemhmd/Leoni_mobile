import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UserProvider extends ChangeNotifier {
  final _api = ApiService();

  String _id = '';
  String _fullName = '';
  String _matricule = '';
  String _role = '';
  String? _avatarUrl;
  bool _loaded = false;

  String get id => _id;
  String get fullName => _fullName;
  String get matricule => _matricule;
  String get role => _role;
  String? get avatarUrl => _avatarUrl;
  bool get loaded => _loaded;

  String get initials {
    final parts = _fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _fullName.isNotEmpty ? _fullName[0].toUpperCase() : 'U';
  }

  Future<void> loadProfile() async {
    try {
      final data = await _api.get('/auth/me');
      _id = data['id']?.toString() ?? '';
      _fullName = data['fullName'] ?? data['full_name'] ?? 'Employé';
      _matricule = data['matricule'] ?? '';
      final roleName = data['role'] is Map
          ? (data['role']['name'] as String? ?? '')
          : (data['role'] as String? ?? '');
      _role = roleName.trim().toUpperCase();
      _avatarUrl = data['avatarUrl'] as String?;
      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('UserProvider.loadProfile error: $e');
    }
  }

  void updateAvatar(String? url) {
    _avatarUrl = url;
    notifyListeners();
  }

  void clear() {
    _id = '';
    _fullName = '';
    _matricule = '';
    _role = '';
    _avatarUrl = null;
    _loaded = false;
    notifyListeners();
  }
}
