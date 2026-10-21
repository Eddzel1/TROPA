import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/web_viewport.dart';

/// Web only: sets the keyboard inset (`viewInsets.bottom`) to the part of the app the on-screen
/// keyboard actually hides, measured from the page instead of trusted from the engine.
///
/// On iPhone Safari the reported inset and Safari's own page shrinking could both take the
/// keyboard's height off the screen, leaving pages with no room at all while typing. Measuring
/// what is visible stays right however the browser handles the keyboard. Elsewhere it does nothing.
class WebKeyboardInset extends StatelessWidget {
  final Widget child;

  const WebKeyboardInset({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;
    final mq = MediaQuery.of(context);
    final area = visibleArea();
    if (area == null) return child;

    // Bottom of what is visible, in the app's own coordinates (the app starts at viewTop).
    final visibleBottom = math.min(area.viewBottom, area.visibleBottom) - area.viewTop;
    final measured = mq.viewInsets.bottom == 0 ? 0.0 : math.max(0.0, mq.size.height - visibleBottom);
    final fixed = mq.copyWith(viewInsets: mq.viewInsets.copyWith(bottom: measured));

    Widget result = MediaQuery(data: fixed, child: child);
    if (keyboardDebugRequested) {
      result = Stack(children: [
        result,
        Positioned(
          left: 4,
          right: 4,
          top: mq.padding.top + 2,
          child: IgnorePointer(
            child: Material(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  'size ${mq.size.width.round()}x${mq.size.height.round()} · engine inset ${mq.viewInsets.bottom.round()}'
                  ' → used ${measured.round()}\n'
                  'view ${area.viewTop.round()}–${area.viewBottom.round()} · visible ${area.visibleTop.round()}–${area.visibleBottom.round()}',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
            ),
          ),
        ),
      ]);
    }
    return result;
  }
}
