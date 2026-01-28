import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:life_os/services/ai_service.dart';
import 'package:life_os/features/mirror/services/life_ledger_service.dart';
import 'package:life_os/features/dashboard/dashboard_providers.dart';
import 'package:life_os/services/supabase_service.dart';
import 'package:life_os/core/models/task.dart';
import 'package:life_os/core/models/habit.dart';
import 'package:life_os/core/models/daily_entry.dart';
import 'dart:async';
import 'dart:convert';

class ReflectionMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Map<String, dynamic>? suggestion;

  ReflectionMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.suggestion,
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

class ReflectionChatNotifier extends AsyncNotifier<ReflectionChatState> {
  @override
  FutureOr<ReflectionChatState> build() async {
    // 1. Load history from Supabase
    final supabase = ref.read(supabaseServiceProvider);
    try {
      final history = await supabase.getChatHistory();
      
      if (history.isEmpty) {
        return ReflectionChatState(
          messages: [
            ReflectionMessage(
              text: 'Hello. I am the Mirror. I analyze your habits, tasks, and notes to surface insights.',
              isUser: false,
            ),
          ],
        );
      }

      return ReflectionChatState(
        messages: history.map((m) => ReflectionMessage(
          text: m['text'] as String,
          isUser: m['is_user'] as bool,
          timestamp: DateTime.parse(m['created_at'] as String),
        )).toList(),
      );
    } catch (e) {
      debugPrint('Memory: Table chat_messages not found or access denied. Running in session-only mode.');
      return ReflectionChatState(
        messages: [
          ReflectionMessage(
            text: '✨ **The Mirror is active (Session-only).**\n\nTo enable long-term memory, please apply the `chat_messages` SQL migration in your Supabase dashboard.',
            isUser: false,
          ),
        ],
      );
    }
  }

  Future<void> sendMessage(String text) async {
    debugPrint('sendMessage started with text: $text');
    final currentState = state.value ?? ReflectionChatState();
    
    // Add user message to state
    state = AsyncValue.data(currentState.copyWith(
      messages: [...currentState.messages, ReflectionMessage(text: text, isUser: true)],
      isLoading: true,
    ));

    print('DEBUG: User message added to state. Loading history logic...');
    // Persist user message (Try-catch to prevent blocking AI logic if table missing)
    try {
      ref.read(supabaseServiceProvider).saveChatMessage(text, true);
      debugPrint('saveChatMessage called');
    } catch (e) {
      debugPrint('saveChatMessage error: $e');
    }

    try {
      final ai = ref.read(aiServiceProvider);
      final ledger = ref.read(lifeLedgerServiceProvider);
      
      debugPrint('Starting Context Gathering...');
      
      // 1. Context Gathering (With individual safety catches & timeouts)
      List<LedgerEntry> longTermInsights = [];
      try {
        longTermInsights = await ledger.search('insight', limit: 10).timeout(const Duration(seconds: 4));
        debugPrint('Insights gathered: ${longTermInsights.length}');
      } catch (e) { debugPrint('Insights failed: $e'); }

      List<LedgerEntry> historicalContext = [];
      try {
        historicalContext = await ledger.search(text, limit: 12).timeout(const Duration(seconds: 4));
        debugPrint('History gathered: ${historicalContext.length}');
      } catch (e) { debugPrint('History failed: $e'); }
      
      debugPrint('Searching tasks/habits...');
      final tasksAsync = await ref.read(allTasksProvider.future).timeout(const Duration(seconds: 4)).catchError((e) {
        debugPrint('Tasks future error: $e');
        return <Task>[];
      });
      final habitsAsync = await ref.read(allHabitsProvider.future).timeout(const Duration(seconds: 4)).catchError((e) {
        debugPrint('Habits future error: $e');
        return <Map<String, dynamic>>[];
      });
      
      // 2. Context synthesis - build a rich context string for the AI
      final contextParts = <String>[];
      
      if (longTermInsights.isNotEmpty) {
        contextParts.add('PAST INSIGHTS:\n' + longTermInsights.map((e) => '- ${e.content}').join('\n'));
      }
      
      if (historicalContext.isNotEmpty) {
        contextParts.add('HISTORICAL DATA:\n' + historicalContext.map((e) => '- ${e.content} (${e.sourceType})').join('\n'));
      }
      
      if (tasksAsync.isNotEmpty) {
        final activeTasks = tasksAsync.where((t) => !t.isCompleted).take(5);
        if (activeTasks.isNotEmpty) {
          contextParts.add('CURRENT TASKS:\n' + activeTasks.map((t) => '- ${t.title}').join('\n'));
        }
      }
      
      final contextStr = contextParts.isEmpty ? 'No context available.' : contextParts.join('\n\n');

      // 2. Prepare Chat History (minimal for now)
      final history = <Content>[];

      // 3. Get AI Response
      final response = await ai.getReflectionResponse(text, contextStr, history: history);
      debugPrint('AI response received: ${response != null}');

      if (response != null) {
        // 4. Memory Loop: Check for triggers
        _processInsights(response);
        final suggestion = _processSuggestions(response);

        // Persist AI message (original text includes triggers, we'll strip them in UI)
        try {
          ref.read(supabaseServiceProvider).saveChatMessage(response, false);
        } catch (e) {
          debugPrint('DEBUG: AI persist error: $e');
        }

        // Update state with AI response
        final newState = state.value ?? currentState;
        state = AsyncValue.data(newState.copyWith(
          messages: [
            ...newState.messages, 
            ReflectionMessage(
              text: response, 
              isUser: false,
              suggestion: suggestion,
            )
          ],
          isLoading: false,
        ));
      } else {
        throw Exception('AI Response Null');
      }
    } catch (e) {
      debugPrint('UNCAUGHT ERROR in sendMessage: $e');
      final newState = state.value ?? currentState;
      state = AsyncValue.data(newState.copyWith(
        messages: [...newState.messages, ReflectionMessage(text: 'I am struggling to find the words right now. Perhaps we can try again?', isUser: false)],
        isLoading: false,
      ));
    }
  }

