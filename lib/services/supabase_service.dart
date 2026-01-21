import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// part 'supabase_service.g.dart';

import 'package:life_os/services/offline_service.dart';

class SupabaseService {
  final SupabaseClient _client;
  final OfflineService _offlineService;

  SupabaseService(this._client, this._offlineService);

  // Auth: Sign in anonymously to get a UID for RLS
  Future<void> signIn() async {
    final session = _client.auth.currentSession;
    if (session == null) {
      await _client.auth.signInAnonymously();
    }
  }

  String get userId => _client.auth.currentUser!.id;

  // --- Gamification ---
  
  // Get all unique dates where a habit was completed (for streak)
  Future<List<String>> getHabitActivityDates() async {
    final response = await _client
        .from('habit_logs')
        .select('completed_at')
        .eq('user_id', userId)
        .order('completed_at', ascending: false);
        
    return (response as List).map((e) => (e['completed_at'] as String).split('T')[0]).toList();
  }
  
  // Get Total XP (Simulated for MVP by counting records?)
  // Real way: 'user_stats' table. 
  // MVP way: Count rows in relevant tables and multiply.
  // habits * 10, tasks * 15, entries * 20.
  // This is expensive on read but fine for MVP with low data volume.
  Future<int> getTotalXp() async {
    final habitsCount = await _client.from('habit_logs').count().eq('user_id', userId);
    final tasksCount = await _client.from('tasks').count().eq('user_id', userId).eq('is_completed', true);
    final entriesCount = await _client.from('daily_entries').count().eq('user_id', userId);
    
    return (habitsCount * 10) + (tasksCount * 15) + (entriesCount * 20);
  }

  // --- Daily Entries (Journal + Mood) ---
  
  // Get today's entry
  Future<Map<String, dynamic>?> getDailyEntry(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final cacheKey = 'daily_entry_$dateStr';

    try {
      if (await _offlineService.isOnline) {
        final response = await _client
            .from('daily_entries')
            .select()
            .eq('user_id', userId)
            .eq('entry_date', dateStr)
            .maybeSingle();
            
        if (response != null) {
          await _offlineService.cacheData(cacheKey, response);
        }
        return response;
      } else {
        // Offline: Try Cache
        final cached = _offlineService.getCachedData(cacheKey);
        if (cached != null) return Map<String, dynamic>.from(cached);
        return null;
      }
    } catch (e) {
      // Fallback
      final cached = _offlineService.getCachedData(cacheKey);
      if (cached != null) return Map<String, dynamic>.from(cached);
      return null;
    }
  }

  // Upsert entry (save mood/journal)
  Future<void> upsertDailyEntry(DateTime date, {int? mood, String? journal}) async {
    final dateStr = date.toIso8601String().split('T')[0];
    
    // First check if exists to preserve other fields if only updating one
    final existing = await getDailyEntry(date);
    
    final data = {
      'user_id': userId,
      'entry_date': dateStr,
      if (mood != null) 'mood_score': mood,
      if (journal != null) 'journal_text': journal,
      // If creating new, created_at defaults to now()
    };

    final data = {
      'user_id': userId,
      'entry_date': dateStr,
      if (mood != null) 'mood_score': mood,
      if (journal != null) 'journal_text': journal,
      // If creating new, created_at defaults to now()
    };

    if (await _offlineService.isOnline) {
      if (existing != null) {
         await _client.from('daily_entries').update(data).eq('id', existing['id']);
      } else {
         await _client.from('daily_entries').insert(data);
      }
      // Update cache
      final cacheKey = 'daily_entry_$dateStr';
      // We need the full object to cache. Ideally fetch again or construct it.
      // Construct:
      final newEntry = {
        'id': existing?['id'] ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
        ...data
      };
      await _offlineService.cacheData(cacheKey, newEntry);
    } else {
      // Offline Queue
      await _offlineService.queueMutation('upsert_entry', {
        'date': date.toIso8601String(),
        'mood': mood,
        'journal': journal,
      });
      
      // Optimistic Cache
      final cacheKey = 'daily_entry_$dateStr';
      final cached = _offlineService.getCachedData(cacheKey) ?? {};
      final newEntry = {
        ...cached,
        'user_id': userId,
        'entry_date': dateStr,
        if (mood != null) 'mood_score': mood,
        if (journal != null) 'journal_text': journal,
      };
      await _offlineService.cacheData(cacheKey, newEntry);
    }
  }

