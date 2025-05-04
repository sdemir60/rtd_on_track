import 'package:flutter/foundation.dart';
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
import 'presentation/cubits/location/location_cubit.dart';
import 'presentation/pages/map_page.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    runApp(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    ));

    final locationService = LocationServiceImpl();
    final geocodingService = GeocodingServiceImpl();
    final backgroundService = BackgroundServiceImpl(locationService);

    final locationLocalDataSource = LocationLocalDataSourceImpl();

    try {
      await locationLocalDataSource.initialize();
    } catch (e) {
      if (kDebugMode) {
        print("Veritabanı başlatma hatası: $e");
      }
    }

    final locationRepository = LocationRepositoryImpl(
      localDataSource: locationLocalDataSource,
      geocodingService: geocodingService,
    );

    final getLocationsUseCase = GetLocationsUseCase(locationRepository);
    final resetLocationsUseCase = ResetLocationsUseCase(locationRepository);
    final trackLocationUseCase = TrackLocationUseCase(locationRepository);
    final toggleTrackingUseCase = ToggleTrackingUseCase(backgroundService);

    try {
      await backgroundService.initializeService(trackLocationUseCase);
    } catch (e) {
      if (kDebugMode) {
        print("Arka plan servisi başlatma hatası: $e");
      }
    }

    runApp(MyApp(
      getLocationsUseCase: getLocationsUseCase,
      resetLocationsUseCase: resetLocationsUseCase,
      trackLocationUseCase: trackLocationUseCase,
      toggleTrackingUseCase: toggleTrackingUseCase,
      locationService: locationService,
    ));
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print("Uygulama başlatma hatası: $e");
      print("Stack trace: $stackTrace");
    }
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text("Uygulama başlatılamadı: $e"),
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

  const MyApp({
    super.key,
    required this.getLocationsUseCase,
    required this.resetLocationsUseCase,
    required this.trackLocationUseCase,
    required this.toggleTrackingUseCase,
    required this.locationService,
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
