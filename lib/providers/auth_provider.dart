import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../services/fcm_service.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _role;
  bool _hasSeenOnboarding = false;
  bool _isLoadingSession = true;

  String? get token => _token;
  String? get role => _role;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  bool get isLoadingSession => _isLoadingSession;
  bool get isAuthenticated => _token != null && _role != null;
  bool get isMerchant => _role == 'merchant';

  Future<void> loadSession({bool syncFcm = false}) async {
    if (!_isLoadingSession) {
      _isLoadingSession = true;
      notifyListeners();
    }

    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _role = prefs.getString('role');
    _hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    _isLoadingSession = false;
    notifyListeners();

    if (syncFcm && isAuthenticated) {
      unawaited(FcmService.syncToken());
    }
  }

  Future<void> refreshAfterLogin() async {
    await loadSession(syncFcm: true);
  }

  Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    _hasSeenOnboarding = true;
    notifyListeners();
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    _token = null;
    _role = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await ApiService().logout();
    await clearSession();
  }
}
