import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<Uint8List> addWatermark({
  required Uint8List imageBytes,
  required String location,
  required String address,
  required String latLng,
  required String dateTime,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  final uiImage = await decodeImageFromList(imageBytes);
  final w = uiImage.width.toDouble();
  final h = uiImage.height.toDouble();

  // Draw base photo
  canvas.drawImage(uiImage, Offset.zero, Paint());

  final overlayH = h * 0.20;
  final overlayTop = h - overlayH;

  // Modern gradient overlay strip
  final overlayPaint = Paint()
    ..shader = ui.Gradient.linear(
      Offset(0, overlayTop),
      Offset(0, h),
      [
        const Color(0x00000000),
        const Color(0xB316131D),
        const Color(0xF216131D),
      ],
      [0.0, 0.25, 1.0],
    );

  canvas.drawRect(
    Rect.fromLTWH(0, overlayTop, w, overlayH),
    overlayPaint,
  );

  // Subtle pastel accent line at the bottom
  final accentPaint = Paint()
    ..shader = ui.Gradient.linear(
      Offset(w * 0.08, h - 6),
      Offset(w * 0.92, h - 6),
      [
        const Color(0xFFFFB5C5),
        const Color(0xFFD6C7FF),
        const Color(0xFFBAE1FF),
      ],
    )
    ..strokeWidth = (h * 0.004).clamp(2.0, 6.0);

  canvas.drawLine(
    Offset(w * 0.08, h - (h * 0.012)),
    Offset(w * 0.92, h - (h * 0.012)),
    accentPaint,
  );

  final titleSize = h * 0.038;
  final bodySize = h * 0.026;
  final metaSize = h * 0.022;

  double y = overlayTop + (overlayH * 0.28);
  final left = w * 0.08;

  draw(
    canvas,
    location,
    titleSize,
    FontWeight.w700,
    left,
    y,
    w,
    color: const Color(0xFFFAF7FC),
  );
  y += titleSize * 1.25;

  draw(
    canvas,
    address,
    bodySize,
    FontWeight.w400,
    left,
    y,
    w,
    color: const Color(0xFFE8E3EE),
  );
  y += bodySize * 1.2;

  draw(
    canvas,
    latLng,
    metaSize,
    FontWeight.w400,
    left,
    y,
    w,
    color: const Color(0xFFD6C7FF),
  );
  y += metaSize * 1.15;

  draw(
    canvas,
    dateTime,
    metaSize,
    FontWeight.w400,
    left,
    y,
    w,
    color: const Color(0xFFB5EAD7),
  );

  final pic = recorder.endRecording();
  final imgOut = await pic.toImage(uiImage.width, uiImage.height);
  final bd = await imgOut.toByteData(format: ui.ImageByteFormat.png);
  return bd!.buffer.asUint8List();
}

void draw(
  Canvas canvas,
  String text,
  double size,
  FontWeight weight,
  double x,
  double y,
  double w, {
  Color color = Colors.white,
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: 0.2,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: w * 0.84);

  tp.paint(canvas, Offset(x, y));
}

//// HIGH-PERFORMANCE NATIVE SINGLE-PASS PIPELINE

const MethodChannel _mediaChannel = MethodChannel('media_store');

/// High-performance zero-copy native single-pass processing & saving
Future<bool> processAndSaveImageNative({
  required String inputPath,
  required String filter,
  required double aspectRatio,
  required bool whiteFrame,
  required bool autoRotate,
  required bool geocamOn,
  required String location,
  required String address,
  required String latLng,
  required String dateTime,
}) async {
  final name = 'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg';
  final stopwatch = Stopwatch()..start();

  try {
    final res = await _mediaChannel.invokeMethod<Map<dynamic, dynamic>>(
      'processAndSaveImage',
      {
        'inputPath': inputPath,
        'name': name,
        'filter': filter,
        'aspectRatio': aspectRatio,
        'whiteFrame': whiteFrame,
        'autoRotate': autoRotate,
        'geocamOn': geocamOn,
        'location': location,
        'address': address,
        'latLng': latLng,
        'dateTime': dateTime,
      },
    );
    stopwatch.stop();
    debugPrint(
      '[GeoCam Benchmark] Single-pass native process & save completed in ${stopwatch.elapsedMilliseconds}ms',
    );
    return res != null && res['success'] == true;
  } on PlatformException catch (e) {
    debugPrint(
      '[GeoCam Error] Native processing failed ($e), executing fallback',
    );
    return false;
  }
}

Future<void> saveToGallery(Uint8List bytes) async {
  await _mediaChannel.invokeMethod('saveImage', {
    'bytes': bytes,
    'name': 'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg',
  });
}

String formatDateTime() {
  final n = DateTime.now();
  final o = n.timeZoneOffset;
  final s = o.isNegative ? '-' : '+';
  return "${n.day.toString().padLeft(2, '0')}/"
      "${n.month.toString().padLeft(2, '0')}/"
      "${n.year} "
      "${n.hour.toString().padLeft(2, '0')}:"
      "${n.minute.toString().padLeft(2, '0')} "
      "GMT $s${o.inHours.abs()}:"
      "${(o.inMinutes.abs() % 60).toString().padLeft(2, '0')}";
}

img.Image cropToAspect(img.Image src, double ratio) {
  final w = src.width;
  final h = src.height;
  final current = w / h;

  if ((current - ratio).abs() < 0.01) return src;

  int cw, ch, x, y;

  if (current > ratio) {
    ch = h;
    cw = (h * ratio).round();
    x = ((w - cw) / 2).round();
    y = 0;
  } else {
    cw = w;
    ch = (w / ratio).round();
    x = 0;
    y = ((h - ch) / 2).round();
  }

  return img.copyCrop(src, x: x, y: y, width: cw, height: ch);
}
