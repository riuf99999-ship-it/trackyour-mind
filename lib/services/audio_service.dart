import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // إعداد TTS
      await _tts.setLanguage('ar-SA'); // عربي افتراضي
      await _tts.setSpeechRate(0.5); // سرعة مناسبة
      await _tts.setVolume(1.0);
      await _tts.setPitch(0.9); // صوت رجل (أقل من 1.0)
      
      // iOS: اختيار صوت عربي
      final voices = await _tts.getVoices;
      if (voices != null) {
        final arabicVoice = (voices as List).firstWhere(
          (v) => v['locale']?.toString().startsWith('ar') == true && 
                 v['gender']?.toString() == 'male',
          orElse: () => null,
        );
        if (arabicVoice != null) {
          await _tts.setVoice({'name': arabicVoice['name'], 'locale': arabicVoice['locale']});
        }
      }
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('TTS init error: $e');
    }
  }

  // نطق النص
  Future<void> speak(String text, {bool isArabic = true}) async {
    await _tts.stop();
    
    try {
      if (isArabic) {
        await _tts.setLanguage('ar-SA');
        await _tts.setPitch(0.85);
      } else {
        await _tts.setLanguage('en-US');
        await _tts.setPitch(0.9);
      }
      
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  // إيقاف النطق
  Future<void> stop() async {
    await _tts.stop();
  }

  // صوت تأكيد الحرف (نقرة)
  Future<void> playLetterConfirm() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/confirm.mp3'));
    } catch (e) {
      // صوت افتراضي لو ما وجد الملف
      await _tts.speak('.');
    }
  }

  // صوت تقدم التحديد
  Future<void> playGazeTick() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/tick.mp3'));
    } catch (e) {
      debugPrint('Tick sound error: $e');
    }
  }

  // صوت الطوارئ (تنبيه قوي)
  Future<void> playEmergencyAlert() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/emergency.mp3'));
    } catch (e) {
      // إذا ما وجد الملف، استخدم TTS
      await _tts.setLanguage('ar-SA');
      await _tts.setPitch(1.2);
      await _tts.speak('طوارئ! طوارئ! هذا الشخص يحتاج مساعدة عاجلة!');
    }
  }

  Future<void> stopEmergencyAlert() async {
    await _audioPlayer.stop();
    await _tts.stop();
  }

  // صوت توتر المستخدم
  Future<void> speakAnxietyDetected() async {
    await _tts.setLanguage('ar-SA');
    await _tts.speak('تم اكتشاف توتر. هل تحتاج مساعدة؟');
  }

  Future<void> dispose() async {
    await _tts.stop();
    await _audioPlayer.dispose();
  }
}
