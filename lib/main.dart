import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/app_state.dart';
import 'screens/home_screen.dart';
import 'utils/constants.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تفعيل الوضع العمودي فقط
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  // تحميل الكاميرات
  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint('Camera error: $e');
  }
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..loadSettings(),
      child: EyeSpeakApp(cameras: cameras),
    ),
  );
}

class EyeSpeakApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  
  const EyeSpeakApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EyeSpeak',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: SplashScreen(cameras: cameras),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  
  const SplashScreen({super.key, required this.cameras});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    
    _controller.forward().then((_) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => HomeScreen(cameras: widget.cameras),
              transitionDuration: const Duration(milliseconds: 600),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // أيقونة العين
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.3),
                        AppColors.background,
                      ],
                    ),
                    border: Border.all(color: AppColors.eyeTrackActive, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.eyeTrackGlow,
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('👁️', style: TextStyle(fontSize: 56)),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // الاسم
                const Text(
                  'EyeSpeak',
                  style: TextStyle(
                    color: AppColors.eyeTrackActive,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                const Text(
                  'تواصل بعينيك',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 18,
                    fontFamily: 'Cairo',
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // شريط التحميل
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: const AlwaysStoppedAnimation(AppColors.eyeTrackActive),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
