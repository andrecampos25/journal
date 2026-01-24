/// Utility class for formatting time in a user-friendly, relative format
class TimeUtils {
  /// Formats a DateTime as a relative time string
  /// e.g., "In 2 hours", "In 30 minutes", "Overdue by 1 hour"
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    // Past (overdue)
    if (difference.isNegative) {
      final absDifference = difference.abs();
      
      if (absDifference.inDays > 0) {
        return 'Overdue by ${absDifference.inDays} day${absDifference.inDays > 1 ? 's' : ''}';
      } else if (absDifference.inHours > 0) {
        return 'Overdue by ${absDifference.inHours} hour${absDifference.inHours > 1 ? 's' : ''}';
      } else if (absDifference.inMinutes > 0) {
        return 'Overdue by ${absDifference.inMinutes} min${absDifference.inMinutes > 1 ? 's' : ''}';
      } else {
        return 'Just overdue';
      }
    }

    // Future
    if (difference.inDays > 0) {
      return 'In ${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'In ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 5) {
      return 'In ${difference.inMinutes} minutes';
    } else if (difference.inMinutes > 0) {
      return 'In a few minutes';
    } else {
      return 'Now';
    }
  }

  /// Returns a color based on time sensitivity
  /// Green for far future, yellow for soon, red for overdue
  static TimeSensitivity getTimeSensitivity(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.isNegative) {
      return TimeSensitivity.overdue;
    } else if (difference.inHours < 1) {
      return TimeSensitivity.urgent;
    } else if (difference.inHours < 3) {
      return TimeSensitivity.soon;
    } else {
      return TimeSensitivity.normal;
    }
  }
}

enum TimeSensitivity {
  overdue,  // Red
  urgent,   // Orange
  soon,     // Yellow
  normal,   // Green/Default
}
