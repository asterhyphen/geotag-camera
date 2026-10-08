class LocationStamp {
  final String location;
  final String address;
  final String latLng;

  const LocationStamp({
    required this.location,
    required this.address,
    required this.latLng,
  });

  static const empty = LocationStamp(
    location: '',
    address: '',
    latLng: '',
  );

  bool get isEmpty => location.isEmpty && address.isEmpty && latLng.isEmpty;
  bool get isNotEmpty => !isEmpty;

  LocationStamp copyWith({
    String? location,
    String? address,
    String? latLng,
  }) {
    return LocationStamp(
      location: location ?? this.location,
      address: address ?? this.address,
      latLng: latLng ?? this.latLng,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationStamp &&
          runtimeType == other.runtimeType &&
          location == other.location &&
          address == other.address &&
          latLng == other.latLng;

  @override
  int get hashCode => location.hashCode ^ address.hashCode ^ latLng.hashCode;
}
