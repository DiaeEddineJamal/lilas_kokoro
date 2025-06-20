

class Milestone {
  final String id;
  final String title;
  final DateTime date;
  final String description;
  final int dayCount;
  final String emoji;
  final bool isCustom;

  Milestone({
    required this.id,
    required this.title,
    required this.date,
    this.description = '',
    this.dayCount = 0,
    this.emoji = '🎉',
    this.isCustom = false,
  });

  // Create a copy of the Milestone with updated fields
  Milestone copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? description,
    int? dayCount,
    String? emoji,
    bool? isCustom,
  }) {
    return Milestone(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      description: description ?? this.description,
      dayCount: dayCount ?? this.dayCount,
      emoji: emoji ?? this.emoji,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  // Convert Milestone to a Map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'description': description,
      'dayCount': dayCount,
      'emoji': emoji,
      'isCustom': isCustom,
    };
  }
  
  // Create a Milestone from a Map (for deserialization)
  factory Milestone.fromMap(Map<String, dynamic> map) {
    return Milestone(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      date: DateTime.parse(map['date']),
      description: map['description'] ?? '',
      dayCount: map['dayCount'] ?? 0,
      emoji: map['emoji'] ?? '🎉',
      isCustom: map['isCustom'] ?? false,
    );
  }
}