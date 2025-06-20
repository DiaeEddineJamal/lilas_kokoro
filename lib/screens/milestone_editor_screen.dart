import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/love_counter_model.dart';
import '../models/milestone_model.dart';
import '../services/data_service.dart';
import '../widgets/gradient_app_bar.dart';
import '../services/theme_service.dart';

class MilestoneEditorScreen extends StatefulWidget {
  final LoveCounter loveCounter;
  final Milestone? existingMilestone;

  const MilestoneEditorScreen({
    Key? key,
    required this.loveCounter,
    this.existingMilestone,
  }) : super(key: key);

  @override
  State<MilestoneEditorScreen> createState() => _MilestoneEditorScreenState();
}

class _MilestoneEditorScreenState extends State<MilestoneEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _dayCountController;
  String _selectedEmoji = '🎉';
  bool _isSaving = false;

  final List<String> _emojis = ['🎉', '💖', '🎂', '🎁', '🎊', '💍', '🏆', '🎯', '🌟', '🥂'];

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    _titleController = TextEditingController(text: widget.existingMilestone?.title ?? '');
    _descriptionController = TextEditingController(text: widget.existingMilestone?.description ?? '');
    _dayCountController = TextEditingController(
      text: widget.existingMilestone?.dayCount.toString() ?? '',
    );
    
    if (widget.existingMilestone != null) {
      _selectedEmoji = widget.existingMilestone!.emoji;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dayCountController.dispose();
    super.dispose();
  }

  Future<void> _saveMilestone() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final dataService = Provider.of<DataService>(context, listen: false);
      
      // Create or update milestone
      final milestone = Milestone(
        id: widget.existingMilestone?.id ?? const Uuid().v4(),
        title: _titleController.text,
        description: _descriptionController.text,
        dayCount: int.parse(_dayCountController.text),
        emoji: _selectedEmoji,
        isCustom: true,
        // Provide the date parameter
        date: DateTime.now().add(Duration(days: int.parse(_dayCountController.text))),
      );

      // Get current milestones
      final currentMilestones = List<Milestone>.from(widget.loveCounter.milestones);
      
      // Update or add the milestone
      if (widget.existingMilestone != null) {
        final index = currentMilestones.indexWhere((m) => m.id == milestone.id);
        if (index >= 0) {
          currentMilestones[index] = milestone;
        } else {
          currentMilestones.add(milestone);
        }
      } else {
        currentMilestones.add(milestone);
      }
      
      // Update the love counter with the new milestones
      final updatedLoveCounter = widget.loveCounter.copyWith(
        milestones: currentMilestones,
      );
      
      await dataService.updateLoveCounter(updatedLoveCounter);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving milestone: $e')),
      );
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
    final backgroundColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: GradientAppBar(
        title: widget.existingMilestone == null ? '🏆 Add Milestone' : '✏️ Edit Milestone',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        'Milestone Details',
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
                          labelStyle: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: themeService.primary,
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
          labelStyle: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: themeService.primary,
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
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _dayCountController,
                        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                                decoration: InputDecoration(
          labelText: 'Day Count',
          labelStyle: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: themeService.primary,
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
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a day count';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
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
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: Material(
                  color: themeService.primary,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _isSaving ? null : _saveMilestone,
                    child: Center(
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Save Milestone',
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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}