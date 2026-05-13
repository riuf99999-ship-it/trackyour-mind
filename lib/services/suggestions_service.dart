import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SuggestionsService {
  static final SuggestionsService _instance = SuggestionsService._internal();
  factory SuggestionsService() => _instance;
  SuggestionsService._internal();

  // قاموس الكلمات الأكثر استخداماً (offline)
  static const Map<String, List<String>> _arabicCommonWords = {
    'ا': ['أريد', 'أنا', 'أحتاج', 'أشعر', 'أين'],
    'أ': ['أريد', 'أنا', 'أحتاج', 'أشعر', 'أذهب'],
    'م': ['ماء', 'مساعدة', 'مريح', 'متعب', 'ممكن'],
    'ط': ['طعام', 'طبيب', 'طوارئ'],
    'أر': ['أريد', 'أرجو'],
    'أح': ['أحتاج', 'أحب', 'أحس'],
    'ما': ['ماء', 'مالي', 'ماذا'],
    'مس': ['مساعدة', 'مستشفى'],
    'شك': ['شكراً'],
    'نع': ['نعم'],
    'لا': ['لا', 'لازم'],
  };

  static const Map<String, List<String>> _englishCommonWords = {
    'i': ['I', 'I need', 'I want', 'I feel', 'I am'],
    'w': ['want', 'water', 'wait', 'well'],
    'n': ['need', 'no', 'now', 'nurse'],
    'h': ['help', 'here', 'hurts', 'hungry'],
    'f': ['food', 'feel', 'fine'],
    'th': ['thank', 'thanks', 'thirsty'],
    'ye': ['yes'],
    'wa': ['water', 'want', 'wait'],
    'he': ['help', 'here'],
    'pa': ['pain', 'please'],
  };

  List<String> getSuggestions(String currentWord, bool isArabic) {
    if (currentWord.isEmpty || currentWord.length < 1) return [];
    
    final wordLower = currentWord.toLowerCase();
    final map = isArabic ? _arabicCommonWords : _englishCommonWords;
    
    Set<String> results = {};
    
    // بحث عن تطابق
    for (final entry in map.entries) {
      if (wordLower.startsWith(entry.key) || entry.key.startsWith(wordLower)) {
        results.addAll(entry.value.where(
          (w) => w.toLowerCase().startsWith(wordLower),
        ));
      }
    }
    
    // إضافة الكلمة نفسها لو طويلة
    if (currentWord.length > 2) {
      results.add(currentWord);
    }
    
    return results.take(4).toList();
  }

  // اقتراح الجملة التالية (AI)
  Future<List<String>> getAISuggestions(String text, bool isArabic) async {
    if (text.trim().length < 3) return [];
    
    try {
      final prompt = isArabic
          ? 'أكمل هذه الجملة بـ 3 خيارات مختلفة قصيرة مناسبة لشخص معاق لا يستطيع الكلام: "$text". أعط فقط الجمل المكتملة مفصولة بـ | بدون شرح.'
          : 'Complete this sentence with 3 different short options for a person who cannot speak: "$text". Give only the completed sentences separated by | without explanation.';

      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'claude-sonnet-4-20250514',
          'max_tokens': 200,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'] as String;
        return content.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty).take(3).toList();
      }
    } catch (e) {
      debugPrint('AI suggestions error: $e');
    }
    
    return [];
  }
}
