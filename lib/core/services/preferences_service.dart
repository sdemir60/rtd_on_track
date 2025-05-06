import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger_utils.dart';

class PreferencesService {
  static const String isTrackingKey = 'is_tracking';

  Future<bool> saveTrackingStatus(bool isTracking) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(isTrackingKey, isTracking);
      logger.info('Takip durumu kaydedildi: $isTracking');
      return true;
    } catch (e) {
      logger.error('Takip durumu kaydedilemedi', e);
      return false;
    }
  }

  Future<bool> getTrackingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isTracking = prefs.getBool(isTrackingKey) ?? false;
      logger.info('Takip durumu alındı: $isTracking');
      return isTracking;
    } catch (e) {
      logger.error('Takip durumu alınamadı', e);
      return false;
    }
  }
}