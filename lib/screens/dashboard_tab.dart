import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../services/data_service.dart';
import '../models/user_model.dart';
import '../widgets/skeleton_loader.dart';
import '../services/skeleton_service.dart';
import 'ai_companion_screen.dart';
import 'reminders_screen.dart';
import 'love_counter_screen.dart';
import 'profile_edit_screen.dart';
import '../widgets/app_header.dart';
import '../models/chat_message_model.dart';
import '../services/ai_companion_service.dart';
import '../routes.dart';
import 'dart:io';

class DashboardTab extends StatefulWidget {
  const DashboardTab({Key? key}) : super(key: key);

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  // Store DataService instance
  late DataService _dataService;
  late AICompanionService _aiService;

  @override
  void initState() {
    super.initState();
    // Get DataService instance here
    _dataService = Provider.of<DataService>(context, listen: false);
    _aiService = Provider.of<AICompanionService>(context, listen: false);
    _loadData();
    // Listen for data refresh events
    _dataService.addListener(_onDataRefresh);
  }

  @override
  void dispose() {
    // Remove listener using the stored instance
    _dataService.removeListener(_onDataRefresh);
    super.dispose();
  }

  void _onDataRefresh() {
    // Trigger skeleton loader only on data refresh
    final skeletonService = Provider.of<SkeletonService>(context, listen: false);
    skeletonService.showLoader();
    _loadData();
  }

