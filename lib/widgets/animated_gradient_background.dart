import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';

class AnimatedGradientBackground extends StatelessWidget {
  final Widget child;
  final bool isDarkMode;
  
  const AnimatedGradientBackground({
    Key? key,
    required this.child,
    required this.isDarkMode,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animated gradient background
        Positioned.fill(
          child: _GradientBackgroundWithAnimation(isDarkMode: isDarkMode),
        ),
        
        // Noise texture overlay
        Positioned.fill(
          child: _NoiseTexture(opacity: isDarkMode ? 0.08 : 0.05),
        ),
        
        // Main content
        child,
      ],
    );
  }
}

class _GradientBackgroundWithAnimation extends StatelessWidget {
  final bool isDarkMode;
  
  const _GradientBackgroundWithAnimation({
    Key? key,
    required this.isDarkMode,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Create a custom animation to drive the gradient
    final tween = MovieTween()
      ..tween(
        'color1',
        isDarkMode 
          ? ColorTween(begin: const Color(0xFF0A0E21), end: const Color(0xFF141A31))
          : ColorTween(begin: const Color(0xFFE5EBF2), end: const Color(0xFFD8E2F0)),
        duration: const Duration(seconds: 10),
      )
      ..tween(
        'color2',
        isDarkMode
          ? ColorTween(begin: const Color(0xFF141A31), end: const Color(0xFF0A1326))
          : ColorTween(begin: const Color(0xFFD6E9F7), end: const Color(0xFFE8DDEA)),
        duration: const Duration(seconds: 10),
      )
      ..tween(
        'color3',
        isDarkMode
          ? ColorTween(begin: const Color(0xFF0F1B29), end: const Color(0xFF121828))
          : ColorTween(begin: const Color(0xFFE8DDEA), end: const Color(0xFFF0E5D6)),
        duration: const Duration(seconds: 10),
      );
    
    return CustomAnimationBuilder<Movie>(
      tween: tween,
      duration: const Duration(seconds: 20),
      builder: (context, value, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.8, -0.6),
              radius: 1.2,
              colors: [
                value.get('color1'),
                value.get('color2'),
                value.get('color3'),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
      control: Control.mirror, // Smoothly animate back and forth
    );
  }
}

class _NoiseTexture extends StatelessWidget {
  final double opacity;
  
  const _NoiseTexture({
    Key? key,
    this.opacity = 0.05,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcOver,
      shaderCallback: (bounds) => ImageShader(
        _createNoiseImage(),
        TileMode.repeated,
        TileMode.repeated,
        Matrix4.identity().storage,
      ),
      child: Opacity(
        opacity: opacity,
        child: Container(
          color: Colors.white,
        ),
      ),
    );
  }
  
  // Generate a noise texture programmatically
  ui.Image _createNoiseImage() {
    final random = Random();
    const width = 256;
    const height = 256;
    
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Draw random noise pixels
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (random.nextDouble() > 0.8) {
          final color = Color.fromRGBO(
            255,
            255,
            255,
            random.nextDouble() * 0.15,
          );
          canvas.drawRect(
            Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1),
            Paint()..color = color,
          );
        }
      }
    }
    
    final picture = recorder.endRecording();
    return picture.toImageSync(width, height);
  }
} 