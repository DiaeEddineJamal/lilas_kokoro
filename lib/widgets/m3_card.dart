import 'package:flutter/material.dart';

/// A Material Design 3 compliant card widget that can be used throughout the app.
/// This widget follows the Material Design 3 guidelines for cards with 3D shadow effects.
class M3Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final Color? color;
  final BorderRadiusGeometry? borderRadius;
  final VoidCallback? onTap;

  const M3Card({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation,
    this.color,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = color ?? (isDark ? const Color(0xFF383844) : Colors.white);
    final customRadius = borderRadius ?? BorderRadius.circular(20);
    final customElevation = elevation ?? (isDark ? 4.0 : 3.0);
    
    // Define the card with 3D shadow effect
    return Padding(
      padding: margin ?? const EdgeInsets.only(bottom: 12.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: customRadius,
          boxShadow: [
            // Main shadow for depth
            BoxShadow(
              color: isDark 
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.15),
              blurRadius: customElevation * 3,
              offset: Offset(0, customElevation),
              spreadRadius: -2,
            ),
            // Subtle secondary shadow for 3D effect
            BoxShadow(
              color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.08),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Material(
          color: cardColor,
          borderRadius: customRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            splashColor: colorScheme.primary.withOpacity(0.1),
            highlightColor: colorScheme.primary.withOpacity(0.05),
            borderRadius: customRadius is BorderRadius 
              ? customRadius 
              : BorderRadius.circular(20),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(16.0),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// A Material Design 3 compliant setting card widget with 3D shadow effect.
/// This widget is specifically designed for settings items.
class M3SettingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? titleColor;
  final Color? subtitleColor;
  final IconData? leadingIcon;
  final Color? leadingIconColor;
  final double? borderRadius;

  const M3SettingCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.backgroundColor,
    this.titleColor,
    this.subtitleColor,
    this.leadingIcon,
    this.leadingIconColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cardRadius = borderRadius ?? 16.0;
    final cardColor = backgroundColor ?? (isDark ? const Color(0xFF383844) : Colors.white);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          // Main shadow
          BoxShadow(
            color: isDark 
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
          // Subtle secondary shadow for 3D effect
          BoxShadow(
            color: isDark
              ? Colors.black.withOpacity(0.2)
              : Colors.black.withOpacity(0.08),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(cardRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(cardRadius),
          splashColor: colorScheme.primary.withOpacity(0.1),
          highlightColor: colorScheme.primary.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                if (leadingIcon != null) ...[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (leadingIconColor ?? colorScheme.primary).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      leadingIcon,
                      color: leadingIconColor ?? colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: titleColor ?? colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: subtitleColor ?? colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}