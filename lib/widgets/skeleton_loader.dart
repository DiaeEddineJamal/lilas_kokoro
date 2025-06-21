import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../services/theme_service.dart';
import '../services/skeleton_service.dart';
import 'app_header.dart';

/// Enhanced Skeleton Loader widget that provides beautiful, customized shimmer effects
/// with better visual appearance and component-specific loading indicators
class SkeletonLoader extends StatefulWidget {
  final Widget child;
  final bool? isLoading;
  final List<Widget>? headerWidgets;
  final ShimmerEffect? customEffect;
  final Color? containerColor;
  final bool enableAnimation;
  final Duration transitionDuration;
  final bool enableGlossyEffect;
  final bool ignoreQuickToggles;
  final List<Type> excludedTypes;

  const SkeletonLoader({
    Key? key,
    required this.child,
    this.isLoading,
    this.headerWidgets,
    this.customEffect,
    this.containerColor,
    this.enableAnimation = true,
    this.transitionDuration = const Duration(milliseconds: 200),
    this.enableGlossyEffect = false,
    this.ignoreQuickToggles = true,
    this.excludedTypes = const <Type>[],
  }) : super(key: key);

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> {
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final skeletonService = Provider.of<SkeletonService>(context);
    final isDarkMode = themeService.isDarkMode;
    
    // Use the provided isLoading value or fall back to the global service
    final shouldShowSkeleton = widget.isLoading ?? (skeletonService.isLoading && !skeletonService.isQuickToggle);
    
    // Optimized shimmer effect for better performance
    final shimmerEffect = widget.customEffect ?? ShimmerEffect(
      baseColor: isDarkMode 
          ? const Color(0xFF2A2A38)
          : Colors.grey[300]!,
      highlightColor: isDarkMode 
          ? const Color(0xFF343444)
          : Colors.grey[100]!,
      duration: const Duration(milliseconds: 1200), // Faster for better performance
    );
    
    // Simpler background color for containers
    final bgColor = widget.containerColor ?? (isDarkMode 
        ? const Color(0xFF2A2A38)
        : Colors.grey.shade100);
    
    final configData = SkeletonizerConfigData(
      effect: shimmerEffect,
      containersColor: bgColor,
      ignoreContainers: false,
      justifyMultiLineText: true,
    );
    
    // Wrapper to handle animations when switching between loading and content state
    Widget buildSkeletonContent(Widget content) {
      final skeletonContent = SkeletonizerConfig(
        data: configData,
        child: Skeletonizer(
          enabled: shouldShowSkeleton,
          child: content,
        ),
      );
      
      // Simplified animation for better performance
      if (widget.enableAnimation) {
        return AnimatedSwitcher(
          duration: widget.transitionDuration,
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: shouldShowSkeleton ? skeletonContent : content,
        );
      }
      
      return shouldShowSkeleton ? skeletonContent : content;
    }
    
    // Handle header widgets specially
    if (widget.headerWidgets != null && widget.headerWidgets!.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Headers are not skeletonized
          ...widget.headerWidgets!,

          // Content is skeletonized and takes remaining space
          Expanded(
            child: buildSkeletonContent(widget.child),
          ),
        ],
      );
    }

    // If no header widgets, just use the Skeletonizer directly
    return buildSkeletonContent(widget.child);
  }
}

/// A specialized version of SkeletonLoader for non-scrollable content
/// that doesn't need to be wrapped in an Expanded widget
class SkeletonLoaderFixed extends StatelessWidget {
  final Widget child;
  final bool? isLoading;
  final List<Widget>? headerWidgets;
  final ShimmerEffect? customEffect;
  final Color? containerColor;
  final bool enableAnimation;
  final Duration transitionDuration;
  final bool enableGlossyEffect;
  final List<Type> excludedTypes;

