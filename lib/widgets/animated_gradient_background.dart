import 'package:flutter/material.dart';
import 'package:gen_art_bg/gen_art_bg.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

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
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        // Dynamic radial gradient background based on selected theme
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.5),
          radius: 1.2,
          colors: isDarkMode 
              ? themeService.darkGradient
              : themeService.lightGradient,
          stops: const [0.0, 1.0],
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
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        // Dynamic radial gradient background that adapts to selected theme
        gradient: RadialGradient(
          center: const Alignment(0.3, -0.7),
          radius: 1.0,
          colors: isDarkMode 
              ? themeService.darkGradient
              : themeService.lightGradient,
          stops: const [0.0, 1.0],
        ),
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