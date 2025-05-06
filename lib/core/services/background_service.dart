import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:latlong2/latlong.dart';
import '../constants/app_constants.dart';
import '../../domain/usecases/track_location_usecase.dart';
import 'location_service.dart';
import '../utils/logger_utils.dart';
import '../utils/notification_utils.dart';
import 'preferences_service.dart';
import 'geocoding_service.dart';
import '../../data/datasources/local/location_local_datasource.dart';
import '../../data/repositories/location_repository_impl.dart';

TrackLocationUseCase? _trackLocationUseCase;
LocationService? _globalLocationService;
StreamSubscription<LatLng>? _locationSubscription;
ReceivePort? _receivePort;

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  logger.info("Arka plan servisi başlatılıyor (onStart)");
  try {
    if (service is AndroidServiceInstance) {
      await service.setForegroundNotificationInfo(
        title: AppConstants.locationNotificationTitle,
        content: AppConstants.locationNotificationText,
      );
    }

    await NotificationUtils.initialize();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });
      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      _stopLocationTracking();
      service.stopSelf();
    });

    service.on('startLocationTracking').listen((event) {
      if (event != null) {
        if (_globalLocationService == null) {
          _globalLocationService = LocationServiceImpl();
        }
        _startLocationTracking();
      }
    });

    await NotificationUtils.showForegroundServiceNotification();

    service.invoke('update', {
      'isRunning': true,
    });

    Timer.periodic(const Duration(minutes: 15), (timer) {
      service.invoke('update', {
        'isRunning': true,
        'lastCheck': DateTime.now().toString(),
      });
      logger.info("Arka plan servisi hala çalışıyor: ${DateTime.now()}");
    });

    final preferencesService = PreferencesService();
    final isTracking = await preferencesService.getTrackingStatus();
    if (isTracking) {
      logger
          .info("Önceki takip durumu aktif, konum takibi yeniden başlatılıyor");
      if (_globalLocationService == null) {
        _globalLocationService = LocationServiceImpl();
      }
      _startLocationTracking();
    }

    logger.info("Arka plan servisi başarıyla başlatıldı (onStart sonu)");
  } catch (e, stackTrace) {
    logger.error("Arka plan servisi çalıştırma hatası", e, stackTrace);
  }
}

