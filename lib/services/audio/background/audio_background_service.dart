import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

const String notificationChannelId = 'audio_service_channel';
const int notificationId = 888;

// These need to be top-level functions, not class methods
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  print("iOS background fetch initiated");
  // Keep service alive in background
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // This is a top-level function as required by the package
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  print("Background service started");

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  // Handle stop service request
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Send data from background service to UI
  service.on('updateAudioStats').listen((event) {
    if (event != null) {
      // Store the audio stats
      service.invoke('audioStats', event);
    }
  });
  // Keep the service running with a periodic task
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        // Update the notification periodically
        service.setForegroundNotificationInfo(
          title: "Echo Aid",
          content: "Audio enhancement running...",
        );
      }
    }

    // Send current timestamp to the UI
    service.invoke('update', {
      'current_time': DateTime.now().toIso8601String(),
      'active': true,
    });
  });
}

class AudioBackgroundService {
  final _service = FlutterBackgroundService();

  // Start the background service
  void startBackgroundService() {
    _service.startService();
  }

  // Stop the background service
  void stopBackgroundService() {
    _service.invoke("stopService");
  }

  // Send data to the background service
  void sendAudioStats(Map<String, dynamic> stats) {
    _service.invoke("updateAudioStats", stats);
  }

  // Listen for updates from the background service
  Stream<Map<String, dynamic>?> get onAudioStats => _service.on('audioStats');

  // Initialize the background service
  Future<void> initializeService() async {
    await _service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'Echo Aid',
        initialNotificationContent: 'Audio enhancement starting...',
        foregroundServiceNotificationId: notificationId,
      ),
    );
  }
}
