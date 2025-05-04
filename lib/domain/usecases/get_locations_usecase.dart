import 'package:dartz/dartz.dart';
import '../entities/location_entity.dart';
import '../repositories/location_repository.dart';
import '../../core/errors/failures.dart';

class GetLocationsUseCase {
  final LocationRepository repository;

  GetLocationsUseCase(this.repository);

  Future<Either<Failure, List<LocationEntity>>> call() async {
    return await repository.getLocations();
  }
}
