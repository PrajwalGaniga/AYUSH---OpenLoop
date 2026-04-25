import 'dart:async';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const double _kFreeFallThreshold = 0.5;
const double _kImpactThreshold   = 2.5;
const int    _kImpactWindowMs    = 300;
const int    _kCooldownMs        = 15000;

/// Entry point for the background isolate.
/// flutter_background_service v5 passes ServiceInstance as parameter.
@pragma('vm:entry-point')
void fallDetectionServiceMain(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();

  service.on('stopService').listen((_) {
    service.stopSelf();
  });

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((_) {
      service.setAsForegroundService();
    });
    service.setForegroundNotificationInfo(
      title: '🛡️ AYUSH Fall Detection',
      content: 'Active — monitoring for falls',
    );
  }

  await _runFallDetection(service);
}

Future<void> _runFallDetection(ServiceInstance service) async {
  final prefs = await SharedPreferences.getInstance();

  bool freeFallDetected = false;
  DateTime? freeFallTime;
  DateTime lastAlertTime = DateTime.fromMillisecondsSinceEpoch(0);

  accelerometerEventStream(samplingPeriod: SensorInterval.fastestInterval)
      .listen((AccelerometerEvent event) async {
    final double mag = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    ) / 9.8;

    final now = DateTime.now();

    // Phase 1: Free-fall
    if (!freeFallDetected && mag < _kFreeFallThreshold) {
      freeFallDetected = true;
      freeFallTime = now;
      return;
    }

    // Phase 2: Impact
    if (freeFallDetected && freeFallTime != null && mag > _kImpactThreshold) {
      final gap = now.difference(freeFallTime!).inMilliseconds;
      if (gap <= _kImpactWindowMs) {
        final sinceLastAlert = now.difference(lastAlertTime).inMilliseconds;
        if (sinceLastAlert >= _kCooldownMs) {
          lastAlertTime = now;
          freeFallDetected = false;

          if (service is AndroidServiceInstance) {
            service.setForegroundNotificationInfo(
              title: '🚨 FALL DETECTED!',
              content: 'Alerting emergency contact...',
            );
          }

          await _triggerSOS(prefs, service);

          await Future.delayed(const Duration(seconds: 5));
          if (service is AndroidServiceInstance) {
            service.setForegroundNotificationInfo(
              title: '🛡️ AYUSH Fall Detection',
              content: 'Active — monitoring for falls',
            );
          }
          return;
        }
      }
      freeFallDetected = false;
    }

    // Reset stale free-fall
    if (freeFallDetected &&
        freeFallTime != null &&
        now.difference(freeFallTime!).inMilliseconds > _kImpactWindowMs * 2) {
      freeFallDetected = false;
    }
  });
}

Future<void> _triggerSOS(SharedPreferences prefs, ServiceInstance service) async {
  try {
    final guardianPhone = prefs.getString('guardian_phone') ?? '';
    final userName = prefs.getString('user_display_name') ?? 'AYUSH User';
    final apiBaseUrl = prefs.getString('api_base_url') ?? '';

    if (guardianPhone.isEmpty || apiBaseUrl.isEmpty) return;

    final clean = guardianPhone.replaceAll(RegExp(r'\D'), '');
    final fullPhone = clean.startsWith('91') ? '+$clean' : '+91$clean';

    final resp = await http.post(
      Uri.parse('$apiBaseUrl/sos/trigger'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'guardian_phone': fullPhone, 'user_name': userName}),
    ).timeout(const Duration(seconds: 15));

    service.invoke('sosTriggered', {
      'success': resp.statusCode == 200,
      'phone': fullPhone,
    });
  } catch (e) {
    service.invoke('sosError', {'error': e.toString()});
  }
}
