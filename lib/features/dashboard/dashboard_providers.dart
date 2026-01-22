import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/services/supabase_service.dart';
import 'package:life_os/core/utils/gamification_logic.dart';
import 'package:life_os/core/models/models.dart';

// --- Gamification ---

class UserStats {
  final int streak;

  UserStats({
    required this.streak, 
  });
}


final userStatsProvider = FutureProvider<UserStats>((ref) async {
  final service = ref.watch(supabaseServiceProvider);

  final activityDates = await service.getHabitActivityDates();
  final streak = GamificationLogic.calculateStreak(activityDates);
  
  return UserStats(
    streak: streak,
  );
});

// Selected Date for Dashboard (defaults to today)
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// --- Daily Entry ---

final dailyEntryProvider = FutureProvider.family<DailyEntry?, DateTime>((ref, date) async {
  final service = ref.watch(supabaseServiceProvider);
  return service.getDailyEntry(date);
});

// Journal History
final journalHistoryProvider = FutureProvider<List<DailyEntry>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  return service.getJournalHistory();
});

// --- Habits ---

// Combined model for Habit + Status
class HabitView {
  final String id;
  final String title;
  final String icon;
  final bool isCompleted;

  HabitView({required this.id, required this.title, required this.icon, required this.isCompleted});
}

// Habits Provider with Optimistic Updates
final todayHabitsProvider = AsyncNotifierProviderFamily<TodayHabitsNotifier, List<HabitView>, DateTime>(() {
  return TodayHabitsNotifier();
});

class TodayHabitsNotifier extends FamilyAsyncNotifier<List<HabitView>, DateTime> {
  @override
  Future<List<HabitView>> build(DateTime arg) async {
    final service = ref.watch(supabaseServiceProvider);

    final habits = await service.getHabits();
    final completedIds = await service.getTodayHabitLogIds(arg);

    final dayOfWeek = arg.weekday;

    return habits.where((h) {
      final freq = h['frequency'] as List?;
      if (freq == null || freq.isEmpty) return true;
      // Handle potential dynamic cast issues from Hive/Supabase
      return freq.map((e) => int.tryParse(e.toString())).contains(dayOfWeek);
    }).map((h) {
      return HabitView(
        id: h['id'],
        title: h['title'],
        icon: h['icon'] ?? '✨',
        isCompleted: completedIds.contains(h['id']),
      );
    }).toList();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(supabaseServiceProvider);
      final habits = await service.getHabits(forceRefresh: true);
      final completedIds = await service.getTodayHabitLogIds(arg);
      final dayOfWeek = arg.weekday;

      final newState = habits.where((h) {
        final freq = h['frequency'] as List?;
        if (freq == null || freq.isEmpty) return true;
        return freq.map((e) => int.tryParse(e.toString())).contains(dayOfWeek);
      }).map((h) {
        return HabitView(
          id: h['id'],
          title: h['title'],
          icon: h['icon'] ?? '✨',
          isCompleted: completedIds.contains(h['id']),
        );
      }).toList();
      state = AsyncValue.data(newState);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleHabit(String habitId, bool isCompleted) async {
    final date = arg;
    final previousState = state.value;
    
    // Optimistic Update
    if (state.hasValue) {
      state = AsyncValue.data(
        state.value!.map((h) => h.id == habitId ? HabitView(id: h.id, title: h.title, icon: h.icon, isCompleted: isCompleted) : h).toList()
      );
    }

    try {
      await ref.read(supabaseServiceProvider).toggleHabit(habitId, date, isCompleted);
      // Stats might need updating too
      ref.invalidate(userStatsProvider);
    } catch (e) {
      // Revert on error
      state = AsyncValue.data(previousState!);
    }
  }
}

// All habits for management
final allHabitsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  return service.getAllHabits();
});

// --- Tasks ---

// Tasks Provider with Optimistic Updates
final todayTasksProvider = AsyncNotifierProviderFamily<TodayTasksNotifier, List<Task>, DateTime>(() {
  return TodayTasksNotifier();
});

