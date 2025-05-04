import 'package:dartz/dartz.dart';
import '../entities/location_entity.dart';
import '../../core/errors/failures.dart';

abstract class LocationRepository {
  Future<Either<Failure, List<LocationEntity>>> getLocations();

  Future<Either<Failure, LocationEntity>> saveLocation(LocationEntity location);

  Future<Either<Failure, void>> resetLocations();

  Future<Either<Failure, String?>> getAddressFromCoordinates(
      double latitude, double longitude);
}
