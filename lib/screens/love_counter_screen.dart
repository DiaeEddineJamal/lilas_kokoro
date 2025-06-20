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
import 'package:uuid/uuid.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/m3_card.dart';
import '../widgets/m3_button.dart';
import '../services/skeleton_service.dart';
import '../widgets/gradient_app_bar.dart';

class LoveCounterScreen extends StatefulWidget {
  final Function(String?, VoidCallback?)? onAppBarUpdate;
  
  const LoveCounterScreen({Key? key, this.onAppBarUpdate}) : super(key: key);

  @override
  State<LoveCounterScreen> createState() => _LoveCounterScreenState();
}

class _LoveCounterScreenState extends State<LoveCounterScreen> {
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _partnerNameController = TextEditingController();
  DateTime _anniversaryDate = DateTime.now();
  String _selectedEmoji = '❤️';
  bool _isEditing = false;
  LoveCounter? _loveCounter;
  
  // Timer for live countdown
  Timer? _countdownTimer;
  DateTime _now = DateTime.now();

  final List<String> _emojis = ['❤️', '💖', '💕', '💓', '💗', '💘', '💝', '💞', '💟', '❤️‍🔥'];

  @override
  void initState() {
    super.initState();
    _loadLoveCounter();
    
    // Start the countdown timer
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _partnerNameController.dispose();
    
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
            if (loveCounter != null) {
              _userNameController.text = loveCounter.userName;
              _partnerNameController.text = loveCounter.partnerName;
              _anniversaryDate = loveCounter.anniversaryDate;
              _selectedEmoji = loveCounter.emoji;
            }
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _anniversaryDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Provider.of<ThemeService>(context, listen: false).primary,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _anniversaryDate) {
      setState(() {
        _anniversaryDate = picked;
      });
    }
  }

  Future<void> _saveLoveCounter() async {
    if (_userNameController.text.isEmpty || _partnerNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final skeletonService = Provider.of<SkeletonService>(context, listen: false);
    skeletonService.showLoader();

    try {
      final userId = Provider.of<UserModel>(context, listen: false).id;
      final dataService = Provider.of<DataService>(context, listen: false);

      final loveCounter = LoveCounter(
        id: _loveCounter?.id ?? const Uuid().v4(),
        userId: userId,
        userName: _userNameController.text,
        partnerName: _partnerNameController.text,
        anniversaryDate: _anniversaryDate,
        emoji: _selectedEmoji,
        milestones: _loveCounter?.milestones ?? [],
      );

      await dataService.updateLoveCounter(loveCounter);

      if (mounted) {
        setState(() {
          _loveCounter = loveCounter;
          _isEditing = false;
        });
        // Update the app bar to remove the edit title
        widget.onAppBarUpdate?.call(null, null);
      }
    } catch (e) {
      debugPrint('Error saving love counter: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $e')),
      );
    } finally {
      if (mounted) {
        skeletonService.hideLoader();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;
    final skeletonService = Provider.of<SkeletonService>(context);
    final theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;

    // Build the main content based on state
    Widget buildContent() {
      if (_isEditing || _loveCounter == null) {
        return RefreshIndicator(
          onRefresh: _onRefresh,
          color: themeService.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Names Card - Consistent with reminder card styling
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: isDarkMode ? const Color(0xFF383844) : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Names',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _userNameController,
                          decoration: InputDecoration(
                            labelText: 'Your Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _partnerNameController,
                          decoration: InputDecoration(
                            labelText: 'Partner\'s Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.favorite),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Anniversary Date Card
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: isDarkMode ? const Color(0xFF383844) : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Anniversary Date',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () => _selectDate(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today),
                                const SizedBox(width: 12),
                                Text(
                                  DateFormat('MMMM d, yyyy').format(_anniversaryDate),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const Spacer(),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Emoji Selection Card
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: isDarkMode ? const Color(0xFF383844) : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose Emoji',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: Wrap(
                            alignment: WrapAlignment.spaceEvenly,
                            spacing: 12,
                            runSpacing: 12,
                            children: _emojis.map((emoji) {
                              return Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    setState(() {
                                      _selectedEmoji = emoji;
                                    });
                                  },
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: _selectedEmoji == emoji
                                          ? themeService.primary.withOpacity(0.2)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _selectedEmoji == emoji
                                            ? themeService.primary
                                            : Colors.grey.shade300,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        emoji,
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Material(
                    color: Provider.of<ThemeService>(context, listen: false).primary,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _saveLoveCounter,
                      child: const Center(
                        child: Text(
                          'Save Love Counter',
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

                const SizedBox(height: 80), // Add space for floating action button
              ],
            ),
          ),
        );
      } else {
        // Display View with live countdown
        return RefreshIndicator(
          onRefresh: _onRefresh,
          color: Provider.of<ThemeService>(context, listen: false).primary,
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
                      colors: Provider.of<ThemeService>(context, listen: false).isDarkMode 
                        ? Provider.of<ThemeService>(context, listen: false).darkGradient
                        : Provider.of<ThemeService>(context, listen: false).lightGradient,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Provider.of<ThemeService>(context, listen: false).primary.withOpacity(0.3),
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
                      icon: Icon(Icons.add, color: Provider.of<ThemeService>(context, listen: false).primary),
                      label: Text(
                        'Add',
                        style: TextStyle(color: Provider.of<ThemeService>(context, listen: false).primary),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Milestones List or Empty State
                if (_loveCounter!.milestones.isEmpty)
                  _buildEmptyMilestones()
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _loveCounter!.milestones.length,
                    itemBuilder: (context, index) {
                      final milestone = _loveCounter!.milestones[index];
                      return _buildMilestoneCard(milestone);
                    },
                  ),
                
                const SizedBox(height: 80), // Add space for floating action button
              ],
            ),
          ),
        );
      }
    }

    return PopScope(
      canPop: !_isEditing,
      onPopInvoked: (didPop) {
        if (!didPop && _isEditing) {
          // If we're in edit mode and the pop was prevented, exit edit mode
          setState(() {
            _isEditing = false;
          });
          // Reset the app bar
          widget.onAppBarUpdate?.call(null, null);
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: SkeletonLoaderFixed(
            isLoading: skeletonService.isLoading,
            child: buildContent(),
          ),
        ),
        // Add floating action button for editing
        floatingActionButton: (_loveCounter != null && !_isEditing) 
            ? FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                  widget.onAppBarUpdate?.call('💕 Edit Love Counter', () {
                    setState(() {
                      _isEditing = false;
                    });
                    widget.onAppBarUpdate?.call(null, null);
                  });
                },
                backgroundColor: Provider.of<ThemeService>(context, listen: false).primary,
                child: const Icon(Icons.edit, color: Colors.white),
              )
            : null,
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
    
    return Center(
      child: Padding(
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
      ),
    );
  }
  
  Widget _buildMilestoneCard(Milestone milestone) {
    final isDarkMode = Provider.of<ThemeService>(context).isDarkMode;
    
    return M3Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: isDarkMode ? const Color(0xFF3E3E4E) : Colors.white,
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
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMM d, yyyy').format(milestone.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Arrow icon with circle background for glossy effect
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
                Icons.arrow_forward_ios,
                size: 12,
                color: isDarkMode 
                  ? Colors.white70 
                  : Provider.of<ThemeService>(context, listen: false).primary,
              ),
            ),
          ),
        ],
      ),
    );
  } 
}