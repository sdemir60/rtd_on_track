import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/location_entity.dart';
import '../../../core/constants/map_constants.dart';
import '../../../core/utils/logger_util.dart';
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

  void _goToCurrentLocation() {
    try {
      final currentPosition = widget.currentPosition;
      if (currentPosition != null) {
        _mapController.move(currentPosition, MapConstants.defaultZoom);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mevcut konum bulunamadı')),
        );
      }
    } catch (e) {
      logger.error("Konuma gitme hatası", e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Konuma gidilemedi: $e')),
      );
    }
  }

  void _fitAllMarkers() {
    try {
      if (widget.locations.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gösterilecek konum bulunamadı')),
        );
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

      final paddingFactor = 0.5;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Markerlar sığdırılamadı: $e')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yakınlaştırma yapılamadı: $e')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Uzaklaştırma yapılamadı: $e')),
      );
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
          if (widget.currentPosition != null)
            MarkerLayer(
              markers: [
                Marker(
                  width: 40.0,
                  height: 40.0,
                  point: widget.currentPosition!,
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
      return widget.locations.map((location) {
        return Marker(
          width: 40.0,
          height: 40.0,
          point: location.position,
          child: GestureDetector(
            onTap: () => widget.onLocationSelected(location),
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

  double _calculateZoomLevel(double delta) {
    return math.max(1, math.min(18, math.log(360 / delta) / math.log(2) + 1));
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
