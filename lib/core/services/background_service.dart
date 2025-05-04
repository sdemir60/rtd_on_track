import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../constants/app_constants.dart';
import '../../domain/usecases/track_location_usecase.dart';
import 'location_service.dart';

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
      await _service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: (service) async {
            try {
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

              final locationStream = _locationService.getLocationStream();
              locationStream.listen((position) async {
                try {
                  await trackLocationUseCase(position);
                } catch (e) {
                  if (kDebugMode) {
                    print("Konum takibi hatası: $e");
                  }
                }
              });

              if (service is AndroidServiceInstance) {
                service.setForegroundNotificationInfo(
                  title: AppConstants.locationNotificationTitle,
                  content: AppConstants.locationNotificationText,
                );
              }

              service.invoke('update', {
                'isRunning': true,
              });
            } catch (e) {
              if (kDebugMode) {
                print("Arka plan servisi çalıştırma hatası: $e");
              }
            }
          },
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
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("Arka plan servisi başlatma hatası: $e");
        print("Stack trace: $stackTrace");
      }
    }
  }

  @override
  Future<void> startService() async {
    try {
      await _service.startService();
    } catch (e) {
      if (kDebugMode) {
        print("Servis başlatma hatası: $e");
      }
    }
  }

  @override
  Future<void> stopService() async {
    try {
      _service.invoke('stopService');
      // TODO: Mantıkla bir yapı mı tekrar gözden geçirelim.
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      if (kDebugMode) {
        print("Servis durdurma hatası: $e");
      }
    }
  }

  @override
  Future<bool> isServiceRunning() async {
    try {
      return await _service.isRunning();
    } catch (e) {
      if (kDebugMode) {
        print("Servis durumu kontrol hatası: $e");
      }
      return false;
    }
  }
}
