import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/love_counter_model.dart';
import '../models/user_model.dart';
import '../services/data_service.dart';
import '../services/theme_service.dart';
import '../services/skeleton_service.dart';
import '../widgets/gradient_app_bar.dart';

class LoveCounterEditScreen extends StatefulWidget {
  final LoveCounter? existingLoveCounter;

  const LoveCounterEditScreen({
    Key? key,
    this.existingLoveCounter,
  }) : super(key: key);

  @override
  State<LoveCounterEditScreen> createState() => _LoveCounterEditScreenState();
}

class _LoveCounterEditScreenState extends State<LoveCounterEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _userNameController;
  late TextEditingController _partnerNameController;
  late DateTime _anniversaryDate;
  String _selectedEmoji = '❤️';
  bool _isSaving = false;

  final List<String> _emojis = ['❤️', '💖', '💕', '💓', '💗', '💘', '💝', '💞', '💟', '❤️‍🔥'];

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers and values
    _userNameController = TextEditingController(
      text: widget.existingLoveCounter?.userName ?? '',
    );
    _partnerNameController = TextEditingController(
      text: widget.existingLoveCounter?.partnerName ?? '',
    );
    
    if (widget.existingLoveCounter != null) {
      _anniversaryDate = widget.existingLoveCounter!.anniversaryDate;
      _selectedEmoji = widget.existingLoveCounter!.emoji;
    } else {
      _anniversaryDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _partnerNameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDarkMode = themeService.isDarkMode;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _anniversaryDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
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
    if (picked != null && picked != _anniversaryDate) {
      setState(() {
        _anniversaryDate = picked;
      });
    }
  }

  Future<void> _saveLoveCounter() async {
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
        final loveCounter = LoveCounter(
          id: widget.existingLoveCounter?.id ?? const Uuid().v4(),
          userId: userId,
          userName: _userNameController.text,
          partnerName: _partnerNameController.text,
          anniversaryDate: _anniversaryDate,
          emoji: _selectedEmoji,
          milestones: widget.existingLoveCounter?.milestones ?? [],
        );

        await dataService.updateLoveCounter(loveCounter);
      });

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving love counter: $e'),
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
    final backgroundColor = theme.scaffoldBackgroundColor;
    final primaryColor = themeService.primary;

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
          title: widget.existingLoveCounter == null ? '💕 Create Love Counter' : '💕 Edit Love Counter',
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
                // Names Card
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
                        TextFormField(
                          controller: _userNameController,
                          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            labelText: 'Your Name',
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
                            prefixIcon: const Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _partnerNameController,
                          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            labelText: 'Partner\'s Name',
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
                            prefixIcon: const Icon(Icons.favorite),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter partner\'s name';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

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
                        Material(
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
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '${_anniversaryDate.day}/${_anniversaryDate.month}/${_anniversaryDate.year}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDarkMode ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
                        onTap: _isSaving ? null : _saveLoveCounter,
                        child: Center(
                          child: _isSaving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
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