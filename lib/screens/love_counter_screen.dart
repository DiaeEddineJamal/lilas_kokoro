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
import '../widgets/app_header.dart';

class LoveCounterScreen extends StatefulWidget {
  const LoveCounterScreen({Key? key}) : super(key: key);

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
    skeletonService.showLoader(); // Show loader using the service

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
    } finally {
       if (mounted) {
         skeletonService.hideLoader();
       }
    }
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
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF85A2),
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
    final isDarkMode = Provider.of<ThemeService>(context).isDarkMode;
    final skeletonService = Provider.of<SkeletonService>(context);

    // Build the main content based on state
    Widget buildContent() {
      if (_isEditing || _loveCounter == null) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Use min to avoid expansion
            children: [
              // Names Card - Simplified without glossy effect
              M3Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(24),
                color: isDarkMode ? const Color(0xFF3E3E4E) : Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Names',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _userNameController,
                        decoration: InputDecoration(
                          labelText: 'Your Name',
                      labelStyle: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                      ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFFF85A2),
                              width: 2,
                            ),
                          ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _partnerNameController,
                        decoration: InputDecoration(
                          labelText: 'Partner\'s Name',
                      labelStyle: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                      ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFFF85A2),
                              width: 2,
                            ),
                        ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
                          ),
                        ),
                      ),
                  ),
                    const SizedBox(height: 8), // Additional padding at bottom
                  ],
                ),
              ),

              // Anniversary Date Card - Now with glossy effect
              M3Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(24),
                color: isDarkMode ? const Color(0xFF3E3E4E) : Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Anniversary Date',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    InkWell(
                      onTap: () => _selectDate(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              color: Color(0xFFFF85A2),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              DateFormat('MMMM d, yyyy').format(_anniversaryDate),
                              style: TextStyle(
                                fontSize: 16,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Color(0xFFFF85A2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Emoji Card - Now with glossy effect
              M3Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(24),
                color: isDarkMode ? const Color(0xFF3E3E4E) : Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Emoji',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
              const SizedBox(height: 24),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: _emojis.map((emoji) {
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedEmoji = emoji;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: _selectedEmoji == emoji
                                  ? const Color(0xFFFF85A2).withOpacity(0.2)
                                  : isDarkMode 
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedEmoji == emoji
                                    ? const Color(0xFFFF85A2)
                                    : isDarkMode
                                        ? Colors.white24
                                        : Colors.grey.shade300,
                                width: _selectedEmoji == emoji ? 2 : 1,
                              ),
                              boxShadow: _selectedEmoji == emoji
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFFF85A2).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
              ),
                  ],
                ),
              ),

              // Save Button - Changed to match global style
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Material(
                    color: const Color(0xFFFF85A2),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _saveLoveCounter,
                      child: Center(
                        child: Text(
                          "Save Love Counter",
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
              ),
            ],
          ),
        );
      } else {
        // Display View with live countdown
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Use min to avoid expansion
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced Love counter card with glossy effect
              Container(
                margin: const EdgeInsets.only(bottom: 24, top: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF85A2).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                      spreadRadius: -2,
                    ),
                    BoxShadow(
                      color: const Color(0xFFFF85A2).withOpacity(0.1),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Decorative elements for glossy effect
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Main card content
                    ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                              colors: [Color(0xFFFF85A2), Color(0xFFFF9BAD)],
                              stops: [0.0, 1.0],
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Emoji with decorative circle
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                          ),
                          child: Center(
                            child: Text(
                              _loveCounter!.emoji,
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                              // Live Countdown Timer
                              _buildLiveCountdown(),
                        
                        const SizedBox(height: 24),
                        
                        // Names with decorative elements
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.25),
                                    width: 1,
                                  ),
                          ),
                          child: Text(
                            '${_loveCounter!.userName} & ${_loveCounter!.partnerName}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Anniversary date
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Since ${DateFormat('MMMM d, yyyy').format(_loveCounter!.anniversaryDate)}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
                  ],
                ),
              ),
              
              // Milestones section with enhanced header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Milestones',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  M3Button(
                    text: "Add New",
                    icon: Icons.add,
                    isTextButton: true,
                    foregroundColor: const Color(0xFFFF85A2),
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
              
              const SizedBox(height: 16),
              
              // Milestones list with enhanced cards and proper physics
              _loveCounter!.milestones.isEmpty
                  ? _buildEmptyMilestones()
                  : ListView.builder(
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
        );
      }
    }

    return Scaffold(
      body: Column(
        children: [
          // App header
          AppHeader(
            title: 'Love Counter',
            titleIcon: Icons.favorite,
          ),
          
          // Content in Expanded widget
          Expanded(
            child: SafeArea(
              top: false, // Already handled by AppHeader
              child: SkeletonLoaderFixed(
                isLoading: skeletonService.isLoading,
                child: buildContent(),
              ),
            ),
          ),
        ],
      ),
      // Add floating action button for editing
      floatingActionButton: (_loveCounter != null && !_isEditing) 
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              backgroundColor: const Color(0xFFFF85A2),
              child: const Icon(Icons.edit, color: Colors.white),
            )
          : null,
    );
  }
  
  // Build the live countdown display
  Widget _buildLiveCountdown() {
    if (_loveCounter == null) return const SizedBox.shrink();
    
    // Get the total duration between anniversary date and now
    final Duration difference = _now.difference(_loveCounter!.anniversaryDate);
    final int totalDays = difference.inDays;
    
    // More accurate calculation for years, months, and days
    DateTime anniversary = _loveCounter!.anniversaryDate;
    DateTime today = _now;
    
    // Calculate years
    int years = today.year - anniversary.year;
    
    // Adjust years if the anniversary hasn't occurred this year yet
    if (today.month < anniversary.month || 
        (today.month == anniversary.month && today.day < anniversary.day)) {
      years--;
    }
    
    // Calculate anniversary date this year (or next year if anniversary hasn't occurred yet)
    DateTime anniversaryThisYear = DateTime(
      today.year + (today.month < anniversary.month || 
                   (today.month == anniversary.month && today.day < anniversary.day) ? 0 : 1),
      anniversary.month,
      anniversary.day,
    );
    
    // Calculate months between today and last anniversary (or next anniversary)
    DateTime lastAnniversary = DateTime(
      today.year - (today.month > anniversary.month || 
                   (today.month == anniversary.month && today.day >= anniversary.day) ? 0 : 1),
      anniversary.month,
      anniversary.day,
    );
    
    int months = 0;
    DateTime countDate = lastAnniversary;
    
    while (countDate.year < today.year || 
           (countDate.year == today.year && countDate.month < today.month)) {
      months++;
      countDate = DateTime(countDate.year + (countDate.month == 12 ? 1 : 0), 
                           countDate.month == 12 ? 1 : countDate.month + 1, 
                           countDate.day);
    }
    
    months = months % 12;
    
    // Calculate days
    int days = today.day - anniversary.day;
    if (days < 0) {
      // Go back one month and add the days in that month
      DateTime prevMonth = DateTime(today.year, today.month - 1, 1);
      int daysInPrevMonth = DateTime(today.year, today.month, 0).day;
      days = daysInPrevMonth + days;
    }
    
    // Get hours, minutes, seconds
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;
    
    return Column(
      children: [
        // Main counter showing days
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
                color: const Color(0xFFFF85A2).withOpacity(0.5),
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
              backgroundColor: const Color(0xFFFF85A2),
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
                                        color: const Color(0xFFFF85A2).withOpacity(0.15),
                                        shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFF85A2).withOpacity(0.3),
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
                        color: const Color(0xFFFF85A2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFF85A2).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                                            'Day ${milestone.dayCount}',
                                            style: TextStyle(
                          fontSize: 12,
                                              color: const Color(0xFFFF85A2),
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
                : const Color(0xFFFF85A2).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: isDarkMode 
                  ? Colors.white70 
                  : const Color(0xFFFF85A2),
              ),
            ),
          ),
        ],
      ),
    );
  } 
  }