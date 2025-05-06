import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'data/datasources/local/location_local_datasource.dart';
import 'data/repositories/location_repository_impl.dart';
import 'domain/usecases/get_locations_usecase.dart';
import 'domain/usecases/reset_locations_usecase.dart';
import 'domain/usecases/track_location_usecase.dart';
import 'domain/usecases/toggle_tracking_usecase.dart';
import 'core/services/location_service.dart';
import 'core/services/background_service.dart';
import 'core/services/geocoding_service.dart';
import 'core/services/preferences_service.dart';
import 'core/utils/logger_utils.dart';
import 'core/utils/notification_utils.dart';
import 'presentation/cubits/location/location_cubit.dart';
import 'presentation/cubits/location/location_state.dart';
import 'presentation/pages/map_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await NotificationUtils.initialize();

    final locationService = LocationServiceImpl();
    final geocodingService = GeocodingServiceImpl();
    final preferencesService = PreferencesService();
    final locationLocalDataSource = LocationLocalDataSourceImpl();

    await locationLocalDataSource.initialize();

    final locationRepository = LocationRepositoryImpl(
      localDataSource: locationLocalDataSource,
      geocodingService: geocodingService,
    );

    final getLocationsUseCase = GetLocationsUseCase(locationRepository);
    final resetLocationsUseCase = ResetLocationsUseCase(locationRepository);
    final trackLocationUseCase = TrackLocationUseCase(locationRepository);

    final backgroundService = BackgroundServiceImpl(locationService);
    final toggleTrackingUseCase =
        ToggleTrackingUseCase(backgroundService, trackLocationUseCase);

    await backgroundService.initializeService(trackLocationUseCase);

    final isTracking = await preferencesService.getTrackingStatus();
    logger.info("Uygulama başlatıldı, takip durumu: $isTracking");

    runApp(MyApp(
      getLocationsUseCase: getLocationsUseCase,
      resetLocationsUseCase: resetLocationsUseCase,
      trackLocationUseCase: trackLocationUseCase,
      toggleTrackingUseCase: toggleTrackingUseCase,
      locationService: locationService,
      isTracking: isTracking,
    ));
  } catch (e, stackTrace) {
    logger.error("Uygulama başlatma hatası", e, stackTrace);
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text("Uygulama başlatılamadı: $e", textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  final GetLocationsUseCase getLocationsUseCase;
  final ResetLocationsUseCase resetLocationsUseCase;
  final TrackLocationUseCase trackLocationUseCase;
  final ToggleTrackingUseCase toggleTrackingUseCase;
  final LocationService locationService;
  final bool isTracking;

  const MyApp({
    super.key,
    required this.getLocationsUseCase,
    required this.resetLocationsUseCase,
    required this.trackLocationUseCase,
    required this.toggleTrackingUseCase,
    required this.locationService,
    required this.isTracking,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LocationCubit(
        getLocationsUseCase: getLocationsUseCase,
        resetLocationsUseCase: resetLocationsUseCase,
        trackLocationUseCase: trackLocationUseCase,
        toggleTrackingUseCase: toggleTrackingUseCase,
        locationService: locationService,
        initialTrackingStatus:
            isTracking ? TrackingStatus.tracking : TrackingStatus.stopped,
      ),
      child: MaterialApp(
        title: 'OnTrack',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const MapPage(),
      ),
    );
  }
}
