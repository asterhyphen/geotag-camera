import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class DartImageService {
  const DartImageService();

  static Uint8List processImage(Map<String, dynamic> data) {
    final Uint8List bytes = data['bytes'];
    final String filter = data['filter'];
    final bool whiteFrame = data['whiteFrame'];
    final double aspectRatio = data['aspectRatio'];
    final bool autoRotate = data['autoRotate'] ?? true;

    img.Image image = img.decodeImage(bytes)!;

    if (autoRotate) {
      image = img.bakeOrientation(image);
    }

    image = cropToAspect(image, aspectRatio);

    // Apply filter
    if (filter == 'mono') {
      image = img.grayscale(image);
    } else if (filter == 'vintage') {
      image = img.adjustColor(
        image,
        brightness: 0.04,
        contrast: 1.08,
        saturation: 0.85,
      );

      image = img.colorOffset(image, red: 18, green: 8, blue: -6);

      image = img.sepia(image, amount: 0.35);
    } else if (filter == 'sepia') {
      image = img.sepia(image);
    }

    // Add white frame
    if (whiteFrame) {
      final frameWidth = (image.width * 0.05).toInt();
      final newWidth = image.width + frameWidth * 2;
      final newHeight = image.height + frameWidth * 2;
      final framed = img.Image(width: newWidth, height: newHeight);
      img.fill(framed, color: img.ColorRgb8(255, 255, 255));
      img.compositeImage(framed, image, dstX: frameWidth, dstY: frameWidth);
      image = framed;
    }

    return Uint8List.fromList(img.encodeJpg(image, quality: 95));
  }

  static Future<Uint8List> addWatermark({
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

    canvas.drawRect(Rect.fromLTWH(0, overlayTop, w, overlayH), overlayPaint);

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

    drawTextOnCanvas(
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

    drawTextOnCanvas(
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

    drawTextOnCanvas(
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

    drawTextOnCanvas(
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

  static void drawTextOnCanvas(
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

  static img.Image cropToAspect(img.Image src, double ratio) {
    final w = src.width;
    final h = src.height;
    final current = w / h;

    if ((current - ratio).abs() < 0.01) return src;

    int cw, ch, x, y;

    if (current > ratio) {
      ch = h;
      cw = (h * ratio).round().clamp(1, w);
      x = ((w - cw) / 2).round().clamp(0, w - cw);
      y = 0;
    } else {
      cw = w;
      ch = (w / ratio).round().clamp(1, h);
      x = 0;
      y = ((h - ch) / 2).round().clamp(0, h - ch);
    }

    return img.copyCrop(src, x: x, y: y, width: cw, height: ch);
  }
}
