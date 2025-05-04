import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import '../../../domain/entities/location_entity.dart';

enum LocationStatus { initial, loading, success, failure }

enum TrackingStatus { stopped, tracking }

class LocationState extends Equatable {
  final List<LocationEntity> locations;
  final LocationStatus status;
  final TrackingStatus trackingStatus;
  final String? errorMessage;
  final LocationEntity? selectedLocation;
  final LatLng? currentPosition;

  const LocationState({
    this.locations = const [],
    this.status = LocationStatus.initial,
    this.trackingStatus = TrackingStatus.stopped,
    this.errorMessage,
    this.selectedLocation,
    this.currentPosition,
  });

  LocationState copyWith({
    List<LocationEntity>? locations,
    LocationStatus? status,
    TrackingStatus? trackingStatus,
    String? errorMessage,
    LocationEntity? selectedLocation,
    LatLng? currentPosition,
    bool clearError = false,
    bool clearSelectedLocation = false,
  }) {
    return LocationState(
      locations: locations ?? this.locations,
      status: status ?? this.status,
      trackingStatus: trackingStatus ?? this.trackingStatus,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      selectedLocation: clearSelectedLocation
          ? null
          : selectedLocation ?? this.selectedLocation,
      currentPosition: currentPosition ?? this.currentPosition,
    );
  }

  @override
  List<Object?> get props => [
        locations,
        status,
        trackingStatus,
        errorMessage,
        selectedLocation,
        currentPosition
      ];
}
