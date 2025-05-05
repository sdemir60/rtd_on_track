import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/location/location_cubit.dart';
import '../cubits/location/location_state.dart';
import '../widgets/map_widget.dart';
import '../widgets/control_buttons.dart';
import '../widgets/location_bottom_sheet.dart';
import '../../core/utils/permission_utils.dart';
import '../../core/utils/logger_util.dart';
import '../../core/services/preferences_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with WidgetsBindingObserver {
  bool _isLoading = true;
  final PreferencesService _preferencesService = PreferencesService();

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
      logger.error("Uygulama baslatma hatasi", e);
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
    logger.info("Uygulama yasam dongusu degisti: $state");
    if (state == AppLifecycleState.resumed) {
      _loadLocations();
    }
  }

  Future<void> _requestPermissions() async {
    try {
      logger.info("Izinler isteniyor");
      
      final hasNotificationPermission = await PermissionUtils.requestNotificationPermission();
      logger.info("Bildirim izni durumu: $hasNotificationPermission");
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      final hasLocationPermission = await PermissionUtils.requestLocationPermission();
      logger.info("Konum izni durumu: $hasLocationPermission");

      await Future.delayed(const Duration(milliseconds: 500));
      
      if (hasLocationPermission) {
        final hasBackgroundLocationPermission = 
            await PermissionUtils.requestBackgroundLocationPermission();
        logger.info("Arka plan konum izni durumu: $hasBackgroundLocationPermission");
      }
    } catch (e) {
      logger.error("Izin isteme hatasi", e);
    }
  }

  void _loadLocations() {
    try {
      context.read<LocationCubit>().loadLocations();
    } catch (e) {
      logger.error("Konum yukleme hatasi", e);
    }
  }

  void _toggleTracking() async {
    try {
      await _requestPermissions();
      context.read<LocationCubit>().toggleTracking();
    } catch (e) {
      logger.error("Takip durumu degistirme hatasi", e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Takip durumu degistirilemedi: $e")),
      );
    }
  }

  void _resetLocations() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konumlari Sifirla'),
        content: const Text('Tum konum gecmisi silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Iptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              try {
                context.read<LocationCubit>().resetLocations();
              } catch (e) {
                logger.error("Konumlari sifirlama hatasi", e);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Konumlar sifirlanamadi: $e")),
                );
              }
            },
            child: const Text('Sifirla'),
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