import 'package:flutter/material.dart';

class AppColors {
  // الألوان الرئيسية - هادئة ومريحة للعيون
  static const Color primary = Color(0xFF1A73E8);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color primaryLight = Color(0xFF64B5F6);
  
  static const Color background = Color(0xFF0A0E1A);
  static const Color surface = Color(0xFF131929);
  static const Color surfaceLight = Color(0xFF1E2A3E);
  
  static const Color accent = Color(0xFF00E5CC);
  static const Color accentWarm = Color(0xFFFFB300);
  
  static const Color danger = Color(0xFFE53935);
  static const Color dangerLight = Color(0xFFEF9A9A);
  
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFA726);
  
  static const Color textPrimary = Color(0xFFE8EAF6);
  static const Color textSecondary = Color(0xFF90A4AE);
  static const Color textDisabled = Color(0xFF546E7A);
  
  static const Color eyeTrackActive = Color(0xFF00E5CC);
  static const Color eyeTrackInactive = Color(0xFF37474F);
  static const Color eyeTrackGlow = Color(0x4400E5CC);
}

class AppConstants {
  // إعدادات تتبع العين
  static const double defaultGazeDuration = 3.0; // ثواني للتأكيد
  static const double defaultBlinkThreshold = 0.25; // EAR للرمشة
  static const double defaultBlinkForce = 0.15; // EAR للرمشة القوية
  static const int blinkDetectionWindow = 500; // milliseconds
  
  // إعدادات الطوارئ
  static const String defaultEmergencyMessage = 'أحتاج مساعدة عاجلة! يرجى المجيء فوراً.';
  
  // مفاتيح التخزين
  static const String keyLanguage = 'language';
  static const String keyEmergencyContacts = 'emergency_contacts';
  static const String keyEmergencyMessage = 'emergency_message';
  static const String keyGazeDuration = 'gaze_duration';
  static const String keyShowSuggestions = 'show_suggestions';
  static const String keyFontSize = 'font_size';
  static const String keyBlinkThreshold = 'blink_threshold';
  static const String keyAdminPin = 'admin_pin';
  static const String keyVoiceGender = 'voice_gender';
  
  // الحروف العربية
  static const List<String> arabicLetters = [
    'ا', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د', 'ذ', 'ر',
    'ز', 'س', 'ش', 'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف',
    'ق', 'ك', 'ل', 'م', 'ن', 'ه', 'و', 'ي', 'ة', 'ء',
    'أ', 'إ', 'آ', 'ؤ', 'ئ', 'لا'
  ];
  
  // الحروف الإنجليزية
  static const List<String> englishLetters = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
    'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
    'U', 'V', 'W', 'X', 'Y', 'Z'
  ];
  
  // الرموز المشتركة
  static const List<String> symbols = [
    '،', '.', '؟', '!', ' ', '⌫'
  ];
  
  // جمل سريعة مشتركة
  static const List<Map<String, String>> quickPhrases = [
    {'ar': 'أحتاج مساعدة', 'en': 'I need help'},
    {'ar': 'أنا بخير', 'en': 'I am fine'},
    {'ar': 'أريد الماء', 'en': 'I want water'},
    {'ar': 'أريد الطعام', 'en': 'I want food'},
    {'ar': 'أشعر بألم', 'en': 'I feel pain'},
    {'ar': 'شكراً', 'en': 'Thank you'},
    {'ar': 'نعم', 'en': 'Yes'},
    {'ar': 'لا', 'en': 'No'},
    {'ar': 'أريد الراحة', 'en': 'I want to rest'},
    {'ar': 'اتصل بالطوارئ', 'en': 'Call emergency'},
  ];
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      fontFamily: 'Cairo',
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo'),
        bodyLarge: TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo'),
        bodyMedium: TextStyle(color: AppColors.textSecondary, fontFamily: 'Cairo'),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
    );
  }
}
