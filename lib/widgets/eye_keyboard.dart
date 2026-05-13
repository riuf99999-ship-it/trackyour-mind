import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../utils/constants.dart';

class EyeKeyboard extends StatelessWidget {
  final Function(String) onLetterSelected;
  final String? highlightedLetter;
  final double gazeProgress;

  const EyeKeyboard({
    super.key,
    required this.onLetterSelected,
    this.highlightedLetter,
    this.gazeProgress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final letters = state.isArabic
        ? [...AppConstants.arabicLetters, ...AppConstants.symbols]
        : [...AppConstants.englishLetters, ...AppConstants.symbols];

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.surfaceLight,
            AppColors.surface,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _buildCircularKeyboard(letters, state.fontSize),
        ),
      ),
    );
  }

  Widget _buildCircularKeyboard(List<String> letters, double fontSize) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        final center = Offset(size / 2, size / 2);
        
        // توزيع الحروف في دوائر متحدة المركز
        final rings = _distributeInRings(letters);
        
        return Stack(
          children: [
            // الدوائر الخارجية (ديكور)
            ...rings.asMap().entries.map((ringEntry) {
              final ringIndex = ringEntry.key;
              final ringLetters = ringEntry.value;
              final ringRadius = (size * 0.15) + (ringIndex * size * 0.13);
              
              return Stack(
                children: ringLetters.asMap().entries.map((entry) {
                  final index = entry.key;
                  final letter = entry.value;
                  final angle = (2 * 3.14159 * index / ringLetters.length) - (3.14159 / 2);
                  
                  final x = center.dx + ringRadius * cos(angle) - 20;
                  final y = center.dy + ringRadius * sin(angle) - 20;
                  
                  return Positioned(
                    left: x,
                    top: y,
                    child: _LetterButton(
                      letter: letter,
                      isHighlighted: letter == highlightedLetter,
                      gazeProgress: letter == highlightedLetter ? gazeProgress : 0.0,
                      fontSize: fontSize,
                      onSelected: onLetterSelected,
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  List<List<String>> _distributeInRings(List<String> letters) {
    // توزيع الحروف: 8 في الداخل، 12 في الوسط، باقي في الخارج
    final List<List<String>> rings = [];
    
    if (letters.length <= 8) {
      rings.add(letters);
    } else if (letters.length <= 20) {
      rings.add(letters.sublist(0, 8));
      rings.add(letters.sublist(8));
    } else {
      rings.add(letters.sublist(0, 8));
      rings.add(letters.sublist(8, 20));
      rings.add(letters.sublist(20));
    }
    
    return rings;
  }
}

double cos(double angle) => _cos(angle);
double sin(double angle) => _sin(angle);

double _cos(double angle) {
  // تقريب دالة cos
  angle = angle % (2 * 3.14159265358979);
  if (angle < 0) angle += 2 * 3.14159265358979;
  
  double result = 1.0;
  double term = 1.0;
  for (int i = 1; i <= 10; i++) {
    term *= -angle * angle / ((2 * i - 1) * (2 * i));
    result += term;
  }
  return result;
}

double _sin(double angle) {
  angle = angle % (2 * 3.14159265358979);
  if (angle < 0) angle += 2 * 3.14159265358979;
  
  double result = angle;
  double term = angle;
  for (int i = 1; i <= 10; i++) {
    term *= -angle * angle / ((2 * i) * (2 * i + 1));
    result += term;
  }
  return result;
}

class _LetterButton extends StatelessWidget {
  final String letter;
  final bool isHighlighted;
  final double gazeProgress;
  final double fontSize;
  final Function(String) onSelected;

  const _LetterButton({
    required this.letter,
    required this.isHighlighted,
    required this.gazeProgress,
    required this.fontSize,
    required this.onSelected,
  });

  bool get isSpecial => ['⌫', ' ', '،', '.', '؟', '!'].contains(letter);
  bool get isDelete => letter == '⌫';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelected(letter),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          children: [
            // الخلفية
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isHighlighted
                    ? AppColors.primary.withOpacity(0.3)
                    : isDelete
                        ? AppColors.danger.withOpacity(0.2)
                        : isSpecial
                            ? AppColors.accent.withOpacity(0.15)
                            : AppColors.surfaceLight,
                border: Border.all(
                  color: isHighlighted
                      ? AppColors.eyeTrackActive
                      : isDelete
                          ? AppColors.danger.withOpacity(0.5)
                          : AppColors.textDisabled.withOpacity(0.3),
                  width: isHighlighted ? 2 : 1,
                ),
                boxShadow: isHighlighted
                    ? [BoxShadow(
                        color: AppColors.eyeTrackGlow,
                        blurRadius: 12,
                        spreadRadius: 2,
                      )]
                    : null,
              ),
              child: Center(
                child: Text(
                  letter,
                  style: TextStyle(
                    color: isHighlighted
                        ? AppColors.eyeTrackActive
                        : isDelete
                            ? AppColors.danger
                            : AppColors.textPrimary,
                    fontSize: fontSize - 4,
                    fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ),
            
            // مؤشر التقدم (دائري)
            if (isHighlighted && gazeProgress > 0)
              Positioned.fill(
                child: CircularProgressIndicator(
                  value: gazeProgress,
                  strokeWidth: 3,
                  color: AppColors.eyeTrackActive,
                  backgroundColor: AppColors.eyeTrackActive.withOpacity(0.2),
                ),
              ),
          ],
        ),
      )
          .animate(target: isHighlighted ? 1 : 0)
          .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15))
          .then()
          .shimmer(color: AppColors.eyeTrackActive.withOpacity(0.3)),
    );
  }
}

// لوحة الجمل السريعة
class QuickPhrasesPanel extends StatelessWidget {
  final bool isArabic;
  final Function(String) onPhraseSelected;

  const QuickPhrasesPanel({
    super.key,
    required this.isArabic,
    required this.onPhraseSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'جمل سريعة' : 'Quick Phrases',
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.quickPhrases.map((phrase) {
              final text = isArabic ? phrase['ar']! : phrase['en']!;
              return GestureDetector(
                onTap: () => onPhraseSelected(text),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: isArabic ? 14 : 13,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