  Future<void> _loadData() async {
    final skeletonService = Provider.of<SkeletonService>(context, listen: false);
    // Remove skeletonService.showLoader();
    // Simulate loading or fetch actual data
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      skeletonService.hideLoader();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<UserModel>(context).id;
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;
    final userModel = Provider.of<UserModel>(context);
    final skeletonService = Provider.of<SkeletonService>(context);

    return Scaffold(
      body: Column(
        children: [
          // Using our custom AppHeader with profile button
          AppHeader(
            title: 'Lilas Kokoro',
        actions: [
              // Remove the Profile Icon Button
              // IconButton(
              //   icon: Icon(Icons.account_circle_rounded, size: 28, color: textColor),
              //   onPressed: () {
              //     // TODO: Navigate to profile or show settings
              //   },
              // ),
              // Consider adding other actions if needed
              // IconButton(
              //   icon: Icon(Icons.notifications_none_rounded, size: 28, color: textColor),
              //   onPressed: () {
              //     // TODO: Navigate to notifications
              //   },
              // ),
        ],
      ),
          
          // Content in an expanded widget
          Expanded(
        child: SafeArea(
              top: false, // Already handled by AppHeader
              child: SkeletonLoaderFixed(
                isLoading: skeletonService.isLoading,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with greeting
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${userModel.name}! 👋',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            'Welcome to your kawaii companion',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                            // Wrap CircleAvatar with GestureDetector for tap action
                            GestureDetector(
                              onTap: () async {
                                // Navigate to ProfileEditScreen
                                final result = await Navigator.push(
                                  context,
                                  SmoothPageRoute(
                                    page: const ProfileEditScreen(),
                                    transitionType: TransitionType.scale,
                                  ),
                                );
                                
                                // If changes were made (result == true), trigger a rebuild
                                if (result == true && mounted) {
                                  setState(() {}); // Rebuild with latest user data
                                }
                              },
                              child: CircleAvatar(
                                backgroundColor: const Color(0xFFFF85A2),
                                radius: 24,
                                backgroundImage: userModel.profileImagePath != null && userModel.profileImagePath!.isNotEmpty
                                  ? FileImage(File(userModel.profileImagePath!))
                                  : null,
                                child: userModel.profileImagePath == null || userModel.profileImagePath!.isEmpty
                                  ? Text(
                                      userModel.name.isNotEmpty ? userModel.name[0].toUpperCase() : 'G',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                              ),
                            ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Quick actions
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickActionButton(
                        context,
                        'Add Reminder',
                        Icons.notifications_active_rounded,
                        const Color(0xFFFF85A2),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RemindersScreen(),
                            ),
                          );
                        },
                      ),
                      _buildQuickActionButton(
                        context,
                        'AI Chat',
                        Icons.chat_bubble_rounded,
                        const Color(0xFF9C89FF),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AICompanionScreen(),
                            ),
                          );
                        },
                      ),
                      _buildQuickActionButton(
                        context,
                        'Love Counter',
                        Icons.favorite_rounded,
                        const Color(0xFFFF6B6B),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoveCounterScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Upcoming reminders
                  Text(
                    'Upcoming Reminders',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  FutureBuilder(
                          future: _dataService.getReminders(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildSkeletonReminderCards();
                      }
                      
                      if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
                        return _buildEmptyState(
                          context,
                          'No upcoming reminders',
                          'Add your first reminder to see it here!',
                          Icons.notifications_off_rounded,
                        );
                      }
                      
                      final reminders = snapshot.data as List;

                            // Get today's date at midnight for comparison
                            final now = DateTime.now();
                            final today = DateTime(now.year, now.month, now.day);

                      final upcomingReminders = reminders
                                // Filter for reminders that are not completed AND are due today or later
                                .where((r) {
                                  final reminderDate = DateTime(r.dateTime.year, r.dateTime.month, r.dateTime.day);
                                  return !r.isCompleted && (reminderDate.isAtSameMomentAs(today) || reminderDate.isAfter(today));
                                })
                          .toList();
                      
                      if (upcomingReminders.isEmpty) {
                        return _buildEmptyState(
                          context,
                          'No upcoming reminders',
                          'All your reminders are completed or in the past!',
                          Icons.check_circle_outline_rounded,
                        );
                      }
                      
                      // Sort by date
                      upcomingReminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));
                      
                      // Take only the first 3
                      final displayReminders = upcomingReminders.take(3).toList();
                      
                      return Column(
                        children: displayReminders.map((reminder) {
                          return _buildReminderCard(context, reminder);
                        }).toList(),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Recent AI Conversations
                  Text(
                    'Recent Conversations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  FutureBuilder(
                          future: _aiService.getConversations(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildSkeletonConversationCard();
                      }
                      
                      final conversations = snapshot.data as List<ChatConversation>? ?? [];
                      
                      if (conversations.isEmpty) {
                        return _buildEmptyState(
                          context,
                          'No conversations yet',
                          'Talk to your AI companion to see them here!',
                          Icons.chat_bubble_outline_rounded,
                        );
                      }
                      
                      // Sort by updated date (most recent first)
                      conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
                      
                      // Take only the first one
                      final displayConversation = conversations.first;
                      
                      return _buildConversationCard(context, displayConversation);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonReminderCards() {
    return Column(
      children: List.generate(3, (index) => 
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.white,
          ),
        )
      ),
    );
  }

  Widget _buildSkeletonConversationCard() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;
    
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white70 : Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF383844) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: const Color(0xFFFF85A2).withOpacity(0.7),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(BuildContext context, dynamic reminder) {
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF383844) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFFF85A2).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                reminder.emoji,
                style: const TextStyle(fontSize: 24),
              ),
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
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reminder.formattedDateTime,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(BuildContext context, ChatConversation conversation) {
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;
    
    // Get last message and format time
    final lastMessage = conversation.lastMessage;
    final lastUpdateTime = _formatLastUpdateTime(conversation.updatedAt);
    
    return GestureDetector(
      onTap: () {
        // Navigate to conversation
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AICompanionScreen(
              conversationId: conversation.id,
            ),
          ),
        );
      },
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF383844) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF9C89FF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                  Icons.chat_bubble_outline_rounded,
                color: Color(0xFF9C89FF),
                size: 30,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          conversation.title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                      ),
                Text(
                        lastUpdateTime,
                        style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
                  const SizedBox(height: 4),
                  Text(
                    conversation.lastMessagePreview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
          ),
        ],
        ),
      ),
    );
  }
  
  // Helper to format the last update time
  String _formatLastUpdateTime(DateTime updatedAt) {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${updatedAt.month}/${updatedAt.day}';
    }
  }
}