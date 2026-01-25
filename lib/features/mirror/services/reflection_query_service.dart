import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/features/dashboard/dashboard_providers.dart';
import 'package:life_os/core/models/models.dart';
import 'package:life_os/services/ai_service.dart';
import 'package:life_os/features/mirror/services/life_ledger_service.dart';

/// A service for querying user data with natural language-like patterns.
class ReflectionQueryService {
  final Ref ref;

  ReflectionQueryService(this.ref);

  /// Process a query and return a response
  Future<ReflectionResponse> query(String input) async {
    final lowerInput = input.toLowerCase().trim();

    // Try AI first for a "soulful" response if it's not a clear command
    if (lowerInput.split(' ').length > 3) {
      final ai = ref.read(aiServiceProvider);
      
      // Gather current context
      final tasks = await ref.read(allTasksProvider.future);
      final habits = await ref.read(allHabitsProvider.future);
      final journals = await ref.read(journalHistoryProvider.future);
      
      // Gather historical context via Life Ledger
      final ledger = ref.read(lifeLedgerServiceProvider);
      final historicalContext = await ledger.search(input, limit: 10);
      
      final context = '''
      CURRENT TASKS: ${tasks.take(10).map((t) => t.title).join(', ')}
      RECENT HABITS: ${habits.take(10).map((h) => h['title']).join(', ')}
      RECENT JOURNALS: ${journals.take(5).map((j) => j.journalText).join(' | ')}
      
      HISTORICAL PATTERNS (from Life Ledger):
      ${historicalContext.map((e) => '[${e.sourceType}] ${e.content} (${e.sourceDate.toIso8601String().split('T')[0]})').join('\n')}
      ''';

      final aiResponse = await ai.getReflectionResponse(input, context);
      if (aiResponse != null && aiResponse.isNotEmpty) {
        return ReflectionResponse(
          message: aiResponse,
          type: ResponseType.insight,
        );
      }
    }

    // Fallback to local logic for specific commands
    if (lowerInput.contains('how many') || lowerInput.contains('count')) {
      return await _handleStatsQuery(lowerInput);
    }

    // Date-based queries
    if (lowerInput.contains('today') || 
        lowerInput.contains('yesterday') || 
        lowerInput.contains('this week') ||
        lowerInput.contains('last week')) {
      return await _handleDateQuery(lowerInput);
    }

    // Search queries
    if (lowerInput.contains('show') || 
        lowerInput.contains('find') || 
        lowerInput.contains('search')) {
      return await _handleSearchQuery(lowerInput);
    }

    // Default: try to find matching content
    return await _handleSearchQuery(lowerInput);
  }

  Future<ReflectionResponse> _handleStatsQuery(String input) async {
    final tasks = await ref.read(allTasksProvider.future);
    final habits = await ref.read(allHabitsProvider.future);
    final journals = await ref.read(journalHistoryProvider.future);

    final completedTasks = tasks.where((t) => t.isCompleted).length;
    final totalTasks = tasks.length;
    final totalHabits = habits.length;
    final totalJournals = journals.length;

    if (input.contains('task')) {
      return ReflectionResponse(
        message: 'You have **$totalTasks tasks** total. $completedTasks are completed.',
        type: ResponseType.stats,
        data: {'completed': completedTasks, 'total': totalTasks},
      );
    }

    if (input.contains('habit')) {
      return ReflectionResponse(
        message: 'You are tracking **$totalHabits habits**.',
        type: ResponseType.stats,
        data: {'total': totalHabits},
      );
    }

    if (input.contains('journal') || input.contains('entry') || input.contains('entries')) {
      return ReflectionResponse(
        message: 'You have **$totalJournals journal entries** in your history.',
        type: ResponseType.stats,
        data: {'total': totalJournals},
      );
    }

    // General stats
    return ReflectionResponse(
      message: '📊 **Your Life at a Glance**\n\n'
          '• $totalTasks tasks ($completedTasks completed)\n'
          '• $totalHabits habits tracked\n'
          '• $totalJournals journal entries',
      type: ResponseType.stats,
      data: {
        'tasks': totalTasks,
        'completedTasks': completedTasks,
        'habits': totalHabits,
        'journals': totalJournals,
      },
    );
  }

