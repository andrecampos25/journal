import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/services/secret_service.dart';

class AIService {
  final SecretService _secretService;

  AIService(this._secretService);

  Future<Map<String, dynamic>?> parseIntent(String input) async {
    final apiKey = await _secretService.getGeminiKey();
    if (apiKey == null || apiKey.isEmpty) return null;

    final modelsToTry = ['gemini-1.5-flash', 'gemini-1.5-pro', 'gemini-pro'];
    
    for (final modelName in modelsToTry) {
      try {
        final model = GenerativeModel(model: modelName, apiKey: apiKey);
        final prompt = '''
        You are a high-precision intent parser for "Life OS", a productivity and reflection app.
        Extract the user's intent from the given input string.

        SUPPORTED INTENTS:
        1. "task": Creating a new to-do item (e.g., "walk the dog", "finish report tomorrow").
        2. "habit": Logging or creating a habit (e.g., "drank water", "did 50 pushups", "log meditation").
        3. "journal": Recording a thought, reflection, or diary entry (e.g., "i am feeling great today", "journal: focus on deep work").

        CURRENT DATE/TIME: ${DateTime.now().toIso8601String()}

        INPUT: "$input"

        RESPONSE RULES:
        - Return ONLY a valid JSON object.
        - If the intent fits "journal" better than "task" (e.g. descriptive feelings or reflections), use "journal".
        - Confidence should be a number between 0.0 and 1.0.

        SCHEMA:
        {
          "type": "task" | "habit" | "journal",
          "action": "create" | "log",
          "title": "Clean title or summary",
          "due_date": "ISO8601 string or null",
          "amount": number | null,
          "confidence": number
        }
        ''';

        final response = await model.generateContent([Content.text(prompt)]);
        final text = response.text;
        if (text != null) {
          final jsonStart = text.indexOf('{');
          final jsonEnd = text.lastIndexOf('}');
          if (jsonStart != -1 && jsonEnd != -1) {
            final jsonStr = text.substring(jsonStart, jsonEnd + 1);
            final decoded = json.decode(jsonStr) as Map<String, dynamic>;
            print('AI Parsed Intent ($modelName): $decoded');
            return decoded;
          }
        }
      } catch (e) {
        print('AI: $modelName failed: $e');
        if (e.toString().contains('404')) continue;
        // Don't break on others, try next model if available
      }
    }
    return null;
  }

  Future<String?> getReflectionResponse(String input, String contextData) async {
    final apiKey = await _secretService.getGeminiKey();
    if (apiKey == null || apiKey.isEmpty) return null;

    final modelsToTry = ['gemini-1.5-flash', 'gemini-1.5-pro', 'gemini-pro'];

    for (final modelName in modelsToTry) {
      try {
        final model = GenerativeModel(model: modelName, apiKey: apiKey);
        final prompt = '''
        You are "The Mirror", the soulful AI companion of a Life OS app. 
        You help the user reflect on their life data.
        
        CONTEXT DATA (Tasks, Habits, Journals): 
        $contextData

        USER QUERY: 
        "$input"

        INSTRUCTIONS:
        - Be insightful, empathetic, and concise.
        - Use the context data to answer the user's question directly.
        - Use markdown (e.g., **bold**, • bullets) for readability.
        - If the query is about stats, summarize them beautifully.
        - If you don't know something from the context, say so gracefully.
        ''';

        final response = await model.generateContent([Content.text(prompt)]);
        return response.text;
      } catch (e) {
        print('AI Reflection: $modelName failed: $e');
        if (e.toString().contains('404')) continue;
        break;
      }
    }
    return null;
  }

  Future<List<double>?> embedText(String text) async {
    final apiKey = await _secretService.getGeminiKey();
    if (apiKey == null || apiKey.isEmpty) return null;

    try {
      // Use the dedicated embedding model
      final model = GenerativeModel(model: 'text-embedding-004', apiKey: apiKey);
      final content = Content.text(text);
      final result = await model.embedContent(content);
      return result.embedding.values.map((v) => v.toDouble()).toList();
    } catch (e) {
      print('AI Embedding failed: $e');
      return null;
    }
  }
}

final aiServiceProvider = Provider<AIService>((ref) {
  final secretService = ref.watch(secretServiceProvider);
  return AIService(secretService);
});
