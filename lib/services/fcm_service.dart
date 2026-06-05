import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class FcmService {
  static const String _webVapidKey = String.fromEnvironment(
    'FIREBASE_WEB_VAPID_KEY',
  );

  static Future<String?> requestToken() async {
    if (kIsWeb && _webVapidKey.isEmpty) {
      debugPrint(
        'FCM web belum aktif: jalankan Chrome dengan '
        '--dart-define=FIREBASE_WEB_VAPID_KEY=VAPID_KEY_KAMU',
      );
      return null;
    }

    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final isAllowed =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (!isAllowed) {
      debugPrint('FCM permission ditolak.');
      return null;
    }

    if (kIsWeb) {
      return messaging.getToken(vapidKey: _webVapidKey);
    }

    return messaging.getToken();
  }

  static Future<void> syncToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('token');
      if (authToken == null || authToken.isEmpty) {
        return;
      }

      final fcmToken = await requestToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        return;
      }

      debugPrint('FCM TOKEN DEVICE INI: $fcmToken');
      await ApiService().updateFcmToken(fcmToken);
    } catch (e) {
      debugPrint('Gagal setup FCM: $e');
    }
  }
}
