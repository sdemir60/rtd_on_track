import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/location/location_cubit.dart';
import '../cubits/location/location_state.dart';
import '../widgets/map_widget.dart';
import '../widgets/control_buttons.dart';
import '../widgets/location_bottom_sheet.dart';
import '../../core/utils/permission_utils.dart';
import '../../core/utils/logger_util.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with WidgetsBindingObserver {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await _requestPermissions();
      _loadLocations();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      logger.error("Uygulama başlatma hatası", e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadLocations();
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final hasLocationPermission =
          await PermissionUtils.requestLocationPermission();

      if (hasLocationPermission) {
        await PermissionUtils.requestBackgroundLocationPermission();
      }
    } catch (e) {
      logger.error("İzin isteme hatası", e);
    }
  }

  void _loadLocations() {
    try {
      context.read<LocationCubit>().loadLocations();
    } catch (e) {
      logger.error("Konum yükleme hatası", e);
    }
  }

  void _toggleTracking() {
    try {
      _requestPermissions().then((_) {
        context.read<LocationCubit>().toggleTracking();
      });
    } catch (e) {
      logger.error("Takip durumu değiştirme hatası", e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Takip durumu değiştirilemedi: $e")),
      );
    }
  }

  void _resetLocations() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konumları Sıfırla'),
        content: const Text('Tüm konum geçmişi silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              try {
                context.read<LocationCubit>().resetLocations();
              } catch (e) {
                logger.error("Konumları sıfırlama hatası", e);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Konumlar sıfırlanamadı: $e")),
                );
              }
            },
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
  }

  void _showLocationDetails(BuildContext context, LocationState state) {
    if (state.selectedLocation != null) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => LocationBottomSheet(
          location: state.selectedLocation!,
          onClose: () {
            Navigator.of(context).pop();
            context.read<LocationCubit>().clearSelectedLocation();
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OnTrack'),
        centerTitle: true,
      ),
      body: BlocConsumer<LocationCubit, LocationState>(
        listener: (context, state) {
          if (state.status == LocationStatus.failure &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }

          if (state.selectedLocation != null) {
            _showLocationDetails(context, state);
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              MapWidget(
                locations: state.locations,
                currentPosition: state.currentPosition,
                onLocationSelected: (location) {
                  context.read<LocationCubit>().selectLocation(location);
                },
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: ControlButtons(
                  trackingStatus: state.trackingStatus,
                  onToggleTracking: _toggleTracking,
                  onResetLocations: _resetLocations,
                ),
              ),
              if (_isLoading ||
                  state.status == LocationStatus.loading ||
                  state.status == LocationStatus.initial)
                const Positioned(
                  top: 10,
                  right: 10,
                  child: Card(
                    elevation: 4,
                    shape: CircleBorder(),
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
