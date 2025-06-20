import 'package:uuid/uuid.dart';

class Sound {
  final String id;
  final String name;
  final String storageUrl;
  final String userId;
  final DateTime createdAt;
  final SoundType type;
  final bool isAsset;
  final bool isDefault;

  Sound({
    String? id,
    required this.name,
    required this.storageUrl,
    required this.userId,
    DateTime? createdAt,
    this.type = SoundType.alarm,
    this.isAsset = false,
    this.isDefault = false,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'storageUrl': storageUrl,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'type': type.name,
      'isAsset': isAsset,
      'isDefault': isDefault,
    };
  }

  factory Sound.fromMap(Map<String, dynamic> map) {
    return Sound(
      id: map['id'],
      name: map['name'] ?? '',
      storageUrl: map['storageUrl'] ?? '',
      userId: map['userId'] ?? '',
      createdAt: map['createdAt'] is String 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      type: map['type'] != null 
          ? SoundType.values.firstWhere(
              (e) => e.name == map['type'],
              orElse: () => SoundType.alarm,
            )
          : SoundType.alarm,
      isAsset: map['isAsset'] ?? false,
      isDefault: map['isDefault'] ?? false,
    );
  }

  // Create a copy with some fields replaced
  Sound copyWith({
    String? id,
    String? name,
    String? storageUrl,
    String? userId,
    DateTime? createdAt,
    SoundType? type,
    bool? isAsset,
    bool? isDefault,
  }) {
    return Sound(
      id: id ?? this.id,
      name: name ?? this.name,
      storageUrl: storageUrl ?? this.storageUrl,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      isAsset: isAsset ?? this.isAsset,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

enum SoundType {
  alarm,
  notification,
  ringtone,
}