import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lilas_kokoro/models/user_model.dart';
import 'package:lilas_kokoro/screens/reminder_editor_screen.dart';
import 'package:lilas_kokoro/services/theme_service.dart';
import 'package:provider/provider.dart';
import '../services/data_service.dart';
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

class _RemindersScreenState extends State<RemindersScreen> {
  List<Reminder>? _cachedReminders;
  late DataService _dataService;

  @override
  void initState() {
    super.initState();
    _dataService = Provider.of<DataService>(context, listen: false);
    _loadReminders();
    // Listen for data refresh events
    _dataService.addListener(_onDataRefresh);
  }

  @override
  void dispose() {
    // Remove listener to prevent memory leaks using stored instance
    _dataService.removeListener(_onDataRefresh);
    super.dispose();
  }

  Future<void> _loadReminders() async {
    // Get service instances
    final skeletonService = Provider.of<SkeletonService>(context, listen: false);
    
    // Pre-fetch reminders to cache
    try {
      _cachedReminders = await _dataService.getReminders();
    } catch (e) {
      debugPrint('Error loading reminders: $e');
    } finally {
      if (mounted) {
        final skeletonService = Provider.of<SkeletonService>(context, listen: false);
        skeletonService.hideLoader();
      }
    }
  }

  void _onDataRefresh() {
    // Trigger skeleton loader only on data refresh
    final skeletonService = Provider.of<SkeletonService>(context, listen: false);
    skeletonService.showLoader();
    _loadReminders();
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
    });
  }

  @override
  Widget build(BuildContext context) {
    // Define dataService and isDarkMode here
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;
    // Get the SkeletonService instance
    final skeletonService = Provider.of<SkeletonService>(context);

    return Scaffold(
      body: Column(
        children: [
          // Add the app header
          AppHeader(
            title: 'Reminders',
            titleIcon: Icons.notifications_active,
          ),
          
          // Content in an expanded widget to take remaining space
          Expanded(
            child: SafeArea(
              top: false, // Already handled by AppHeader
              child: SkeletonLoaderFixed(
                isLoading: skeletonService.isLoading,
                child: FutureBuilder<List<Reminder>>(
                  future: _dataService.getReminders(),
                  builder: (context, snapshot) {
                    // If we're loading but have cached data, use that instead of showing skeletons
                    if (snapshot.connectionState == ConnectionState.waiting && _cachedReminders != null) {
                      return _buildRemindersList(context, _cachedReminders!, _dataService, isDarkMode);
                    }
                    
                    // If still loading with no cache, show appropriate number of skeletons
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      // Base number of skeletons on cached reminders count or default to 3
                      final skeletonCount = _cachedReminders?.length ?? 3;
                      return _buildSkeletonRemindersList(skeletonCount);
                    } 
                    
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } 
                    
                    final reminders = snapshot.data ?? [];
                    _cachedReminders = reminders; // Update cache
                    
                    if (reminders.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off_rounded,
                              size: 80,
                              color: Colors.pink.shade200,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No reminders yet',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.pink.shade300,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the + button to create one',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return _buildRemindersList(context, reminders, _dataService, isDarkMode);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ReminderEditorScreen(),
            ),
          );
        },
        backgroundColor: isDarkMode ? const Color(0xFF8E2A55) : const Color(0xFFFF85A2),
        elevation: 4,
        tooltip: 'Add Reminder',
        heroTag: 'reminderButton',
        mini: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildRemindersList(BuildContext context, List<Reminder> reminders, DataService dataService, bool isDarkMode) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: reminders.length,
      itemBuilder: (context, index) {
        final reminder = reminders[index];
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
                title: const Text('Delete Reminder'),
                content: const Text('Are you sure you want to delete this reminder?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) async {
            // Mark this as a quick toggle
            final skeletonService = Provider.of<SkeletonService>(context, listen: false);
            
            await skeletonService.withQuickToggle(() async {
              await dataService.deleteReminder(reminder.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reminder deleted')),
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
                              ? const Color(0xFFFF85A2)
                              : Colors.transparent,
                          border: Border.all(
                            color: reminder.isCompleted
                                ? const Color(0xFFFF85A2)
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
                                const Icon(
                                  Icons.repeat,
                                  size: 14,
                                  color: Color(0xFFFF85A2),
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
                                    color: const Color(0xFFFF85A2),
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
      },
    );
  }

  Widget _buildSkeletonRemindersList(int count) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: count,
      itemBuilder: (context, index) {
        return AppBones.reminderCard(withGloss: true);
      },
    );
  }
}
