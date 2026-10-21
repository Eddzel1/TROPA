import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Lays [child] out at the available height, but never shorter than [minHeight]. When the phone
/// keyboard (or a small screen) leaves less room, the whole body scrolls instead of overflowing,
/// and Flutter scrolls the focused field into view. With enough room it doesn't scroll, so [child]
/// can keep using `Expanded` for its list.
///
/// The widget tree has the same shape either way. Switching between a plain and a scrolling
/// layout would rebuild [child] as the keyboard opens, and the focused search field would lose
/// focus and close the keyboard again.
class KeyboardSafeBody extends StatelessWidget {
  final double minHeight;
  final EdgeInsetsGeometry padding;
  final Widget child;

  const KeyboardSafeBody({super.key, required this.minHeight, this.padding = EdgeInsets.zero, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final available = constraints.hasBoundedHeight ? constraints.maxHeight - padding.vertical : minHeight;
      final fits = available >= minHeight;
      return SingleChildScrollView(
        padding: padding,
        physics: fits ? const NeverScrollableScrollPhysics() : null,
        child: SizedBox(height: math.max(available, minHeight), child: child),
      );
    });
  }
}
