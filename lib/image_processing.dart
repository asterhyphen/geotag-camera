import 'dart:typed_data';
import 'features/watermark/data/services/dart_image_service.dart';

Uint8List processImage(Map<String, dynamic> data) {
  return DartImageService.processImage(data);
}