  // Get all journal entries (history)
  Future<List<Map<String, dynamic>>> getJournalHistory() async {
    return await _client
        .from('daily_entries')
        .select()
        .eq('user_id', userId)
        .order('entry_date', ascending: false);
  }

  // --- Habits ---

  // Get active habits
  Future<List<Map<String, dynamic>>> getHabits() async {
    const cacheKey = 'habits_active';
    try {
      if (await _offlineService.isOnline) {
        final response = await _client
            .from('habits')
            .select()
            .eq('user_id', userId)
            .eq('archived', false)
            .order('created_at');
        
        // Cache list
        await _offlineService.cacheData(cacheKey, response);
        return List<Map<String, dynamic>>.from(response);
      } else {
        final cached = _offlineService.getCachedData(cacheKey);
        if (cached != null) return List<Map<String, dynamic>>.from(cached);
        return [];
      }
    } catch (e) {
      final cached = _offlineService.getCachedData(cacheKey);
      if (cached != null) return List<Map<String, dynamic>>.from(cached);
      return [];
    }
  }

  // Get ALL habits (for management)
  Future<List<Map<String, dynamic>>> getAllHabits() async {
    const cacheKey = 'habits_all';
    try {
      if (await _offlineService.isOnline) {
        final response = await _client
            .from('habits')
            .select()
            .eq('user_id', userId)
            .order('created_at');
         
        await _offlineService.cacheData(cacheKey, response);
        return List<Map<String, dynamic>>.from(response);
      } else {
        final cached = _offlineService.getCachedData(cacheKey);
        if (cached != null) return List<Map<String, dynamic>>.from(cached);
        return [];
      }
    } catch (e) {
       final cached = _offlineService.getCachedData(cacheKey);
       if (cached != null) return List<Map<String, dynamic>>.from(cached);
       return [];
    }
  }

  // Create Habit
  Future<void> createHabit(String title) async {
    await _client.from('habits').insert({
      'user_id': userId,
      'title': title,
      // description, frequency etc can be added later
    });
  }

  // Update Habit
  Future<void> updateHabit(String id, String title) async {
    await _client.from('habits').update({'title': title}).eq('id', id);
  }

  // Archive/Unarchive Habit
  Future<void> setHabitArchived(String id, bool archived) async {
    await _client.from('habits').update({'archived': archived}).eq('id', id);
  }

  // Toggle habit for today
  Future<void> toggleHabit(String habitId, DateTime date, bool isCompleted) async {
    // This requires complex logic: 
    // 1. Check if log exists for today.
    // 2. If isCompleted && !exists -> Insert log
    // 3. If !isCompleted && exists -> Delete log
    // 4. Update habit streaks (handled by DB triggers or separate logic? PRD said App Logic)
    
    // For MVP Phase 2, just handling the log.
    
    // Start of day
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    if (await _offlineService.isOnline) {
       if (isCompleted) {
         await _client.from('habit_logs').insert({
           'habit_id': habitId,
           'user_id': userId,
           'completed_at': DateTime.now().toIso8601String(),
         });
       } else {
         // Find log for today and delete
          await _client
             .from('habit_logs')
             .delete()
             .eq('habit_id', habitId)
             .eq('user_id', userId)
             .gte('completed_at', startOfDay.toIso8601String())
             .lte('completed_at', endOfDay.toIso8601String());
       }
       // Update cache for read consistency immediately? 
       // Ideally we just invalidate, but we can also manual update cache.
    } else {
      // Offline: Add to Queue
      await _offlineService.queueMutation('toggle_habit', {
        'habitId': habitId,
        'date': date.toIso8601String(),
        'isCompleted': isCompleted
      });
      
      // Optimistic Cache Update
      final dateStr = date.toIso8601String().split('T')[0];
      final cacheKey = 'habit_logs_$dateStr';
      final currentLogs = List<String>.from(_offlineService.getCachedData(cacheKey) ?? []);
      
      if (isCompleted) {
        if (!currentLogs.contains(habitId)) currentLogs.add(habitId);
      } else {
        currentLogs.remove(habitId);
      }
      await _offlineService.cacheData(cacheKey, currentLogs);
    }
  }
  
