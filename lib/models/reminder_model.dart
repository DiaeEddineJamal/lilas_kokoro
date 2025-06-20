import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class Reminder {
  final String id;
  final String title;
  final String description;
  final DateTime dateTime;
  final bool isCompleted;
  final String userId;
  final String emoji;
  final String category;
  final bool isRepeating;
  final List<String> repeatDays;

  Reminder({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.userId,
    this.isCompleted = false,
    this.emoji = '💖',
    this.category = 'general',
    this.isRepeating = false,
    this.repeatDays = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'isCompleted': isCompleted,
      'userId': userId,
      'emoji': emoji,
      'category': category,
      'isRepeating': isRepeating,
      'repeatDays': repeatDays,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dateTime: DateTime.parse(map['dateTime']),
      isCompleted: map['isCompleted'] ?? false,
      userId: map['userId'] ?? '',
      emoji: map['emoji'] ?? '💖',
      category: map['category'] ?? 'general',
      isRepeating: map['isRepeating'] ?? false,
      repeatDays: List<String>.from(map['repeatDays'] ?? []),
    );
  }

  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    bool? isCompleted,
    String? userId,
    String? emoji,
    String? category,
    bool? isRepeating,
    List<String>? repeatDays,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      isCompleted: isCompleted ?? this.isCompleted,
      userId: userId ?? this.userId,
      emoji: emoji ?? this.emoji,
      category: category ?? this.category,
      isRepeating: isRepeating ?? this.isRepeating,
      repeatDays: repeatDays ?? this.repeatDays,
    );
  }

  String get formattedDate {
    return DateFormat('MMM d, yyyy').format(dateTime);
  }

  String get formattedTime {
    return DateFormat('h:mm a').format(dateTime);
  }

  String get formattedDateTime {
    return DateFormat('MMM d, yyyy - h:mm a').format(dateTime);
  }
  
  DateTime? get date => dateTime;
  
  TimeOfDay? get time => TimeOfDay(
    hour: dateTime.hour,
    minute: dateTime.minute,
  );
}