  Future<ReflectionResponse> _handleDateQuery(String input) async {
    DateTime targetDate;
    String dateLabel;

    if (input.contains('yesterday')) {
      targetDate = DateTime.now().subtract(const Duration(days: 1));
      dateLabel = 'yesterday';
    } else if (input.contains('last week')) {
      targetDate = DateTime.now().subtract(const Duration(days: 7));
      dateLabel = 'last week';
    } else {
      targetDate = DateTime.now();
      dateLabel = 'today';
    }

    final tasks = await ref.read(todayTasksProvider(targetDate).future);
    final habits = await ref.read(todayHabitsProvider(targetDate).future);

    final taskTitles = tasks.map((t) => '• ${t.title}').join('\n');
    final habitTitles = habits.map((h) => '• ${h.title}').join('\n');

    String message = '📅 **$dateLabel**\n\n';
    
    if (tasks.isNotEmpty) {
      message += '**Tasks:**\n$taskTitles\n\n';
    } else {
      message += 'No tasks for $dateLabel.\n\n';
    }

    if (habits.isNotEmpty) {
      message += '**Habits:**\n$habitTitles';
    } else {
      message += 'No habit data for $dateLabel.';
    }

    return ReflectionResponse(
      message: message,
      type: ResponseType.list,
      data: {'tasks': tasks.length, 'habits': habits.length},
    );
  }

  Future<ReflectionResponse> _handleSearchQuery(String input) async {
    // Extract search terms
    final searchTerms = input
        .replaceAll(RegExp(r'(show|find|search|me|the|for|about|related|to)', caseSensitive: false), '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2)
        .toList();

    if (searchTerms.isEmpty) {
      return ReflectionResponse(
        message: '🔍 What would you like to search for? Try asking about tasks, habits, or journal entries.',
        type: ResponseType.prompt,
      );
    }

    final tasks = await ref.read(allTasksProvider.future);
    final habits = await ref.read(allHabitsProvider.future);
    final journals = await ref.read(journalHistoryProvider.future);

    final matchingTasks = tasks.where((t) =>
        searchTerms.any((term) => t.title.toLowerCase().contains(term))).toList();
    
    final matchingHabits = habits.where((h) {
      final title = (h['title'] as String? ?? '').toLowerCase();
      return searchTerms.any((term) => title.contains(term));
    }).toList();

    final matchingJournals = journals.where((j) =>
        searchTerms.any((term) => (j.journalText ?? '').toLowerCase().contains(term))).toList();

    if (matchingTasks.isEmpty && matchingHabits.isEmpty && matchingJournals.isEmpty) {
      return ReflectionResponse(
        message: '🔍 No results found for "${searchTerms.join(' ')}".\n\nTry different keywords or ask about your stats.',
        type: ResponseType.empty,
      );
    }

    String message = '🔍 **Results for "${searchTerms.join(' ')}"**\n\n';

    if (matchingTasks.isNotEmpty) {
      message += '**Tasks (${matchingTasks.length}):**\n';
      message += matchingTasks.take(5).map((t) => '• ${t.title}').join('\n');
      message += '\n\n';
    }

    if (matchingHabits.isNotEmpty) {
      message += '**Habits (${matchingHabits.length}):**\n';
      message += matchingHabits.take(5).map((h) => '• ${h['title']}').join('\n');
      message += '\n\n';
    }

    if (matchingJournals.isNotEmpty) {
      message += '**Journal Entries (${matchingJournals.length}):**\n';
      message += matchingJournals.take(3).map((j) {
        final preview = (j.journalText ?? '').length > 60 
            ? '${j.journalText!.substring(0, 60)}...' 
            : j.journalText ?? '';
        return '• $preview';
      }).join('\n');
    }

    return ReflectionResponse(
      message: message.trim(),
      type: ResponseType.list,
      data: {
        'tasks': matchingTasks.length,
        'habits': matchingHabits.length,
        'journals': matchingJournals.length,
      },
    );
  }
}

enum ResponseType { stats, list, prompt, empty, insight }

class ReflectionResponse {
  final String message;
  final ResponseType type;
  final Map<String, dynamic>? data;

  ReflectionResponse({
    required this.message,
    required this.type,
    this.data,
  });
}

final reflectionQueryServiceProvider = Provider<ReflectionQueryService>((ref) {
  return ReflectionQueryService(ref);
});
