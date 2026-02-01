import 'dart:typed_data';
import 'services.dart';
import 'package:image/image.dart' as img;

Uint8List processImage(Map<String, dynamic> data) {
  final Uint8List bytes = data['bytes'];
  final String filter = data['filter'];
  final bool whiteFrame = data['whiteFrame'];
  final double aspectRatio = data['aspectRatio'];

  img.Image image = img.decodeImage(bytes)!;

  image = cropToAspect(image, aspectRatio);

  // Apply filter
  if (filter == 'mono') {
    image = img.grayscale(image);
  } else if (filter == 'vintage') {
    image = img.adjustColor(
      image,
      brightness: 0.1,
      contrast: 1.2,
      saturation: 0.7,
    );
    image = img.colorOffset(image, red: 15, green: 5, blue: -10);
    image = img.sepia(image);
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
