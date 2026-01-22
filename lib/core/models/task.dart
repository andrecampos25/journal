/// Task model representing a to-do item
class Task {
  final String id;
  final String userId;
  final String title;
  final DateTime? dueDate;
  final bool isCompleted;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    this.dueDate,
    this.isCompleted = false,
    required this.createdAt,
  });

  /// Create from Supabase/JSON map
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'] as String) : null,
      isCompleted: map['is_completed'] as bool? ?? false,
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
      'due_date': dueDate?.toIso8601String(),
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  Task copyWith({
    String? id,
    String? userId,
    String? title,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if task is overdue
  bool get isOverdue => 
      dueDate != null && 
      !isCompleted && 
      dueDate!.isBefore(DateTime.now());

  /// Formatted due time (HH:mm)
  String? get formattedDueTime {
    if (dueDate == null) return null;
    return '${dueDate!.hour.toString().padLeft(2, '0')}:${dueDate!.minute.toString().padLeft(2, '0')}';
  }
}
