import 'package:geocoding/geocoding.dart';
import '../utils/logger_utils.dart';

abstract class GeocodingService {
  Future<String?> getAddressFromCoordinates(double latitude, double longitude);
}

class GeocodingServiceImpl implements GeocodingService {
  @override
  Future<String?> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.subLocality}, ${place.locality}, ${place.country}';
      }
      return null;
    } catch (e) {
      logger.error("Adres bilgisi alınamadı", e);
      return null;
    }
  }
}
