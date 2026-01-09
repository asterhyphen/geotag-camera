import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image/image.dart' as img;

const MethodChannel _mediaChannel = MethodChannel('media_store');

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CameraPage(),
    );
  }
}

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final picker = ImagePicker();
  bool watermarkOn = true;

  Future<void> capture() async {
    final XFile? photo =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 100);
    if (photo == null) return;

    final originalBytes = await photo.readAsBytes();

    LocationPermission permission = await Geolocator.checkPermission(
);
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final placemarks =
        await placemarkFromCoordinates(pos.latitude, pos.longitude);
    final p = placemarks.first;

    final location =
        "${p.locality}, ${p.administrativeArea}, ${p.country}";
    final address =
        "${p.street}, ${p.subLocality}, ${p.postalCode}";
    final latLng =
        "Lat ${pos.latitude.toStringAsFixed(6)}°  Long ${pos.longitude.toStringAsFixed(6)}°";
    final dateTime = formatDateTime();

    final cleanBytes = await compute(processImage, originalBytes);

    Uint8List finalBytes = cleanBytes;
    if (watermarkOn) {
      await Future.delayed(const Duration(milliseconds: 16));
      finalBytes = await addWatermark(
        imageBytes: cleanBytes,
        location: location,
        address: address,
        latLng: latLng,
        dateTime: dateTime,
      );
    }

    final ts = DateTime.now().millisecondsSinceEpoch;
    await saveToGallery(cleanBytes, "IMG_$ts.jpg");
    await saveToGallery(finalBytes, "IMG_${ts}_geo.jpg");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: ElevatedButton(
          onPressed: capture,
          child: const Text("CAPTURE"),
        ),
      ),
    );
  }
}

//// ================= MEDIASTORE =================

Future<void> saveToGallery(Uint8List bytes, String name) async {
  await _mediaChannel.invokeMethod('saveImage', {
    'bytes': bytes,
    'name': name,
  });
}

//// ================= IMAGE PROCESS =================

Uint8List processImage(Uint8List bytes) {
  final img.Image base = img.decodeImage(bytes)!;
  return Uint8List.fromList(img.encodeJpg(base, quality: 100));
}

//// ================= WATERMARK (REFERENCE MATCH) =================

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

  // Bottom bar — reference proportion
  final overlayH = h * 0.23;
  final overlayTop = h - overlayH;

  canvas.drawRect(
    Rect.fromLTWH(0, overlayTop, w, overlayH),
    Paint()..color = const Color(0xE6000000),
  );

  // ---- MAP THUMBNAIL (LEFT) ----
  final mapSize = overlayH * 0.72;
  final mapLeft = 24.0;
  final mapTop = overlayTop + (overlayH - mapSize) / 2;

  final rrect = RRect.fromRectAndRadius(
    Rect.fromLTWH(mapLeft, mapTop, mapSize, mapSize),
    const Radius.circular(16),
  );

  // Fake Google map card
  canvas.drawRRect(
    rrect,
    Paint()..color = const Color(0xFF1E88E5),
  );

  // Pin
  canvas.drawCircle(
    Offset(mapLeft + mapSize / 2, mapTop + mapSize / 2),
    mapSize * 0.08,
    Paint()..color = Colors.redAccent,
  );

  // ---- TEXT BLOCK (RIGHT, OPTICALLY CENTERED) ----
  final textLeft = mapLeft + mapSize + 28;
  double y = overlayTop + overlayH * 0.18;

  final titleStyle = const TextStyle(
    color: Colors.white,
    fontSize: 36,
    fontWeight: FontWeight.w600,
  );

  final bodyStyle = const TextStyle(
    color: Colors.white70,
    fontSize: 28,
    height: 1.2,
  );

  final metaStyle = const TextStyle(
    color: Colors.white60,
    fontSize: 24,
  );

  _draw(canvas, location, titleStyle, textLeft, y, w - textLeft - 24);
  y += 48;

  _draw(canvas, address, bodyStyle, textLeft, y, w - textLeft - 24);
  y += 40;

  _draw(canvas, latLng, metaStyle, textLeft, y, w - textLeft - 24);
  y += 34;

  _draw(canvas, dateTime, metaStyle, textLeft, y, w - textLeft - 24);

  final picture = recorder.endRecording();
  final imgOut = await picture.toImage(uiImage.width, uiImage.height);
  final bd = await imgOut.toByteData(format: ui.ImageByteFormat.png);
  return bd!.buffer.asUint8List();
}

void _draw(
  Canvas canvas,
  String text,
  TextStyle style,
  double x,
  double y,
  double maxWidth,
) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: maxWidth);
  tp.paint(canvas, Offset(x, y));
}

//// ================= UTILS =================

String formatDateTime() {
  final n = DateTime.now();
  final o = n.timeZoneOffset;
  final s = o.isNegative ? "-" : "+";
  return "${n.day.toString().padLeft(2, '0')}/"
      "${n.month.toString().padLeft(2, '0')}/"
      "${n.year} "
      "${n.hour.toString().padLeft(2, '0')}:"
      "${n.minute.toString().padLeft(2, '0')} "
      "GMT $s${o.inHours.abs()}:"
      "${(o.inMinutes.abs() % 60).toString().padLeft(2, '0')}";
}
