import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/pastel_theme.dart';
import '../../data/services/location_service.dart';
import '../../domain/models/location_stamp.dart';

Future<LocationStamp?> showLocationPickerDialog(
  BuildContext context, {
  LocationStamp? currentCustomLocation,
  LocationStamp? cachedLocation,
}) async {
  final initialStamp = currentCustomLocation ?? cachedLocation;

  final locationController = TextEditingController(
    text: initialStamp?.location ?? '',
  );
  final addressController = TextEditingController(
    text: initialStamp?.address ?? '',
  );
  final latController = TextEditingController(
    text: LocationService.extractCoordinate(initialStamp?.latLng, 'Lat'),
  );
  final lngController = TextEditingController(
    text: LocationService.extractCoordinate(initialStamp?.latLng, 'Long'),
  );

  try {
    return await showDialog<LocationStamp?>(
      context: context,
      builder: (context) {
        String? statusText;
        bool isSuccess = false;
        bool isDetecting = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> autoDetectCoordinates() async {
              final query = [
                addressController.text.trim(),
                locationController.text.trim(),
              ].where((s) => s.isNotEmpty).join(', ');

              if (query.isEmpty) {
                setModalState(() {
                  statusText =
                      'Please enter a City or Address first to detect coordinates!';
                  isSuccess = false;
                });
                return;
              }

              setModalState(() {
                isDetecting = true;
                statusText = 'Finding coordinates for "$query"...';
                isSuccess = false;
              });

              try {
                final locations = await locationFromAddress(query);
                if (locations.isNotEmpty) {
                  final loc = locations.first;
                  latController.text = loc.latitude.toStringAsFixed(6);
                  lngController.text = loc.longitude.toStringAsFixed(6);
                  setModalState(() {
                    isDetecting = false;
                    statusText = 'Coordinates auto-detected successfully!';
                    isSuccess = true;
                  });
                  HapticFeedback.selectionClick();
                  return;
                }
              } catch (_) {}

              // Fallback: try using current GPS if query lookup failed
              try {
                final currentPos = cachedLocation != null
                    ? null
                    : await Geolocator.getLastKnownPosition();
                final lat = LocationService.extractCoordinate(
                  cachedLocation?.latLng,
                  'Lat',
                );
                final lng = LocationService.extractCoordinate(
                  cachedLocation?.latLng,
                  'Long',
                );

                if (lat.isNotEmpty && lng.isNotEmpty) {
                  latController.text = lat;
                  lngController.text = lng;
                  setModalState(() {
                    isDetecting = false;
                    statusText = 'Filled with your current GPS coordinates';
                    isSuccess = true;
                  });
                  return;
                } else if (currentPos != null) {
                  latController.text = currentPos.latitude.toStringAsFixed(6);
                  lngController.text = currentPos.longitude.toStringAsFixed(6);
                  setModalState(() {
                    isDetecting = false;
                    statusText = 'Filled with your current GPS coordinates';
                    isSuccess = true;
                  });
                  return;
                }
              } catch (_) {}

              setModalState(() {
                isDetecting = false;
                statusText =
                    'Could not find coordinates for this location. You can enter them manually.';
                isSuccess = false;
              });
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: PastelColors.surfaceDark,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: PastelColors.pink.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: PastelShadows.soft(
                    color: PastelColors.pink.withValues(alpha: 0.2),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Cute Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: PastelColors.pink.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.place_rounded,
                              color: PastelColors.pink,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Location Tag',
                            style: TextStyle(
                              color: PastelColors.textLight,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      _buildCuteTextField(
                        controller: locationController,
                        label: 'City & Region',
                        hint: 'Tokyo, Japan',
                        icon: Icons.location_city_rounded,
                      ),
                      const SizedBox(height: 12),

                      _buildCuteTextField(
                        controller: addressController,
                        label: 'Address / Landmark',
                        hint: 'Shibuya Crossing',
                        icon: Icons.map_rounded,
                      ),
                      const SizedBox(height: 12),

                      // Autodetect Coordinates Button Row
                      Row(
                        children: [
                          Expanded(
                            child: BouncyTap(
                              onTap: isDetecting ? null : autoDetectCoordinates,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: PastelColors.lavender.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: PastelColors.lavender.withValues(
                                      alpha: 0.35,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (isDetecting) ...[
                                      const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            PastelColors.lavender,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ] else ...[
                                      const Icon(
                                        Icons.auto_fix_high_rounded,
                                        size: 15,
                                        color: PastelColors.lavender,
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    const Text(
                                      'Auto-Detect Lat/Long',
                                      style: TextStyle(
                                        color: PastelColors.lavender,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildCuteTextField(
                              controller: latController,
                              label: 'Latitude',
                              hint: '35.6595',
                              isNumeric: true,
                              icon: Icons.explore_rounded,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildCuteTextField(
                              controller: lngController,
                              label: 'Longitude',
                              hint: '139.7004',
                              isNumeric: true,
                              icon: Icons.compass_calibration_rounded,
                            ),
                          ),
                        ],
                      ),

                      if (statusText != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          statusText!,
                          style: TextStyle(
                            color: isSuccess
                                ? PastelColors.mint
                                : PastelColors.pinkDeep,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () => Navigator.of(context).pop(
                              LocationStamp.empty,
                            ),
                            icon: const Icon(
                              Icons.gps_fixed_rounded,
                              size: 16,
                              color: PastelColors.mint,
                            ),
                            label: const Text(
                              'Use GPS',
                              style: TextStyle(
                                color: PastelColors.mint,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: PastelColors.textMuted,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              BouncyTap(
                                onTap: () async {
                                  var location =
                                      locationController.text.trim();
                                  var address = addressController.text.trim();
                                  var latStr = latController.text.trim();
                                  var lngStr = lngController.text.trim();

                                  // If empty, auto-fill from cached or current GPS
                                  if (location.isEmpty && address.isEmpty) {
                                    setModalState(() {
                                      statusText =
                                          'Please provide a location name or address!';
                                      isSuccess = false;
                                    });
                                    return;
                                  }

                                  double? latitude = double.tryParse(latStr);
                                  double? longitude = double.tryParse(lngStr);

                                  // If coordinates missing, attempt quick lookup or fallback to cached GPS
                                  if (latitude == null || longitude == null) {
                                    final query = [
                                      address,
                                      location,
                                    ].where((s) => s.isNotEmpty).join(', ');
                                    try {
                                      final locs =
                                          await locationFromAddress(query);
                                      if (locs.isNotEmpty) {
                                        latitude = locs.first.latitude;
                                        longitude = locs.first.longitude;
                                      }
                                    } catch (_) {}
                                  }

                                  // Fallback to cached device GPS if available
                                  if (latitude == null || longitude == null) {
                                    final latCached = double.tryParse(
                                      LocationService.extractCoordinate(
                                        cachedLocation?.latLng,
                                        'Lat',
                                      ),
                                    );
                                    final lngCached = double.tryParse(
                                      LocationService.extractCoordinate(
                                        cachedLocation?.latLng,
                                        'Long',
                                      ),
                                    );
                                    if (latCached != null &&
                                        lngCached != null) {
                                      latitude = latCached;
                                      longitude = lngCached;
                                    } else {
                                      latitude = 0.0;
                                      longitude = 0.0;
                                    }
                                  }

                                  final latLngStr = (latitude != 0.0 ||
                                          longitude != 0.0)
                                      ? "Lat ${latitude.toStringAsFixed(6)}, Long ${longitude.toStringAsFixed(6)}"
                                      : "";

                                  if (!context.mounted) return;

                                  Navigator.of(context).pop(
                                    LocationStamp(
                                      location: location.isNotEmpty
                                          ? location
                                          : address,
                                      address: address,
                                      latLng: latLngStr,
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: PastelColors.magicGradient,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: PastelColors.pink.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'Save Tag',
                                    style: TextStyle(
                                      color: PastelColors.textDark,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  } finally {
    locationController.dispose();
    addressController.dispose();
    latController.dispose();
    lngController.dispose();
  }
}

Widget _buildCuteTextField({
  required TextEditingController controller,
  required String label,
  required String hint,
  IconData? icon,
  bool isNumeric = false,
}) {
  return TextField(
    controller: controller,
    keyboardType: isNumeric
        ? const TextInputType.numberWithOptions(signed: true, decimal: true)
        : TextInputType.text,
    style: const TextStyle(color: PastelColors.textLight, fontSize: 13),
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null
          ? Icon(icon, color: PastelColors.lavender, size: 18)
          : null,
      filled: true,
      fillColor: PastelColors.cardDark.withValues(alpha: 0.8),
      hintStyle: const TextStyle(color: PastelColors.textMuted, fontSize: 12),
      labelStyle: const TextStyle(color: PastelColors.lavender, fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: PastelColors.lavender.withValues(alpha: 0.25),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: PastelColors.pink, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}
