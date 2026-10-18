import 'dart:math' as math;

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'tropa_member.dart';

/// TROPA brand colours used on the card.
class TropaIdColors {
  static const blue = Color(0xFF004EB0);
  static const green = Color(0xFF39B54A);
  static const ink = Color(0xFF0B1B33);
  static const label = Color(0xFF5A6780);
  static const body = Color(0xFF3E4A60);
  static const bodyDark = Color(0xFF23314A);
  static const panel = Color(0xFFEEF3FB);
  static const panelBorder = Color(0xFFD7E2F4);
  static const divider = Color(0xFFDCE4F0);
  static const chipGreenBg = Color(0xFFE1F4E4);
  static const chipGreenFg = Color(0xFF1E6B2A);
  static const paleBlue = Color(0xFFC8D8F3);
  static const photoBg = Color(0xFFE8EEF8);
}

class TropaIdAssets {
  static const logo = 'assets/tropa_id/tropa_logo.png';
  static const emblem = 'assets/tropa_id/tropa_emblem.png';
}

// The card is laid out on a fixed 856 x 540 canvas (CR80 / bank-card ratio)
// and scaled to whatever size it is given, so it looks identical everywhere.
const double _kW = 856;
const double _kH = 540;
const double kTropaIdAspectRatio = _kW / _kH;

const _tagline = 'TROPA TA! DI MOBIYA, DI MAPASAGDAN';

// ---------------------------------------------------------------------------
// FRONT
// ---------------------------------------------------------------------------

class TropaIdCardFront extends StatelessWidget {
  const TropaIdCardFront({super.key, required this.member});

  final TropaMember member;

