import 'package:flutter/material.dart';
import 'tooltip_wrapper.dart';

/// A Material Design 3 compliant switch widget that can be used throughout the app.
/// This widget follows the Material Design 3 guidelines for switches with 3D shadow effects.
class M3Switch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String title;
  final String? subtitle;
  final Color? activeColor;
  final Color? activeTrackColor;
  final Color? inactiveThumbColor;
  final Color? inactiveTrackColor;
  final String? tooltip;

  const M3Switch({
    Key? key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.activeColor,
    this.activeTrackColor,
    this.inactiveThumbColor,
    this.inactiveTrackColor,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    // Use our custom TooltipWrapper instead of direct Tooltip
    return TooltipWrapper(
      message: tooltip,
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: SwitchListTile(
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
                fontSize: 16,
              ),
            ),
            subtitle: subtitle != null 
              ? Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ) 
              : null,
            value: value,
            onChanged: onChanged,
            activeColor: activeColor ?? colorScheme.primary,
            activeTrackColor: activeTrackColor ?? 
              (isDark ? colorScheme.primary.withOpacity(0.4) : colorScheme.primaryContainer),
            inactiveThumbColor: inactiveThumbColor ?? colorScheme.outline,
            inactiveTrackColor: inactiveTrackColor ?? 
              (isDark ? colorScheme.surfaceVariant.withOpacity(0.5) : colorScheme.surfaceVariant),
            // Clean modern look without check icon
            thumbIcon: null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          ),
        ),
      ),
    );
  }
}