import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/app_state.dart';
import '../services/audio_service.dart';
import '../services/emergency_service.dart';
import '../services/eye_tracking_service.dart';
import '../services/suggestions_service.dart';
import '../utils/constants.dart';
import '../widgets/eye_keyboard.dart';
import '../widgets/eye_status_widget.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  
  const HomeScreen({super.key, required this.cameras});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final EyeTrackingService _eyeService = EyeTrackingService();
  final AudioService _audioService = AudioService();
  final EmergencyService _emergencyService = EmergencyService();
  final SuggestionsService _suggestionsService = SuggestionsService();
  
  late GazeLetterTracker _gazeTracker;
  Timer? _suggestionTimer;
  bool _isEmergencyMode = false;
  bool _isCameraReady = false;
  
  // لتتبع النظرة على الأزرار
  String? _gazeButton;
  double _buttonGazeProgress = 0.0;
  Timer? _buttonGazeTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable(); // منع إيقاف الشاشة
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive); // ملء الشاشة
    _initialize();
  }

  Future<void> _initialize() async {
    final state = context.read<AppState>();
    
    _gazeTracker = GazeLetterTracker(gazeDuration: state.gazeDuration);
    
    _gazeTracker.onGazeProgress = (letter, progress) {
      state.setHighlightedLetter(letter.isEmpty ? null : letter, progress);
    };
    
    _gazeTracker.onLetterSelected = (letter) async {
      await _selectLetter(letter);
    };
    
    _gazeTracker.onGazeCanceled = () {
      state.setHighlightedLetter(null, 0);
    };
    
    // تهيئة خدمة تتبع العين
    _eyeService.onMetricsUpdate = (metrics) {
      state.updateEyeMetrics(metrics);
      
      // تنبيه التوتر
      if (metrics.isAnxious && !_isEmergencyMode) {
        _audioService.speakAnxietyDetected();
      }
    };
    
    _eyeService.onStrongBlink = () async {
      // رمشة قوية = تأكيد آخر حرف أو إرسال الجملة
      if (state.currentText.isNotEmpty) {
        await _speakCurrentText();
      }
    };
    
    _eyeService.onGazeUpdate = (gazeX, gazeY) {
      _updateGazePosition(gazeX, gazeY);
    };
    
    _eyeService.onEARUpdate = (left, right) {
      // تحديث مباشر
    };
    
    await _audioService.initialize();
    await _emergencyService.initialize();
    
    // تهيئة الكاميرا
    if (widget.cameras.isNotEmpty) {
      await _eyeService.initialize(widget.cameras);
      setState(() => _isCameraReady = true);
    }
  }

  void _updateGazePosition(double gazeX, double gazeY) {
    // هذه الدالة ستُستخدم مستقبلاً لتتبع الحروف بالنظرة الدقيقة
    // حالياً الاختيار يتم بالتحديد اليدوي + تأكيد بالرمشة
  }

  Future<void> _selectLetter(String letter) async {
    final state = context.read<AppState>();
    
    // اهتزاز خفيف
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 50, amplitude: 100);
    }
    
    await _audioService.playLetterConfirm();
    state.addLetter(letter);
    
    // تحديث الاقتراحات
    _updateSuggestions();
  }

  void _updateSuggestions() {
    final state = context.read<AppState>();
    if (!state.showSuggestions || state.currentWord.isEmpty) return;
    
    final suggestions = _suggestionsService.getSuggestions(
      state.currentWord,
      state.isArabic,
    );
    state.updateSuggestions(suggestions);
    
    // تأخير للاقتراحات الذكية
    _suggestionTimer?.cancel();
    _suggestionTimer = Timer(const Duration(seconds: 2), () async {
      if (!mounted) return;
      final aiSuggestions = await _suggestionsService.getAISuggestions(
        state.currentText,
        state.isArabic,
      );
      if (mounted && aiSuggestions.isNotEmpty) {
        state.updateSuggestions(aiSuggestions);
      }
    });
  }

  Future<void> _speakCurrentText() async {
    final state = context.read<AppState>();
    if (state.currentText.trim().isEmpty) return;
    
    await _audioService.speak(state.currentText, isArabic: state.isArabic);
    
    // اهتزاز للتأكيد
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 200, amplitude: 200);
    }
  }

  Future<void> _triggerEmergency() async {
    if (_isEmergencyMode) {
      setState(() => _isEmergencyMode = false);
      await _emergencyService.cancelEmergency();
      return;
    }
    
    setState(() => _isEmergencyMode = true);
    final state = context.read<AppState>();
    
    // اهتزاز قوي
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(
        pattern: [0, 500, 200, 500, 200, 500],
        intensities: [0, 255, 0, 255, 0, 255],
      );
    }
    
    await _emergencyService.triggerEmergency(
      contacts: state.emergencyContacts,
      message: state.emergencyMessage,
      isArabic: state.isArabic,
    );
  }

  void _startEyeTracking() async {
    final state = context.read<AppState>();
    if (!_isCameraReady) return;
    
    state.setCameraActive(true);
    state.setEyeTrackingActive(true);
    await _eyeService.startTracking(state.blinkThreshold);
  }

  void _stopEyeTracking() async {
    final state = context.read<AppState>();
    state.setCameraActive(false);
    state.setEyeTrackingActive(false);
    await _eyeService.stopTracking();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // شريط العلوي
            _buildTopBar(state),
            
            // منطقة الطوارئ (تظهر لما يكون نشط)
            if (_isEmergencyMode)
              _buildEmergencyBanner(state),
            
            // مقاييس العين
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: EyeStatusWidget(
                metrics: state.eyeMetrics,
                emotion: state.emotionState,
                isTracking: state.isEyeTrackingActive,
              ),
            ),
            
            // شاشة الكاميرا (صغيرة)
            if (state.isCameraActive && _eyeService.cameraController != null)
              _buildCameraPreview(),
            
            // النص المكتوب
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextDisplayWidget(
                text: state.currentText,
                fontSize: state.fontSize,
                isArabic: state.isArabic,
              ),
            ),
            
            // الاقتراحات
            if (state.showSuggestions && state.suggestions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SuggestionsBar(
                  suggestions: state.suggestions,
                  onSuggestionTap: (word) {
                    state.acceptSuggestion(word);
                    _audioService.speak(word, isArabic: state.isArabic);
                  },
                  isArabic: state.isArabic,
                ),
              ),
            
            // لوحة الحروف الدائرية
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: state.showQuickPhrases
                    ? QuickPhrasesPanel(
                        isArabic: state.isArabic,
                        onPhraseSelected: (phrase) async {
                          state.clearText();
                          for (final char in phrase.split('')) {
                            state.addLetter(char);
                          }
                          await _speakCurrentText();
                          state.toggleQuickPhrases();
                        },
                      )
                    : EyeKeyboard(
                        onLetterSelected: _selectLetter,
                        highlightedLetter: state.highlightedLetter,
                        gazeProgress: state.gazeProgress,
                      ),
              ),
            ),
            
            // أزرار التحكم السفلية
            _buildBottomControls(state),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(AppState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // اسم التطبيق
          Text(
            'EyeSpeak',
            style: const TextStyle(
              color: AppColors.eyeTrackActive,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          
          const Spacer(),
          
          // زر اللغة
          _TopButton(
            label: state.isArabic ? 'EN' : 'عر',
            onTap: state.toggleLanguage,
            color: AppColors.primary,
          ),
          
          const SizedBox(width: 8),
          
          // زر الجمل السريعة
          _TopButton(
            label: state.isArabic ? '⚡' : '⚡',
            onTap: state.toggleQuickPhrases,
            color: state.showQuickPhrases ? AppColors.accent : AppColors.surfaceLight,
          ),
          
          const SizedBox(width: 8),
          
          // زر الإعدادات
          _TopButton(
            label: '⚙️',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            color: AppColors.surfaceLight,
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyBanner(AppState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: AppColors.danger,
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              state.isArabic ? '🚨 وضع الطوارئ نشط - تم إرسال التنبيه' : '🚨 Emergency Active - Alert Sent',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          GestureDetector(
            onTap: _triggerEmergency,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                state.isArabic ? 'إلغاء' : 'Cancel',
                style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'),
              ),
            ),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(color: Colors.white.withOpacity(0.2));
  }

  Widget _buildCameraPreview() {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.eyeTrackActive.withOpacity(0.5)),
      ),
      clipBehavior: Clip.hardEdge,
      child: CameraPreview(_eyeService.cameraController!),
    );
  }

  Widget _buildBottomControls(AppState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // زر الطوارئ
          Expanded(
            child: _ControlButton(
              label: state.isArabic ? '🚨 طوارئ' : '🚨 Emergency',
              isActive: _isEmergencyMode,
              color: AppColors.danger,
              onTap: _triggerEmergency,
              isLarge: true,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // زر مسح
          _ControlButton(
            label: state.isArabic ? '🗑️ مسح' : '🗑️ Clear',
            color: AppColors.warning,
            onTap: () {
              state.clearText();
              _audioService.stop();
            },
          ),
          
          const SizedBox(width: 8),
          
          // زر إرسال/نطق
          _ControlButton(
            label: state.isArabic ? '🔊 تكلم' : '🔊 Speak',
            color: AppColors.success,
            onTap: _speakCurrentText,
          ),
          
          const SizedBox(width: 8),
          
          // زر تشغيل/إيقاف تتبع العين
          _ControlButton(
            label: state.isEyeTrackingActive
                ? (state.isArabic ? '👁️ إيقاف' : '👁️ Stop')
                : (state.isArabic ? '👁️ تتبع' : '👁️ Track'),
            isActive: state.isEyeTrackingActive,
            color: AppColors.primary,
            onTap: state.isEyeTrackingActive ? _stopEyeTracking : _startEyeTracking,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _suggestionTimer?.cancel();
    _buttonGazeTimer?.cancel();
    _gazeTracker.dispose();
    _eyeService.dispose();
    _audioService.dispose();
    super.dispose();
  }
}

class _TopButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _TopButton({required this.label, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color == AppColors.surfaceLight ? AppColors.textPrimary : color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isActive;
  final bool isLarge;

  const _ControlButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.isActive = false,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isLarge ? 16 : 10,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isActive ? color : color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.6)),
          boxShadow: isActive
              ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12)]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
          textAlign: TextAlign.center,
        ),
      )
          .animate(target: isActive ? 1 : 0)
          .scale(begin: const Offset(1, 1), end: const Offset(1.03, 1.03)),
    );
  }
}
