import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:life_os/services/ai_service.dart';
import 'package:life_os/features/mirror/services/life_ledger_service.dart';
import 'package:life_os/features/dashboard/dashboard_providers.dart';
import 'dart:async';

class ReflectionMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ReflectionMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ReflectionChatState {
  final List<ReflectionMessage> messages;
  final bool isLoading;

  ReflectionChatState({
    this.messages = const [],
    this.isLoading = false,
  });

  ReflectionChatState copyWith({
    List<ReflectionMessage>? messages,
    bool? isLoading,
  }) {
    return ReflectionChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ReflectionChatNotifier extends AutoDisposeAsyncNotifier<ReflectionChatState> {
  @override
  FutureOr<ReflectionChatState> build() {
    // Initial welcome message
    return ReflectionChatState(
      messages: [
        ReflectionMessage(
          text: '👋 **I am The Mirror.**\n\nI am here to help you find meaning in your journey. Ask me anything about your history, or let\'s explore patterns you haven\'t noticed yet.',
          isUser: false,
        ),
      ],
    );
  }

  Future<void> sendMessage(String text) async {
    final currentState = state.value ?? ReflectionChatState();
    
    // Add user message to state
    state = AsyncValue.data(currentState.copyWith(
      messages: [...currentState.messages, ReflectionMessage(text: text, isUser: true)],
      isLoading: true,
    ));

    try {
      final ai = ref.read(aiServiceProvider);
      final ledger = ref.read(lifeLedgerServiceProvider);
      
      // 1. Context Gathering
      // Search the ledger for relevant historical context
      final historicalContext = await ledger.search(text, limit: 12);
      
      // Get current data for immediate context
      final tasks = await ref.read(allTasksProvider.future);
      final habits = await ref.read(allHabitsProvider.future);
      
      final contextStr = '''
      CURRENT STATUS:
      - Active Tasks: ${tasks.where((t) => !t.isCompleted).take(5).map((t) => t.title).join(', ')}
      - Tracked Habits: ${habits.take(5).map((h) => h['title']).join(', ')}
      
      HISTORICAL CONTEXT (from Life Ledger):
      ${historicalContext.map((e) => '[${e.sourceType}] ${e.content} (${e.sourceDate.toIso8601String().split('T')[0]})').join('\n')}
      ''';

      // 2. Prepare Chat History for Gemini
      final history = currentState.messages.map((m) {
        return m.isUser ? Content.text(m.text) : Content.model([TextPart(m.text)]);
      }).toList();

      // 3. Get AI Response
      final response = await ai.getReflectionResponse(text, contextStr, history: history);

      if (response != null) {
        // 4. Memory Loop: Check for "INSIGHT:" trigger
        _processInsights(response);

        // Update state with AI response
        final newState = state.value ?? currentState;
        state = AsyncValue.data(newState.copyWith(
          messages: [...newState.messages, ReflectionMessage(text: response, isUser: false)],
          isLoading: false,
        ));
      } else {
        throw Exception('No response from AI');
      }
    } catch (e) {
      final newState = state.value ?? currentState;
      state = AsyncValue.data(newState.copyWith(
        messages: [...newState.messages, ReflectionMessage(text: 'I am struggling to find the words right now. Perhaps we can try again?', isUser: false)],
        isLoading: false,
      ));
    }
  }

  void _processInsights(String aiText) {
    if (aiText.contains('INSIGHT:')) {
      final lines = aiText.split('\n');
      for (final line in lines) {
        if (line.trim().startsWith('INSIGHT:')) {
          final insight = line.replaceFirst('INSIGHT:', '').trim();
          if (insight.isNotEmpty) {
            // Persist the insight back to the Life Ledger
            ref.read(lifeLedgerServiceProvider).indexContent(
              sourceType: 'insight',
              sourceId: 'ai_insight_${DateTime.now().millisecondsSinceEpoch}',
              content: insight,
              sourceDate: DateTime.now(),
            );
            print('Memory Loop: Saved AI Insight: $insight');
          }
        }
      }
    }
  }
}

final reflectionChatProvider = AsyncNotifierProvider.autoDispose<ReflectionChatNotifier, ReflectionChatState>(() {
  return ReflectionChatNotifier();
});
