import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/location_model.dart';
import '../../../core/utils/logger_util.dart';

abstract class LocationLocalDataSource {
  Future<List<LocationModel>> getLocations();

  Future<LocationModel> saveLocation(LocationModel location);

  Future<void> resetLocations();

  Future<void> initialize();
}

class LocationLocalDataSourceImpl implements LocationLocalDataSource {
  Isar? _isar;
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    try {
      if (!_isInitialized) {
        final dir = await getApplicationDocumentsDirectory();

        _isar = await Isar.open(
          [LocationModelSchema],
          directory: dir.path,
        );

        _isInitialized = true;
      }
    } catch (e, stackTrace) {
      logger.error("Veritabanı başlatma hatası", e, stackTrace);
      //TODO: Hata olsa da başlatmış saymak ne kadar doğru tekrar gözden geçir.
      _isInitialized = true;
    }
  }

  @override
  Future<List<LocationModel>> getLocations() async {
    try {
      if (!_isInitialized) await initialize();
      if (_isar == null) return [];

      return await _isar!.locationModels.where().sortByTimestamp().findAll();
    } catch (e) {
      logger.error("Konumları alma hatası", e);
      return [];
    }
  }

  @override
  Future<LocationModel> saveLocation(LocationModel location) async {
    try {
      if (!_isInitialized) await initialize();
      if (_isar == null) return location;

      await _isar!.writeTxn(() async {
        location.id = await _isar!.locationModels.put(location);
      });

      return location;
    } catch (e) {
      logger.error("Konum kaydetme hatası", e);
      return location;
    }
  }

  @override
  Future<void> resetLocations() async {
    try {
      if (!_isInitialized) await initialize();
      if (_isar == null) return;

      await _isar!.writeTxn(() async {
        await _isar!.locationModels.clear();
      });
    } catch (e) {
      logger.error("Konumları sıfırlama hatası", e);
    }
  }
}
