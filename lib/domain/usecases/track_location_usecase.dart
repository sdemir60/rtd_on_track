import 'package:dartz/dartz.dart';
import '../entities/location_entity.dart';
import '../repositories/location_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/logger_utils.dart';
import 'package:latlong2/latlong.dart';

class TrackLocationUseCase {
  final LocationRepository repository;

  TrackLocationUseCase(this.repository);

  Future<Either<Failure, LocationEntity?>> call(LatLng currentPosition) async {
    try {
      logger.info("Yeni konum işleniyor: $currentPosition");

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

      return result;
    } catch (e) {
      logger.error("Konum takibi hatası", e);
      return Left(ServiceFailure(message: e.toString()));
    }
  }
}
