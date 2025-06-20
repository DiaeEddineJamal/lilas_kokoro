import 'reminder_model.dart';

class DefaultReminders {
  static List<Reminder> createDefaultReminders(String userId) {
    return [
      Reminder(
        id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Welcome to Lilas Kokoro! 💖',
        description: 'Thank you for using our app! Tap to mark this reminder as completed.',
        dateTime: DateTime.now().add(const Duration(minutes: 30)),
        userId: userId,
        emoji: '🎀',
        category: 'general',
      ),
      Reminder(
        id: 'self_care_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Self-Care Reminder',
        description: 'Take a moment to breathe and relax. You\'re doing great!',
        dateTime: DateTime.now().add(const Duration(hours: 3)),
        userId: userId,
        emoji: '🌸',
        category: 'self-care',
      ),
      Reminder(
        id: 'hydrate_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Hydration Check',
        description: 'Remember to drink water and stay hydrated!',
        dateTime: DateTime.now().add(const Duration(hours: 1)),
        userId: userId,
        emoji: '💧',
        category: 'health',
      ),
    ];
  }
}