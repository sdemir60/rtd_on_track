import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/location_model.dart';
import '../../../core/utils/logger_utils.dart';

abstract class LocationLocalDataSource {
  Future<List<LocationModel>> getLocations();

  Future<LocationModel> saveLocation(LocationModel location);

  Future<void> resetLocations();

  Future<void> initialize();
}

class LocationLocalDataSourceImpl implements LocationLocalDataSource {
  static LocationLocalDataSourceImpl? _instance;
  Isar? _isar;
  bool _isInitialized = false;

  factory LocationLocalDataSourceImpl() {
    _instance ??= LocationLocalDataSourceImpl._internal();
    return _instance!;
  }

  LocationLocalDataSourceImpl._internal();

  @override
  Future<void> initialize() async {
    try {
      if (!_isInitialized) {
        logger.info("Veritabanı başlatılıyor...");
        final dir = await getApplicationDocumentsDirectory();

        if (Isar.instanceNames.isNotEmpty) {
          _isar = Isar.getInstance();
          if (_isar != null) {
            _isInitialized = true;
            logger.info("Veritabanı zaten açık, mevcut örnek kullanılıyor.");
            return;
          }
        }

        _isar = await Isar.open(
          [LocationModelSchema],
          directory: dir.path,
        );

        _isInitialized = true;
        logger.info("Veritabanı başarıyla başlatıldı. Path: ${dir.path}");
      }
    } catch (e, stackTrace) {
      logger.error("Veritabanı başlatma hatası", e, stackTrace);
      if (Isar.instanceNames.isNotEmpty) {
        _isar = Isar.getInstance();
        if (_isar != null) {
          _isInitialized = true;
          logger.info("Hata sonrası mevcut veritabanı örneği kullanılıyor.");
        }
      }
    }
  }

  @override
  Future<List<LocationModel>> getLocations() async {
    try {
      logger.info("Konumlar veritabanından alınıyor...");
      if (!_isInitialized) await initialize();
      if (_isar == null) {
        logger.warning("Veritabanı başlatılmadı, boş liste döndürülüyor");
        return [];
      }

      final locations =
          await _isar!.locationModels.where().sortByTimestamp().findAll();
      logger.info("${locations.length} adet konum başarıyla alındı");
      return locations;
    } catch (e, stackTrace) {
      logger.error("Konumları alma hatası", e, stackTrace);
      return [];
    }
  }

  @override
  Future<LocationModel> saveLocation(LocationModel location) async {
    try {
      logger.info(
          "Konum kaydediliyor: Lat: ${location.latitude}, Lng: ${location.longitude}, Timestamp: ${location.timestamp}");
      if (!_isInitialized) await initialize();
      if (_isar == null) {
        logger.warning("Veritabanı başlatılmadı, konum kaydedilemedi");
        return location;
      }

      final existingLocations = await _isar!.locationModels
          .filter()
          .latitudeEqualTo(location.latitude)
          .longitudeEqualTo(location.longitude)
          .findAll();

      bool isDuplicate = false;
      for (var existing in existingLocations) {
        final timeDifference =
            location.timestamp.difference(existing.timestamp).inSeconds.abs();
        if (timeDifference < 5) {
          logger.info(
              "Aynı konumda ve yakın zamanda bir kayıt zaten var, yeni kayıt eklenmeyecek.");
          isDuplicate = true;
          return existing;
        }
      }

      if (!isDuplicate) {
        await _isar!.writeTxn(() async {
          location.id = await _isar!.locationModels.put(location);
        });
        logger.info("Konum başarıyla kaydedildi. ID: ${location.id}");
      }

      return location;
    } catch (e, stackTrace) {
      logger.error("Konum kaydetme hatası", e, stackTrace);
      return location;
    }
  }

  @override
  Future<void> resetLocations() async {
    try {
      logger.info("Konumlar sıfırlanıyor...");
      if (!_isInitialized) await initialize();
      if (_isar == null) {
        logger.warning("Veritabanı başlatılmadı, konumlar sıfırlanamadı");
        return;
      }

      await _isar!.writeTxn(() async {
        await _isar!.locationModels.clear();
      });

      logger.info("Tüm konumlar başarıyla sıfırlandı");
    } catch (e, stackTrace) {
      logger.error("Konumları sıfırlama hatası", e, stackTrace);
    }
  }
}
