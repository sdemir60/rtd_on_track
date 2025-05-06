import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/location_entity.dart';
import '../../../core/constants/map_constants.dart';
import '../../../core/utils/logger_utils.dart';
import '../../../core/utils/location_utils.dart';
import '../cubits/location/location_cubit.dart';
import '../cubits/location/location_state.dart';
import 'dart:math' as math;

class MapWidget extends StatefulWidget {
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
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return BlocListener<LocationCubit, LocationState>(
      listenWhen: (previous, current) =>
          current.currentPosition != previous.currentPosition &&
          current.currentPosition != null,
      listener: (context, state) {
        if (state.currentPosition != null) {
          _mapController.move(
              state.currentPosition!, _mapController.camera.zoom);
        }
      },
      child: Stack(
        children: [
          _buildMap(),
          _buildMapControls(),
        ],
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      right: 16,
      top: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildControlButton(
            icon: Icons.my_location,
            tooltip: 'Konumuma Git',
            onPressed: _goToCurrentLocation,
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            icon: Icons.fit_screen,
            tooltip: 'Tüm Markerları Göster',
            onPressed: _fitAllMarkers,
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            icon: Icons.zoom_in,
            tooltip: 'Yakınlaştır',
            onPressed: _zoomIn,
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            icon: Icons.zoom_out,
            tooltip: 'Uzaklaştır',
            onPressed: _zoomOut,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: Tooltip(
            message: tooltip,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(icon, size: 24),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to show alerts
  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Tamam'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _goToCurrentLocation() {
    try {
      final currentPosition = widget.currentPosition;
      if (currentPosition != null) {
        final zoomLevel = math.max(MapConstants.defaultZoom - 0.5, 5.0);
        _mapController.move(currentPosition, zoomLevel);

        final locations = widget.locations;
        if (locations.isNotEmpty) {
          LocationEntity? targetLocation;

          final lastLocation = locations.last;
          if (lastLocation.position.latitude == currentPosition.latitude &&
              lastLocation.position.longitude == currentPosition.longitude) {
            targetLocation = lastLocation;
          } else {
            double minDistance = double.infinity;
            for (final location in locations) {
              final distance = _calculateDistance(
                  location.position.latitude,
                  location.position.longitude,
                  currentPosition.latitude,
                  currentPosition.longitude);

              if (distance < minDistance) {
                minDistance = distance;
                targetLocation = location;
              }
            }
          }

          if (targetLocation != null) {
            context.read<LocationCubit>().selectLocation(targetLocation);
          }
        }
      } else {
        _showAlert('Konum Hatası', 'Mevcut konum bulunamadı');
      }
    } catch (e) {
      logger.error("Konuma gitme hatası", e);
      _showAlert('Konum Hatası', 'Konuma gidilemedi: $e');
    }
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    // Using the utility method from LocationUtils instead of duplicating the calculation
    return LocationUtils.calculateDistance(
      LatLng(lat1, lon1),
      LatLng(lat2, lon2),
    );
  }

  void _fitAllMarkers() {
    try {
      if (widget.locations.isEmpty) {
        _showAlert('Konum Hatası', 'Gösterilecek konum bulunamadı');
        return;
      }

      double minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;

      for (final location in widget.locations) {
        minLat = math.min(minLat, location.position.latitude);
        maxLat = math.max(maxLat, location.position.latitude);
        minLng = math.min(minLng, location.position.longitude);
        maxLng = math.max(maxLng, location.position.longitude);
      }

      if (widget.currentPosition != null) {
        minLat = math.min(minLat, widget.currentPosition!.latitude);
        maxLat = math.max(maxLat, widget.currentPosition!.latitude);
        minLng = math.min(minLng, widget.currentPosition!.longitude);
        maxLng = math.max(maxLng, widget.currentPosition!.longitude);
      }

      const paddingFactor = 0.5;
      final latDiff = (maxLat - minLat) * paddingFactor;
      final lngDiff = (maxLng - minLng) * paddingFactor;

      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;

      final latZoom = _calculateZoomLevel(maxLat - minLat + 2 * latDiff);
      final lngZoom = _calculateZoomLevel(maxLng - minLng + 2 * lngDiff);
      final zoom = math.min(latZoom, lngZoom);

      _mapController.move(LatLng(centerLat, centerLng), zoom);
    } catch (e) {
      logger.error("Markerları sığdırma hatası", e);
      _showAlert('Harita Hatası', 'Markerlar sığdırılamadı: $e');
    }
  }

  void _zoomIn() {
    try {
      final currentZoom = _mapController.camera.zoom;
      final newZoom =
          math.min(currentZoom + 1.0, 18.0); // Maximum zoom level is 18
      _mapController.move(_mapController.camera.center, newZoom);
    } catch (e) {
      logger.error("Yakınlaştırma hatası", e);
      _showAlert('Harita Hatası', 'Yakınlaştırma yapılamadı: $e');
    }
  }

  void _zoomOut() {
    try {
      final currentZoom = _mapController.camera.zoom;
      final newZoom =
          math.max(currentZoom - 1.0, 1.0); // Minimum zoom level is 1
      _mapController.move(_mapController.camera.center, newZoom);
    } catch (e) {
      logger.error("Uzaklaştırma hatası", e);
      _showAlert('Harita Hatası', 'Uzaklaştırma yapılamadı: $e');
    }
  }

  Widget _buildMap() {
    try {
      final center = widget.currentPosition ??
          (widget.locations.isNotEmpty
              ? widget.locations.last.position
              : MapConstants.defaultCenter);

      return FlutterMap(
        mapController: _mapController,
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
          BlocBuilder<LocationCubit, LocationState>(
            buildWhen: (previous, current) =>
                previous.selectedLocation != current.selectedLocation ||
                previous.currentPosition != current.currentPosition,
            builder: (context, state) {
              return MarkerClusterLayerWidget(
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
              );
            },
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
      final markers = <Marker>[];
      final state = context.read<LocationCubit>().state;
      final selectedLocation = state.selectedLocation;
      final currentPosition = widget.currentPosition;

      for (int i = 0; i < widget.locations.length; i++) {
        final location = widget.locations[i];
        final isLastLocation = i == widget.locations.length - 1;
        final isSelected = selectedLocation?.id == location.id;

        final isActive =
            isSelected || (isLastLocation && selectedLocation == null);

        markers.add(Marker(
          width: 40.0,
          height: 40.0,
          point: location.position,
          child: GestureDetector(
            onTap: () {
              if (isSelected) {
                context.read<LocationCubit>().clearSelectedLocation();
              } else {
                widget.onLocationSelected(location);
              }
            },
            child: Icon(
              Icons.location_on,
              color: isActive ? Colors.blue : Colors.red,
              size: 30,
            ),
          ),
        ));
      }

      if (currentPosition != null &&
          !widget.locations.any((loc) =>
              loc.position.latitude == currentPosition.latitude &&
              loc.position.longitude == currentPosition.longitude)) {
        final isActive = selectedLocation == null && widget.locations.isEmpty;

        markers.add(Marker(
          width: 40.0,
          height: 40.0,
          point: currentPosition,
          child: GestureDetector(
            onTap: () {
              if (selectedLocation != null) {
                context.read<LocationCubit>().clearSelectedLocation();
              }
            },
            child: Icon(
              Icons.location_on,
              color: isActive ? Colors.blue : Colors.red,
              size: 30,
            ),
          ),
        ));
      }

      return markers;
    } catch (e) {
      logger.error("Marker oluşturma hatası", e);
      return [];
    }
  }

  double _calculateZoomLevel(double delta) {
    return math.max(1, math.min(18, math.log(360 / delta) / math.log(2) + 1));
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
