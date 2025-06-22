import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lilas_kokoro/models/user_model.dart';
import 'package:lilas_kokoro/screens/reminder_editor_screen.dart';
import 'package:lilas_kokoro/services/theme_service.dart';
import 'package:provider/provider.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';
import '../models/reminder_model.dart';
import '../widgets/skeleton_loader.dart' hide SkeletonBones;
import '../services/skeleton_service.dart';
import '../widgets/app_bones.dart';
import '../widgets/app_header.dart';

extension StringExtension on String {
  String capitalize() {
    return isEmpty ? '' : '${this[0].toUpperCase()}${substring(1)}';
  }
}

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> with AutomaticKeepAliveClientMixin {
  List<Reminder>? _cachedReminders;
  late DataService _dataService;
  bool _isInitialLoad = true;
  bool _hasLoadedOnce = false;
  
  // Keep alive to prevent rebuilds when switching tabs
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _dataService = Provider.of<DataService>(context, listen: false);
    _loadRemindersQuietly();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Load reminders without showing skeleton - for initial loads and background updates
  Future<void> _loadRemindersQuietly() async {
    if (!mounted) return;
    
    try {
      final reminders = await _dataService.getReminders();
      if (mounted) {
        setState(() {
          _cachedReminders = reminders;
          _hasLoadedOnce = true;
          _isInitialLoad = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading reminders: $e');
      if (mounted) {
        setState(() {
          _hasLoadedOnce = true;
          _isInitialLoad = false;
        });
      }
    }
  }

  /// Load reminders with skeleton - only for explicit user-triggered refreshes
  Future<void> _loadRemindersWithSkeleton() async {
    final skeletonService = Provider.of<SkeletonService>(context, listen: false);
    
    await skeletonService.withLoading(() async {
      await _loadRemindersQuietly();
    });
  }

  Future<void> _onRefresh() async {
    await _loadRemindersWithSkeleton();
  }

  void _toggleReminderCompletionOptimistic(Reminder reminder, DataService dataService) async {
    // Mark this as a quick toggle to avoid skeleton loading
    final skeletonService = Provider.of<SkeletonService>(context, listen: false);
    
    await skeletonService.withQuickToggle(() async {
      // Toggle completion status
      final updatedReminder = reminder.copyWith(isCompleted: !reminder.isCompleted);
      
      // Optimistically update the UI
      if (_cachedReminders != null) {
        setState(() {
          final index = _cachedReminders!.indexWhere((r) => r.id == reminder.id);
          if (index != -1) {
            _cachedReminders![index] = updatedReminder;
          }
        });
      }
      
      // Update in the database
      await dataService.updateReminder(updatedReminder);
      
      // Handle notification based on completion status
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      final notificationId = reminder.id.hashCode.abs() % 100000;
      
      if (updatedReminder.isCompleted) {
        // Cancel notification if reminder is completed
        await notificationService.cancelNotification(notificationId);
      } else {
        // Reschedule notification if reminder is uncompleted
        await notificationService.scheduleReminderNotification(updatedReminder);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;
    final dataService = Provider.of<DataService>(context);
    final skeletonService = Provider.of<SkeletonService>(context);

    // Only show skeleton on initial load or explicit loading
    final shouldShowSkeleton = _isInitialLoad || skeletonService.isLoading;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SkeletonLoaderFixed(
        isLoading: shouldShowSkeleton,
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: themeService.primary,
          child: _buildContent(isDarkMode, dataService, themeService),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: Provider.of<ThemeService>(context).isDarkMode 
              ? Provider.of<ThemeService>(context).darkGradient 
              : Provider.of<ThemeService>(context).lightGradient,
            radius: 1.0,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Provider.of<ThemeService>(context).primary.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ReminderEditorScreen(),
              ),
            );
            
            // Refresh data quietly if a reminder was added/edited
            if (result == true) {
              _loadRemindersQuietly();
            }
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          tooltip: 'Add Reminder',
          heroTag: 'reminderButton',
          mini: false,
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
  
  Widget _buildContent(bool isDarkMode, DataService dataService, ThemeService themeService) {
    // Use cached data if available, otherwise show appropriate state
    final reminders = _cachedReminders ?? [];
    
    if (!_hasLoadedOnce && _isInitialLoad) {
      // Still loading initial data
      return const Center(child: CircularProgressIndicator());
    }
    
    if (reminders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.notifications_off_rounded,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No reminders yet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pull down to refresh or tap the + button to create your first reminder',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white54 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: reminders.length,
      itemBuilder: (context, index) {
        final reminder = reminders[index];
        return _buildReminderCard(reminder, isDarkMode, dataService, themeService);
      },
    );
  }

  Widget _buildReminderCard(Reminder reminder, bool isDarkMode, DataService dataService, ThemeService themeService) {
    return Dismissible(
      key: Key(reminder.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: isDarkMode ? const Color(0xFF383844) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Delete Reminder',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Are you sure you want to delete this reminder?',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        // Mark this as a quick toggle
        final skeletonService = Provider.of<SkeletonService>(context, listen: false);
        
        await skeletonService.withQuickToggle(() async {
          // Cancel the notification for this reminder
          final notificationService = Provider.of<NotificationService>(context, listen: false);
          final notificationId = reminder.id.hashCode.abs() % 100000;
          await notificationService.cancelNotification(notificationId);
          
          // Delete the reminder from data service
          await dataService.deleteReminder(reminder.id);
                  ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reminder deleted'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        });
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: isDarkMode ? const Color(0xFF383844) : Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReminderEditorScreen(
                  existingReminder: reminder,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleReminderCompletionOptimistic(reminder, dataService),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: reminder.isCompleted
                          ? themeService.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: reminder.isCompleted
                            ? themeService.primary
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: reminder.isCompleted
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: reminder.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: reminder.isCompleted
                              ? isDarkMode
                                  ? Colors.white38
                                  : Colors.grey.shade500
                              : isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                        ),
                      ),
                      if (reminder.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          reminder.description,
                          style: TextStyle(
                            fontSize: 14,
                            decoration: reminder.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: reminder.isCompleted
                                ? isDarkMode
                                    ? Colors.white24
                                    : Colors.grey.shade400
                                : isDarkMode
                                    ? Colors.white70
                                    : Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (reminder.isRepeating) ...[
                            Icon(
                              Icons.repeat,
                              size: 14,
                              color: themeService.primary,
                            ),
                            const SizedBox(width: 4),
                          ],
                          if (reminder.dateTime != null) ...[
                            Text(
                              DateFormat.yMMMd().format(reminder.dateTime!),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode
                                    ? Colors.white54
                                    : Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat.jm().format(reminder.dateTime!),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: themeService.primary,
                              ),
                            ),
                          ] else ...[
                            Text(
                              'No date set',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: isDarkMode
                                    ? Colors.white38
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      reminder.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
