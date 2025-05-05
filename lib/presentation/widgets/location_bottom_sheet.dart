import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/location_entity.dart';

class LocationBottomSheet extends StatelessWidget {
  final LocationEntity location;
  final VoidCallback onClose;

  const LocationBottomSheet({
    super.key,
    required this.location,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm:ss');
    final formattedDate = dateFormat.format(location.timestamp);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildInfoRow('Tarih', formattedDate),
          const SizedBox(height: 8),
          _buildInfoRow('Enlem', location.position.latitude.toStringAsFixed(6)),
          const SizedBox(height: 8),
          _buildInfoRow(
              'Boylam', location.position.longitude.toStringAsFixed(6)),
          if (location.address != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow('Adres', location.address!),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }
}
