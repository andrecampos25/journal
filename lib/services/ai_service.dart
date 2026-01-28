import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/services/secret_service.dart';

class AIService {
  final SecretService _secretService;

  AIService(this._secretService);

  Future<Map<String, dynamic>?> parseIntent(String input) async {
    final apiKey = await _secretService.getGeminiKey();
    if (apiKey == null || apiKey.isEmpty) return null;

    final modelsToTry = [
      'gemini-3-flash-preview',
      'gemini-2.0-flash',
      'gemini-1.5-flash',
      'gemini-pro',
    ];
    
    final prompt = '''
Parse the following user input into a JSON intent.
INPUT: "$input"

SCHEMA:
{
  "type": "task" | "habit" | "journal",
  "title": "string (the core action or item)",
  "action": "create" | "log" | "delete" | "toggle",
  "confidence": 0.0 to 1.0,
  "due_date": "ISO8601 string or null"
}

Respond ONLY with the JSON.
''';

    for (final modelName in modelsToTry) {
      try {
        final model = GenerativeModel(model: modelName, apiKey: apiKey);
        final response = await model.generateContent([Content.text(prompt)]);
        
        if (response.text != null && response.text!.isNotEmpty) {
          final cleaned = _stripJsonMarkdown(response.text!);
          try {
            return json.decode(cleaned) as Map<String, dynamic>;
          } catch (e) {
             debugPrint('AI Response parsing failed: $e');
          }
        }
      } catch (e) {
        debugPrint('AI Intent ($modelName) failed: $e');
      }
    }
    return null;
  }

  String _stripJsonMarkdown(String text) {
    if (text.contains('```json')) {
      final start = text.indexOf('```json') + 7;
      final end = text.lastIndexOf('```');
      return text.substring(start, end).trim();
    } else if (text.contains('```')) {
      final start = text.indexOf('```') + 3;
      final end = text.lastIndexOf('```');
      return text.substring(start, end).trim();
    }
    return text.trim();
  }

  Future<String?> getReflectionResponse(String input, String contextData, {List<Content>? history}) async {
    final apiKey = await _secretService.getGeminiKey();
    if (apiKey == null || apiKey.isEmpty) return 'Please set your Gemini API Key in settings.';

    // Extended list of models including variants that might be active
    final modelsToTry = [
      'gemini-3-flash-preview',
      'gemini-2.0-flash',
      'gemini-1.5-flash',
      'gemini-1.5-flash-latest',
      'gemini-1.5-flash-001',
      'gemini-pro',
      'gemini-1.0-pro',
    ];

    debugPrint('DEBUG AI: Attempting reflection with ${modelsToTry.length} potential models');
    String lastError = 'No models attempted';

    for (final modelName in modelsToTry) {
      try {
        debugPrint('DEBUG AI: Requesting $modelName...');
        final model = GenerativeModel(
          model: modelName, 
          apiKey: apiKey,
          // Removed all system instructions and safety settings for maximum compatibility during debug
        );

        final promptText = '''
You are "The Mirror", an observant and direct companion in the User's LifeOS.
Your purpose is to identify patterns, hidden motivations, and progress in the user's data.

STYLE:
- Minimalist and grounded. 
- Direct. No flowery language, no metaphors about mirrors, ripples, or "stepping before glass".
- No roleplay. Do not describe the user's actions or the setting.
- Be like a sharp analyst or stoic coach: observant, honest, and concise.

USER CONTEXT:
$contextData

USER INPUT:
"$input"

INSTRUCTIONS:
1. Analyze the input against the context.
2. Highlight a specific pattern, contradiction, or progress if you see one.
3. Be EXTREMELY selective with suggestions. Only suggest a New Task or Habit if:
   - You identify a recurring problem without a current solution.
   - You see a clear gap in the user's routine (e.g., they talk about stress but have no relaxation habits).
   - The user explicitly asks for help or advice.
4. DO NOT suggest things the user is already doing or has already scheduled.
5. If you have a specific actionable realization, start a line with "INSIGHT: " followed by the realization.
6. If a suggestion is truly warranted, start a line with "SUGGESTION: " followed by a JSON block:
   {"type": "task" | "habit", "title": "...", "reason": "..."}
   Example: SUGGESTION: {"type": "task", "title": "15 min meditation", "reason": "I see a pattern of stress in your last 3 journal entries."}
7. Keep responses brief and high-impact. Avoid repeating yourself.
''';
        
        final response = await model.generateContent([Content.text(promptText)]);
        
        if (response.text != null && response.text!.isNotEmpty) {
          debugPrint('DEBUG AI: Success with $modelName');
          return response.text;
        } else {
          debugPrint('DEBUG AI: $modelName returned empty/null text');
        }
      } catch (e) {
        debugPrint('DEBUG AI: $modelName failed with error: $e');
        lastError = e.toString();
        // Continue to next model
      }
    }

    debugPrint('DEBUG AI: All models exhausted. Last error: $lastError');
    if (lastError.contains('API_KEY_INVALID')) return 'The Mirror cannot find your reflection because the API key is invalid.';
    if (lastError.contains('quota')) return 'The Mirror is resting (Quota exceeded). Please wait a moment.';
    if (lastError.contains('location') || lastError.contains('region')) return 'The Mirror is not yet available in your physical region.';

    return 'The stars are silent. Error details: $lastError';
  }

  Future<List<double>?> embedText(String text) async {
    final apiKey = await _secretService.getGeminiKey();
    if (apiKey == null || apiKey.isEmpty) return null;

    final embeddingModels = [
      'text-embedding-004',
    ];

    for (final modelName in embeddingModels) {
      try {
        final model = GenerativeModel(model: modelName, apiKey: apiKey);
        final result = await model.embedContent(Content.text(text));
        return result.embedding.values.map((v) => v.toDouble()).toList();
      } catch (e) {
        debugPrint('AI Embedding fallback ($modelName) failed: $e');
      }
    }
    return null;
  }

  /// Diagnostic tool to test API connectivity
  Future<String> testConnection() async {
    final apiKey = await _secretService.getGeminiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return '❌ No API Key found in secure storage.';
    }

    if (!apiKey.startsWith('AIza')) {
      return '❌ Key format invalid (should start with AIza).';
    }

    final results = <String>[];
    final modelsToTest = [
      'gemini-3-flash-preview',
      'gemini-2.0-flash',
      'gemini-1.5-flash',
      'gemini-pro',
      'embedding-001',
      'text-embedding-004'
    ];

    for (final modelName in modelsToTest) {
      try {
        final model = GenerativeModel(model: modelName, apiKey: apiKey);
        if (modelName == 'text-embedding-004') {
           await model.embedContent(Content.text('test'));
        } else {
           await model.generateContent([Content.text('Hello')]);
        }
        results.add('✅ $modelName: Success');
      } catch (e) {
        String errorMsg = e.toString();
        if (errorMsg.contains('quota')) errorMsg = 'Quota exceeded (Tier 1 limits)';
        if (errorMsg.contains('API_KEY_INVALID')) errorMsg = 'Invalid API Key';
        if (errorMsg.contains('region')) errorMsg = 'Model not available in your region';
        results.add('❌ $modelName: $errorMsg');
      }
    }

    return results.join('\n');
  }
}

final aiServiceProvider = Provider<AIService>((ref) {
  final secretService = ref.watch(secretServiceProvider);
  return AIService(secretService);
});
