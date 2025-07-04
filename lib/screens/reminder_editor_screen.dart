import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/reminder_model.dart';
import '../models/user_model.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';
import '../services/theme_service.dart';
import '../services/skeleton_service.dart';
import '../widgets/gradient_app_bar.dart';

class ReminderEditorScreen extends StatefulWidget {
  final Reminder? existingReminder;

  const ReminderEditorScreen({
    Key? key,
    this.existingReminder,
  }) : super(key: key);

  @override
  State<ReminderEditorScreen> createState() => _ReminderEditorScreenState();
}

class _ReminderEditorScreenState extends State<ReminderEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _isRepeating = false;
  final List<String> _selectedDays = [];
  String _selectedEmoji = '📝';
  String _selectedCategory = 'General';
  bool _isSaving = false;

  // List of cute emojis to choose from
  final List<String> _emojis = ['📝', '💖', '🎀', '🌟', '💫', '🦋', '🌺', '🍡', '🌷', '🎵'];

  // List of categories
  final List<String> _categories = ['General', 'Health', 'Work', 'Personal', 'Shopping', 'Other'];

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers and values
    _titleController = TextEditingController(text: widget.existingReminder?.title ?? '');
    _descriptionController = TextEditingController(text: widget.existingReminder?.description ?? '');
    
    if (widget.existingReminder != null) {
      _selectedDate = widget.existingReminder!.dateTime;
      _selectedTime = TimeOfDay(
        hour: widget.existingReminder!.dateTime.hour,
        minute: widget.existingReminder!.dateTime.minute,
      );
      _isRepeating = widget.existingReminder!.isRepeating;
      _selectedDays.addAll(widget.existingReminder!.repeatDays);
      _selectedEmoji = widget.existingReminder!.emoji;
      _selectedCategory = widget.existingReminder!.category;
    } else {
      _selectedDate = DateTime.now().add(const Duration(days: 1));
      _selectedTime = TimeOfDay.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDarkMode = themeService.isDarkMode;
    
    // Ensure initialDate is not before firstDate
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final initialDate = _selectedDate.isBefore(firstDate) ? firstDate : _selectedDate;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: isDarkMode 
            ? ThemeData.dark().copyWith(
                colorScheme: ColorScheme.dark(
                  primary: themeService.primary,
                  onPrimary: Colors.white,
                  surface: const Color(0xFF383844),
                  onSurface: Colors.white,
                ),
                dialogBackgroundColor: const Color(0xFF383844),
              )
            : ThemeData.light().copyWith(
                colorScheme: ColorScheme.light(
                  primary: themeService.primary,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black87,
                ),
                dialogBackgroundColor: Colors.white,
              ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDarkMode = themeService.isDarkMode;
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: isDarkMode 
            ? ThemeData.dark().copyWith(
                colorScheme: ColorScheme.dark(
                  primary: themeService.primary,
                  onPrimary: Colors.white,
                  surface: const Color(0xFF383844),
                  onSurface: Colors.white,
                ),
                dialogBackgroundColor: const Color(0xFF383844),
                timePickerTheme: TimePickerThemeData(
                  backgroundColor: const Color(0xFF383844),
                  hourMinuteTextColor: Colors.white,
                  dayPeriodTextColor: Colors.white,
                  dialHandColor: themeService.primary,
                  dialTextColor: Colors.white,
                ),
              )
            : ThemeData.light().copyWith(
                colorScheme: ColorScheme.light(
                  primary: themeService.primary,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black87,
                ),
                dialogBackgroundColor: Colors.white,
                timePickerTheme: TimePickerThemeData(
                  backgroundColor: Colors.white,
                  hourMinuteTextColor: Colors.black87,
                  dayPeriodTextColor: Colors.black87,
                  dialHandColor: themeService.primary,
                  dialTextColor: Colors.black87,
                ),
              ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final userId = Provider.of<UserModel>(context, listen: false).id;
      final dataService = Provider.of<DataService>(context, listen: false);
      final skeletonService = Provider.of<SkeletonService>(context, listen: false);
      
      // Use skeleton service for quick toggle operation
      await skeletonService.withQuickToggle(() async {
        // Combine date and time
        final dateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );

        final reminder = Reminder(
          id: widget.existingReminder?.id ?? const Uuid().v4(),
          title: _titleController.text,
          description: _descriptionController.text,
          dateTime: dateTime,
          isCompleted: widget.existingReminder?.isCompleted ?? false,
          userId: userId,
          emoji: _selectedEmoji,
          category: _selectedCategory,
          isRepeating: _isRepeating,
          repeatDays: _selectedDays,
        );

        if (widget.existingReminder == null) {
          await dataService.addReminder(reminder);
        } else {
          await dataService.updateReminder(reminder);
        }

        // Schedule notification
        final notificationService = NotificationService();
        await notificationService.scheduleReminderNotification(reminder);
      });

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving reminder: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;
    final theme = Theme.of(context);
    final primaryColor = themeService.primary;
    final backgroundColor = theme.scaffoldBackgroundColor;


    return WillPopScope(
      onWillPop: () async {
        // Safely pop the route
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
          return false; // We handled the pop
        }
        return true; // Allow the system to handle the back button
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: GradientAppBar(
          title: widget.existingReminder == null ? '➕ Add Reminder' : '✏️ Edit Reminder',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          automaticallyImplyLeading: false,
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Description
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
                          'Reminder Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _titleController,
                          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            labelText: 'Title',
                            labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey.shade700),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
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
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            labelText: 'Description',
                            labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey.shade700),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
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
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Date and Time
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
                          'Date & Time',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _selectDate(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: isDarkMode ? Colors.white24 : Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          color: primaryColor,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            DateFormat('MMM d, yyyy').format(_selectedDate),
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isDarkMode ? Colors.white : Colors.black87,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _selectTime(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: isDarkMode ? Colors.white24 : Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          color: primaryColor,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            _selectedTime.format(context),
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isDarkMode ? Colors.white : Colors.black87,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Emoji selector card
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
                                          ? primaryColor.withOpacity(0.2)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _selectedEmoji == emoji
                                            ? primaryColor
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
                
                const SizedBox(height: 16),
                
                // Category selector
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
                          'Category',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: _categories.map((category) {
                              final isSelected = _selectedCategory == category;
                              return Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () {
                                    setState(() {
                                      _selectedCategory = category;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? primaryColor
                                          : primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      category,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : primaryColor,
                                        fontWeight: FontWeight.bold,
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
                
                const SizedBox(height: 16),
                
                // Repeat options
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
                        Row(
                          children: [
                            Text(
                              'Repeat',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            const Spacer(),
                            Switch(
                              value: _isRepeating,
                              activeColor: primaryColor,
                              onChanged: (value) {
                                setState(() {
                                  _isRepeating = value;
                                  if (!value) {
                                    _selectedDays.clear();
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        if (_isRepeating) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Repeat Days',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
                              ].asMap().entries.map((entry) {
                                final day = entry.value;
                                final isSelected = _selectedDays.contains(day);
                                
                                return Material(
                                  color: Colors.transparent,
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedDays.remove(day);
                                        } else {
                                          _selectedDays.add(day);
                                        }
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? primaryColor
                                            : Colors.transparent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? primaryColor
                                              : Colors.grey.shade300,
                                          width: 2,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: primaryColor.withOpacity(0.3),
                                                  blurRadius: 4,
                                                  spreadRadius: 1,
                                                )
                                              ]
                                            : null,
                                      ),
                                      child: Center(
                                        child: Text(
                                          day.substring(0, 1),
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : Colors.black87,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDarkMode ? themeService.darkGradient : themeService.lightGradient,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _isSaving ? null : _saveReminder,
                        child: Center(
                          child: _isSaving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  'Save Reminder',
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
                const SizedBox(height: 16),
              ],
              ),
          ),
        ),
      ),
    );
  }
}