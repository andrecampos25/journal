import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/services/supabase_service.dart';
import 'package:life_os/core/utils/gamification_logic.dart';

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
  await service.signIn(); // Ensure auth

  final activityDates = await service.getHabitActivityDates();
  final streak = GamificationLogic.calculateStreak(activityDates);
  
  final totalXp = await service.getTotalXp();
  final level = GamificationLogic.calculateLevel(totalXp);
  final progress = GamificationLogic.calculateLevelProgress(totalXp);
  
final userStatsProvider = FutureProvider<UserStats>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  await service.signIn();

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

final dailyEntryProvider = FutureProvider.family<Map<String, dynamic>?, DateTime>((ref, date) async {
  final service = ref.watch(supabaseServiceProvider);
  // Ensure we are signed in
  await service.signIn(); 
  return service.getDailyEntry(date);
});

// Journal History
final journalHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  await service.signIn();
  return service.getJournalHistory();
});

// --- Habits ---

// Combined model for Habit + Status
class HabitView {
  final String id;
  final String title;
  final bool isCompleted;

  HabitView({required this.id, required this.title, required this.isCompleted});
}

final todayHabitsProvider = FutureProvider.family<List<HabitView>, DateTime>((ref, date) async {
  final service = ref.watch(supabaseServiceProvider);
  await service.signIn();

  final habits = await service.getHabits();
  final completedIds = await service.getTodayHabitLogIds(date);

  return habits.map((h) {
    return HabitView(
      id: h['id'],
      title: h['title'],
      isCompleted: completedIds.contains(h['id']),
    );
  }).toList();
});

// All habits for management
final allHabitsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  await service.signIn();
  return service.getAllHabits();
});

// --- Tasks ---

final todayTasksProvider = FutureProvider.family<List<Map<String, dynamic>>, DateTime>((ref, date) async {
  final service = ref.watch(supabaseServiceProvider);
  await service.signIn();
  return service.getTodayTasks(date);
});

// All active tasks for management
final allTasksProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  await service.signIn();
  return service.getAllActiveTasks();
});
