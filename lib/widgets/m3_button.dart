import 'package:flutter/material.dart';
import 'tooltip_wrapper.dart';

enum M3ButtonType {
  primary,
  secondary,
  tertiary,
  error,
}

/// A Material Design 3 compliant button widget that can be used throughout the app.
/// This widget follows the Material Design 3 guidelines for buttons with added glossy effects.
class M3Button extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isOutlined;
  final bool isTextButton;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final bool isLoading;
  final double borderRadius;
  final bool isFullWidth;
  final M3ButtonType buttonType;

  const M3Button({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isOutlined = false,
    this.isTextButton = false,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.width,
    this.height,
    this.isLoading = false,
    this.borderRadius = 16,
    this.isFullWidth = false,
    this.buttonType = M3ButtonType.primary,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Determine button style based on type
    Widget button;
    
    if (isTextButton) {
      // Text button with enhanced ink effect
      button = TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: foregroundColor ?? colorScheme.primary,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: _buildButtonContent(context),
      );
    } else if (isOutlined) {
      // Outlined button with glossy effect
      button = OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: foregroundColor ?? colorScheme.primary,
          side: BorderSide(
            color: (foregroundColor ?? colorScheme.primary).withOpacity(0.8),
            width: 1.5,
          ),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          // Add subtle shadow for depth
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        child: _buildButtonContent(context),
      );
    } else {
      // Elevated button with glossy gradient effect
      Color baseColor = backgroundColor ?? colorScheme.primary;
      
      button = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              baseColor,
              Color.lerp(baseColor, isDark ? Colors.black : Colors.white, 0.2)!,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: baseColor.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
              spreadRadius: -2,
            ),
            BoxShadow(
              color: baseColor.withOpacity(0.2),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(borderRadius),
            splashColor: Colors.white.withOpacity(0.1),
            highlightColor: Colors.white.withOpacity(0.05),
            child: Container(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _buildButtonContent(context),
            ),
          ),
        ),
      );
    }
    
    // Apply fixed width/height if specified
    if (width != null || height != null) {
      return SizedBox(
        width: width,
        height: height,
        child: button,
      );
    }
    
    return isFullWidth 
      ? SizedBox(
          width: double.infinity,
          child: button,
        )
      : button;
  }
  
  Widget _buildButtonContent(BuildContext context) {
    final textColor = isTextButton || isOutlined 
        ? (foregroundColor ?? Theme.of(context).colorScheme.primary)
        : (foregroundColor ?? Colors.white);
    
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }
    
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }
    
    return Text(
      text,
      style: TextStyle(
        color: textColor,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

/// A Material Design 3 compliant floating action button with glossy effect.
class M3FloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isExtended;
  final String? label;

  const M3FloatingActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.isExtended = false,
    this.label,
  }) : assert(!isExtended || (isExtended && label != null), 'Label is required for extended FAB');

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = backgroundColor ?? colorScheme.primaryContainer;
    
    return TooltipWrapper(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isExtended ? 16 : 28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor,
                Color.lerp(baseColor, isDark ? Colors.black : Colors.white, 0.15)!,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: baseColor.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
                spreadRadius: -2,
              ),
            ],
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(isExtended ? 16 : 28),
            splashColor: Colors.white.withOpacity(0.2),
            highlightColor: Colors.white.withOpacity(0.1),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isExtended ? 16 : 16,
                vertical: isExtended ? 16 : 16
              ),
              child: isExtended && label != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: foregroundColor ?? colorScheme.onPrimaryContainer),
                        const SizedBox(width: 8),
                        Text(
                          label!,
                          style: TextStyle(
                            color: foregroundColor ?? colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Icon(icon, color: foregroundColor ?? colorScheme.onPrimaryContainer),
      ),
          ),
        ),
      ),
    );
  }
}