@pragma('vm:entry-point')
void _startLocationTracking() async {
  logger.info("Konum takibi başlatılıyor");

  if (_globalLocationService == null) {
    _globalLocationService = LocationServiceImpl();
  }

  final locationLocalDataSource = LocationLocalDataSourceImpl();
  try {
    await locationLocalDataSource.initialize();
    logger.info("Veritabanı başarıyla başlatıldı");
  } catch (e, stackTrace) {
    logger.error("Veritabanı başlatma hatası, devam ediliyor", e, stackTrace);
  }

  final geocodingService = GeocodingServiceImpl();

  final locationRepository = LocationRepositoryImpl(
    localDataSource: locationLocalDataSource,
    geocodingService: geocodingService,
  );

  if (_trackLocationUseCase == null) {
    _trackLocationUseCase = TrackLocationUseCase(locationRepository);
  }

  _locationSubscription?.cancel();
  _locationSubscription =
      _globalLocationService!.getLocationStream().listen((position) async {
    try {
      final SendPort? sendPort =
          IsolateNameServer.lookupPortByName('location_tracking_port');
      if (sendPort != null) {
        sendPort.send({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }

      if (_trackLocationUseCase != null) {
        try {
          await _trackLocationUseCase!(position);
          logger.info("Konum veritabanına kaydedildi: $position");
        } catch (e, stackTrace) {
          logger.error("Konum kaydetme hatası", e, stackTrace);
        }
      }

      logger.info("Konum alındı: $position");
    } catch (e, stackTrace) {
      logger.error("Konum takibi hatası", e, stackTrace);
    }
  });
}

@pragma('vm:entry-point')
void _stopLocationTracking() {
  logger.info("Konum takibi durduruluyor");
  _locationSubscription?.cancel();
  _locationSubscription = null;
}

abstract class BackgroundService {
  Future<void> initializeService(TrackLocationUseCase trackLocationUseCase);

  Future<void> startService(TrackLocationUseCase trackLocationUseCase);

  Future<void> stopService();

  Future<bool> isServiceRunning();
}

class BackgroundServiceImpl implements BackgroundService {
  final FlutterBackgroundService _service = FlutterBackgroundService();
  final LocationService _locationService;
  final PreferencesService _preferencesService = PreferencesService();
  TrackLocationUseCase? _trackLocationUseCase;

  BackgroundServiceImpl(this._locationService) {
    _globalLocationService = this._locationService;
  }

  @override
  Future<void> initializeService(
      TrackLocationUseCase trackLocationUseCase) async {
    try {
      _trackLocationUseCase = trackLocationUseCase;

      await NotificationUtils.initialize();

      await _service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          autoStart: true,
          isForegroundMode: true,
          notificationChannelId: AppConstants.locationChannelId,
          initialNotificationTitle: AppConstants.locationNotificationTitle,
          initialNotificationContent: AppConstants.locationNotificationText,
          foregroundServiceNotificationId: 888,
          autoStartOnBoot: true,
        ),
        iosConfiguration: IosConfiguration(
          autoStart: true,
          onForeground: (service) async {},
          onBackground: (service) async {
            return true;
          },
        ),
      );

      final isTracking = await _preferencesService.getTrackingStatus();
      if (isTracking) {
        logger.info(
            "Uygulama başlatıldı ve takip durumu aktif, servis başlatılıyor");
        await startService(trackLocationUseCase);
      }
    } catch (e, stackTrace) {
      logger.error("Arka plan servisi başlatma hatası", e, stackTrace);
    }
  }

  @override
  Future<void> startService(TrackLocationUseCase trackLocationUseCase) async {
    logger.info("Arka plan servisi başlatılıyor (startService)");
    try {
      await _preferencesService.saveTrackingStatus(true);

      _receivePort = ReceivePort();
      IsolateNameServer.registerPortWithName(
          _receivePort!.sendPort, 'location_tracking_port');

      _receivePort!.listen((message) {
        if (message is Map<String, dynamic>) {
          final latitude = message['latitude'] as double;
          final longitude = message['longitude'] as double;
          final position = LatLng(latitude, longitude);

          trackLocationUseCase(position);
        }
      });

      final isRunning = await _service.isRunning();
      if (isRunning) {
        logger.info("Servis zaten çalışıyor, konum takibi başlatılıyor");
        _service.invoke('startLocationTracking', {});
        return;
      }

      await NotificationUtils.showForegroundServiceNotification();

      await _service.startService();

      _service.invoke('startLocationTracking', {});

      _startForegroundTracking(trackLocationUseCase);

      Timer.periodic(const Duration(minutes: 30), (timer) async {
        final serviceRunning = await isServiceRunning();
        if (!serviceRunning) {
          logger.warning("Servis durmuş, yeniden başlatılıyor");
          timer.cancel();
          await _service.startService();
          _service.invoke('startLocationTracking', {});
        } else {
          logger.info("Watchdog: Servis hala çalışıyor.");
        }
      });

      logger.info("Arka plan servisi başarıyla başlatıldı");
    } catch (e, stackTrace) {
      logger.error("Servis başlatma hatası", e, stackTrace);
      throw Exception("Arka plan servisi başlatılamadı: $e");
    }
  }

  StreamSubscription<LatLng>? _foregroundLocationSubscription;

  void _startForegroundTracking(TrackLocationUseCase trackLocationUseCase) {
    _foregroundLocationSubscription?.cancel();
    _foregroundLocationSubscription =
        _locationService?.getLocationStream().listen((position) async {
      try {
        await trackLocationUseCase(position);
      } catch (e, stackTrace) {
        logger.error("Ön planda konum takibi hatası", e, stackTrace);
      }
    });
  }

  void _stopForegroundTracking() {
    _foregroundLocationSubscription?.cancel();
    _foregroundLocationSubscription = null;
  }

  @override
  Future<void> stopService() async {
    logger.info("Arka plan servisi durduruluyor (stopService)");
    try {
      await _preferencesService.saveTrackingStatus(false);

      IsolateNameServer.removePortNameMapping('location_tracking_port');
      _receivePort?.close();
      _receivePort = null;

      _stopForegroundTracking();

      _service.invoke('stopService');
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      logger.error("Servis durdurma hatası", e);
    }
  }

  @override
  Future<bool> isServiceRunning() async {
    try {
      return await _service.isRunning();
    } catch (e) {
      logger.error("Servis durumu kontrol hatası", e);
      return false;
    }
  }
}
