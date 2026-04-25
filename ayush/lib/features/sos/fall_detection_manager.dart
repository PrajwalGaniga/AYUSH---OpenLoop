import 'package:flutter_background_service/flutter_background_service.dart';
import 'fall_detection_service.dart';

class FallDetectionManager {
  static final FallDetectionManager _instance = FallDetectionManager._();
  static FallDetectionManager get instance => _instance;
  FallDetectionManager._();

  static Future<void> initialize() async {
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: fallDetectionServiceMain,
        isForegroundMode: true,
        autoStart: false,
        notificationChannelId: 'ayush_fall_detection',
        initialNotificationTitle: '🛡️ AYUSH Fall Detection',
        initialNotificationContent: 'Tap to open',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.health],
      ),
      iosConfiguration: IosConfiguration(autoStart: false),
    );
  }

  Future<void> startService() async {
    await FlutterBackgroundService().startService();
  }

  Future<void> stopService() async {
    FlutterBackgroundService().invoke('stopService');
  }

  Future<bool> isRunning() async {
    return FlutterBackgroundService().isRunning();
  }
}