  @override
  Widget build(BuildContext context) {
    final m = member;
    return _CardFrame(
      semanticLabel: 'TROPA member ID front. ${m.fullName}, ${m.idNumber}',
      children: [
        const Positioned.fill(
          child: CustomPaint(
            painter: _SecurityPatternPainter(
              ringCenter: Offset(0.88, 0.22),
              lineAngleDeg: 115,
            ),
          ),
        ),
        const Positioned(
          left: 0, right: 0, bottom: 0, height: 6,
          child: ColoredBox(color: TropaIdColors.green),
        ),
        const Positioned.fill(
          child: CustomPaint(
            painter: _PanelPainter(
              // Blue runs ~1 unit under the green stripe so no white seam shows between them.
              blue: [Offset(0, 0), Offset(331, 0), Offset(288.2, 540), Offset(0, 540)],
              green: [Offset(330.1, 0), Offset(346, 0), Offset(302.75, 540), Offset(287.2, 540)],
              patternAngleDeg: 135,
            ),
          ),
        ),

        // Left panel: label, photo, member type
        Positioned(
          left: 40, top: 38,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MEMBER ID', style: _poppins(12, FontWeight.w700, Colors.white, ls: .18)),
              Text('SINCE ${m.sinceYear}',
                  style: _poppins(10, FontWeight.w500, TropaIdColors.paleBlue, ls: .12)),
            ],
          ),
        ),
        Positioned(
          left: 40, top: 100, width: 204, height: 256,
          child: Container(
            decoration: BoxDecoration(
              color: TropaIdColors.photoBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 6),
              boxShadow: const [
                BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, 10)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: m.photo == null
                  ? const _PhotoPlaceholder()
                  : Image(
                      image: m.photo!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      semanticLabel: 'Cardholder photo',
                      errorBuilder: (_, __, ___) => const _PhotoPlaceholder(),
                    ),
            ),
          ),
        ),
        Positioned(
          left: 40, top: 372, width: 204,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                m.memberType.toUpperCase(),
                maxLines: 1,
                style: _poppins(12, FontWeight.w700, TropaIdColors.blue, ls: .12),
              ),
            ),
          ),
        ),
        Positioned(
          left: 40, top: 414, width: 204,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _bar(TropaIdColors.green),
              const SizedBox(width: 6),
              _bar(Colors.white.withValues(alpha: .5)),
              const SizedBox(width: 6),
              _bar(Colors.white.withValues(alpha: .5)),
            ],
          ),
        ),

        // Right side: logo + ghost photo
        Positioned(
          left: 380, top: 28, width: 230, height: 87,
          child: Image.asset(TropaIdAssets.logo, fit: BoxFit.contain, semanticLabel: 'TROPA'),
        ),
        if (m.photo != null)
        Positioned(
          right: 40, top: 24, width: 76, height: 94,
          child: ExcludeSemantics(
            child: Opacity(
              opacity: .32,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ColorFiltered(
                  colorFilter: const ColorFilter.matrix(_grayscale),
                  child: Image(
                    image: m.photo!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Name
        Positioned(
          left: 380, top: 130, width: 436,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('CARDHOLDER', ls: .14),
              const SizedBox(height: 2),
              _fitLeft(Text(m.nameLine1, style: _nameStyle)),
              _fitLeft(Text(m.nameLine2, style: _nameStyle)),
            ],
          ),
        ),

        // ID number box
        Positioned(
          left: 380, top: 222, width: 436,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: TropaIdColors.panel,
              border: Border.all(color: TropaIdColors.panelBorder),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 6, height: 34,
                  decoration: BoxDecoration(
                    color: TropaIdColors.green,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('ID NUMBER', ls: .14),
                      Text(m.idNumber,
                          style: _mono(22, FontWeight.w700, TropaIdColors.blue, ls: .05)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: TropaIdColors.chipGreenBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(m.status.toUpperCase(),
                      style: _poppins(10, FontWeight.w600, TropaIdColors.chipGreenFg, ls: .12)),
                ),
              ],
            ),
          ),
        ),

        // Details
        Positioned(
          left: 380, top: 296, width: 436,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Field(label: 'ADDRESS', value: m.address.toUpperCase(), fit: true),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _Field(label: 'BIRTH DATE', value: m.birthDate == null ? '—' : formatIdDate(m.birthDate!))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Divided(
                      child: _Field(label: 'DATE ISSUED', value: formatIdDate(m.dateIssued)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Divided(
                      child: _Field(label: 'VALID UNTIL', value: formatIdDate(m.validUntil)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Signature + barcode
        Positioned(
          left: 380, top: 384, width: 436,
          child: Column(
            children: [
              Container(
                height: 44,
                alignment: Alignment.bottomCenter,
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: TropaIdColors.ink, width: 1.5)),
                ),
                // Left blank for the cardholder to sign the printed card, unless a captured
                // signature image is supplied.
                child: m.signature != null
                    ? Image(image: m.signature!, height: 44, fit: BoxFit.contain)
                    : null,
              ),
              const SizedBox(height: 6),
              _label('CARDHOLDER SIGNATURE'),
              const SizedBox(height: 12),
              BarcodeWidget(
                barcode: Barcode.code128(),
                data: m.idNumber,
                width: 240,
                height: 30,
                drawText: false,
                color: TropaIdColors.ink,
              ),
            ],
          ),
        ),

        const Positioned(
          left: 300, right: 0, bottom: 12, height: 12,
          child: _MicroText(leftPadding: 80),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// BACK
// ---------------------------------------------------------------------------

class TropaIdCardBack extends StatelessWidget {
  const TropaIdCardBack({
    super.key,
    required this.member,
    this.issuer = const TropaIssuer(),
  });

  final TropaMember member;
  final TropaIssuer issuer;

  @override
  Widget build(BuildContext context) {
    final m = member;
    final notes = [
      'Present this card at TROPA offices and partner counters',
      'Scan the QR code with the TROPA app to verify',
      'Report a lost or damaged card at ${issuer.hotline}',
    ];

    return _CardFrame(
      semanticLabel: 'TROPA member ID back. ${m.idNumber}',
      children: [
        const Positioned.fill(
          child: CustomPaint(
            painter: _SecurityPatternPainter(
              ringCenter: Offset(0.10, 0.85),
              lineAngleDeg: 65,
            ),
          ),
        ),
        const Positioned(
          left: 0, right: 0, bottom: 0, height: 6,
          child: ColoredBox(color: TropaIdColors.green),
        ),
        const Positioned.fill(
          child: CustomPaint(
            painter: _PanelPainter(
              // Blue runs ~1 unit under the green stripe so no white seam shows between them.
              blue: [Offset(567.8, 0), Offset(856, 0), Offset(856, 540), Offset(524.9, 540)],
              green: [Offset(553.25, 0), Offset(568.8, 0), Offset(525.9, 540), Offset(510, 540)],
              patternAngleDeg: 45,
            ),
          ),
        ),

        // Header
        Positioned(
          left: 40, top: 34, width: 450,
          child: Row(
            children: [
              Image.asset(TropaIdAssets.emblem, width: 40, height: 40, excludeFromSemantics: true),
              const SizedBox(width: 10),
              Text('TROPA MEMBER ID',
                  style: _poppins(13, FontWeight.w700, TropaIdColors.blue, ls: .18)),
              const Spacer(),
              Text(m.idNumber, style: _mono(13, FontWeight.w700, TropaIdColors.blue, ls: .05)),
            ],
          ),
        ),

        // Info strip
        Positioned(
          left: 40, top: 90, width: 450,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: TropaIdColors.panel,
              border: Border.all(color: TropaIdColors.panelBorder),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _Field(
                    label: 'MEMBER TYPE',
                    value: m.memberType.toUpperCase(),
                    valueSize: 13,
                    valueWeight: FontWeight.w700,
                    fit: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Divided(
                    color: TropaIdColors.panelBorder,
                    child: _Field(
                      label: 'DATE ISSUED',
                      value: formatIdDate(m.dateIssued),
                      valueSize: 13,
                      valueWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Divided(
                    color: TropaIdColors.panelBorder,
                    child: _Field(
                      label: 'VALID UNTIL',
                      value: formatIdDate(m.validUntil),
                      valueSize: 13,
                      valueWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Using this card
        Positioned(
          left: 40, top: 172, width: 450,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('USING THIS CARD', ls: .14),
              for (final note in notes) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 22, height: 22,
                      decoration: const BoxDecoration(
                        color: TropaIdColors.chipGreenBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, size: 15, color: TropaIdColors.chipGreenFg),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(note,
                          style: _poppins(13, FontWeight.w500, TropaIdColors.bodyDark)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Authorized signature
        Positioned(
          left: 40, top: 300, width: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 44,
                width: double.infinity,
                alignment: Alignment.bottomCenter,
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: TropaIdColors.ink, width: 1.5)),
                ),
                child: issuer.authorizedSignature != null
                    ? Image(image: issuer.authorizedSignature!, height: 44, fit: BoxFit.contain)
                    : null,
              ),
              const SizedBox(height: 4),
              _label('AUTHORIZED SIGNATURE'),
            ],
          ),
        ),

        // Return notice
        Positioned(
          left: 40, top: 392, width: 450,
          child: Text(
            'This card is non-transferable and remains the property of '
            '${issuer.issuingOffice}. If found, please return to '
            '${issuer.officeAddress} or call ${issuer.hotline}.',
            style: _poppins(11, FontWeight.w400, TropaIdColors.body, height: 1.55),
          ),
        ),

        // QR panel
        Positioned(
          left: 600, top: 0, width: 220, height: 540,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('VERIFY ID', style: _poppins(11, FontWeight.w700, Colors.white, ls: .18)),
              const SizedBox(height: 14),
              Container(
                width: 200, height: 200,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, 10)),
                  ],
                ),
                child: QrImageView(
                  data: m.qrPayload,
                  padding: EdgeInsets.zero,
                  errorCorrectionLevel: QrErrorCorrectLevel.Q,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: TropaIdColors.ink),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: TropaIdColors.ink,
                  ),
                  semanticsLabel: 'Verification QR code',
                ),
              ),
              const SizedBox(height: 10),
              Text(m.idNumber, style: _mono(15, FontWeight.w700, Colors.white, ls: .05)),
              const SizedBox(height: 10),
              Text('Scan with the TROPA app',
                  style: _poppins(12, FontWeight.w400, TropaIdColors.paleBlue)),
            ],
          ),
        ),

        const Positioned(
          left: 0, width: 540, bottom: 12, height: 12,
          child: _MicroText(leftPadding: 40),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// FLIP CARD (for the in-app digital ID)
// ---------------------------------------------------------------------------

/// Shows the front; tap to flip to the back and again to flip back.
class TropaIdFlipCard extends StatefulWidget {
  const TropaIdFlipCard({
    super.key,
    required this.member,
    this.issuer = const TropaIssuer(),
  });

  final TropaMember member;
  final TropaIssuer issuer;

  @override
  State<TropaIdFlipCard> createState() => _TropaIdFlipCardState();
}

class _TropaIdFlipCardState extends State<TropaIdFlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  bool _showBack = false;

  void _flip() {
    _showBack = !_showBack;
    _showBack ? _c.forward() : _c.reverse();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final front = TropaIdCardFront(member: widget.member);
    final back = TropaIdCardBack(member: widget.member, issuer: widget.issuer);

    return Semantics(
      button: true,
      label: 'Flip ID card',
      child: GestureDetector(
        onTap: _flip,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final angle = Curves.easeInOut.transform(_c.value) * math.pi;
            final showFront = angle < math.pi / 2;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateY(angle),
              child: showFront
                  ? front
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(math.pi),
                      child: back,
                    ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared building blocks
// ---------------------------------------------------------------------------

class _CardFrame extends StatelessWidget {
  const _CardFrame({required this.children, required this.semanticLabel});

  final List<Widget> children;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: semanticLabel,
      child: AspectRatio(
        aspectRatio: kTropaIdAspectRatio,
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: _kW,
            height: _kH,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: ColoredBox(
                color: Colors.white,
                child: Stack(clipBehavior: Clip.hardEdge, children: children),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    this.valueSize = 14,
    this.valueWeight = FontWeight.w600,
    this.fit = false,
  });

  final String label;
  final String value;
  final double valueSize;
  final FontWeight valueWeight;

  /// Shrink long values to fit on one line instead of wrapping.
  final bool fit;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      value,
      maxLines: 1,
      softWrap: false,
      style: _poppins(valueSize, valueWeight, TropaIdColors.ink),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 2),
        fit ? _fitLeft(text) : text,
      ],
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: TropaIdColors.photoBg,
        child: Center(child: Icon(Icons.person_rounded, size: 120, color: TropaIdColors.paleBlue)),
      );
}

class _Divided extends StatelessWidget {
  const _Divided({required this.child, this.color = TropaIdColors.divider});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(border: Border(left: BorderSide(color: color))),
      child: child,
    );
  }
}

class _MicroText extends StatelessWidget {
  const _MicroText({required this.leftPadding});

  final double leftPadding;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ClipRect(
        child: Padding(
          padding: EdgeInsets.only(left: leftPadding),
          child: Text(
            List.filled(6, _tagline).join(' · '),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.clip,
            style: _poppins(7.5, FontWeight.w600, TropaIdColors.blue.withValues(alpha: .5),
                ls: .14, height: 1.6),
          ),
        ),
      ),
    );
  }
}

