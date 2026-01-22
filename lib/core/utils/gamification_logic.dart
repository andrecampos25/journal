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
}