  Map<String, dynamic>? _processSuggestions(String aiText) {
    if (aiText.contains('SUGGESTION:')) {
      try {
        final line = aiText.split('\n').firstWhere((l) => l.trim().startsWith('SUGGESTION:'));
        final jsonStr = line.replaceFirst('SUGGESTION:', '').trim();
        return json.decode(jsonStr) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('Failed to parse suggestion: $e');
      }
    }
    return null;
  }

  Future<void> acceptSuggestion(Map<String, dynamic> suggestion) async {
    final supabase = ref.read(supabaseServiceProvider);
    final type = suggestion['type'] as String;
    final title = suggestion['title'] as String;

    try {
      if (type == 'task') {
        await supabase.createTask(title, DateTime.now().add(const Duration(hours: 4)));
        ref.invalidate(todayTasksProvider);
        ref.invalidate(allTasksProvider);
      } else if (type == 'habit') {
        await supabase.createHabit(title);
        ref.invalidate(todayHabitsProvider);
        ref.invalidate(allHabitsProvider);
      }
      ref.invalidate(userStatsProvider);
      
      // Update chat state to show it was accepted
      final currentState = state.value;
      if (currentState != null) {
        state = AsyncValue.data(currentState.copyWith(
          messages: [
            ...currentState.messages,
            ReflectionMessage(text: '✅ Done. I have added "$title" to your ${type}s.', isUser: false)
          ]
        ));
      }
    } catch (e) {
      debugPrint('Failed to accept suggestion: $e');
    }
  }

  Future<void> dismissSuggestion(int index) async {
    final currentState = state.value;
    if (currentState != null && index < currentState.messages.length) {
      final messages = List<ReflectionMessage>.from(currentState.messages);
      final msg = messages[index];
      messages[index] = ReflectionMessage(
        text: msg.text,
        isUser: msg.isUser,
        timestamp: msg.timestamp,
        suggestion: null,
      );
      state = AsyncValue.data(currentState.copyWith(messages: messages));
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
              sourceType: 'journal',
              sourceId: 'ai_insight_${DateTime.now().millisecondsSinceEpoch}',
              content: '[AI Insight] $insight',
              sourceDate: DateTime.now(),
            );
            debugPrint('Memory Loop: Saved AI Insight: $insight');
          }
        }
      }
    }
  }
}

final reflectionChatProvider = AsyncNotifierProvider<ReflectionChatNotifier, ReflectionChatState>(() {
  return ReflectionChatNotifier();
});
