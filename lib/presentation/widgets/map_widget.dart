import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import '../../../domain/entities/location_entity.dart';
import '../../../core/constants/map_constants.dart';
import '../../../core/utils/logger_util.dart';

class MapWidget extends StatelessWidget {
  final List<LocationEntity> locations;
  final LatLng? currentPosition;
  final Function(LocationEntity) onLocationSelected;

  const MapWidget({
    super.key,
    required this.locations,
    this.currentPosition,
    required this.onLocationSelected,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final center = currentPosition ??
          (locations.isNotEmpty
              ? locations.last.position
              : MapConstants.defaultCenter);

      return FlutterMap(
        options: MapOptions(
          initialCenter: center,
          initialZoom: MapConstants.defaultZoom,
          maxZoom: 18,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          MarkerClusterLayerWidget(
            options: MarkerClusterLayerOptions(
              maxClusterRadius: MapConstants.maxClusterRadius,
              size: const Size(40, 40),
              padding: const EdgeInsets.all(50),
              markers: _buildMarkers(),
              builder: (context, markers) => Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).primaryColor,
                ),
                child: Center(
                  child: Text(
                    markers.length.toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          if (currentPosition != null)
            MarkerLayer(
              markers: [
                Marker(
                  width: 40.0,
                  height: 40.0,
                  point: currentPosition!,
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.blue,
                    size: 30,
                  ),
                ),
              ],
            ),
        ],
      );
    } catch (e) {
      logger.error("Harita oluşturma hatası", e);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Harita yüklenemedi.'),
            const SizedBox(height: 8),
            Text('Hata: $e',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }
  }

  List<Marker> _buildMarkers() {
    try {
      return locations.map((location) {
        return Marker(
          width: 40.0,
          height: 40.0,
          point: location.position,
          child: GestureDetector(
            onTap: () => onLocationSelected(location),
            child: const Icon(
              Icons.location_on,
              color: Colors.red,
              size: 30,
            ),
          ),
        );
      }).toList();
    } catch (e) {
      logger.error("Marker oluşturma hatası", e);
      return [];
    }
  }
}
