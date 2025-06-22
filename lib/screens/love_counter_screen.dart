import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Add this import for DateFormat
import '../models/love_counter_model.dart';
import '../models/milestone_model.dart';
import '../models/user_model.dart';
import '../services/data_service.dart';
import '../services/theme_service.dart';
import 'milestone_editor_screen.dart';
import 'love_counter_edit_screen.dart';
import 'package:uuid/uuid.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/m3_card.dart';
import '../widgets/m3_button.dart';
import '../services/skeleton_service.dart';
import '../widgets/gradient_app_bar.dart';

class LoveCounterScreen extends StatefulWidget {
  const LoveCounterScreen({Key? key}) : super(key: key);

  @override
  State<LoveCounterScreen> createState() => _LoveCounterScreenState();
}

class _LoveCounterScreenState extends State<LoveCounterScreen> {
  LoveCounter? _loveCounter;
  
  // Timer for live countdown
  Timer? _countdownTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadLoveCounter();
    
    // Start the countdown timer
    _startCountdownTimer();
  }

  @override
  void dispose() {
    // Cancel timer to prevent memory leaks
    _countdownTimer?.cancel();
    
    super.dispose();
  }
  
  void _startCountdownTimer() {
    // Update every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  Future<void> _loadLoveCounter() async {
    final skeletonService = Provider.of<SkeletonService>(context, listen: false);
    
    await skeletonService.withQuickToggle(() async {
      try {
        final dataService = Provider.of<DataService>(context, listen: false);
        final loveCounter = await dataService.getLoveCounter();
        
        if (mounted) {
          setState(() {
            _loveCounter = loveCounter;
          });
        }
      } catch (e) {
        debugPrint('Error loading love counter: $e');
      }
    });
  }

  Future<void> _onRefresh() async {
    await _loadLoveCounter();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;
    final skeletonService = Provider.of<SkeletonService>(context);
    final theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;

    // If no love counter exists, show create message
    if (_loveCounter == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: SkeletonLoaderFixed(
            isLoading: skeletonService.isLoading,
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: themeService.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 100),
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade100,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.favorite_outline,
                          size: 60,
                          color: themeService.primary.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Create Your Love Counter',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Track the beautiful journey with your loved one',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: Material(
                          color: themeService.primary,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoveCounterEditScreen(),
                                ),
                              );
                              
                              if (result == true) {
                                _loadLoveCounter();
                              }
                            },
                            child: const Center(
                              child: Text(
                                'Create Love Counter',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Display View with live countdown
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SkeletonLoaderFixed(
          isLoading: skeletonService.isLoading,
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            color: themeService.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Main Love Counter Card with Gradient Background
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDarkMode 
                          ? themeService.darkGradient
                          : themeService.lightGradient,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: themeService.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Names with emoji
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _loveCounter!.userName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  _loveCounter!.emoji,
                                  style: const TextStyle(fontSize: 28),
                                ),
                              ),
                              Text(
                                _loveCounter!.partnerName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Live countdown display
                          _buildLiveCountdown(),
                          
                          const SizedBox(height: 16),
                          
                          // Anniversary date
                          Text(
                            'Since ${DateFormat('MMMM d, yyyy').format(_loveCounter!.anniversaryDate)}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Milestones Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Milestones',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MilestoneEditorScreen(
                                loveCounter: _loveCounter!,
                              ),
                            ),
                          ).then((_) => _loadLoveCounter());
                        },
                        icon: Icon(Icons.add, color: themeService.primary),
                        label: Text(
                          'Add',
                          style: TextStyle(color: themeService.primary),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Milestones List or Empty State
                  if (_loveCounter!.milestones.isEmpty)
                    _buildEmptyMilestones()
                  else ...[
                    // Hint text for milestone interaction
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Tap to edit • Long press for more options',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.white54 : Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _loveCounter!.milestones.length,
                      itemBuilder: (context, index) {
                        final milestone = _loveCounter!.milestones[index];
                        return _buildMilestoneCard(milestone);
                      },
                    ),
                  ],
                  
                  const SizedBox(height: 80), // Add space for floating action button
                ],
              ),
            ),
          ),
        ),
      ),
      // Add floating action button for editing
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: isDarkMode ? themeService.darkGradient : themeService.lightGradient,
            radius: 1.0,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: themeService.primary.withOpacity(0.4),
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
                builder: (context) => LoveCounterEditScreen(
                  existingLoveCounter: _loveCounter,
                ),
              ),
            );
            
            if (result == true) {
              _loadLoveCounter();
            }
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.edit, color: Colors.white),
        ),
      ),
    );
  }
  
  // Build the live countdown display
  Widget _buildLiveCountdown() {
    if (_loveCounter == null) return const SizedBox.shrink();
    
    // Get the anniversary date and current time
    final DateTime anniversary = _loveCounter!.anniversaryDate;
    final DateTime now = _now;
    
    // Calculate the total difference
    final Duration totalDifference = now.difference(anniversary);
    final int totalDays = totalDifference.inDays;
    
    // Calculate years, months, and days breakdown using a simpler approach
    int years = now.year - anniversary.year;
    int months = now.month - anniversary.month;
    int days = now.day - anniversary.day;
    
    // Adjust if days are negative
    if (days < 0) {
      months--;
      // Get days in the previous month
      final DateTime prevMonth = DateTime(now.year, now.month - 1, 1);
      final int daysInPrevMonth = DateTime(now.year, now.month, 0).day;
      days += daysInPrevMonth;
    }
    
    // Adjust if months are negative
    if (months < 0) {
      years--;
      months += 12;
    }
    
    // Get hours, minutes, seconds from the total difference
    final int hours = totalDifference.inHours % 24;
    final int minutes = totalDifference.inMinutes % 60;
    final int seconds = totalDifference.inSeconds % 60;
    
    return Column(
      children: [
        // Main counter showing total days
        Text(
          '$totalDays',
          style: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Days Together',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        
        // Detailed breakdown in a visually appealing grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTimeElement('$years', 'Years'),
              _buildTimeElement('$months', 'Months'),
              _buildTimeElement('$days', 'Days'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTimeElement('$hours', 'Hours'),
              _buildTimeElement('$minutes', 'Minutes'),
              _buildTimeElement('$seconds', 'Seconds'),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildTimeElement(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
  
  Widget _buildEmptyMilestones() {
    final isDarkMode = Provider.of<ThemeService>(context).isDarkMode;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade100,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              Icons.favorite_border,
              size: 40,
              color: Provider.of<ThemeService>(context, listen: false).primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No milestones yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first milestone to celebrate special moments',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white54 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          M3Button(
            text: "Add First Milestone",
            icon: Icons.add,
            backgroundColor: Provider.of<ThemeService>(context, listen: false).primary,
            foregroundColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MilestoneEditorScreen(
                    loveCounter: _loveCounter!,
                  ),
                ),
              ).then((_) => _loadLoveCounter());
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildMilestoneCard(Milestone milestone) {
    final isDarkMode = Provider.of<ThemeService>(context).isDarkMode;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF3E3E4E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MilestoneEditorScreen(
                  loveCounter: _loveCounter!,
                  existingMilestone: milestone,
                ),
              ),
            ).then((_) => _loadLoveCounter());
          },
          onLongPress: () {
            debugPrint('🔥 Long press detected on milestone: ${milestone.title}');
            _showMilestoneOptions(milestone);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Emoji circle
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Provider.of<ThemeService>(context, listen: false).primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Provider.of<ThemeService>(context, listen: false).primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      milestone.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Milestone details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        milestone.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Provider.of<ThemeService>(context, listen: false).primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Provider.of<ThemeService>(context, listen: false).primary.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Day ${milestone.dayCount}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Provider.of<ThemeService>(context, listen: false).primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (milestone.description.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                milestone.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // More options icon (indicates long press)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDarkMode 
                      ? Colors.white.withOpacity(0.1) 
                      : Provider.of<ThemeService>(context, listen: false).primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.more_vert,
                      size: 16,
                      color: isDarkMode 
                        ? Colors.white70 
                        : Provider.of<ThemeService>(context, listen: false).primary,
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

  void _showMilestoneOptions(Milestone milestone) {
    debugPrint('🎯 Showing milestone options for: ${milestone.title}');
    final isDarkMode = Provider.of<ThemeService>(context, listen: false).isDarkMode;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF2D2D3A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              // Milestone info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      milestone.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            milestone.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            'Day ${milestone.dayCount}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action buttons
              ListTile(
                leading: Icon(
                  Icons.edit,
                  color: Provider.of<ThemeService>(context, listen: false).primary,
                ),
                title: Text(
                  'Edit Milestone',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MilestoneEditorScreen(
                        loveCounter: _loveCounter!,
                        existingMilestone: milestone,
                      ),
                    ),
                  ).then((_) => _loadLoveCounter());
                },
              ),
              
              ListTile(
                leading: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
                title: Text(
                  'Delete Milestone',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteMilestone(milestone);
                },
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteMilestone(Milestone milestone) async {
    final isDarkMode = Provider.of<ThemeService>(context, listen: false).isDarkMode;
    
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF383844) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete Milestone',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: RichText(
            text: TextSpan(
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: 16,
              ),
              children: [
                const TextSpan(text: 'Are you sure you want to delete '),
                TextSpan(
                  text: '"${milestone.title}"',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: '? This action cannot be undone.'),
              ],
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
        );
      },
    );

    if (shouldDelete == true) {
      await _deleteMilestone(milestone);
    }
  }

  Future<void> _deleteMilestone(Milestone milestone) async {
    final skeletonService = Provider.of<SkeletonService>(context, listen: false);
    
    await skeletonService.withQuickToggle(() async {
      try {
        final dataService = Provider.of<DataService>(context, listen: false);
        
        // Get current milestones and remove the selected one
        final currentMilestones = List<Milestone>.from(_loveCounter!.milestones);
        currentMilestones.removeWhere((m) => m.id == milestone.id);
        
        // Update the love counter with the new milestones list
        final updatedLoveCounter = _loveCounter!.copyWith(
          milestones: currentMilestones,
        );
        
        await dataService.updateLoveCounter(updatedLoveCounter);
        
        // Reload the love counter to reflect changes
        await _loadLoveCounter();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Milestone "${milestone.title}" deleted successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting milestone: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
  }
}