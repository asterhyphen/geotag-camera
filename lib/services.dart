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

  canvas.drawImage(uiImage, Offset.zero, Paint());

  final overlayH = h * 0.22;
  final overlayTop = h - overlayH;

  canvas.drawRect(
    Rect.fromLTWH(0, overlayTop, w, overlayH),
    Paint()..color = const Color(0xE6000000),
  );

  final titleSize = h * 0.045;
  final bodySize = h * 0.032;
  final metaSize = h * 0.028;

  double y = overlayTop + overlayH * 0.18;
  final left = w * 0.08;

  draw(canvas, location, titleSize, FontWeight.w600, left, y, w);
  y += titleSize * 1.2;
  draw(canvas, address, bodySize, FontWeight.normal, left, y, w);
  y += bodySize * 1.15;
  draw(canvas, latLng, metaSize, FontWeight.normal, left, y, w);
  y += metaSize * 1.1;
  draw(canvas, dateTime, metaSize, FontWeight.normal, left, y, w);

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
  double w,
) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(color: Colors.white, fontSize: size, fontWeight: weight),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: w * 0.84);

  tp.paint(canvas, Offset(x, y));
}

//// SAVE (FIXED)

const MethodChannel _mediaChannel = MethodChannel('media_store');

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
