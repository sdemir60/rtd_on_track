import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'location_state.dart';
import '../../../domain/usecases/get_locations_usecase.dart';
import '../../../domain/usecases/reset_locations_usecase.dart';
import '../../../domain/usecases/track_location_usecase.dart';
import '../../../domain/usecases/toggle_tracking_usecase.dart';
import '../../../core/services/location_service.dart';
import '../../../domain/entities/location_entity.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/utils/logger_utils.dart';
import '../../../core/utils/location_utils.dart';
import '../../../core/constants/app_constants.dart';

class LocationCubit extends Cubit<LocationState> {
  final GetLocationsUseCase _getLocationsUseCase;
  final ResetLocationsUseCase _resetLocationsUseCase;
  final TrackLocationUseCase _trackLocationUseCase;
  final ToggleTrackingUseCase _toggleTrackingUseCase;
  final LocationService _locationService;
  final PreferencesService _preferencesService = PreferencesService();

  StreamSubscription<LatLng>? _locationSubscription;

  LocationCubit({
    required GetLocationsUseCase getLocationsUseCase,
    required ResetLocationsUseCase resetLocationsUseCase,
    required TrackLocationUseCase trackLocationUseCase,
    required ToggleTrackingUseCase toggleTrackingUseCase,
    required LocationService locationService,
    TrackingStatus initialTrackingStatus = TrackingStatus.stopped,
  })  : _getLocationsUseCase = getLocationsUseCase,
        _resetLocationsUseCase = resetLocationsUseCase,
        _trackLocationUseCase = trackLocationUseCase,
        _toggleTrackingUseCase = toggleTrackingUseCase,
        _locationService = locationService,
        super(LocationState(trackingStatus: initialTrackingStatus)) {
    if (initialTrackingStatus == TrackingStatus.tracking) {
      _startLocationTracking();
    }
  }

  Future<void> loadLocations() async {
    emit(state.copyWith(status: LocationStatus.loading));

    final result = await _getLocationsUseCase();

    result.fold(
      (failure) => emit(state.copyWith(
        status: LocationStatus.failure,
        errorMessage: failure.message,
      )),
      (locations) {
        final uniqueLocations = <LocationEntity>[];
        final seen = <String>{};

        for (var location in locations) {
          final key =
              '${location.position.latitude},${location.position.longitude}';
          if (!seen.contains(key)) {
            seen.add(key);
            uniqueLocations.add(location);
          } else {
            logger.info('Duplike konum atlandı: $key');
          }
        }

        emit(state.copyWith(
          status: LocationStatus.success,
          locations: uniqueLocations,
          clearError: true,
        ));
      },
    );
  }

  Future<void> toggleTracking() async {
    final isCurrentlyTracking = state.trackingStatus == TrackingStatus.tracking;
    final newTrackingStatus =
        isCurrentlyTracking ? TrackingStatus.stopped : TrackingStatus.tracking;

    emit(state.copyWith(status: LocationStatus.loading));

    final result = await _toggleTrackingUseCase(!isCurrentlyTracking);

    result.fold(
      (failure) => emit(state.copyWith(
        status: LocationStatus.failure,
        errorMessage: failure.message,
      )),
      (isTracking) {
        if (isTracking) {
          _startLocationTracking();
        } else {
          _stopLocationTracking();
        }

        _preferencesService.saveTrackingStatus(isTracking);

        emit(state.copyWith(
          status: LocationStatus.success,
          trackingStatus: newTrackingStatus,
          clearError: true,
        ));
      },
    );
  }

  Future<void> resetLocations() async {
    emit(state.copyWith(status: LocationStatus.loading));

    final result = await _resetLocationsUseCase();

    result.fold(
      (failure) => emit(state.copyWith(
        status: LocationStatus.failure,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(
        status: LocationStatus.success,
        locations: const [],
        clearError: true,
      )),
    );
  }

  void selectLocation(LocationEntity location) {
    emit(state.copyWith(selectedLocation: location));
  }

  void clearSelectedLocation() {
    emit(state.copyWith(clearSelectedLocation: true));
  }

  void _startLocationTracking() {
    logger.info("Konum takibi başlatılıyor (LocationCubit)");
    _locationSubscription?.cancel();
    _locationSubscription =
        _locationService.getLocationStream().listen((position) async {
      emit(state.copyWith(currentPosition: position));

      final result = await _trackLocationUseCase(position);

      result.fold(
        (failure) => emit(state.copyWith(
          status: LocationStatus.failure,
          errorMessage: failure.message,
        )),
        (newLocation) {
          if (newLocation != null) {
            final currentLocations = List<LocationEntity>.from(state.locations);

            final isDuplicate = currentLocations.any((loc) =>
                LocationUtils.calculateDistance(
                    loc.position, newLocation.position) <
                AppConstants.locationDistanceThreshold);

            if (!isDuplicate) {
              currentLocations.add(newLocation);
              logger.info("Yeni konum eklendi: ${newLocation.position}");

              emit(state.copyWith(
                locations: currentLocations,
                clearError: true,
              ));
            } else {
              logger.info(
                  "Bu konum zaten ekli, tekrar eklenmedi: ${newLocation.position}");
            }
          }
        },
      );
    });
  }

  void _stopLocationTracking() {
    logger.info("Konum takibi durduruluyor (LocationCubit)");
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    return super.close();
  }
}
