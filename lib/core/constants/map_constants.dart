import 'package:latlong2/latlong.dart';

// TODO: Varsayılan cihazın konumu olmalı.
class MapConstants {
  static const double defaultZoom = 15.0;
  static const LatLng defaultCenter = LatLng(41.0082, 28.9784);
  static const double clusterRadius = 45;
  static const int maxClusterRadius = 100;
  static const int animationDuration = 500;
}