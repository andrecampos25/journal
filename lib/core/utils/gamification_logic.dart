import 'dart:math';
import 'package:life_os/services/supabase_service.dart';

class GamificationLogic {
  
  // Calculate Streak: Consecutive days with at least one completed habit or daily entry
  // For MVP: We will just check Habit Logs for now, or maybe Daily Entries (Journaling). 
  // Let's use Habit Logs as the primary driver for streaks.
  static int calculateStreak(List<String> completedDates) {
    if (completedDates.isEmpty) return 0;

    // Sort dates descending
    final dates = completedDates.map((d) => DateTime.parse(d)).toList()
      ..sort((a, b) => b.compareTo(a));
    
    // Normalize to dates only (no time)
    final normalizedDates = dates.map((d) => DateTime(d.year, d.month, d.day)).toSet().toList(); // unique days
    
    if (normalizedDates.isEmpty) return 0;

    int streak = 0;
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    
    // Check if the most recent activity was today or yesterday. 
    // If most recent is older than yesterday, streak is broken (unless we start counting from there? No, streak is 0 if broken).
    // Actually, widespread logic: Current streak is valid if active Today OR Yesterday.
    
    final lastActive = normalizedDates.first;
    final diff = todayNormalized.difference(lastActive).inDays;
    
    if (diff > 1) {
      return 0; // Streak broken
    }

    // Iterate backwards
    DateTime checkDate = lastActive;
    streak = 1;
    
    for (int i = 1; i < normalizedDates.length; i++) {
        final prevDate = normalizedDates[i];
        final expectedPrev = checkDate.subtract(const Duration(days: 1));
        
        if (prevDate.year == expectedPrev.year && 
            prevDate.month == expectedPrev.month && 
            prevDate.day == expectedPrev.day) {
          streak++;
          checkDate = prevDate;
        } else {
          break;
        }
    }
    
    return streak;
  }
  
  // Calculate XP and Level
  // Logic: 
  // 1 Habit = 10 XP
  // 1 Daily Entry = 20 XP
  // 1 Task = 15 XP
  // Level N requires N * 100 XP? Or incremental curve.
  // Simple: Level = Floor(TotalXP / 100) + 1.
  
  static int calculateLevel(int totalXp) {
    // Inverse of: totalXp = 50 * L * (L + 1)
    // L = (-50 + sqrt(2500 + 200 * totalXp)) / 100
    if (totalXp <= 0) return 1;
    return ((-50 + sqrt(2500 + 200 * totalXp)) / 100).floor() + 1;
  }
  
  static double calculateLevelProgress(int totalXp) {
    int level = calculateLevel(totalXp);
    int currentLevelMinXp = 50 * (level - 1) * level;
    int nextLevelMinXp = 50 * level * (level + 1);
    
    int range = nextLevelMinXp - currentLevelMinXp;
    int progressXp = totalXp - currentLevelMinXp;
    
    return (progressXp / range).clamp(0.0, 1.0);
  }
}
