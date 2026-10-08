import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final availableCamerasProvider = Provider<List<CameraDescription>>((ref) {
  return [];
});
