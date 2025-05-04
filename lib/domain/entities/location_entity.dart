import 'package:latlong2/latlong.dart';

class LocationEntity {
  final int? id;
  final LatLng position;
  final DateTime timestamp;
  final String? address;

  const LocationEntity({
    this.id,
    required this.position,
    required this.timestamp,
    this.address,
  });
}
