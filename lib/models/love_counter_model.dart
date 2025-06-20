
import 'milestone_model.dart';

class LoveCounter {
  final String id;
  final String userId;
  final String userName;
  final String partnerName;
  final DateTime anniversaryDate;
  final String emoji;
  final List<Milestone> milestones;

  LoveCounter({
    required this.id,
    required this.userId,
    required this.userName,
    required this.partnerName,
    required this.anniversaryDate,
    this.emoji = '❤️',
    required this.milestones,
  });

  // Get days since anniversary
  int get daysSinceAnniversary {
    final now = DateTime.now();
    return now.difference(anniversaryDate).inDays;
  }

  // Get formatted anniversary date
  String get formattedAnniversaryDate {
    return '${anniversaryDate.day}/${anniversaryDate.month}/${anniversaryDate.year}';
  }

  // Create a copy of the LoveCounter with updated fields
  LoveCounter copyWith({
    String? id,
    String? userId,
    String? userName,
    String? partnerName,
    DateTime? anniversaryDate,
    String? emoji,
    List<Milestone>? milestones,
  }) {
    return LoveCounter(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      partnerName: partnerName ?? this.partnerName,
      anniversaryDate: anniversaryDate ?? this.anniversaryDate,
      emoji: emoji ?? this.emoji,
      milestones: milestones ?? this.milestones,
    );
  }

  // Convert LoveCounter to a Map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'partnerName': partnerName,
      'anniversaryDate': anniversaryDate.toIso8601String(),
      'emoji': emoji,
      'milestones': milestones.map((m) => m.toMap()).toList(),
    };
  }
  
  // Create a LoveCounter from a Map (for deserialization)
  factory LoveCounter.fromMap(Map<String, dynamic> map) {
    return LoveCounter(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      partnerName: map['partnerName'] ?? '',
      anniversaryDate: DateTime.parse(map['anniversaryDate']),
      emoji: map['emoji'] ?? '❤️',
      milestones: (map['milestones'] as List?)
          ?.map((m) => Milestone.fromMap(m))
          .toList() ?? [],
    );
  }
}