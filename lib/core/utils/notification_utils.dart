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
      logger.info("Bildirim sistemi başariyla başlatıldı.");
    } catch (e) {
      logger.error("Bildirim sistemi başlatılırken hata oluştu.", e);
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

      logger.info("Bildirim kanalı başarıyla oluşturuldu.");
    } catch (e) {
      logger.error("Bildirim kanalı oluşturulurken hata oluştu.", e);
    }
  }

  static Future<void> showForegroundServiceNotification() async {
    try {
      bool hasPermission = await PermissionUtils.checkNotificationPermission();
      if (!hasPermission) {
        logger.warning("Bildirim izni verilmemiş, bildirim gösterilemiyor.");
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

      logger.info("Ön plan servisi bildirimi gösterildi.");
    } catch (e) {
      logger.error("Bildirim gösterilirken hata oluştu.", e);
    }
  }
}
