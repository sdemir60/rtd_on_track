import 'package:permission_handler/permission_handler.dart';
import '../utils/logger_utils.dart';

class PermissionUtils {
  static Future<Map<Permission, PermissionStatus>> requestPermissions(
      List<Permission> permissions) async {
    Map<Permission, PermissionStatus> statuses = {};

    for (var permission in permissions) {
      try {
        PermissionStatus status = await permission.status;

        if (status.isGranted) {
          statuses[permission] = status;
          continue;
        }

        status = await permission.request();
        statuses[permission] = status;

        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e) {
        logger.error('İzin isteme hatası: ${permission.toString()}', e);
        statuses[permission] = PermissionStatus.denied;
      }
    }

    return statuses;
  }

  static Future<bool> requestLocationPermission() async {
    final statuses = await requestPermissions([Permission.location]);
    final isGranted = statuses[Permission.location]?.isGranted ?? false;
    logger.info('Konum izni durumu: $isGranted');
    return isGranted;
  }

  static Future<bool> requestBackgroundLocationPermission() async {
    final locationStatus = await Permission.location.status;
    if (!locationStatus.isGranted) {
      logger.warning(
          'Arka plan konum izni istemeden önce normal konum izni gerekli');
      return false;
    }

    final statuses = await requestPermissions([Permission.locationAlways]);
    final isGranted = statuses[Permission.locationAlways]?.isGranted ?? false;
    logger.info('Arka plan konum izni durumu: $isGranted');
    return isGranted;
  }

  static Future<bool> requestNotificationPermission() async {
    final statuses = await requestPermissions([Permission.notification]);
    final isGranted = statuses[Permission.notification]?.isGranted ?? false;
    logger.info('Bildirim izni durumu: $isGranted');
    return isGranted;
  }

  static Future<bool> checkLocationPermission() async {
    return await Permission.location.isGranted;
  }

  static Future<bool> checkBackgroundLocationPermission() async {
    return await Permission.locationAlways.isGranted;
  }

  static Future<bool> checkNotificationPermission() async {
    return await Permission.notification.isGranted;
  }

  static Future<bool> isPermanentlyDenied(Permission permission) async {
    final status = await permission.status;
    return status.isPermanentlyDenied;
  }

  static Future<bool> openSettings() async {
    return await openAppSettings();
  }
}