/// Fine concentric rings + diagonal hairlines (security background).
class _SecurityPatternPainter extends CustomPainter {
  const _SecurityPatternPainter({required this.ringCenter, required this.lineAngleDeg});

  /// Ring centre as a fraction of the card size.
  final Offset ringCenter;
  final double lineAngleDeg;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(ringCenter.dx * size.width, ringCenter.dy * size.height);
    final maxR = size.longestSide * 1.2;
    final rings = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = TropaIdColors.blue.withValues(alpha: .07);
    for (double r = 7; r < maxR; r += 7) {
      canvas.drawCircle(c, r, rings);
    }

    final lines = Paint()
      ..strokeWidth = 1
      ..color = TropaIdColors.green.withValues(alpha: .05);
    _drawParallelLines(canvas, size, lineAngleDeg, 12, lines);
  }

  @override
  bool shouldRepaint(covariant _SecurityPatternPainter old) =>
      old.ringCenter != ringCenter || old.lineAngleDeg != lineAngleDeg;
}

/// Slanted blue panel with a fine diagonal texture and a green edge stripe.
class _PanelPainter extends CustomPainter {
  const _PanelPainter({
    required this.blue,
    required this.green,
    required this.patternAngleDeg,
  });

  final List<Offset> blue;
  final List<Offset> green;
  final double patternAngleDeg;

