import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../constants/app_constants.dart';
import '../../domain/usecases/track_location_usecase.dart';
import 'location_service.dart';
import '../utils/logger_util.dart';
import '../utils/notification_helper/notification_helper.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  logger.info("Arka plan servisi başlatılıyor (onStart)");
  try {
    await NotificationHelper.initialize();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });
      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    if (service is AndroidServiceInstance) {
      await service.setForegroundNotificationInfo(
        title: AppConstants.locationNotificationTitle,
        content: AppConstants.locationNotificationText,
      );

      await NotificationHelper.showForegroundServiceNotification();
    }

    service.invoke('update', {
      'isRunning': true,
    });
    logger.info("Arka plan servisi başarıyla başlatıldı (onStart sonu)");
  } catch (e, stackTrace) {
    logger.error("Arka plan servisi çalıştırma hatası", e, stackTrace);
  }
}

abstract class BackgroundService {
  Future<void> initializeService(TrackLocationUseCase trackLocationUseCase);

  Future<void> startService();

  Future<void> stopService();

  Future<bool> isServiceRunning();
}

class BackgroundServiceImpl implements BackgroundService {
  final FlutterBackgroundService _service = FlutterBackgroundService();
  final LocationService _locationService;

  BackgroundServiceImpl(this._locationService);

  @override
  Future<void> initializeService(
      TrackLocationUseCase trackLocationUseCase) async {
    try {
      await NotificationHelper.initialize();

      await _service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          autoStart: false,
          isForegroundMode: true,
          notificationChannelId: AppConstants.locationChannelId,
          initialNotificationTitle: AppConstants.locationNotificationTitle,
          initialNotificationContent: AppConstants.locationNotificationText,
          foregroundServiceNotificationId: 888,
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: (service) async {},
          onBackground: (service) async {
            return true;
          },
        ),
      );

      logger.info("Konum dinlemesi başlatıldı");
      final locationStream = _locationService.getLocationStream();
      bool firstPositionLogged = false;
      locationStream.listen((position) async {
        if (!firstPositionLogged) {
          logger.info("İlk konum alındı: $position");
          firstPositionLogged = true;
        }
        try {
          await trackLocationUseCase(position);
        } catch (e) {
          logger.error("Konum takibi hatası", e);
        }
      });
    } catch (e, stackTrace) {
      logger.error("Arka plan servisi başlatma hatası", e, stackTrace);
    }
  }

  @override
  Future<void> startService() async {
    logger.info("Arka plan servisi başlatılıyor (startService)");
    try {
      final isRunning = await _service.isRunning();
      if (isRunning) {
        logger.info("Servis zaten çalışıyor, yeniden başlatmaya gerek yok.");
        return;
      }

      await _service.startService();
      logger.info("Arka plan servisi başarıyla başlatıldı");
    } catch (e, stackTrace) {
      logger.error("Servis başlatma hatası", e, stackTrace);
      throw Exception("Arka plan servisi başlatılamadı: $e");
    }
  }

  @override
  Future<void> stopService() async {
    logger.info("Arka plan servisi durduruluyor (stopService)");
    try {
      _service.invoke('stopService');
      // TODO: Mantıkla bir yapı mı tekrar gözden geçirelim.
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
