import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants/app_constants.dart';
import 'permission_utils.dart';
import 'logger_utils.dart';

class NotificationUtils {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
      );

      await createNotificationChannel();
      logger.info("Bildirim sistemi basariyla baslatildi");
    } catch (e) {
      logger.error("Bildirim sistemi baslatilirken hata olustu", e);
    }
  }

  static Future<void> createNotificationChannel() async {
    try {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        AppConstants.locationChannelId,
        AppConstants.locationChannelName,
        importance: Importance.high,
        playSound: false,
        enableVibration: false,
        description: 'Konum takip servisi bildirimleri',
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      logger.info("Bildirim kanali basariyla olusturuldu");
    } catch (e) {
      logger.error("Bildirim kanali olusturulurken hata olustu", e);
    }
  }

  static Future<void> showForegroundServiceNotification() async {
    try {
      bool hasPermission = await PermissionUtils.checkNotificationPermission();
      if (!hasPermission) {
        logger.warning("Bildirim izni verilmemis, bildirim gosterilemiyor");
      }

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        AppConstants.locationChannelId,
        AppConstants.locationChannelName,
        channelDescription: 'Konum takip servisi bildirimleri',
        importance: Importance.high,
        priority: Priority.high,
        ongoing: true,
        autoCancel: false,
        playSound: false,
        enableVibration: false,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await flutterLocalNotificationsPlugin.show(
        888,
        AppConstants.locationNotificationTitle,
        AppConstants.locationNotificationText,
        platformChannelSpecifics,
      );

      logger.info("On plan servisi bildirimi gosterildi");
    } catch (e) {
      logger.error("Bildirim gosterilirken hata olustu", e);
    }
  }
}
