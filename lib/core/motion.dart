import 'package:flutter/material.dart';

/// Motion tokens shared by the app. Entrances ease out, moves ease in and out, exits are 20%
/// shorter than their entrance, and nothing bounces.
class TropaMotion {
  static const fast = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 250);

  static const enter = Curves.easeOutCubic;
  static const exitCurve = Curves.easeInCubic;
  static const move = Curves.easeInOutCubic;

  /// Wait after the last keystroke before a search box runs its search.
  static const searchDebounce = Duration(milliseconds: 300);

  /// Exit duration for an entrance of [d].
  static Duration exit(Duration d) => d * 0.8;

  /// True when the OS asks for reduced motion.
  static bool reduced(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// `showDialog` with the app's popover motion: fades in while scaling up from 0.95, and leaves
/// faster than it came.
Future<T?> showTropaDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final reduced = TropaMotion.reduced(context);
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Theme.of(context).dialogTheme.barrierColor ?? Colors.black54,
    transitionDuration: reduced ? Duration.zero : TropaMotion.medium,
    pageBuilder: (context, _, __) => SafeArea(child: Builder(builder: builder)),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: TropaMotion.enter, reverseCurve: TropaMotion.exitCurve);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(scale: Tween(begin: 0.95, end: 1.0).animate(curved), child: child),
      );
    },
  );
}

/// Shrinks [child] to 0.97 while a pointer is down. Listens without claiming the gesture, so
/// the child's own InkWell or button still gets the tap.
class TropaPressable extends StatefulWidget {
  final Widget child;

  const TropaPressable({super.key, required this.child});

  @override
  State<TropaPressable> createState() => _TropaPressableState();
}

class _TropaPressableState extends State<TropaPressable> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down && !TropaMotion.reduced(context) ? 0.97 : 1,
        duration: const Duration(milliseconds: 100),
        curve: TropaMotion.enter,
        child: widget.child,
      ),
    );
  }
}

/// Fades [child] in and lifts it 8px on first build, [index] × 30ms after its siblings.
class TropaStaggerIn extends StatefulWidget {
  final int index;
  final Widget child;

  const TropaStaggerIn({super.key, required this.index, required this.child});

  @override
  State<TropaStaggerIn> createState() => _TropaStaggerInState();
}

class _TropaStaggerInState extends State<TropaStaggerIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: TropaMotion.medium);
  late final Animation<double> _curved = CurvedAnimation(parent: _controller, curve: TropaMotion.enter);

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (TropaMotion.reduced(context)) {
      _controller.value = 1;
    } else {
      Future.delayed(Duration(milliseconds: 30 * widget.index), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curved,
      child: AnimatedBuilder(
        animation: _curved,
        builder: (context, child) => Transform.translate(offset: Offset(0, 8 * (1 - _curved.value)), child: child),
        child: widget.child,
      ),
    );
  }
}

/// Pulses [child] once (1 → 1.06 → 1 over 300ms) each time [done] turns true, to confirm that
/// something finished.
class TropaSuccessPulse extends StatefulWidget {
  final bool done;
  final Widget child;

  const TropaSuccessPulse({super.key, required this.done, required this.child});

  @override
  State<TropaSuccessPulse> createState() => _TropaSuccessPulseState();
}

class _TropaSuccessPulseState extends State<TropaSuccessPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  late final Animation<double> _scale = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.06).chain(CurveTween(curve: TropaMotion.enter)), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 1.06, end: 1.0).chain(CurveTween(curve: TropaMotion.move)), weight: 60),
  ]).animate(_controller);

  @override
  void didUpdateWidget(TropaSuccessPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.done && !oldWidget.done && !TropaMotion.reduced(context)) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(scale: _scale, child: widget.child);
}
