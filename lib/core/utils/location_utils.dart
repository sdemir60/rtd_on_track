import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../utils/logger_utils.dart';

class LocationUtils {
  static LatLng positionToLatLng(Position position) {
    return LatLng(position.latitude, position.longitude);
  }

  static double calculateDistance(LatLng point1, LatLng point2) {
    try {
      return Geolocator.distanceBetween(
          point1.latitude, point1.longitude, point2.latitude, point2.longitude);
    } catch (e) {
      logger.error("Mesafe hesaplama hatası.", e);
      return 0;
    }
  }

  static bool isSignificantMovement(
      LatLng lastPosition, LatLng currentPosition, double threshold) {
    final distance = calculateDistance(lastPosition, currentPosition);
    logger.info("Mesafe: $distance metre, eu015fik: $threshold metre");
    return distance >= threshold;
  }
}
