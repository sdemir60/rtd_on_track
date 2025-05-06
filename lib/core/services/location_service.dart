import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../utils/location_utils.dart';
import '../utils/logger_utils.dart';
import '../constants/app_constants.dart';

abstract class LocationService {
  Future<LatLng?> getCurrentLocation();

  Stream<LatLng> getLocationStream();

  Future<bool> isLocationServiceEnabled();
}

class LocationServiceImpl implements LocationService {
  @override
  Future<LatLng?> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return LocationUtils.positionToLatLng(position);
    } catch (e) {
      logger.error("Konum alınamadı.", e);
      return null;
    }
  }

  @override
  Stream<LatLng> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: AppConstants.locationDistanceThreshold,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "Konumunuz arka planda takip ediliyor",
          notificationTitle: "Konum Takibi Aktif",
          enableWakeLock: true,
          notificationIcon: AndroidResource(
            name: 'ic_launcher',
            defType: 'mipmap',
          ),
        ),
      ),
    ).map((position) {
      logger.info(
          "Yeni konum alındı: ${position.latitude}, ${position.longitude}");
      return LocationUtils.positionToLatLng(position);
    });
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      final permission = await Geolocator.checkPermission();

      if (!serviceEnabled) {
        logger.warning("Konum servisi kapalı");
        return false;
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        logger.warning("Konum izni yok");
        return false;
      }

      return true;
    } catch (e) {
      logger.error("Konum servisi kontrolünde hata", e);
      return false;
    }
  }
}
