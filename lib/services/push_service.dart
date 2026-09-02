import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة إشعارات Push (Firebase Cloud Messaging)
///
/// الميزة الأصلية الأهم لقبول آبل: التطبيق يستقبل تحديثات الطلب والشحنة
/// حتى وهو مغلق. عند الضغط على الإشعار يُفتح الرابط المرفق داخل التطبيق.
///
/// الرسالة من السيرفر تحمل حقل data `url` (مثال: https://tajership.com/track?awb=...).
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  /// يُستدعى عندما يضغط المستخدم إشعاراً يحمل رابطاً
  final StreamController<String> _openUrl = StreamController<String>.broadcast();
  Stream<String> get onOpenUrl => _openUrl.stream;

  String? _token;
  String? get token => _token;

  bool _ready = false;

  /// تهيئة Firebase وطلب الإذن وتسجيل المستمعين
  Future<void> init() async {
    if (_ready) return;
    try {
      await Firebase.initializeApp();
      final fm = FirebaseMessaging.instance;

      // iOS: طلب إذن الإشعارات (يظهر مرة واحدة للمستخدم)
      await fm.requestPermission(alert: true, badge: true, sound: true);

      // عرض الإشعار حتى والتطبيق مفتوح (iOS)
      await fm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _token = await fm.getToken();
      await _persistToken(_token);
      fm.onTokenRefresh.listen((t) {
        _token = t;
        _persistToken(t);
      });

      // إشعار ضُغط والتطبيق بالخلفية
      FirebaseMessaging.onMessageOpenedApp.listen(_handleOpened);

      // إشعار فتح التطبيق من الإغلاق التام
      final initial = await fm.getInitialMessage();
      if (initial != null) _handleOpened(initial);

      _ready = true;
    } catch (e) {
      // Firebase غير مهيأ (مثلاً قبل إضافة ملفات الإعداد) — التطبيق يعمل بدون Push
      debugPrint('PushService init skipped: $e');
    }
  }

  void _handleOpened(RemoteMessage m) {
    final url = m.data['url'];
    if (url is String && url.startsWith('http')) {
      _openUrl.add(url);
    }
  }

  Future<void> _persistToken(String? t) async {
    if (t == null) return;
    final p = await SharedPreferences.getInstance();
    await p.setString('fcm_token', t);
  }
}
