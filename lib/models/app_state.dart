import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

enum AppLanguage { arabic, english }
enum EmotionState { neutral, happy, anxious, tired, pain }

class EmergencyContact {
  final String name;
  final String phone;
  
  EmergencyContact({required this.name, required this.phone});
  
  Map<String, dynamic> toJson() => {'name': name, 'phone': phone};
  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      EmergencyContact(name: json['name'], phone: json['phone']);
}

class EyeMetrics {
  final double earLeft;
  final double earRight;
  final double blinkRate; // رمشات في الدقيقة
  final bool isAnxious;
  final DateTime timestamp;
  
  EyeMetrics({
    required this.earLeft,
    required this.earRight,
    required this.blinkRate,
    required this.isAnxious,
    required this.timestamp,
  });
}

class AppState extends ChangeNotifier {
  // اللغة
  AppLanguage _language = AppLanguage.arabic;
  AppLanguage get language => _language;
  bool get isArabic => _language == AppLanguage.arabic;
  
  // النص المكتوب
  String _currentText = '';
  String get currentText => _currentText;
  
  // الكلمة الحالية
  String _currentWord = '';
  String get currentWord => _currentWord;
  
  // الاقتراحات
  List<String> _suggestions = [];
  List<String> get suggestions => _suggestions;
  bool _showSuggestions = true;
  bool get showSuggestions => _showSuggestions;
  
  // الحرف المحدد حالياً (للتحديد البصري)
  String? _highlightedLetter;
  String? get highlightedLetter => _highlightedLetter;
  double _gazeProgress = 0.0;
  double get gazeProgress => _gazeProgress;
  
  // الكاميرا والتتبع
  bool _isCameraActive = false;
  bool get isCameraActive => _isCameraActive;
  bool _isEyeTrackingActive = false;
  bool get isEyeTrackingActive => _isEyeTrackingActive;
  
  // مقاييس العين
  EyeMetrics? _eyeMetrics;
  EyeMetrics? get eyeMetrics => _eyeMetrics;
  EmotionState _emotionState = EmotionState.neutral;
  EmotionState get emotionState => _emotionState;
  
  // إعدادات
  double _gazeDuration = AppConstants.defaultGazeDuration;
  double get gazeDuration => _gazeDuration;
  double _fontSize = 18.0;
  double get fontSize => _fontSize;
  double _blinkThreshold = AppConstants.defaultBlinkThreshold;
  double get blinkThreshold => _blinkThreshold;
  
  // جهات الطوارئ
  List<EmergencyContact> _emergencyContacts = [];
  List<EmergencyContact> get emergencyContacts => _emergencyContacts;
  String _emergencyMessage = AppConstants.defaultEmergencyMessage;
  String get emergencyMessage => _emergencyMessage;
  
  // وضع الجمل السريعة
  bool _showQuickPhrases = false;
  bool get showQuickPhrases => _showQuickPhrases;
  
  // PIN المشرف
  String _adminPin = '1234';
  String get adminPin => _adminPin;
  
  // تحميل الإعدادات
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    _language = prefs.getString(AppConstants.keyLanguage) == 'english'
        ? AppLanguage.english
        : AppLanguage.arabic;
    _showSuggestions = prefs.getBool(AppConstants.keyShowSuggestions) ?? true;
    _fontSize = prefs.getDouble(AppConstants.keyFontSize) ?? 18.0;
    _gazeDuration = prefs.getDouble(AppConstants.keyGazeDuration) ?? AppConstants.defaultGazeDuration;
    _blinkThreshold = prefs.getDouble(AppConstants.keyBlinkThreshold) ?? AppConstants.defaultBlinkThreshold;
    _emergencyMessage = prefs.getString(AppConstants.keyEmergencyMessage) ?? AppConstants.defaultEmergencyMessage;
    _adminPin = prefs.getString(AppConstants.keyAdminPin) ?? '1234';
    
    final contactsJson = prefs.getString(AppConstants.keyEmergencyContacts);
    if (contactsJson != null) {
      final List decoded = jsonDecode(contactsJson);
      _emergencyContacts = decoded.map((e) => EmergencyContact.fromJson(e)).toList();
    }
    
