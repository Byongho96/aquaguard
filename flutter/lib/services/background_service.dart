import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../core/constants/app_constants.dart';
import 'dart:convert';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'gps_service_channel',
      initialNotificationTitle: 'AquaGuard GPS',
      initialNotificationContent: '트럭 위치 정보를 전송 중입니다.',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

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

  // WebSocket Client for Background
  StompClient? stompClient;

  void connectWebSocket() {
    stompClient = StompClient(
      config: StompConfig(
        url: AppConstants.wsUrl,
        onConnect: (frame) {
          print('[Background WS] Connected');
        },
        onWebSocketError: (error) => print('[Background WS] Error: $error'),
        reconnectDelay: const Duration(seconds: 5),
      ),
    );
    stompClient?.activate();
  }

  connectWebSocket();

  // Location tracking
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    if (stompClient != null && stompClient!.connected) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        final payload = {
          'truckId': 'BUSAN-12-HO',
          'latitude': position.latitude,
          'longitude': position.longitude,
        };

        stompClient?.send(
          destination: '/topic/trucks/gps',
          body: jsonEncode(payload),
        );
        
        if (service is AndroidServiceInstance) {
          if (await service.isForegroundService()) {
            service.setForegroundNotificationInfo(
              title: "AquaGuard 실시간 트래킹",
              content: "위치: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}",
            );
          }
        }
      } catch (e) {
        print('[Background GPS] Error: $e');
      }
    }
  });
}
