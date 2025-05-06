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
    return statuses[Permission.location]?.isGranted ?? false;
  }

  static Future<bool> requestBackgroundLocationPermission() async {
    final locationStatus = await Permission.location.status;
    if (!locationStatus.isGranted) {
      logger.warning(
          'Arka plan konum izni istemeden önce normal konum izni gerekli');
      return false;
    }

    final statuses = await requestPermissions([Permission.locationAlways]);
    return statuses[Permission.locationAlways]?.isGranted ?? false;
  }

  static Future<bool> requestNotificationPermission() async {
    final statuses = await requestPermissions([Permission.notification]);
    return statuses[Permission.notification]?.isGranted ?? false;
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
}
