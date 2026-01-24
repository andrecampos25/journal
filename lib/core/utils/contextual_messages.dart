/// Utility class for contextual messages based on time of day and context
class ContextualMessages {
  /// Returns a contextual empty state message for tasks
  static String getTasksEmptyMessage() {
    final hour = DateTime.now().hour;
    final isWeekend = _isWeekend();

    if (isWeekend) {
      if (hour < 12) {
        return "Enjoy your weekend morning! ☕\nNo tasks for today.";
      } else if (hour < 18) {
        return "Weekend vibes! 🌞\nYou're all caught up.";
      } else {
        return "Peaceful weekend evening 🌙\nRelax, no tasks pending.";
      }
    }

    // Weekday messages
    if (hour < 12) {
      return "Good morning! 🌅\nNo tasks scheduled yet.";
    } else if (hour < 18) {
      return "Afternoon check-in ☀️\nYour schedule is clear!";
    } else {
      return "Evening wind down 🌆\nAll tasks completed!";
    }
  }

  /// Returns a contextual empty state message for habits
  static String getHabitsEmptyMessage() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return "Start your day right! 💪\nCreate your first habit.";
    } else if (hour < 18) {
      return "Build better habits 🎯\nBegin your journey today.";
    } else {
      return "Consistency is key 🔑\nStart tomorrow strong.";
    }
  }

  /// Returns a celebration message when all tasks are done
  static String getAllTasksDoneMessage() {
    final hour = DateTime.now().hour;
    final messages = [
      "Crushing it! All tasks complete! 🎉",
      "You're on fire! Everything's done! 🔥",
      "Perfect! Nothing left on your list! ✨",
      "Amazing work! All checked off! 🌟",
    ];

    if (hour < 12) {
      return "Early bird gets the worm! 🐦\nAll tasks already done!";
    } else if (hour < 15) {
      return messages[DateTime.now().day % messages.length];
    } else {
      return "Day conquered! 🏆\nTime to relax!";
    }
  }

  /// Returns a celebration message when all habits are done
  static String getAllHabitsDoneMessage() {
    final messages = [
      "Habit streak! All done! 🎯",
      "Consistency champion! ⭐",
      "Perfect day! All habits complete! 💯",
      "You're unstoppable! 🚀",
    ];
    return messages[DateTime.now().day % messages.length];
  }

  /// Returns a motivational quote for empty states
  static String getMotivationalQuote() {
    final quotes = [
      "Small steps lead to big changes.",
      "Progress over perfection.",
      "Your future self will thank you.",
      "Every journey begins with a single step.",
      "Consistency beats intensity.",
      "You are capable of amazing things.",
      "Make today count.",
      "Be better than yesterday.",
    ];
    return quotes[DateTime.now().day % quotes.length];
  }

  static bool _isWeekend() {
    final weekday = DateTime.now().weekday;
    return weekday == DateTime.saturday || weekday == DateTime.sunday;
  }
}
