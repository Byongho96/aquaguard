import 'dart:convert';

import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../core/constants/app_constants.dart';
import '../models/tank_model.dart';

typedef RealtimeCallback = void Function(TankModel data);

class WebSocketService {
  StompClient? _client;
  final Map<String, StompUnsubscribe> _subscriptions = {};
  RealtimeCallback? _onData;
  bool _connected = false;

  bool get isConnected => _connected;

  void connect({required RealtimeCallback onData}) {
    _onData = onData;

    _client = StompClient(
      config: StompConfig(
        url: AppConstants.wsUrl,
        onConnect: _onConnect,
        onWebSocketError: (error) => print('WebSocket Error: $error'),
        onStompError: (frame) => print('STOMP Error: ${frame.body}'),
        onDisconnect: (_) {
          _connected = false;
          print('WebSocket Disconnected');
        },
        reconnectDelay: const Duration(seconds: 5),
      ),
    );

    _client!.activate();
  }

  void _onConnect(StompFrame frame) {
    _connected = true;
    print('WebSocket Connected');
  }

  void subscribeTank(String tankId) {
    if (_client == null || !_connected) return;
    if (_subscriptions.containsKey(tankId)) return;

    final unsubscribe = _client!.subscribe(
      destination: '/topic/tanks/$tankId/realtime',
      callback: (frame) {
        if (frame.body != null && _onData != null) {
          final Map<String, dynamic> json =
              jsonDecode(frame.body!) as Map<String, dynamic>;
          final TankModel model = TankModel.fromWebSocket(json);
          _onData!(model);
        }
      },
    );
    _subscriptions[tankId] = unsubscribe;
  }

  void unsubscribeTank(String tankId) {
    final unsubscribe = _subscriptions.remove(tankId);
    if (unsubscribe != null) {
      unsubscribe(unsubscribeHeaders: {});
    }
  }

  void disconnect() {
    _subscriptions.clear();
    _client?.deactivate();
    _client = null;
    _connected = false;
  }
}
