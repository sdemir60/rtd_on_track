import 'package:dartz/dartz.dart';
import '../entities/location_entity.dart';
import '../repositories/location_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/location_utils.dart';
import 'package:latlong2/latlong.dart';

class TrackLocationUseCase {
  final LocationRepository repository;
  LatLng? _lastSavedPosition;

  TrackLocationUseCase(this.repository);

  Future<Either<Failure, LocationEntity?>> call(LatLng currentPosition) async {
    if (_lastSavedPosition == null ||
        LocationUtils.isSignificantMovement(
            _lastSavedPosition!,
            currentPosition,
            AppConstants.locationDistanceThreshold.toDouble())) {
      final addressResult = await repository.getAddressFromCoordinates(
          currentPosition.latitude, currentPosition.longitude);

      String? address;
      addressResult.fold((failure) => address = null, (data) => address = data);

      final location = LocationEntity(
        position: currentPosition,
        timestamp: DateTime.now(),
        address: address,
      );

      final result = await repository.saveLocation(location);

      return result.fold((failure) => Left(failure), (savedLocation) {
        _lastSavedPosition = currentPosition;
        return Right(savedLocation);
      });
    }

    return const Right(null);
  }
}
