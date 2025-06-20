import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/love_counter_model.dart';
import '../models/milestone_model.dart';
import '../services/data_service.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingMilestone == null ? 'Add Milestone' : 'Edit Milestone',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFF85A2),
        foregroundColor: Colors.white,
        elevation: 0,
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
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
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Title',
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
                        decoration: InputDecoration(
                          labelText: 'Description',
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
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _dayCountController,
                        decoration: InputDecoration(
                          labelText: 'Day Count',
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
                          helperText: 'Number of days from your anniversary',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter day count';
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
              
              const SizedBox(height: 16),
              
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
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
                        ),
                      ),
                      const SizedBox(height: 16),
                      // For the emoji selector
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: _emojis.map((emoji) {
                          return Material(
                            color: Colors.transparent,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
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
                                      ? const Color(0xFFFF85A2).withOpacity(0.2)
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _selectedEmoji == emoji
                                        ? const Color(0xFFFF85A2)
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
                      
                      const SizedBox(height: 24),
                      
                      // For the save button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: Material(
                          color: const Color(0xFFFF85A2),
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
                      )
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveMilestone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF85A2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Save Milestone',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}