import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/services/supabase_service.dart';
import 'package:life_os/services/ai_service.dart';

/// The Life Ledger: Infinite Context Engine
/// 
/// This service manages semantic embeddings of all user data,
/// enabling cross-referencing of content from years ago with today's activities.
/// 
/// Note: Full functionality requires:
/// 1. pgvector extension enabled in Supabase
/// 2. Working AI/embedding service
/// 
/// Until then, this provides a placeholder that falls back to keyword search.
class LifeLedgerService {
  final SupabaseService _supabaseService;
  final AIService? _aiService;

  LifeLedgerService(this._supabaseService, this._aiService);

  /// Check if vector search is available
  Future<bool> isVectorSearchAvailable() async {
    try {
      // Try to query the embeddings table
      await _supabaseService.client
          .from('life_ledger_embeddings')
          .select('id')
          .limit(1);
      return true;
    } catch (e) {
      // Table doesn't exist or pgvector not enabled
      return false;
    }
  }

  /// Search the Life Ledger for semantically similar content
  /// Falls back to keyword search if vector search is unavailable
  Future<List<LedgerEntry>> search(String query, {int limit = 10}) async {
    final isAvailable = await isVectorSearchAvailable();
    final userId = _supabaseService.client.auth.currentUser?.id;
    
    if (isAvailable && _aiService != null && userId != null) {
      try {
        final embedding = await _aiService.embedText(query);
        if (embedding != null) {
          final List<dynamic> response = await _supabaseService.client.rpc(
            'search_life_ledger',
            params: {
              'p_user_id': userId,
              'p_query_embedding': embedding,
              'p_limit': limit,
            },
          );
          
          return response.map((item) => LedgerEntry(
            sourceType: item['source_type'],
            sourceId: item['source_id'],
            content: item['content'],
            sourceDate: DateTime.parse(item['source_date']),
            similarity: item['similarity'],
          )).toList();
        }
      } catch (e) {
        debugPrint('LifeLedger Search failed: $e');
      }
    }
    
    return _keywordSearch(query, limit: limit);
  }

  /// Fallback keyword search across all data
  Future<List<LedgerEntry>> _keywordSearch(String query, {int limit = 10}) async {
    final results = <LedgerEntry>[];
    final keywords = query.toLowerCase().split(' ').where((w) => w.length > 2).toList();
    
    if (keywords.isEmpty) return results;

    // Search tasks
    try {
      final tasks = await _supabaseService.client
          .from('tasks')
          .select('id, title, due_date, created_at')
          .or(keywords.map((k) => 'title.ilike.%$k%').join(','))
          .limit(limit);
      
      for (final task in tasks) {
        results.add(LedgerEntry(
          sourceType: 'task',
          sourceId: task['id'],
          content: task['title'],
          sourceDate: task['due_date'] != null 
              ? DateTime.parse(task['due_date']) 
              : DateTime.parse(task['created_at']),
        ));
      }
    } catch (e) { /* ignore */ }

    // Search habits
    try {
      final habits = await _supabaseService.client
          .from('habits')
          .select('id, title, created_at')
          .or(keywords.map((k) => 'title.ilike.%$k%').join(','))
          .limit(limit);
      
      for (final habit in habits) {
        results.add(LedgerEntry(
          sourceType: 'habit',
          sourceId: habit['id'],
          content: habit['title'],
          sourceDate: DateTime.parse(habit['created_at']),
        ));
      }
    } catch (e) { /* ignore */ }

    // Search journal entries
    try {
      final journals = await _supabaseService.client
          .from('daily_entries')
          .select('id, journal_text, entry_date')
          .or(keywords.map((k) => 'journal_text.ilike.%$k%').join(','))
          .limit(limit);
      
      for (final entry in journals) {
        if (entry['journal_text'] != null) {
          results.add(LedgerEntry(
            sourceType: 'journal',
            sourceId: entry['id'],
            content: entry['journal_text'],
            sourceDate: DateTime.parse(entry['entry_date']),
          ));
        }
      }
    } catch (e) { /* ignore */ }

    results.sort((a, b) => b.sourceDate.compareTo(a.sourceDate));
    return results.take(limit).toList();
  }

  /// Index new content into the Life Ledger
  Future<void> indexContent({
    required String sourceType,
    required String sourceId,
    required String content,
    required DateTime sourceDate,
  }) async {
    final isAvailable = await isVectorSearchAvailable();
    final userId = _supabaseService.client.auth.currentUser?.id;
    if (!isAvailable || userId == null || _aiService == null) return;

    try {
      final embedding = await _aiService.embedText(content);
      await _supabaseService.client.from('life_ledger_embeddings').upsert({
        'user_id': userId,
        'source_type': sourceType,
        'source_id': sourceId,
        'content': content,
        'source_date': sourceDate.toIso8601String().split('T')[0],
        'embedding': embedding,
      });
    } catch (e) {
      debugPrint('LifeLedger Indexing failed: $e');
    }
  }
}

class LedgerEntry {
  final String sourceType;
  final String sourceId;
  final String content;
  final DateTime sourceDate;
  final double? similarity;

  LedgerEntry({
    required this.sourceType,
    required this.sourceId,
    required this.content,
    required this.sourceDate,
    this.similarity,
  });

  String get typeEmoji {
    switch (sourceType) {
      case 'task': return '✓';
      case 'habit': return '🔥';
      case 'journal': return '📝';
      default: return '•';
    }
  }
}

final lifeLedgerServiceProvider = Provider<LifeLedgerService>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  final aiService = ref.watch(aiServiceProvider);
  return LifeLedgerService(supabaseService, aiService);
});
