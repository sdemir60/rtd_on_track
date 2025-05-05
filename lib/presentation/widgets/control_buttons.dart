import 'package:flutter/material.dart';
import '../cubits/location/location_state.dart';

class ControlButtons extends StatelessWidget {
  final TrackingStatus trackingStatus;
  final VoidCallback onToggleTracking;
  final VoidCallback onResetLocations;

  const ControlButtons({
    super.key,
    required this.trackingStatus,
    required this.onToggleTracking,
    required this.onResetLocations,
  });

  @override
  Widget build(BuildContext context) {
    final isTracking = trackingStatus == TrackingStatus.tracking;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'toggleTracking',
          onPressed: onToggleTracking,
          backgroundColor: isTracking ? Colors.red : Colors.green,
          child: Icon(
            isTracking ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        FloatingActionButton(
          heroTag: 'resetLocations',
          onPressed: onResetLocations,
          backgroundColor: Colors.orange,
          child: const Icon(
            Icons.refresh,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
