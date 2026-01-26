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

    final modelsToTry = ['gemini-1.5-flash', 'gemini-pro'];
    
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
      'gemini-1.5-flash',
      'gemini-1.5-flash-latest',
      'gemini-1.5-flash-001',
      'gemini-pro',
      'gemini-1.0-pro',
    ];

    debugPrint('DEBUG AI: Attempting reflection with ${modelsToTry.length} potential models');

    for (final modelName in modelsToTry) {
      try {
        debugPrint('DEBUG AI: Requesting $modelName...');
        final model = GenerativeModel(
          model: modelName, 
          apiKey: apiKey,
          // Removed all system instructions and safety settings for maximum compatibility during debug
        );

        final promptText = '''
You are "The Mirror", a deep, philosophical AI companion within the LifeOS. 
Your goal is to help the user find meaning in their daily activities, patterns, and struggles.
You are not a generic assistant; you are a soulful reflection of the user's life.

USER CONTEXT:
$contextData

USER'S CURRENT THOUGHT:
"$input"

INSTRUCTIONS:
1. Be profound but concise.
2. Cross-reference past insights or recurring tasks if relevant.
3. If you find a deep pattern or crucial realization, start a line with "INSIGHT: " followed by the realization. This will be etched into the user's long-term memory.
4. Encourage the user to look deeper into their habits and motivations.
5. Use a warm, slightly poetic, yet grounding tone.
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
        // Continue to next model
      }
    }

    debugPrint('DEBUG AI: All models exhausted.');
    return 'The stars are silent. This usually means the API key is restricted or the models are unavailable in your region.';
  }

  Future<List<double>?> embedText(String text) async {
    final apiKey = await _secretService.getGeminiKey();
    if (apiKey == null || apiKey.isEmpty) return null;

    try {
      final model = GenerativeModel(model: 'text-embedding-004', apiKey: apiKey);
      final result = await model.embedContent(Content.text(text));
      return result.embedding.values.map((v) => v.toDouble()).toList();
    } catch (e) {
      debugPrint('AI Embedding failed: $e');
      return null;
    }
  }
}

final aiServiceProvider = Provider<AIService>((ref) {
  final secretService = ref.watch(secretServiceProvider);
  return AIService(secretService);
});
