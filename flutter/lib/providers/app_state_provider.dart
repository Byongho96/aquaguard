import 'dart:async';

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

enum NetworkStatus { wifi, cellular, offline }

class AppStateProvider with ChangeNotifier {
  final Connectivity _connectivity = Connectivity();

  DateTime _currentTime = DateTime.now();
  Timer? _timer;

  NetworkStatus _networkStatus = NetworkStatus.offline;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  DateTime get currentTime => _currentTime;
  NetworkStatus get networkStatus => _networkStatus;

  AppStateProvider() {
    _startClock();
    _initConnectivity();
  }

  void _startClock() {
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _currentTime = DateTime.now();
      notifyListeners();
    });
  }

  // 앱 시작 시 현재 연결 상태를 확인하고 이후 변화를 구독합니다.
  void _initConnectivity() {
    _connectivity.checkConnectivity().then(_updateConnectionStatus);
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi)) {
      _networkStatus = NetworkStatus.wifi;
    } else if (results.contains(ConnectivityResult.mobile)) {
      _networkStatus = NetworkStatus.cellular;
    } else {
      _networkStatus = NetworkStatus.offline;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