class TodayTasksNotifier extends FamilyAsyncNotifier<List<Task>, DateTime> {
  @override
  Future<List<Task>> build(DateTime arg) async {
    final service = ref.watch(supabaseServiceProvider);
    
    // 1. Fetch Today's Scheduled Tasks
    final todayTasks = await service.getTodayTasks(arg);
    
    // If we have 3 or more today tasks, we just show them (and maybe more)
    // The requirement implies we show *exactly* 3 in the dashboard card usually, 
    // but the provider returns a list. 
    // Wait, the Dashboard widget might slice it, or we slice it here?
    // "Top 3 priority tasks show up in dashboard".
    // "When no tasks are dated for today".
    // "When tasks are dated for today, replace top priority tasks starting from the 3rd to the 1st".
    
    // Actually, this provider `todayTasksProvider` is used by the `TodayTasksList` widget.
    // If this list is meant to represent "The 3 Tasks to Show", we should apply logic here.
    
    // Fetch ALL active backlog tasks (undated or future? No, usually priority is backlog)
    // Let's assume Priority = Active non-completed tasks (sorted by position), excluding Today's?
    // Or just All Active tasks? 
    // The prompt says "Top 3 priority tasks... when no tasks are dated for today".
    // This implies "Priority Tasks" are a separate bucket (e.g., undated backlog).
    // Let's assume we fetch all active tasks and filter out those scheduled for today to get "Backlog".
    
    final allActive = await service.getAllActiveTasks();
    
    // Filter Backlog: Tasks that are NOT scheduled for today (or already included in todayTasks)
    // We assume 'getAllActiveTasks' returns everything not completed.
    // 'todayTasks' are those with due_date <= today end of day.
    // So Backlog = Active tasks with NO due date OR due date in future? 
    // Usually "Priority" implies the user manually ordered them.
    // Let's exclude tasks with specific due dates today from "Backlog Source".
    
    final todayIds = todayTasks.map((t) => t.id).toSet();
    final backlog = allActive.where((t) => !todayIds.contains(t.id)).toList();
    
    // Logic:
    // We want a final list of 3 items max for the dashboard "Focus" view? 
    // Or does the user want this mixed list to be THE list shown?
    // "Top 3 priority tasks show up in dashboard".
    
    // Visualizing the Slots: [1] [2] [3]
    
    // Case 0: 0 Today Tasks.
    // Show Backlog[0], Backlog[1], Backlog[2].
    
    // Case 1: 1 Today Task.
    // Show Backlog[0], Backlog[1], Today[0]. 
    // (User said "replace top priority tasks starting from the 3rd to the 1st")
    // This confirms: Slot 3 is the first to go.
    
    // Case 2: 2 Today Tasks.
    // Show Backlog[0], Today[0], Today[1].
    
    // Case 3: 3+ Today Tasks.
    // Show Today[0], Today[1], Today[2]... 
    
    // WAIT. If I have 10 Today Tasks, do I show only 3? 
    // The request mentions "Top 3 priority tasks show up in dashboard". 
    // This implies the dashboard WIDGET has limited space (maybe 3 slots).
    // But `todayTasksProvider` might be used for a full list screen too?
    // No, `today_tasks_list.dart` is the widget. Use logic there?
    // BUT the provider is named `todayTasksProvider`. If I change its return to be this "Mixed Bag", 
    // it implies "Focus Tasks".
    
    // Let's construct this "Focus List".
    
    List<Task> result = [];
    
    if (todayTasks.isEmpty) {
      result.addAll(backlog.take(3));
    } else if (todayTasks.length == 1) {
      result.addAll(backlog.take(2));
      result.add(todayTasks[0]);
    } else if (todayTasks.length == 2) {
      result.addAll(backlog.take(1));
      result.addAll(todayTasks);
    } else {
      // 3 or more today tasks
      result.addAll(todayTasks); // Show all today tasks? Or just top 3?
      // User said "replace top priority tasks starting from the 3rd to the 1st".
      // If I have 3 today tasks, they take slots 3, 2, 1.
      // So result is just todayTasks.
    }
    
    return result;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(supabaseServiceProvider);
      final tasks = await service.getTodayTasks(arg, forceRefresh: true);
      
      // Rebuild the mixed view logic
      final allActive = await service.getAllActiveTasks();
      final todayIds = tasks.map((t) => t.id).toSet();
      final backlog = allActive.where((t) => !todayIds.contains(t.id)).toList();
      
      List<Task> result = [];
      
      if (tasks.isEmpty) {
        result.addAll(backlog.take(3));
      } else if (tasks.length == 1) {
        result.addAll(backlog.take(2));
        result.add(tasks[0]);
      } else if (tasks.length == 2) {
        result.addAll(backlog.take(1));
        result.addAll(tasks);
      } else {
        result.addAll(tasks);
      }
      
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleTask(String id, bool isCompleted) async {
    final previousState = state.value;

    // Optimistic Update
    if (state.hasValue) {
       state = AsyncValue.data(
         state.value!.map((t) => t.id == id ? t.copyWith(isCompleted: isCompleted) : t).toList()
       );
    }

    try {
      await ref.read(supabaseServiceProvider).toggleTaskCompletion(id, isCompleted);
      ref.invalidate(userStatsProvider);
      ref.invalidate(allTasksProvider);
    } catch (e) {
      state = AsyncValue.data(previousState!);
    }
  }
}

// All active tasks for management
final allTasksProvider = FutureProvider<List<Task>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  return service.getAllActiveTasks();
});
