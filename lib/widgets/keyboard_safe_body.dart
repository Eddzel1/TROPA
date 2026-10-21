import 'package:flutter/material.dart';

/// Lays [child] out at the available height, but never shorter than [minHeight]. When the phone
/// keyboard (or a small screen) leaves less room, the whole body scrolls instead of overflowing,
/// and Flutter scrolls the focused field into view. With enough room nothing changes, so [child]
/// can keep using `Expanded` for its list.
class KeyboardSafeBody extends StatelessWidget {
  final double minHeight;
  final EdgeInsetsGeometry padding;
  final Widget child;

  const KeyboardSafeBody({super.key, required this.minHeight, this.padding = EdgeInsets.zero, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final vertical = padding.vertical;
      if (!constraints.hasBoundedHeight || constraints.maxHeight - vertical >= minHeight) {
        return Padding(padding: padding, child: child);
      }
      return SingleChildScrollView(
        padding: padding,
        child: SizedBox(height: minHeight, child: child),
      );
    });
  }
}
