import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../models/user_model.dart';
import '../services/data_service.dart';
import '../services/navigation_state_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  
  // Onboarding data with GIFs - Updated for AI companion focus
  final List<Map<String, dynamic>> _onboardingData = [
    {
      'title': 'Welcome to Lilas Kokoro',
      'description': 'Your kawaii AI companion with smart reminders and personal assistance to make your day better.',
      'image': 'assets/images/onboarding/gif 1.gif',
      'color': const Color(0xFFFF85A2), // Pink
    },
    {
      'title': 'Smart Reminders',
      'description': 'Never miss important events with customizable reminders that adapt to your schedule.',
      'image': 'assets/images/onboarding/gif 2.gif',
      'color': const Color(0xFF8EC5FC), // Light Blue
    },
    {
      'title': 'AI Companion',
      'description': 'Chat with your AI assistant about anything - get answers, creative content, and helpful advice.',
      'image': 'assets/images/onboarding/gif 3.gif',
      'color': const Color(0xFFA3E4D7), // Mint
    },
    {
      'title': 'Love Tracker',
      'description': 'Celebrate special moments with your loved ones by tracking important dates and milestones.',
      'image': 'assets/images/onboarding/gif 4.gif',
      'color': const Color(0xFF95E1D3), // Teal
    },
    { // Final page for name input - Using gif 5 as requested
      'title': 'Almost There!',
      'description': 'Tell us your name to personalize your experience',
      'image': 'assets/images/onboarding/gif 5.gif', // Using gif 5 as requested
      'color': const Color(0xFFa091e7), // Purple - Neutral/inviting
    },
  ];

  @override
  void initState() {
    super.initState();
    _nameFocusNode.addListener(() {
      // We don't need the page scroll listener anymore for the name input
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final userName = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'User';
    final userId = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now();
    
    try {
      final dataService = Provider.of<DataService>(context, listen: false);
      final userModel = Provider.of<UserModel>(context, listen: false);
      final navigationStateService = Provider.of<NavigationStateService>(context, listen: false);
      
      final updatedUser = userModel.copyWith(
        id: userId,
        name: userName,
        email: '$userName@example.com', // Consider a placeholder or removing email if not used
        createdAt: now,
        lastLogin: now,
        onboardingCompleted: true,
      );
      
      await dataService.saveUser(updatedUser);
      
      await navigationStateService.completeOnboarding();
      
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to complete onboarding: $e'),
          actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom; // Use safe area padding

    // Define colors based on theme (use more neutral base)
    final backgroundColor = isDarkMode ? const Color(0xFF1A1A2E) : Colors.white;
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkMode ? Colors.white70 : Colors.grey.shade600;
    
    // Current page's accent color
    final accentColor = _onboardingData[_currentPage]['color'];
    
    return Scaffold(
      resizeToAvoidBottomInset: true, // Allow resizing for keyboard
      backgroundColor: backgroundColor,
      body: Column(
          children: [
          // Flexible PageView area
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  // If focusing name field, ensure keyboard is dismissed when swiping away
                  if (index != _onboardingData.length - 1 && _nameFocusNode.hasFocus) {
                     _nameFocusNode.unfocus();
                  }
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                 // Common layout for all pages, including the last one
                 return _buildPageContent(
                   context,
                   index,
                   isDarkMode,
                   primaryTextColor,
                   secondaryTextColor,
                  );
                },
              ),
            ),

          // Static Bottom Section (Progress, Buttons)
          Container(
            padding: EdgeInsets.only(
              left: 24, 
              right: 24, 
              top: 16, 
              bottom: bottomPadding > 0 ? bottomPadding : 24 // Use safe area bottom padding
            ),
              child: Column(
              mainAxisSize: MainAxisSize.min,
                children: [
                // Progress Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_onboardingData.length -1, (index) { // Exclude final page dot
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: index == _currentPage ? 24 : 8,
                      decoration: BoxDecoration(
                        color: index == _currentPage 
                            ? accentColor 
                            : accentColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                    ),
                    );
                  }),
                  ),
                const SizedBox(height: 24),

                // Navigation Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Skip Button (Visible only on first pages)
                    Opacity(
                       opacity: _currentPage < _onboardingData.length - 2 ? 1.0 : 0.0,
                       child: TextButton(
                         onPressed: _currentPage < _onboardingData.length - 2 
                             ? () {
                                 _pageController.animateToPage(
                                   _onboardingData.length - 1, // Go to name input
                                   duration: const Duration(milliseconds: 500),
                                   curve: Curves.easeInOut,
                                 );
                               }
                             : null, // Disable if not visible
                         style: TextButton.styleFrom(
                           foregroundColor: secondaryTextColor,
                           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                              child: Text(
                                'Skip',
                           style: const TextStyle(
                             fontFamily: 'Barriecito',
                                  fontSize: 16,
                             fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                    ),

                    // Next / Get Started Button (Using GestureDetector)
                    _buildActionButton(accentColor),
                          ],
                        ),
                ],
              ),
            ),
          ],
      ),
    );
  }

  // Build Action Button (Next/Get Started) using GestureDetector
  Widget _buildActionButton(Color accentColor) {
    final bool isLastPage = _currentPage == _onboardingData.length - 1;
    final String buttonText = isLastPage ? 'Get Started' : 'Next';
    final VoidCallback? action = isLastPage 
        ? _completeOnboarding 
        : () {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
            );
          };

    return GestureDetector(
      onTap: action,
              child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 15),
                decoration: BoxDecoration(
          color: accentColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
                ),
          ],
        ),
                  child: Text(
          buttonText,
          style: const TextStyle(
            fontFamily: 'Barriecito',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white, // Assuming white text looks good on accent colors
                ),
              ),
            ),
    );
  }

  // Builds the content for each page (including the final one)
  Widget _buildPageContent(
    BuildContext context,
    int index,
    bool isDarkMode,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    final data = _onboardingData[index];
    final accentColor = data['color'];
    final bool isFinalPage = index == _onboardingData.length - 1;
    final size = MediaQuery.of(context).size;

    // Determine content alignment based on page type
    final crossAxisAlignment = isFinalPage ? CrossAxisAlignment.center : CrossAxisAlignment.center;
    final textAlign = isFinalPage ? TextAlign.center : TextAlign.center;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: crossAxisAlignment, // Center alignment
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // GIF Container (Consistent Styling with Fixed Size)
          Container(
            // Use fixed dimensions for consistency
            width: 280,  // Fixed width
            height: 280, // Fixed height
            margin: const EdgeInsets.only(bottom: 32, top: 20), // Adjusted margin
                        decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
            ),
            child: ClipRRect( // Clip the GIF to the rounded corners
               borderRadius: BorderRadius.circular(24),
               child: Image.asset(
                 data['image'],
                 fit: BoxFit.cover,
                 errorBuilder: (context, error, stackTrace) {
                   return Icon(
                     Icons.image_not_supported_outlined,
                     size: 80,
                     color: secondaryTextColor,
                  );
                },
              ),
            ),
          ),
          
          // Title (Consistent Styling)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              data['title'],
              style: TextStyle(
                fontFamily: 'Barriecito',
                fontSize: 26, // Slightly adjusted size
                fontWeight: FontWeight.w600, // Use SemiBold for modern feel
                color: accentColor, // Use accent color for title
              ),
              textAlign: textAlign,
            ),
          ),
          
          // Description (Consistent Styling)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0), // Less horizontal padding
            child: Text(
              data['description'],
              style: TextStyle(
                fontFamily: 'Barriecito',
                fontSize: 16, // Consistent size
                color: secondaryTextColor,
                height: 1.6, // Increased line height for readability
              ),
              textAlign: textAlign,
            ),
          ),
          
          // Specific content for the final page (Name Input)
          if (isFinalPage) ...[
             const SizedBox(height: 32), // Space before input field
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 8.0),
               child: TextField(
                 controller: _nameController,
                 focusNode: _nameFocusNode,
                 style: TextStyle(color: primaryTextColor, fontSize: 18),
                 decoration: InputDecoration(
                   hintText: 'Your Name',
                   hintStyle: TextStyle(color: secondaryTextColor.withOpacity(0.7)),
                   filled: true,
                   fillColor: isDarkMode 
                       ? Colors.white.withOpacity(0.05) 
                       : Colors.black.withOpacity(0.04),
                   border: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(12),
                     borderSide: BorderSide.none,
                   ),
                   focusedBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(12),
                     borderSide: BorderSide(color: accentColor, width: 1.5),
                   ),
                   prefixIcon: Icon(
                     Icons.person_outline_rounded,
                     color: _nameFocusNode.hasFocus ? accentColor : secondaryTextColor,
            ),
                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                 ),
                 textInputAction: TextInputAction.done,
                 onSubmitted: (_) => _completeOnboarding(),
               ),
             ),
             const SizedBox(height: 20), // Space after input field before button area
          ],
        ],
      ),
    );
  }
}