    notifyListeners();
  }
  
  // حفظ الإعدادات
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyLanguage, _language == AppLanguage.arabic ? 'arabic' : 'english');
    await prefs.setBool(AppConstants.keyShowSuggestions, _showSuggestions);
    await prefs.setDouble(AppConstants.keyFontSize, _fontSize);
    await prefs.setDouble(AppConstants.keyGazeDuration, _gazeDuration);
    await prefs.setDouble(AppConstants.keyBlinkThreshold, _blinkThreshold);
    await prefs.setString(AppConstants.keyEmergencyMessage, _emergencyMessage);
    await prefs.setString(AppConstants.keyAdminPin, _adminPin);
    await prefs.setString(
      AppConstants.keyEmergencyContacts,
      jsonEncode(_emergencyContacts.map((e) => e.toJson()).toList()),
    );
  }
  
  // تبديل اللغة
  void toggleLanguage() {
    _language = _language == AppLanguage.arabic ? AppLanguage.english : AppLanguage.arabic;
    saveSettings();
    notifyListeners();
  }
  
  // إضافة حرف
  void addLetter(String letter) {
    if (letter == '⌫') {
      deleteLast();
      return;
    }
    _currentText += letter;
    _updateCurrentWord(letter);
    notifyListeners();
  }
  
  // حذف آخر حرف
  void deleteLast() {
    if (_currentText.isNotEmpty) {
      _currentText = _currentText.substring(0, _currentText.length - 1);
      _updateCurrentWordFromText();
      notifyListeners();
    }
  }
  
  // مسح كل شيء
  void clearText() {
    _currentText = '';
    _currentWord = '';
    _suggestions = [];
    notifyListeners();
  }
  
  void _updateCurrentWord(String letter) {
    if (letter == ' ' || letter == '،' || letter == '.') {
      _currentWord = '';
    } else {
      _currentWord += letter;
    }
  }
  
  void _updateCurrentWordFromText() {
    final words = _currentText.split(RegExp(r'[\s،.]'));
    _currentWord = words.isNotEmpty ? words.last : '';
  }
  
  // تحديث الاقتراحات
  void updateSuggestions(List<String> suggestions) {
    _suggestions = suggestions;
    notifyListeners();
  }
  
  // إضافة اقتراح
  void acceptSuggestion(String word) {
    if (_currentWord.isNotEmpty) {
      _currentText = _currentText.substring(0, _currentText.length - _currentWord.length) + word + ' ';
    } else {
      _currentText += word + ' ';
    }
    _currentWord = '';
    _suggestions = [];
    notifyListeners();
  }
  
  // تحديث الحرف المحدد
  void setHighlightedLetter(String? letter, double progress) {
    _highlightedLetter = letter;
    _gazeProgress = progress;
    notifyListeners();
  }
  
  // تحديث مقاييس العين
  void updateEyeMetrics(EyeMetrics metrics) {
    _eyeMetrics = metrics;
    // تحديد حالة التوتر: أكثر من 25 رمشة في الدقيقة
    if (metrics.blinkRate > 25) {
      _emotionState = EmotionState.anxious;
    } else if (metrics.blinkRate < 8) {
      _emotionState = EmotionState.tired;
    } else {
      _emotionState = EmotionState.neutral;
    }
    notifyListeners();
  }
  
  // تشغيل/إيقاف الكاميرا
  void setCameraActive(bool active) {
    _isCameraActive = active;
    notifyListeners();
  }
  
  void setEyeTrackingActive(bool active) {
    _isEyeTrackingActive = active;
    notifyListeners();
  }
  
  // تبديل الجمل السريعة
  void toggleQuickPhrases() {
    _showQuickPhrases = !_showQuickPhrases;
    notifyListeners();
  }
  
  // تبديل الاقتراحات
  void toggleSuggestions() {
    _showSuggestions = !_showSuggestions;
    saveSettings();
    notifyListeners();
  }
  
  // تحديث إعدادات المشرف
  void updateGazeDuration(double duration) {
    _gazeDuration = duration;
    saveSettings();
    notifyListeners();
  }
  
  void updateFontSize(double size) {
    _fontSize = size;
    saveSettings();
    notifyListeners();
  }
  
  void updateBlinkThreshold(double threshold) {
    _blinkThreshold = threshold;
    saveSettings();
    notifyListeners();
  }
  
  void updateEmergencyMessage(String message) {
    _emergencyMessage = message;
    saveSettings();
    notifyListeners();
  }
  
  void addEmergencyContact(EmergencyContact contact) {
    _emergencyContacts.add(contact);
    saveSettings();
    notifyListeners();
  }
  
  void removeEmergencyContact(int index) {
    _emergencyContacts.removeAt(index);
    saveSettings();
    notifyListeners();
  }
  
  void updateAdminPin(String pin) {
    _adminPin = pin;
    saveSettings();
    notifyListeners();
  }
  
  void updateLanguage(AppLanguage lang) {
    _language = lang;
    saveSettings();
    notifyListeners();
  }
}
