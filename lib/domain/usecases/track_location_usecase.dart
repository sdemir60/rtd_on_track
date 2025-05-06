import 'package:dartz/dartz.dart';
import '../entities/location_entity.dart';
import '../repositories/location_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/location_utils.dart';
import '../../core/utils/logger_utils.dart';
import 'package:latlong2/latlong.dart';

class TrackLocationUseCase {
  final LocationRepository repository;
  LatLng? _lastSavedPosition;

  TrackLocationUseCase(this.repository);

  Future<Either<Failure, LocationEntity?>> call(LatLng currentPosition) async {
    try {
      if (_lastSavedPosition == null ||
          LocationUtils.isSignificantMovement(
              _lastSavedPosition!,
              currentPosition,
              AppConstants.locationDistanceThreshold.toDouble())) {

        final locationsResult = await repository.getLocations();
        bool isDuplicate = false;
        
        await locationsResult.fold(
          (failure) => isDuplicate = false, 
          (locations) {
            final now = DateTime.now();
            for (final loc in locations) {
              if (loc.position.latitude == currentPosition.latitude && 
                  loc.position.longitude == currentPosition.longitude) {
                final timeDiff = now.difference(loc.timestamp).inMinutes.abs();
                if (timeDiff < 5) {
                  isDuplicate = true;
                  break;
                }
              }
            }
          }
        );
        
        if (isDuplicate) {
          logger.info("Aynı konumda yakın zamanlı bir kayıt zaten var, yeni kayıt eklenmeyecek.");
          _lastSavedPosition = currentPosition;
          return const Right(null);
        }
        
        final addressResult = await repository.getAddressFromCoordinates(
            currentPosition.latitude, currentPosition.longitude);

        String? address;
        addressResult.fold(
            (failure) => address = null, (data) => address = data);

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
    } catch (e) {
      logger.error("Konum takibi hatası", e);
      return Left(ServiceFailure(message: e.toString()));
    }
  }
}
