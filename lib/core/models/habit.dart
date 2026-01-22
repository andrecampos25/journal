/// Habit model representing a recurring behavior to track
class Habit {
  final String id;
  final String userId;
  final String title;
  final String icon;
  final List<int> frequency; // Days of week (1=Mon, 7=Sun)
  final bool archived;
  final DateTime createdAt;

  Habit({
    required this.id,
    required this.userId,
    required this.title,
    this.icon = '✨',
    this.frequency = const [],
    this.archived = false,
    required this.createdAt,
  });

  /// Create from Supabase/JSON map
  factory Habit.fromMap(Map<String, dynamic> map) {
    // Handle frequency which may come as List<dynamic>
    final rawFreq = map['frequency'] as List?;
    final frequency = rawFreq?.map((e) => int.tryParse(e.toString()) ?? 0).toList() ?? [];
    
    return Habit(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      icon: (map['icon'] as String?) ?? '✨',
      frequency: frequency,
      archived: map['archived'] as bool? ?? false,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to map for Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'icon': icon,
      'frequency': frequency,
      'archived': archived,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  Habit copyWith({
    String? id,
    String? userId,
    String? title,
    String? icon,
    List<int>? frequency,
    bool? archived,
    DateTime? createdAt,
  }) {
    return Habit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      frequency: frequency ?? this.frequency,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if habit is scheduled for a specific day of week
  bool isScheduledFor(int dayOfWeek) {
    if (frequency.isEmpty) return true; // Daily if no specific days
    return frequency.contains(dayOfWeek);
  }

  /// Get formatted frequency string (e.g., "Mon, Wed, Fri")
  String get frequencyLabel {
    if (frequency.isEmpty) return 'Daily';
    const days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return frequency.map((d) => days[d]).join(', ');
  }
}
