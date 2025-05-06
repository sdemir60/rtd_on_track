import 'package:dartz/dartz.dart';
import '../../domain/entities/location_entity.dart';
import '../../domain/repositories/location_repository.dart';
import '../../core/errors/failures.dart';
import '../datasources/local/location_local_datasource.dart';
import '../models/location_model.dart';
import '../../core/services/geocoding_service.dart';
import '../../core/utils/logger_utils.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationLocalDataSource localDataSource;
  final GeocodingService geocodingService;

  LocationRepositoryImpl({
    required this.localDataSource,
    required this.geocodingService,
  });

  @override
  Future<Either<Failure, List<LocationEntity>>> getLocations() async {
    try {
      final locationModels = await localDataSource.getLocations();
      final locations =
          locationModels.map((model) => model.toEntity()).toList();
      return Right(locations);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, LocationEntity>> saveLocation(
      LocationEntity location) async {
    try {
      final locationModel = LocationModel.fromEntity(location);
      final savedModel = await localDataSource.saveLocation(locationModel);
      return Right(savedModel.toEntity());
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetLocations() async {
    try {
      await localDataSource.resetLocations();
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String?>> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      final address =
          await geocodingService.getAddressFromCoordinates(latitude, longitude);
      return Right(address);
    } catch (e) {
      logger.error("Repository: Adres bilgisi alınamadı", e);
      return Right("Konum bilgisi alınamadı");
    }
  }
}
