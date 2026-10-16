import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/design_system.dart';

/// Animated TROPA wordmark: the emblem is the "O" in TR◉PA.
///
/// 2.6s sequence, played once on mount:
///   0.00–0.70s  emblem pops in with a bounce and spin
///   0.65–1.25s  "TR" and "PA" slide out from behind the emblem
///   1.30–1.90s  tagline fades up
///   1.90–2.60s  a soft light sweeps across the shield
///
/// With [loop], the finished logo holds for 0.6s, fades out over 0.2s and the
/// sequence replays (3.4s cycle).
///
/// Jumps straight to the final frame when the platform asks for reduced motion.
class TropaAnimatedLogo extends StatefulWidget {
  const TropaAnimatedLogo({
    super.key,
    this.emblemSize = 60,
    this.showTagline = true,
    this.loop = false,
  });

  final double emblemSize;
  final bool showTagline;
  final bool loop;

  @override
  State<TropaAnimatedLogo> createState() => _TropaAnimatedLogoState();
}

class _TropaAnimatedLogoState extends State<TropaAnimatedLogo>
    with SingleTickerProviderStateMixin {
  static const _logoAsset = 'assets/images/tropa_logo.png';
  static const _brandGreen = Color(0xFF3CB54A);

  static const _sequenceMs = 2600;
  static const _holdMs = 600;
  static const _fadeOutMs = 200;

  late final int _cycleMs =
      widget.loop ? _sequenceMs + _holdMs + _fadeOutMs : _sequenceMs;

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _cycleMs),
  );

  /// Interval on the cycle timeline, given in milliseconds.
  Interval _ms(int start, int end, {Curve curve = Curves.linear}) =>
      Interval(start / _cycleMs, end / _cycleMs, curve: curve);

  late final Animation<double> _emblemScale = TweenSequence<double>([
    TweenSequenceItem(
        tween: Tween(begin: 0.2, end: 1.12)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 60),
    TweenSequenceItem(
        tween: Tween(begin: 1.12, end: 0.95)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20),
    TweenSequenceItem(
        tween: Tween(begin: 0.95, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20),
  ]).animate(CurvedAnimation(parent: _ctrl, curve: _ms(0, 700)));

  late final Animation<double> _emblemTurns = TweenSequence<double>([
    TweenSequenceItem(
        tween: Tween(begin: -120.0, end: 10.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 60),
    TweenSequenceItem(
        tween: Tween(begin: 10.0, end: -3.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20),
    TweenSequenceItem(
        tween: Tween(begin: -3.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20),
  ]).animate(CurvedAnimation(parent: _ctrl, curve: _ms(0, 700)));

  late final Animation<double> _emblemFade =
      CurvedAnimation(parent: _ctrl, curve: _ms(0, 200, curve: Curves.easeOut));

  late final Animation<double> _letterSlide = CurvedAnimation(
      parent: _ctrl,
      curve: _ms(650, 1250, curve: const Cubic(0.16, 0.9, 0.24, 1)));

  late final Animation<double> _letterFade = CurvedAnimation(
      parent: _ctrl, curve: _ms(650, 860, curve: Curves.easeOut));

  late final Animation<double> _tagline = CurvedAnimation(
      parent: _ctrl, curve: _ms(1300, 1900, curve: Curves.easeOutCubic));

  late final Animation<double> _shine = CurvedAnimation(
      parent: _ctrl, curve: _ms(1900, 2600, curve: Curves.easeInOut));

  /// 1 → 0 at the end of each loop cycle; stays 1 when not looping.
  late final Animation<double> _outro = widget.loop
      ? Tween(begin: 1.0, end: 0.0).animate(CurvedAnimation(
          parent: _ctrl,
          curve: _ms(_sequenceMs + _holdMs, _cycleMs, curve: Curves.easeIn)))
      : const AlwaysStoppedAnimation(1.0);

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _ctrl.value = _sequenceMs / _cycleMs;
    } else if (widget.loop) {
      _ctrl.repeat();
    } else {
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emblem = widget.emblemSize;
    final wordColor = TropaColors.primaryOf(context);
    final letterStyle = GoogleFonts.manrope(
      fontSize: emblem * 0.86,
      fontWeight: FontWeight.w800,
      height: 1.0,
      letterSpacing: -emblem * 0.03,
      color: wordColor,
    );
    // Letters start tucked behind the emblem's centre.
    final slideDistance = emblem * 1.05;

    Widget letters(String text, double direction) => AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) => Opacity(
            opacity: _letterFade.value,
            child: Transform.translate(
              offset: Offset(
                  direction * slideDistance * (1 - _letterSlide.value), 0),
              child: child,
            ),
          ),
          child: Text(text, style: letterStyle),
        );

    final wordmark = Stack(
      alignment: Alignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            letters('TR', 1),
            SizedBox(width: emblem + emblem * 0.08),
            letters('PA', -1),
          ],
        ),
        // Painted last so the letters slide out from underneath it.
        AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) => Opacity(
            opacity: _emblemFade.value,
            child: Transform.rotate(
              angle: _emblemTurns.value * math.pi / 180,
              child: Transform.scale(scale: _emblemScale.value, child: child),
            ),
          ),
          child: SizedBox.square(
            dimension: emblem,
            child: AnimatedBuilder(
              animation: _shine,
              builder: (context, child) => ShaderMask(
                // srcATop: the light only lands on the emblem's own pixels.
                blendMode: BlendMode.srcATop,
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    Colors.white.withValues(
                        alpha: _shine.value > 0 && _shine.value < 1 ? 0.7 : 0),
                    Colors.white.withValues(alpha: 0),
                  ],
                  stops: const [0.38, 0.5, 0.62],
                  transform: _SlideGradient(-1.2 + 2.4 * _shine.value),
                ).createShader(bounds),
                child: child,
              ),
              child:
                  Image.asset(_logoAsset, filterQuality: FilterQuality.medium),
            ),
          ),
        ),
      ],
    );

    return Semantics(
      container: true,
      label: 'TROPA, Tabang Respeto Og Panalipud',
      child: ExcludeSemantics(
        child: FadeTransition(
          opacity: _outro,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              wordmark,
              if (widget.showTagline) ...[
                SizedBox(height: emblem * 0.28),
                AnimatedBuilder(
                  animation: _tagline,
                  builder: (context, child) => Opacity(
                    opacity: _tagline.value,
                    child: Transform.translate(
                        offset: Offset(0, 10 * (1 - _tagline.value)),
                        child: child),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 3,
                        decoration: BoxDecoration(
                            color: _brandGreen,
                            borderRadius: BorderRadius.circular(2)),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'TABANG RESPETO OG PANALIPUD',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.2,
                          color: TropaColors.textMedium(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.dx);

  final double dx;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * dx, bounds.height * dx, 0);
}
