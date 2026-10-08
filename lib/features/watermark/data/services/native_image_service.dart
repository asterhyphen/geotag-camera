import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NativeImageService {
  static const MethodChannel _mediaChannel = MethodChannel('media_store');

  const NativeImageService();

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
      final res = await _mediaChannel
          .invokeMethod<Map<dynamic, dynamic>>('processAndSaveImage', {
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
          });
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
}
