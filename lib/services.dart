import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'features/watermark/data/services/dart_image_service.dart';
import 'features/watermark/data/services/native_image_service.dart';

export 'features/watermark/data/services/dart_image_service.dart';
export 'features/watermark/data/services/date_time_formatter.dart';
export 'features/watermark/data/services/native_image_service.dart';
export 'features/location/data/services/location_service.dart';

const NativeImageService _nativeService = NativeImageService();

Future<Uint8List> addWatermark({
  required Uint8List imageBytes,
  required String location,
  required String address,
  required String latLng,
  required String dateTime,
}) {
  return DartImageService.addWatermark(
    imageBytes: imageBytes,
    location: location,
    address: address,
    latLng: latLng,
    dateTime: dateTime,
  );
}

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
}) {
  return _nativeService.processAndSaveImageNative(
    inputPath: inputPath,
    filter: filter,
    aspectRatio: aspectRatio,
    whiteFrame: whiteFrame,
    autoRotate: autoRotate,
    geocamOn: geocamOn,
    location: location,
    address: address,
    latLng: latLng,
    dateTime: dateTime,
  );
}

Future<void> saveToGallery(Uint8List bytes) {
  return _nativeService.saveToGallery(bytes);
}

img.Image cropToAspect(img.Image src, double ratio) {
  return DartImageService.cropToAspect(src, ratio);
}
