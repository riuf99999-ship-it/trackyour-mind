import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/app_state.dart';

class EyeTrackingService {
  static final EyeTrackingService _instance = EyeTrackingService._internal();
  factory EyeTrackingService() => _instance;
  EyeTrackingService._internal();

  FaceDetector? _faceDetector;
  CameraController? _cameraController;
  bool _isProcessing = false;
  
  // Callbacks
  Function(EyeMetrics)? onMetricsUpdate;
  Function(double earLeft, double earRight)? onEARUpdate;
  Function()? onStrongBlink; // رمشة قوية = تأكيد
  Function(double gazeX, double gazeY)? onGazeUpdate;
  
  // تتبع الرمشات
  final List<DateTime> _blinkTimestamps = [];
  bool _wasBlinking = false;
  DateTime? _blinkStartTime;
  double _lastEARLeft = 1.0;
  double _lastEARRight = 1.0;
  
  // حساب معدل الرمشات
  double get blinkRate {
    final now = DateTime.now();
    _blinkTimestamps.removeWhere(
      (t) => now.difference(t).inSeconds > 60,
    );
    return _blinkTimestamps.length.toDouble();
  }
  
  Future<void> initialize(List<CameraDescription> cameras) async {
    // استخدام الكاميرا الأمامية
    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    
    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );
    
    await _cameraController!.initialize();
    
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableLandmarks: true,
        enableContours: true,
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: 0.15,
      ),
    );
  }
  
  Future<void> startTracking(double blinkThreshold) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    
    await _cameraController!.startImageStream((CameraImage image) async {
      if (_isProcessing) return;
      _isProcessing = true;
      
      try {
        await _processFrame(image, blinkThreshold);
      } catch (e) {
        debugPrint('Eye tracking error: $e');
      } finally {
        _isProcessing = false;
      }
    });
  }
  
  Future<void> stopTracking() async {
    if (_cameraController?.value.isStreamingImages ?? false) {
      await _cameraController!.stopImageStream();
    }
  }
  
  Future<void> _processFrame(CameraImage image, double blinkThreshold) async {
    if (_faceDetector == null) return;
    
    final inputImage = _convertCameraImage(image);
    if (inputImage == null) return;
    
    final faces = await _faceDetector!.processImage(inputImage);
    if (faces.isEmpty) return;
    
    final face = faces.first;
    
    // EAR = Eye Aspect Ratio (مقياس انفتاح العين)
    final leftEAR = face.leftEyeOpenProbability ?? 1.0;
    final rightEAR = face.rightEyeOpenProbability ?? 1.0;
    final avgEAR = (leftEAR + rightEAR) / 2;
    
    onEARUpdate?.call(leftEAR, rightEAR);
    
    // اكتشاف الرمشة
    final isBlinking = avgEAR < blinkThreshold;
    
    if (isBlinking && !_wasBlinking) {
      // بدأت الرمشة
      _blinkStartTime = DateTime.now();
      _wasBlinking = true;
    } else if (!isBlinking && _wasBlinking) {
      // انتهت الرمشة
      if (_blinkStartTime != null) {
        final blinkDuration = DateTime.now().difference(_blinkStartTime!).inMilliseconds;
        _blinkTimestamps.add(DateTime.now());
        
        // الرمشة القوية: العين مغلقة أكثر من 300ms وEAR أقل من العتبة بكثير
        final isStrong = blinkDuration > 300 && avgEAR < (blinkThreshold * 0.6);
        if (isStrong) {
          onStrongBlink?.call();
        }
      }
      _wasBlinking = false;
      _blinkStartTime = null;
    }
    
    // حساب اتجاه النظرة (تقريبي من موضع الوجه)
    final headEulerY = face.headEulerAngleY ?? 0; // يسار/يمين
    final headEulerZ = face.headEulerAngleZ ?? 0; // أعلى/أسفل
    
    // تحويل زاوية الرأس إلى إحداثيات شاشة (0-1)
    final gazeX = (headEulerY + 30) / 60; // -30 إلى +30 درجة
    final gazeY = (headEulerZ + 20) / 40;
    
    onGazeUpdate?.call(gazeX.clamp(0.0, 1.0), gazeY.clamp(0.0, 1.0));
    
    // تحديث المقاييس
    final metrics = EyeMetrics(
      earLeft: leftEAR,
      earRight: rightEAR,
      blinkRate: blinkRate,
      isAnxious: blinkRate > 25,
      timestamp: DateTime.now(),
    );
    onMetricsUpdate?.call(metrics);
    
    _lastEARLeft = leftEAR;
    _lastEARRight = rightEAR;
  }
  
  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();
      
      final imageSize = Size(image.width.toDouble(), image.height.toDouble());
      
      const imageRotation = InputImageRotation.rotation270deg;
      
      final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw);
      if (inputImageFormat == null) return null;
      
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: imageSize,
          rotation: imageRotation,
          format: inputImageFormat,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    } catch (e) {
      return null;
    }
  }
  
  CameraController? get cameraController => _cameraController;
  
  Future<void> dispose() async {
    await stopTracking();
    _faceDetector?.close();
    await _cameraController?.dispose();
    _faceDetector = null;
    _cameraController = null;
  }
}

// خدمة تتبع الحروف بالعين
class GazeLetterTracker {
  final double gazeDuration; // ثواني لتأكيد الحرف
  
  String? _currentLetter;
  DateTime? _gazeStartTime;
  Timer? _progressTimer;
  
  Function(String letter, double progress)? onGazeProgress;
  Function(String letter)? onLetterSelected;
  Function()? onGazeCanceled;
  
  GazeLetterTracker({required this.gazeDuration});
  
  void startGazingAt(String letter) {
    if (_currentLetter == letter) return; // نفس الحرف، استمر
    
    // حرف جديد
    _progressTimer?.cancel();
    _currentLetter = letter;
    _gazeStartTime = DateTime.now();
    
    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_gazeStartTime == null) {
        timer.cancel();
        return;
      }
      
      final elapsed = DateTime.now().difference(_gazeStartTime!).inMilliseconds;
      final progress = elapsed / (gazeDuration * 1000);
      
      onGazeProgress?.call(letter, progress.clamp(0.0, 1.0));
      
      if (progress >= 1.0) {
        timer.cancel();
        onLetterSelected?.call(letter);
        _currentLetter = null;
        _gazeStartTime = null;
      }
    });
  }
  
  void cancelGaze() {
    _progressTimer?.cancel();
    if (_currentLetter != null) {
      onGazeCanceled?.call();
    }
    _currentLetter = null;
    _gazeStartTime = null;
    onGazeProgress?.call('', 0.0);
  }
  
  void dispose() {
    _progressTimer?.cancel();
  }
}
