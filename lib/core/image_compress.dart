import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;

/// Shrinks a photo so its longer side is at most [maxSide] px (never enlarging it) and re-encodes
/// it as a JPEG. Transparent areas become white. A phone photo of several MB comes out around
/// 60-150 KB, which is plenty for the member list and the printed ID card.
Future<Uint8List> compressPhoto(Uint8List raw, {int maxSide = 800, int quality = 80}) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(raw);
  final descriptor = await ui.ImageDescriptor.encoded(buffer);
  final scale = math.min(1.0, maxSide / math.max(descriptor.width, descriptor.height));
  final w = math.max(1, (descriptor.width * scale).round());
  final h = math.max(1, (descriptor.height * scale).round());
  // Decoding at the target size is done by the engine, so large photos stay fast.
  final codec = await descriptor.instantiateCodec(targetWidth: w, targetHeight: h);
  final frame = await codec.getNextFrame();

  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder)
    ..drawColor(const ui.Color(0xFFFFFFFF), ui.BlendMode.src)
    ..drawImage(frame.image, ui.Offset.zero, ui.Paint());
  final flat = await recorder.endRecording().toImage(w, h);
  final rgba = await flat.toByteData(format: ui.ImageByteFormat.rawRgba);

  frame.image.dispose();
  flat.dispose();
  codec.dispose();
  descriptor.dispose();
  buffer.dispose();

  final image = img.Image.fromBytes(width: w, height: h, bytes: rgba!.buffer, numChannels: 4);
  return img.encodeJpg(image, quality: quality);
}
