import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/models/location_stamp.dart';

class LocationService {
  const LocationService();

  Future<bool> checkAndRequestPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever;
    } catch (e) {
      debugPrint('[GeoCam Location Service Permission Error] $e');
      return false;
    }
  }

  Future<LocationStamp?> getLastKnownLocation() async {
    try {
      final pos = await Geolocator.getLastKnownPosition();
      if (pos != null) {
        return await locationStampFromPosition(pos);
      }
    } catch (e) {
      debugPrint('[GeoCam Location Service Last Known Error] $e');
    }
    return null;
  }

  Future<LocationStamp?> getCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      return await locationStampFromPosition(pos);
    } catch (e) {
      debugPrint('[GeoCam Location Service Current Pos Error] $e');
    }
    return null;
  }

  Stream<LocationStamp> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 25,
      ),
    ).asyncMap(locationStampFromPosition);
  }

  Future<LocationStamp> locationStampFromPosition(Position pos) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      final p = placemarks.isNotEmpty ? placemarks.first : null;

      final city = p?.locality ?? p?.subAdministrativeArea ?? '';
      final region = p?.administrativeArea ?? '';
      final country = p?.country ?? '';

      final locationParts = [
        city,
        region,
        country,
      ].where((s) => s.isNotEmpty).toList();
      final locationStr = locationParts.isNotEmpty
          ? locationParts.join(', ')
          : "Lat ${pos.latitude.toStringAsFixed(4)}, Long ${pos.longitude.toStringAsFixed(4)}";

      final street = p?.street ?? '';
      final subLocality = p?.subLocality ?? '';
      final addressParts = [
        street,
        subLocality,
      ].where((s) => s.isNotEmpty).toList();
      final addressStr = addressParts.join(', ');

      return LocationStamp(
        location: locationStr,
        address: addressStr,
        latLng:
            "Lat ${pos.latitude.toStringAsFixed(6)}, "
            "Long ${pos.longitude.toStringAsFixed(6)}",
      );
    } catch (_) {
      return LocationStamp(
        location:
            "Lat ${pos.latitude.toStringAsFixed(4)}, Long ${pos.longitude.toStringAsFixed(4)}",
        address: "",
        latLng:
            "Lat ${pos.latitude.toStringAsFixed(6)}, "
            "Long ${pos.longitude.toStringAsFixed(6)}",
      );
    }
  }

  static String extractCoordinate(String? latLng, String prefix) {
    if (latLng == null || latLng.isEmpty) return '';
    final parts = latLng.split(', ');
    for (final part in parts) {
      if (part.startsWith('$prefix ')) {
        return part.substring(prefix.length + 1);
      }
    }
    return '';
  }
}
