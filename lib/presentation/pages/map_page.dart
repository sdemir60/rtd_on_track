import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/location/location_cubit.dart';
import '../cubits/location/location_state.dart';
import '../widgets/map_widget.dart';
import '../widgets/control_buttons.dart';
import '../widgets/location_bottom_sheet.dart';
import '../widgets/loading_overlay.dart';
import '../../core/utils/permission_utils.dart';
import '../../core/utils/logger_utils.dart';
import '../../core/utils/dialog_utils.dart';

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

  // Helper method to show alerts
  void _showAlert(String title, String message) {
    DialogUtils.showAlert(context, title, message);
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
    logger.info("Uygulama yaşam döngüsü değişti: $state");
    if (state == AppLifecycleState.resumed) {
      _loadLocations();
    }
  }

  Future<void> _requestPermissions() async {
    try {
      logger.info("İzinler isteniyor");

      final hasNotificationPermission =
          await PermissionUtils.requestNotificationPermission();
      logger.info("Bildirim izni durumu: $hasNotificationPermission");

      await Future.delayed(const Duration(milliseconds: 500));

      final hasLocationPermission =
          await PermissionUtils.requestLocationPermission();
      logger.info("Konum izni durumu: $hasLocationPermission");

      await Future.delayed(const Duration(milliseconds: 500));

      if (hasLocationPermission) {
        final hasBackgroundLocationPermission =
            await PermissionUtils.requestBackgroundLocationPermission();
        logger.info(
            "Arka plan konum izni durumu: $hasBackgroundLocationPermission");
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

  void _toggleTracking() async {
    try {
      await _requestPermissions();
      context.read<LocationCubit>().toggleTracking();
    } catch (e) {
      logger.error("Takip durumu değiştirme hatası", e);
      _showAlert('Takip Hatası', "Takip durumu değiştirilemedi: $e");
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
                context.read<LocationCubit>().clearSelectedLocation();

                context.read<LocationCubit>().resetLocations();
              } catch (e) {
                logger.error("Konumları sıfırlama hatası.", e);
                _showAlert('Sıfırlama Hatası', "Konumlar sıfırlanamadı: $e");
              }
            },
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'OnTrack',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w500,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            height: 4,
          ),
        ),
      ),
      body: BlocConsumer<LocationCubit, LocationState>(
        listener: (context, state) {
          if (state.status == LocationStatus.failure &&
              state.errorMessage != null) {
            _showAlert('Hata', state.errorMessage!);
          }
        },
        builder: (context, state) {
          final bool isLoading = _isLoading ||
              state.status == LocationStatus.loading ||
              state.status == LocationStatus.initial;

          return LoadingOverlay(
            isLoading: isLoading,
            child: Stack(
              children: [
                MapWidget(
                  locations: state.locations,
                  currentPosition: state.currentPosition,
                  onLocationSelected: (location) {
                    context.read<LocationCubit>().selectLocation(location);
                  },
                ),
                _BottomSheetWithControls(
                  trackingStatus: state.trackingStatus,
                  onToggleTracking: _toggleTracking,
                  onResetLocations: _resetLocations,
                  locations: state.locations,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BottomSheetWithControls extends StatefulWidget {
  final TrackingStatus trackingStatus;
  final VoidCallback onToggleTracking;
  final VoidCallback onResetLocations;
  final List locations;

  const _BottomSheetWithControls({
    required this.trackingStatus,
    required this.onToggleTracking,
    required this.onResetLocations,
    required this.locations,
  });

  @override
  State<_BottomSheetWithControls> createState() =>
      _BottomSheetWithControlsState();
}

class _BottomSheetWithControlsState extends State<_BottomSheetWithControls> {
  double _sheetExtent = 0.03;
  final DraggableScrollableController _controller =
      DraggableScrollableController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            DraggableScrollableSheet(
              controller: _controller,
              initialChildSize: 0.03,
              minChildSize: 0.03,
              maxChildSize: 0.5,
              snap: true,
              snapSizes: const [0.03, 0.3],
              builder: (context, scrollController) {
                return BlocConsumer<LocationCubit, LocationState>(
                  listenWhen: (previous, current) =>
                      previous.selectedLocation != current.selectedLocation,
                  listener: (context, state) {
                    if (state.selectedLocation != null) {
                      _controller.animateTo(
                        0.3,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else if (state.selectedLocation == null &&
                        _sheetExtent > 0.03) {
                      _controller.animateTo(
                        0.03,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  buildWhen: (previous, current) =>
                      previous.selectedLocation != current.selectedLocation,
                  builder: (context, locationState) {
                    return NotificationListener<
                        DraggableScrollableNotification>(
                      onNotification: (notification) {
                        setState(() {
                          _sheetExtent = notification.extent;
                        });

                        if (notification.extent <= 0.03 &&
                            context
                                    .read<LocationCubit>()
                                    .state
                                    .selectedLocation !=
                                null) {
                          context.read<LocationCubit>().clearSelectedLocation();
                        }
                        return true;
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 16,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Center(
                                child: Container(
                                  width: 40,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[400],
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListView(
                                controller: scrollController,
                                children: [
                                  BlocBuilder<LocationCubit, LocationState>(
                                    builder: (context, state) {
                                      if (state.selectedLocation != null) {
                                        return LocationBottomSheet(
                                          location: state.selectedLocation!,
                                          onClose: () {
                                            context
                                                .read<LocationCubit>()
                                                .clearSelectedLocation();
                                          },
                                        );
                                      } else {
                                        return const SizedBox.shrink();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            Positioned(
              right: 16,
              bottom: constraints.maxHeight * _sheetExtent + 15,
              child: ControlButtons(
                trackingStatus: widget.trackingStatus,
                onToggleTracking: widget.onToggleTracking,
                onResetLocations: widget.onResetLocations,
              ),
            ),
          ],
        );
      },
    );
  }
}
