import 'dart:ui';

enum StarType { task, habit, journal, insight }

class Star {
  final String id;
  Offset position;
  Offset velocity;
  final double radius;
  final Color color;
  final StarType type;
  final String? linkedDataId;
  final String title;
  final DateTime? date; // For temporal correlations
  final List<String> keywords; // For semantic correlations

  Star({
    required this.id,
    required this.position,
    required this.velocity,
    required this.radius,
    required this.color,
    required this.type,
    this.linkedDataId,
    required this.title,
    this.date,
    this.keywords = const [],
  });

  void update(Size canvasSize, double dt) {
    position += velocity * dt;

    // Wrap around edges for infinite drift
    if (position.dx < -radius) {
      position = Offset(canvasSize.width + radius, position.dy);
    } else if (position.dx > canvasSize.width + radius) {
      position = Offset(-radius, position.dy);
    }
    if (position.dy < -radius) {
      position = Offset(position.dx, canvasSize.height + radius);
    } else if (position.dy > canvasSize.height + radius) {
      position = Offset(position.dx, -radius);
    }
  }

  /// Calculate correlation strength with another star (0.0 to 1.0)
  double correlationWith(Star other) {
    if (linkedDataId == null || other.linkedDataId == null) return 0.0;
    if (id == other.id) return 0.0;

    double score = 0.0;

    // Temporal correlation: same day = strong connection
    if (date != null && other.date != null) {
      final dayDiff = date!.difference(other.date!).inDays.abs();
      if (dayDiff == 0) {
        score += 0.5; // Same day = 50% correlation
      } else if (dayDiff <= 7) {
        score += 0.2 * (1 - dayDiff / 7); // Within a week, decreasing
      }
    }

    // Keyword overlap: shared words = semantic connection
    if (keywords.isNotEmpty && other.keywords.isNotEmpty) {
      final overlap = keywords.where((k) => other.keywords.contains(k)).length;
      if (overlap > 0) {
        score += 0.3 * (overlap / keywords.length).clamp(0.0, 1.0);
      }
    }

    // Cross-type bonus: habits and tasks on same day are interesting
    if (type != other.type && date != null && other.date != null) {
      final dayDiff = date!.difference(other.date!).inDays.abs();
      if (dayDiff == 0) {
        score += 0.2; // Cross-type same-day correlation
      }
    }

    return score.clamp(0.0, 1.0);
  }
}

/// Represents a connection (thread) between two stars
class StarThread {
  final Star star1;
  final Star star2;
  final double strength; // 0.0 to 1.0

  StarThread({
    required this.star1,
    required this.star2,
    required this.strength,
  });
}

/// Utility to extract keywords from text
List<String> extractKeywords(String text) {
  final words = text.toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), '')
      .split(RegExp(r'\s+'))
      .where((w) => w.length > 3) // Only words > 3 chars
      .toSet()
      .toList();
  
  // Common stop words to filter
  const stopWords = {
    'the', 'and', 'for', 'with', 'this', 'that', 'from', 'have', 'been', 'will', 
    'would', 'could', 'should', 'about', 'just', 'more', 'some', 'than', 'then', 
    'their', 'there', 'they', 'very', 'what', 'when', 'where', 'which', 'your'
  };
  return words.where((w) => !stopWords.contains(w)).toList();
}
