import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/location_stamp.dart';
import '../../data/services/location_service.dart';

class LocationState {
  final LocationStamp? cachedLocationStamp;
  final LocationStamp? customLocation;
  final bool isPermissionGranted;
  final bool isLoading;

  const LocationState({
    this.cachedLocationStamp,
    this.customLocation,
    this.isPermissionGranted = false,
    this.isLoading = false,
  });

  LocationStamp get effectiveLocation =>
      customLocation ?? cachedLocationStamp ?? LocationStamp.empty;

  LocationState copyWith({
    LocationStamp? cachedLocationStamp,
    LocationStamp? customLocation,
    bool? isPermissionGranted,
    bool? isLoading,
    bool clearCustom = false,
  }) {
    return LocationState(
      cachedLocationStamp: cachedLocationStamp ?? this.cachedLocationStamp,
      customLocation: clearCustom ? null : (customLocation ?? this.customLocation),
      isPermissionGranted: isPermissionGranted ?? this.isPermissionGranted,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  final LocationService _locationService;
  StreamSubscription<LocationStamp>? _positionSub;

  LocationNotifier({
    LocationService locationService = const LocationService(),
  })  : _locationService = locationService,
        super(const LocationState()) {
    init();
  }

  Future<void> init() async {
    final granted = await _locationService.checkAndRequestPermission();
    if (!granted) {
      state = state.copyWith(isPermissionGranted: false);
      return;
    }

    state = state.copyWith(isPermissionGranted: true, isLoading: true);

    // 1. Warm up from last known immediately (0ms)
    final lastKnown = await _locationService.getLastKnownLocation();
    if (lastKnown != null) {
      state = state.copyWith(
        cachedLocationStamp: lastKnown,
        isLoading: false,
      );
    }

    // 2. Query current position asynchronously
    _locationService.getCurrentLocation().then((current) {
      if (current != null) {
        state = state.copyWith(
          cachedLocationStamp: current,
          isLoading: false,
        );
      }
    }).catchError((_) {});

    // 3. Keep updating from stream
    _positionSub?.cancel();
    _positionSub = _locationService.getPositionStream().listen((stamp) {
      state = state.copyWith(cachedLocationStamp: stamp);
    });
  }

  void setCustomLocation(LocationStamp? stamp) {
    if (stamp == null || stamp.isEmpty) {
      state = state.copyWith(clearCustom: true);
    } else {
      state = state.copyWith(customLocation: stamp);
    }
  }

  void clearCustomLocation() {
    state = state.copyWith(clearCustom: true);
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return const LocationService();
});

final locationProvider =
    StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  final service = ref.watch(locationServiceProvider);
  return LocationNotifier(locationService: service);
});
