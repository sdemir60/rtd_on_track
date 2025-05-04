import 'package:dartz/dartz.dart';
import '../repositories/location_repository.dart';
import '../../core/errors/failures.dart';

class ResetLocationsUseCase {
  final LocationRepository repository;

  ResetLocationsUseCase(this.repository);

  Future<Either<Failure, void>> call() async {
    return await repository.resetLocations();
  }
}
