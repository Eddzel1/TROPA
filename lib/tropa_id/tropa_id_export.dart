import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Wrap a card side in this so it can be saved as a print-ready PNG.
///
/// ```dart
/// final frontKey = GlobalKey();
/// TropaIdCapture(captureKey: frontKey, child: TropaIdCardFront(member: m));
/// final png = await captureTropaIdPng(frontKey, dpi: 300);
/// ```
class TropaIdCapture extends StatelessWidget {
  const TropaIdCapture({super.key, required this.captureKey, required this.child});

  final GlobalKey captureKey;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      RepaintBoundary(key: captureKey, child: child);
}

/// Renders the captured card at real CR80 size (3.375 x 2.125 in) for [dpi].
/// 300 dpi gives a 1013 x 638 px image; use 600 for sharper printing.
///
/// Make sure the photo and fonts have finished loading before calling
/// (for example call it after the card has been on screen for a frame,
/// or precache the photo with `precacheImage`).
Future<Uint8List> captureTropaIdPng(GlobalKey key, {double dpi = 300}) async {
  final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) {
    throw StateError('TropaIdCapture is not on screen yet.');
  }
  final ratio = (3.375 * dpi) / boundary.size.width;
  final image = await boundary.toImage(pixelRatio: ratio);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}