  const SkeletonLoaderFixed({
    Key? key,
    required this.child,
    this.isLoading,
    this.headerWidgets,
    this.customEffect,
    this.containerColor,
    this.enableAnimation = true,
    this.transitionDuration = const Duration(milliseconds: 200),
    this.enableGlossyEffect = false,
    this.excludedTypes = const <Type>[],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final skeletonService = Provider.of<SkeletonService>(context);
    final isDarkMode = themeService.isDarkMode;
    
    final shouldShowSkeleton = isLoading ?? skeletonService.isLoading;
    
    // Simplified shimmer effect for better performance
    final shimmerEffect = customEffect ?? ShimmerEffect(
      baseColor: isDarkMode 
          ? const Color(0xFF2A2A38)
          : Colors.grey[300]!,
      highlightColor: isDarkMode 
          ? const Color(0xFF343444)
          : Colors.grey[100]!,
      duration: const Duration(milliseconds: 1200),
    );
    
    // Simpler background color
    final bgColor = containerColor ?? (isDarkMode 
        ? const Color(0xFF2A2A38)
        : Colors.grey.shade100);
    
    final configData = SkeletonizerConfigData(
      effect: shimmerEffect,
      containersColor: bgColor,
      ignoreContainers: false,
      justifyMultiLineText: true,
    );
    
    Widget buildContent() {
      final skeletonContent = SkeletonizerConfig(
        data: configData,
        child: Skeletonizer(
          enabled: shouldShowSkeleton,
          child: child,
        ),
      );
      
      // Simplified animation
      if (enableAnimation) {
        return AnimatedSwitcher(
          duration: transitionDuration,
          child: shouldShowSkeleton ? skeletonContent : child,
        );
      }
      
      return shouldShowSkeleton ? skeletonContent : child;
    }
    
    // Handle header widgets
    if (headerWidgets != null && headerWidgets!.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...headerWidgets!,
          Expanded(child: buildContent()),
        ],
      );
    }
    
    return buildContent();
  }
}

