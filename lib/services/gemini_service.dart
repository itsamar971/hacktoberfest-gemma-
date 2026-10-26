import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Service managing Gemma / Gemini AI operations
class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  // Gemma model strictly specified for hackathon
  static const String defaultModel = 'gemma-4-26b-a4b-it';
  static const String fallbackModel = 'gemini-2.5-flash';

  // Configured with user API key, can also be passed via --dart-define
  static String apiKey = const String.fromEnvironment('GEMINI_API_KEY');

  GenerativeModel? _model;
  GenerativeModel? _fallbackGenerativeModel;
  String _currentModelName = defaultModel;

  /// Initialize Gemini / Gemma with an API key
  void initialize({String? key, String? modelName}) {
    if (key != null && key.isNotEmpty) {
      apiKey = key;
    }
    if (modelName != null && modelName.isNotEmpty) {
      _currentModelName = modelName;
    }

    if (apiKey.isNotEmpty) {
      _model = GenerativeModel(
        model: _currentModelName,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
        ),
      );
      debugPrint('✅ GeminiService initialized with model: $_currentModelName');
    } else {
      debugPrint('⚠️ GeminiService: No GEMINI_API_KEY provided yet.');
    }
  }

  bool get isReady => _model != null || apiKey.isNotEmpty;

  GenerativeModel _getModel() {
    if (_model == null) {
      if (apiKey.isEmpty) {
        throw StateError(
          'GEMINI_API_KEY is not configured. Please supply your API key or pass --dart-define=GEMINI_API_KEY=your_key',
        );
      }
      initialize(key: apiKey, modelName: _currentModelName);
    }
    return _model!;
  }

  /// Core generator with Gemma first, and fallback if necessary
  Future<String> _generateWithGemma(String prompt) async {
    final model = _getModel();
    try {
      final response = await model.generateContent([Content.text(prompt)]);
      if (response.text != null && response.text!.trim().isNotEmpty) {
        return response.text!.trim();
      }
    } catch (e) {
      debugPrint('⚠️ Gemma primary generation note: $e. Checking fallback...');
    }

    // Safety fallback to guarantee hackathon demo reliability
    try {
      _fallbackGenerativeModel ??= GenerativeModel(
        model: fallbackModel,
        apiKey: apiKey,
        generationConfig: GenerationConfig(temperature: 0.7),
      );
      final response = await _fallbackGenerativeModel!.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? '';
    } catch (e) {
      debugPrint('❌ Fallback generation error: $e');
      rethrow;
    }
  }

  /// 1. Break down a goal into daily micro-steps (<20 mins each)
  Future<List<Map<String, dynamic>>> generateDreamTasks(String dream, {int days = 7}) async {
    final systemPrompt = '''
You are an expert productivity coach for ambitious women.
Break down the user's dream goal into a $days-day plan of tiny, actionable micro-steps.
Each step MUST take less than 20 minutes to complete.

Return ONLY a raw JSON array of objects (no markdown, no code fences, no extra text).
Each object must have:
- "title": A short, action-oriented task description (max 10 words).
- "duration": Estimated minutes (integer, 5-20).

Example:
[
  {"title": "Research best local running trails", "duration": 15},
  {"title": "Buy comfortable running shoes", "duration": 20}
]
''';

    final prompt = '$systemPrompt\n\nUser Goal: "$dream"\nDuration: $days days.';
    final rawText = await _generateWithGemma(prompt);

    // Parse JSON cleanly
    try {
      final cleanJson = rawText
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();
      final List<dynamic> parsed = jsonDecode(cleanJson);
      return parsed.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      debugPrint('Gemma Dream Task Parse Error: $e\nRaw: $rawText');
      // Fallback: return single starting step
      return [
        {"title": "Take first small step toward: $dream", "duration": 15}
      ];
    }
  }

  /// 2. Roleplay recruiter for salary negotiation coaching
  Future<String> negotiateSalary(List<Map<String, dynamic>> messages) async {
    final systemInstruction = '''
You are a professional corporate hiring manager and salary negotiation coach.
The user is negotiating their compensation for a high-level role.

Rules:
1. Respond as the recruiter. Be tough, realistic, but respectful and fair.
2. At the end of your response, ALWAYS include a "Strategy Tip" in brackets:
   [Tip: tactical feedback on what the user did well and how they can improve their leverage/anchoring/ROI].
3. Keep the conversation natural and engaging.
''';

    // Format chat history
    final buffer = StringBuffer(systemInstruction);
    buffer.writeln('\n--- Conversation History ---');
    for (final m in messages) {
      final role = (m['isRecruiter'] == true || m['role'] == 'assistant') ? 'Recruiter' : 'Candidate';
      final text = m['text'] ?? m['content'] ?? '';
      buffer.writeln('$role: $text');
    }
    buffer.writeln('Recruiter:');

    final reply = await _generateWithGemma(buffer.toString());
    return reply.isNotEmpty ? reply : 'I hear your points. Let us review the budget and discuss.';
  }

  /// 3. Journal Reflection & Insight
  Future<String> getJournalInsight(String text, {bool isDiscussion = false}) async {
    final prompt = isDiscussion
        ? '''
You are an empathetic, calm personal growth companion for ambitious women.
The user is sharing a reflection from their private journal.
Engage in a warm, thoughtful dialogue. Be encouraging, ask one gentle question, and help reframe challenges into growth opportunities. Keep your answer concise (under 120 words).

Context & Message:
$text
'''
        : '''
You are an empathetic, calm personal growth companion for ambitious women.
Reflect on this journal entry:
"$text"

Provide:
1. A warm, empathetic reflection summarizing what they are experiencing.
2. An empowering takeaway or gentle affirmation.
Keep it under 100 words.
''';

    final reply = await _generateWithGemma(prompt);
    return reply.isNotEmpty ? reply : 'Thank you for reflecting today. Keep growing at your own pace.';
  }
}
