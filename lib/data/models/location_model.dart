import 'package:isar/isar.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/entities/location_entity.dart';

part 'location_model.g.dart';

@collection
class LocationModel {
  Id id = Isar.autoIncrement;

  late double latitude;
  late double longitude;
  late DateTime timestamp;
  String? address;

  LocationModel({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.address,
  });

  factory LocationModel.fromEntity(LocationEntity entity) {
    return LocationModel(
      latitude: entity.position.latitude,
      longitude: entity.position.longitude,
      timestamp: entity.timestamp,
      address: entity.address,
    );
  }

  LocationEntity toEntity() {
    return LocationEntity(
      id: id,
      position: LatLng(latitude, longitude),
      timestamp: timestamp,
      address: address,
    );
  }
}
