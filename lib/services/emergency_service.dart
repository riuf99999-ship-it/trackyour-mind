import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_state.dart';
import 'audio_service.dart';

class EmergencyService {
  static final EmergencyService _instance = EmergencyService._internal();
  factory EmergencyService() => _instance;
  EmergencyService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isEmergencyActive = false;
  bool get isEmergencyActive => _isEmergencyActive;

  Future<void> initialize() async {
    const initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(iOS: initSettingsIOS);
    await _notifications.initialize(initSettings);
  }

  // تفعيل الطوارئ
  Future<void> triggerEmergency({
    required List<EmergencyContact> contacts,
    required String message,
    required bool isArabic,
  }) async {
    if (_isEmergencyActive) return;
    _isEmergencyActive = true;

    // 1. تشغيل صوت الطوارئ
    await AudioService().playEmergencyAlert();

    // 2. إشعار محلي
    await _showEmergencyNotification(message, isArabic);

    // 3. إرسال رسائل SMS لجهات الطوارئ
    for (final contact in contacts) {
      await _sendSMS(contact.phone, message);
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> _showEmergencyNotification(String message, bool isArabic) async {
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );
    
    const details = NotificationDetails(iOS: iosDetails);
    
    await _notifications.show(
      999,
      isArabic ? '🚨 طوارئ - EyeSpeak' : '🚨 Emergency - EyeSpeak',
      message,
      details,
    );
  }

  Future<void> _sendSMS(String phone, String message) async {
    try {
      final smsUri = Uri(
        scheme: 'sms',
        path: phone,
        queryParameters: {'body': message},
      );
      
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      }
    } catch (e) {
      debugPrint('SMS error: $e');
    }
  }

  // إلغاء الطوارئ
  Future<void> cancelEmergency() async {
    _isEmergencyActive = false;
    await AudioService().stopEmergencyAlert();
    await _notifications.cancel(999);
  }

  // اتصال طوارئ مباشر
  Future<void> callContact(String phone) async {
    final callUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    }
  }
}
