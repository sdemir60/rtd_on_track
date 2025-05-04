import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationUtils {
  static LatLng positionToLatLng(Position position) {
    return LatLng(position.latitude, position.longitude);
  }

  static double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
        point1.latitude, point1.longitude, point2.latitude, point2.longitude);
  }

  static bool isSignificantMovement(
      LatLng lastPosition, LatLng currentPosition, double threshold) {
    final distance = calculateDistance(lastPosition, currentPosition);
    return distance >= threshold;
  }
}
