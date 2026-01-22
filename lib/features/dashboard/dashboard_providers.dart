import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/services/supabase_service.dart';
import 'package:life_os/core/utils/gamification_logic.dart';
import 'package:life_os/core/models/models.dart';

// --- Gamification ---

class UserStats {
  final int streak;
  final int level;
  final double currentLevelProgress;
  final int totalXp;

  UserStats({
    required this.streak, 
    required this.level, 
    required this.currentLevelProgress,
    required this.totalXp
  });
}


final userStatsProvider = FutureProvider<UserStats>((ref) async {
  final service = ref.watch(supabaseServiceProvider);

  final activityDates = await service.getHabitActivityDates();
  final streak = GamificationLogic.calculateStreak(activityDates);
  
  final totalXp = await service.getTotalXp();
  final level = GamificationLogic.calculateLevel(totalXp);
  final progress = GamificationLogic.calculateLevelProgress(totalXp);
  
  return UserStats(
    streak: streak,
    level: level,
    currentLevelProgress: progress,
    totalXp: totalXp
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
    return service.getTodayTasks(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(supabaseServiceProvider);
      final tasks = await service.getTodayTasks(arg, forceRefresh: true);
      state = AsyncValue.data(tasks);
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
