import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_service.dart';

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (email != null && email.isNotEmpty) {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await FirebaseService.saveFcmToken(userEmail: email, token: token);
      }
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      final current = FirebaseAuth.instance.currentUser;
      final currentEmail = current?.email;
      if (currentEmail == null || currentEmail.isEmpty) return;
      await FirebaseService.saveFcmToken(userEmail: currentEmail, token: token);
    });
  }
}