/// Specialized skeleton components for common UI patterns
class SkeletonBones {
  /// Create a card-like skeleton with customizable dimensions and shape
  static Widget card({
    double? width,
    double height = 100,
    double borderRadius = 16,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    List<Widget>? children,
    bool withGloss = true,
  }) {
    return Skeleton.leaf(
      child: Builder(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;
          final isDarkMode = colorScheme.brightness == Brightness.dark;
          
          Widget cardContent = Container(
            width: width ?? double.infinity,
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: withGloss ? [
                BoxShadow(
                  color: isDarkMode
                      ? colorScheme.primary.withOpacity(0.05)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  spreadRadius: -2,
                ),
              ] : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: children ?? [
                Bone.text(words: 2, width: 120),
                const SizedBox(height: 8),
                Bone.text(words: 4, fontSize: 14),
                const SizedBox(height: 12),
                Bone.text(words: 3, fontSize: 12, width: 100),
              ],
            ),
          );
          
          return cardContent;
        }
      ),
    );
  }
  
  /// Create a list tile skeleton with avatar, title, and subtitle
  static Widget listTile({
    bool withAvatar = true,
    bool withSubtitle = true,
    bool withTrailing = true,
    double avatarSize = 40,
    double borderRadius = 12,
    bool withGloss = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Builder(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;
          final isDarkMode = colorScheme.brightness == Brightness.dark;
          
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              color: Colors.transparent,
              boxShadow: withGloss ? [
                BoxShadow(
                  color: isDarkMode
                      ? colorScheme.primary.withOpacity(0.04)
                      : Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  spreadRadius: -2,
                ),
              ] : null,
            ),
            child: Row(
              children: [
                if (withAvatar) 
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Bone.circle(size: avatarSize),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Bone.text(words: 2, width: 140),
                      if (withSubtitle) ...[
                        const SizedBox(height: 8),
                        Bone.text(words: 3, fontSize: 14, width: 180),
                      ],
                    ],
                  ),
                ),
                if (withTrailing)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Bone.icon(),
                  ),
              ],
            ),
          );
        }
      ),
    );
  }
  
  /// Create an alarm card skeleton
  static Widget alarmCard({
    bool withGloss = true,
  }) {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final isDarkMode = colorScheme.brightness == Brightness.dark;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: withGloss ? 2 : 1,
          shadowColor: isDarkMode
              ? colorScheme.primary.withOpacity(0.1)
              : Colors.black.withOpacity(0.06),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Skeleton.leaf(child: Container()),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Bone.text(words: 2, width: 150),
                      const SizedBox(height: 8),
                      Bone.text(words: 1, width: 80, fontSize: 14),
                      const SizedBox(height: 4),
                      Bone.text(words: 2, width: 120, fontSize: 12),
                    ],
                  ),
                ),
                Container(
                  width: 46,
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Skeleton.leaf(child: Container()),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
  
  /// Create a reminder card skeleton with improved visuals
  static Widget reminderCard({
    bool withGloss = true,
  }) {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final isDarkMode = colorScheme.brightness == Brightness.dark;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: withGloss ? 2 : 1,
          shadowColor: isDarkMode
              ? colorScheme.primary.withOpacity(0.1)
              : Colors.black.withOpacity(0.06),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Skeleton.leaf(child: Container()),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Bone.text(words: 3, width: 180),
                      const SizedBox(height: 8),
                      Bone.text(words: 2, width: 120, fontSize: 14),
                      const SizedBox(height: 4),
                      Bone.text(words: 2, width: 100, fontSize: 12),
                    ],
                  ),
                ),
                Skeleton.ignore(
                  child: Icon(
                    Icons.more_vert, 
                    color: Colors.grey.withOpacity(0.5),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
  
  /// Create a dashboard stat card skeleton with enhanced visuals
  static Widget statCard({
    double height = 100,
    bool withGloss = true,
  }) {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final isDarkMode = colorScheme.brightness == Brightness.dark;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          elevation: withGloss ? 2 : 1,
          shadowColor: isDarkMode
              ? colorScheme.primary.withOpacity(0.1)
              : Colors.black.withOpacity(0.06),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            height: height,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Bone.text(words: 1, width: 60, fontSize: 12),
                const SizedBox(height: 12),
                Bone.text(words: 1, fontSize: 24, width: 40),
                const SizedBox(height: 8),
                Bone.text(words: 2, fontSize: 12, width: 100),
              ],
            ),
          ),
        );
      }
    );
  }
  
  /// Create a glossy progress indicator skeleton
  static Widget progressIndicator({
    double width = 200,
    double height = 12,
    double borderRadius = 6,
    double progress = 0.7,
    bool withGloss = true,
  }) {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final isDarkMode = colorScheme.brightness == Brightness.dark;
        
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: isDarkMode
                ? Color.alphaBlend(colorScheme.primary.withOpacity(0.1), Colors.grey[800]!)
                : Color.alphaBlend(colorScheme.primary.withOpacity(0.05), Colors.grey[200]!),
            boxShadow: withGloss ? [
              BoxShadow(
                color: isDarkMode
                    ? colorScheme.primary.withOpacity(0.05)
                    : Colors.black.withOpacity(0.03),
                blurRadius: 4,
                spreadRadius: -1,
              ),
            ] : null,
          ),
          child: Skeleton.leaf(child: Container()),
        );
      }
    );
  }
  
  /// Create an incoming message bubble skeleton
  static Widget incomingMessage({
    double maxWidth = 250,
    bool withAvatar = true,
    bool withGloss = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (withAvatar)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Bone.circle(size: 32),
            ),
          Flexible(
            child: Builder(
              builder: (context) {
                final colorScheme = Theme.of(context).colorScheme;
                final isDarkMode = colorScheme.brightness == Brightness.dark;
                
                return Container(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    color: isDarkMode
                        ? Color.alphaBlend(colorScheme.primary.withOpacity(0.1), Colors.grey[800]!)
                        : Color.alphaBlend(colorScheme.primary.withOpacity(0.05), Colors.grey[200]!),
                    boxShadow: withGloss ? [
                      BoxShadow(
                        color: isDarkMode
                            ? colorScheme.primary.withOpacity(0.05)
                            : Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        spreadRadius: -1,
                      ),
                    ] : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Bone.text(words: 6, fontSize: 14),
                      const SizedBox(height: 6),
                      Bone.text(words: 1, width: 60, fontSize: 10),
                    ],
                  ),
                );
              }
            ),
          ),
        ],
      ),
    );
  }
  
  /// Create an outgoing message bubble skeleton
  static Widget outgoingMessage({
    double maxWidth = 250,
    bool withDeliveryStatus = true,
    bool withGloss = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Builder(
              builder: (context) {
                final colorScheme = Theme.of(context).colorScheme;
                final isDarkMode = colorScheme.brightness == Brightness.dark;
                
                return Container(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                    color: isDarkMode
                        ? Color.alphaBlend(colorScheme.primary.withOpacity(0.25), Colors.grey[800]!)
                        : Color.alphaBlend(colorScheme.primary.withOpacity(0.15), Colors.grey[100]!),
                    boxShadow: withGloss ? [
                      BoxShadow(
                        color: isDarkMode
                            ? colorScheme.primary.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        spreadRadius: -1,
                      ),
                    ] : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Bone.text(words: 5, fontSize: 14),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Bone.text(words: 1, width: 50, fontSize: 10),
                          if (withDeliveryStatus) ...[
                            const SizedBox(width: 4),
                            Bone.icon(size: 12),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget that traverses the widget tree to apply shimmer effects
class ShimmerLoading extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final List<Type> excludedTypes;

  const ShimmerLoading({
    Key? key,
    required this.isLoading,
    required this.child,
    this.excludedTypes = const <Type>[],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Always skip loading for AppHeader
    if (child.runtimeType == AppHeader || excludedTypes.any((type) => child.runtimeType == type)) {
      return child;
    }
    
    // Check for quick toggle operations in SkeletonService
    final skeletonService = Provider.of<SkeletonService>(context, listen: false);
    if (skeletonService.isQuickToggle) {
      return child; // Skip skeleton loading for quick toggle operations
    }
    
    return Skeletonizer(
      enabled: isLoading,
      child: child,
    );
  }
}