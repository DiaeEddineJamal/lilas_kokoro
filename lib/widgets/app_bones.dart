import 'package:flutter/material.dart';

/// App-specific skeleton widgets for component-specific loading states
class AppBones {
  // Standard card skeleton with customizable aspect ratio
  static Widget card({
    double width = double.infinity,
    double? height,
    double aspectRatio = 16 / 9,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(16)),
    EdgeInsets margin = const EdgeInsets.all(0),
    EdgeInsets padding = const EdgeInsets.all(16),
    bool withGloss = true,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return Container(
          width: width,
          height: height,
          margin: margin,
          padding: padding,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A30) : Colors.white,
            borderRadius: borderRadius,
            boxShadow: withGloss ? [
              BoxShadow(
                color: isDark 
                    ? const Color(0xFFFF85A2).withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ] : null,
          ),
          child: height == null 
            ? AspectRatio(
                aspectRatio: aspectRatio,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3A3A45) : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3A3A45) : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
        );
      }
    );
  }
  
  // Reminder card skeleton
  static Widget reminderCard({bool withGloss = true}) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF383844) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: withGloss ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ] : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Checkbox placeholder
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A35) : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Emoji circle
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF85A2).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 18,
                        width: 140,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A2A35) : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 14,
                        width: 180,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A2A35) : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 120,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A2A35) : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
  
  // Love counter card skeleton
  static Widget loveCounterCard({bool withGloss = true}) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF85A2), Color(0xFFFF9BAD)],
            ),
            boxShadow: withGloss ? [
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
            ] : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Emoji circle
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Counter
                Container(
                  height: 72,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Text
                Container(
                  height: 20,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Time grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _timeElement(),
                    _timeElement(),
                    _timeElement(),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _timeElement(),
                    _timeElement(),
                    _timeElement(),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    );
  }
  
  static Widget _timeElement() {
    return Container(
      height: 60,
      width: 60,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
  
  // Alarm card skeleton
  static Widget alarmCard({bool withGloss = true}) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF383844) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: withGloss ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ] : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Time circle
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A35) : const Color(0xFFF5F5F5),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 18,
                        width: 120,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A2A35) : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 14,
                        width: 80,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A2A35) : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Switch
                Container(
                  width: 46,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A35) : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
} 