/// DailyEntry model representing a journal entry with mood
class DailyEntry {
  final String? id;
  final String userId;
  final DateTime entryDate;
  final int? moodScore;
  final String? journalText;
  final DateTime? createdAt;

  DailyEntry({
    this.id,
    required this.userId,
    required this.entryDate,
    this.moodScore,
    this.journalText,
    this.createdAt,
  });

  /// Create from Supabase/JSON map
  factory DailyEntry.fromMap(Map<String, dynamic> map) {
    return DailyEntry(
      id: map['id'] as String?,
      userId: map['user_id'] as String,
      entryDate: DateTime.parse(map['entry_date'] as String),
      moodScore: map['mood_score'] as int?,
      journalText: map['journal_text'] as String?,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  /// Convert to map for Supabase
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'entry_date': _formatDate(entryDate),
      if (moodScore != null) 'mood_score': moodScore,
      if (journalText != null) 'journal_text': journalText,
    };
  }

  /// Create a copy with modified fields
  DailyEntry copyWith({
    String? id,
    String? userId,
    DateTime? entryDate,
    int? moodScore,
    String? journalText,
    DateTime? createdAt,
  }) {
    return DailyEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      entryDate: entryDate ?? this.entryDate,
      moodScore: moodScore ?? this.moodScore,
      journalText: journalText ?? this.journalText,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Format date as YYYY-MM-DD for Supabase
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get mood as emoji
  String get moodEmoji {
    if (moodScore == null) return '😐';
    if (moodScore! <= 2) return '😢';
    if (moodScore! <= 4) return '😕';
    if (moodScore! <= 6) return '😐';
    if (moodScore! <= 8) return '🙂';
    return '😁';
  }

  /// Check if entry has content
  bool get hasContent => 
      (journalText != null && journalText!.isNotEmpty) || 
      moodScore != null;
}