  @override
  void paint(Canvas canvas, Size size) {
    final bluePath = Path()..addPolygon(blue, true);
    canvas.drawPath(bluePath, Paint()..color = TropaIdColors.blue);

    canvas.save();
    canvas.clipPath(bluePath);
    _drawParallelLines(
      canvas,
      size,
      patternAngleDeg,
      11,
      Paint()
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: .06),
    );
    canvas.restore();

    canvas.drawPath(Path()..addPolygon(green, true), Paint()..color = TropaIdColors.green);
  }

  @override
  bool shouldRepaint(covariant _PanelPainter old) => false;
}

void _drawParallelLines(Canvas canvas, Size size, double angleDeg, double gap, Paint paint) {
  final d = math.sqrt(size.width * size.width + size.height * size.height);
  canvas.save();
  canvas.translate(size.width / 2, size.height / 2);
  canvas.rotate(angleDeg * math.pi / 180);
  for (double y = -d; y < d; y += gap) {
    canvas.drawLine(Offset(-d, y), Offset(d, y), paint);
  }
  canvas.restore();
}

Widget _bar(Color color) => Container(
      width: 22,
      height: 4,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
    );

Widget _label(String text, {double ls = .12}) =>
    Text(text, style: _poppins(10, FontWeight.w600, TropaIdColors.label, ls: ls));

Widget _fitLeft(Widget child) => FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: child,
    );

final _nameStyle = _poppins(31, FontWeight.w800, TropaIdColors.ink, height: 1.05);

/// [ls] is letter-spacing in em (like CSS), converted to logical px.
TextStyle _poppins(double size, FontWeight weight, Color color,
        {double ls = 0, double? height}) =>
    GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: ls * size,
      height: height,
    );

TextStyle _mono(double size, FontWeight weight, Color color, {double ls = 0}) =>
    GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: ls * size,
    );

const List<double> _grayscale = [
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
];
