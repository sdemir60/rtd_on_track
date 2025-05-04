import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../utils/location_utils.dart';
import '../utils/logger_util.dart';

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
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, //TODO: Sabitlere eklenebilir.
      ),
    ).map((position) => LocationUtils.positionToLatLng(position));
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }
}
