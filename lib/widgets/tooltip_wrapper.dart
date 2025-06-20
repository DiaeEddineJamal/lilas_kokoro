import 'package:flutter/material.dart';

/// A wrapper for tooltips that prevents the "multiple tickers" issue
/// by only creating tooltips when they're actually needed.
class TooltipWrapper extends StatelessWidget {
  final Widget child;
  final String? message;

  const TooltipWrapper({
    Key? key,
    required this.child,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Only use a tooltip if we have a non-empty message
    if (message == null || message!.isEmpty) {
      return child;
    }

    // Wrap in a RepaintBoundary to reduce unnecessary repaints
    return RepaintBoundary(
      child: Tooltip(
        message: message!,
        child: child,
      ),
    );
  }
} 