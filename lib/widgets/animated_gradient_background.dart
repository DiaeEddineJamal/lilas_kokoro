import 'package:flutter/material.dart';
import 'package:gen_art_bg/gen_art_bg.dart';

class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  
  const AnimatedGradientBackground({
    super.key,
    required this.child,
  });

  @override
  State<AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with TickerProviderStateMixin {

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        // Base gradient background
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode 
              ? [
                  const Color(0xFF1a1a2e), // Deep dark blue
                  const Color(0xFF16213e), // Dark navy
                  const Color(0xFF0f3460), // Midnight blue
                ]
              : [
                  const Color(0xFFffeef4), // Soft pink
                  const Color(0xFFf8f4ff), // Light lavender
                  const Color(0xFFf0f8ff), // Alice blue
                ],
        ),
      ),
      child: Stack(
        children: [
          // WaveDotGrid overlay with proper color blending
          Container(
            width: double.infinity,
            height: double.infinity,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                isDarkMode 
                    ? const Color(0xFF0f3460) // Darker blue to blend with dark background
                    : const Color.fromARGB(255, 255, 255, 255), // Gray to blend with light background
                BlendMode.overlay,
              ),
              child: Opacity(
                opacity: isDarkMode ? 0.8 : 0.4,
                child: WaveDotGrid(
                  columns: 15,
                  rows: 25,
                  locationConstant: 100,
                ),
              ),
            ),
          ),
          // Child content
          widget.child,
        ],
      ),
    );
  }
}

/// A sophisticated animated background specifically for chat interfaces
class ChatAnimatedBackground extends StatelessWidget {
  const ChatAnimatedBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        // Base gradient background that adapts to theme
        color: isDarkMode 
            ? const Color(0xFF1a1a2e) // Deep dark blue for dark mode
            : Colors.white, // Pure white for light mode
      ),
      child: isDarkMode 
        ? Container(
            width: double.infinity,
            height: double.infinity,
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Color(0xFF0f3460), // Darker blue to blend with dark background
                BlendMode.overlay,
              ),
              child: Opacity(
                opacity: 0.7,
                child: WaveDotGrid(
                  columns: 15, // Number of columns
                  rows: 25, // Number of rows
                  locationConstant: 100, // Location constant for wave effect
                ),
              ),
            ),
          )
        : WaveDotGrid(
            columns: 15, // Number of columns
            rows: 25, // Number of rows
            locationConstant: 100, // Location constant for wave effect
          ),
    );
  }
} 