  // Get logs for today (to know which are done)
  Future<List<String>> getTodayHabitLogIds(DateTime date) async {
  // Get logs for today (to know which are done)
  Future<List<String>> getTodayHabitLogIds(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final dateStr = date.toIso8601String().split('T')[0];
    final cacheKey = 'habit_logs_$dateStr';

    try {
      if (await _offlineService.isOnline) {
        final response = await _client
            .from('habit_logs')
            .select('habit_id')
            .eq('user_id', userId)
            .gte('completed_at', startOfDay.toIso8601String())
            .lte('completed_at', endOfDay.toIso8601String());
            
        final ids = (response as List).map((e) => e['habit_id'] as String).toList();
        await _offlineService.cacheData(cacheKey, ids);
        return ids;
      } else {
        final cached = _offlineService.getCachedData(cacheKey);
        if (cached != null) return List<String>.from(cached);
        return [];
      }
    } catch (e) {
      final cached = _offlineService.getCachedData(cacheKey);
      if (cached != null) return List<String>.from(cached);
      return [];
    }
  }

  // --- Tasks ---

  // Get tasks due today or overdue
  Future<List<Map<String, dynamic>>> getTodayTasks(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final cacheKey = 'tasks_today_$dateStr';
    
    try {
      if (await _offlineService.isOnline) {
        final response = await _client
            .from('tasks')
            .select()
            .eq('user_id', userId)
            .eq('is_completed', false)
            .lte('due_date', dateStr) // Due today or earlier
            .order('due_date');
            
        await _offlineService.cacheData(cacheKey, response);
        return List<Map<String, dynamic>>.from(response);
      } else {
        final cached = _offlineService.getCachedData(cacheKey);
        if (cached != null) return List<Map<String, dynamic>>.from(cached);
        return [];
      }
    } catch (e) {
      final cached = _offlineService.getCachedData(cacheKey);
      if (cached != null) return List<Map<String, dynamic>>.from(cached);
      return [];
    }
  }

  // Get ALL active tasks (for management)
  Future<List<Map<String, dynamic>>> getAllActiveTasks() async {
    return await _client
        .from('tasks')
        .select()
        .eq('user_id', userId)
        .eq('is_completed', false)
        .order('due_date'); // Show soonest due first
        // We could also show completed ones separately
  }

  // Create Task
  Future<void> createTask(String title, DateTime? dueDate) async {
    await _client.from('tasks').insert({
      'user_id': userId,
      'title': title,
      'due_date': dueDate?.toIso8601String(),
    });
  }

  // Update Task
  Future<void> updateTask(String id, String title, DateTime? dueDate) async {
    await _client.from('tasks').update({
       'title': title,
       'due_date': dueDate?.toIso8601String(),
    }).eq('id', id);
  }

  // Complete Task (we already have a query for dashboard but maybe we need explicit toggle here too?)
  // Let's add explicit toggle.
  Future<void> toggleTaskCompletion(String id, bool isCompleted) async {
    await _client.from('tasks').update({'is_completed': isCompleted}).eq('id', id);
  }

  // Delete Task
  Future<void> deleteTask(String id) async {
    await _client.from('tasks').delete().eq('id', id);
  }
  // --- Sync Logic ---
  
  Future<void> syncPendingMutations() async {
    if (!await _offlineService.isOnline) return;
    
    final queue = _offlineService.getQueue();
    if (queue.isEmpty) return;
    
    for (final mutation in queue) {
      try {
        final type = mutation['type'];
        final payload = mutation['payload'] as Map;
        
        switch (type) {
          case 'toggle_habit':
             await toggleHabit(
               payload['habitId'] as String, 
               DateTime.parse(payload['date'] as String), 
               payload['isCompleted'] as bool
             );
             break;
          case 'upsert_entry':
             await upsertDailyEntry(
               DateTime.parse(payload['date'] as String),
               mood: payload['mood'] as int?,
               journal: payload['journal'] as String?
             );
             break;
          // Add other cases (create_habit, create_task) if implemented offline
        }
        
        // Remove from queue on success
        await _offlineService.removeFromQueue(mutation['id']);
      } catch (e) {
        // Keep in queue if failed? Or skip?
        // simple retry next time
        print('Sync failed for ${mutation['id']}: $e');
      }
    }
  }
}


// SupabaseService supabaseService(SupabaseServiceRef ref) {
//   return SupabaseService(Supabase.instance.client);
// }

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  final offlineService = ref.watch(offlineServiceProvider);
  return SupabaseService(Supabase.instance.client, offlineService);
});
