import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/app_state.dart';
import '../utils/constants.dart';

class EyeStatusWidget extends StatelessWidget {
  final EyeMetrics? metrics;
  final EmotionState emotion;
  final bool isTracking;

  const EyeStatusWidget({
    super.key,
    this.metrics,
    required this.emotion,
    required this.isTracking,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTracking ? AppColors.eyeTrackActive.withOpacity(0.5) : AppColors.textDisabled.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // مؤشر الحالة
          _StatusIndicator(isActive: isTracking),
          const SizedBox(width: 12),
          
          // معلومات EAR
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'EAR يسار: ',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontFamily: 'Cairo'),
                    ),
                    Text(
                      metrics != null ? metrics!.earLeft.toStringAsFixed(2) : '--',
                      style: TextStyle(
                        color: _earColor(metrics?.earLeft),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'يمين: ',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontFamily: 'Cairo'),
                    ),
                    Text(
                      metrics != null ? metrics!.earRight.toStringAsFixed(2) : '--',
                      style: TextStyle(
                        color: _earColor(metrics?.earRight),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'رمشات/دقيقة: ',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontFamily: 'Cairo'),
                    ),
                    Text(
                      metrics != null ? metrics!.blinkRate.toInt().toString() : '--',
                      style: TextStyle(
                        color: emotion == EmotionState.anxious ? AppColors.warning : AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // مؤشر الحالة العاطفية
          _EmotionBadge(emotion: emotion),
        ],
      ),
    );
  }

  Color _earColor(double? ear) {
    if (ear == null) return AppColors.textDisabled;
    if (ear < 0.2) return AppColors.danger;
    if (ear < 0.3) return AppColors.warning;
    return AppColors.success;
  }
}

class _StatusIndicator extends StatelessWidget {
  final bool isActive;
  
  const _StatusIndicator({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (isActive)
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.eyeTrackActive.withOpacity(0.2),
            ),
          ).animate(onPlay: (c) => c.repeat()).scale(
            begin: const Offset(1, 1),
            end: const Offset(1.5, 1.5),
            duration: 1500.ms,
          ).then().scale(
            begin: const Offset(1.5, 1.5),
            end: const Offset(1, 1),
            duration: 1500.ms,
          ),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.eyeTrackActive : AppColors.textDisabled,
          ),
        ),
      ],
    );
  }
}

class _EmotionBadge extends StatelessWidget {
  final EmotionState emotion;
  
  const _EmotionBadge({required this.emotion});

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (emotion) {
      EmotionState.neutral => ('😐', AppColors.textSecondary, 'طبيعي'),
      EmotionState.anxious => ('😰', AppColors.warning, 'توتر'),
      EmotionState.tired => ('😴', AppColors.primaryLight, 'تعب'),
      EmotionState.happy => ('😊', AppColors.success, 'بخير'),
      EmotionState.pain => ('😣', AppColors.danger, 'ألم'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontFamily: 'Cairo'),
          ),
        ],
      ),
    )
        .animate(target: emotion == EmotionState.anxious ? 1 : 0)
        .shake(hz: 2, offset: const Offset(2, 0));
  }
}

// شريط النص المكتوب
class TextDisplayWidget extends StatelessWidget {
  final String text;
  final double fontSize;
  final bool isArabic;

  const TextDisplayWidget({
    super.key,
    required this.text,
    required this.fontSize,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(minHeight: 80),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 20,
          ),
        ],
      ),
      child: text.isEmpty
          ? Text(
              isArabic ? 'انظر إلى الحروف للكتابة...' : 'Look at letters to type...',
              style: TextStyle(
                color: AppColors.textDisabled,
                fontSize: fontSize - 2,
                fontStyle: FontStyle.italic,
                fontFamily: 'Cairo',
              ),
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            )
          : Text(
              text,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: fontSize,
                fontFamily: 'Cairo',
                height: 1.5,
              ),
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            ),
    );
  }
}

// شريط الاقتراحات
class SuggestionsBar extends StatelessWidget {
  final List<String> suggestions;
  final Function(String) onSuggestionTap;
  final bool isArabic;

  const SuggestionsBar({
    super.key,
    required this.suggestions,
    required this.onSuggestionTap,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();
    
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        reverse: isArabic,
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return GestureDetector(
            onTap: () => onSuggestionTap(suggestion),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.5)),
              ),
              child: Text(
                suggestion,
                style: const TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 14,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
