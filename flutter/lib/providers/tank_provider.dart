import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../models/alert_model.dart';
import '../models/tank_model.dart';
import '../services/api_service.dart';

enum PollingMode { none, main, detail }

class TankProvider with ChangeNotifier {
  final ApiService _apiService = AppConstants.useMockData
      ? MockApiService()
      : DioApiService();

  List<TankModel> _tanks = [];
  bool _isLoading = false;

  Timer? _pollingTimer;
  int _pollingSeconds = 1;
  PollingMode _currentMode = PollingMode.none;
  String? _currentDetailTankId;

  // 항상 실행되는 백그라운드 폴링 타이머 (상세 페이지에서도 알림 감지용)
  Timer? _backgroundTimer;

  // 현재 이상이 감지된 수조별 알림 (tankId → TankAlert)
  final Map<String, TankAlert> _currentAlerts = {};
  // 사용자가 닫은 알림 키 (tankId:message)
  final Set<String> _dismissedAlertKeys = {};

  final Map<String, String> _tankNames = <String, String>{};
  final Map<String, TankHistoryModel> _tankHistories =
      <String, TankHistoryModel>{};
  static const int _maxGraphPoints = 20;

  // 🎯 전역 설정에서 수조별(tankId) 설정으로 변경
  final Map<String, Map<String, List<double>>> _tankThresholds = {};

  final Map<String, List<double>> _defaultThresholds = <String, List<double>>{
    'temperature': [10.0, 30.0],
    'oxygen': [5.0, 15.0],
    'ph': [6.0, 8.5],
    'turbidity': [0.0, 15.0],
  };

  List<TankModel> get tanks => _tanks;
  bool get isLoading => _isLoading;
  int get pollingSeconds => _pollingSeconds;

  /// 현재 활성 상태이며 아직 닫지 않은 알림 목록
  List<TankAlert> get pendingAlerts => _currentAlerts.values
      .where((a) => !_dismissedAlertKeys.contains(a.key))
      .toList();

  TankProvider() {
    _loadLocalSettings();
    _startBackgroundTimer();
  }

  // 폴링 주기 로드 (임계값은 수조 데이터 조회 시 함께 로드)
  Future<void> _loadLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _pollingSeconds = prefs.getInt('polling_seconds') ?? 1;
    notifyListeners();
  }

  Duration get _pollingDuration => Duration(seconds: _pollingSeconds);

  Future<void> updatePollingInterval(int seconds) async {
    _pollingSeconds = seconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('polling_seconds', seconds);

    if (_pollingTimer != null && _pollingTimer!.isActive) {
      _stopTimer();

      if (_currentMode == PollingMode.main) {
        _pollingTimer = Timer.periodic(_pollingDuration, (_) async {
          await _fetchAllRealtimeData();
        });
      } else if (_currentMode == PollingMode.detail &&
          _currentDetailTankId != null) {
        _pollingTimer = Timer.periodic(_pollingDuration, (_) async {
          await _fetchSpecificRealtimeData(_currentDetailTankId!);
        });
      }
    }
    notifyListeners();
  }

  Future<void> startMainPolling() async {
    _stopTimer();
    _stopBackgroundTimer();
    _currentMode = PollingMode.main;

    _isLoading = true;
    notifyListeners();

    await _fetchAllRealtimeData();

    _isLoading = false;
    notifyListeners();

    _pollingTimer = Timer.periodic(_pollingDuration, (_) async {
      await _fetchAllRealtimeData();
    });
  }

  Future<void> startDetailPolling(String tankId) async {
    _stopTimer();
    _currentMode = PollingMode.detail;
    _currentDetailTankId = tankId;

    try {
      final history = await _apiService.getHistoryData(tankId);
      _tankHistories[tankId] = history;
      _trimHistory(tankId);
    } catch (e) {
      print('History Load Error: $e');
    }

    await _fetchSpecificRealtimeData(tankId);

    _pollingTimer = Timer.periodic(_pollingDuration, (_) async {
      await _fetchSpecificRealtimeData(tankId);
    });
  }

  void stopPolling() {
    _stopTimer();
    _currentMode = PollingMode.none;
    _currentDetailTankId = null;
    _startBackgroundTimer();
  }

  void _stopTimer() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _startBackgroundTimer() {
    _backgroundTimer?.cancel();
    _backgroundTimer = Timer.periodic(_pollingDuration, (_) async {
      await _fetchAllRealtimeData();
    });
  }

  void _stopBackgroundTimer() {
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
  }

  Future<void> _fetchAllRealtimeData() async {
    try {
      final tankIds = await _apiService.getTanks();
      final prefs = await SharedPreferences.getInstance();
      final List<TankModel> updatedTanks = <TankModel>[];

      for (final String tankId in tankIds) {
        final TankModel realtimeData = await _apiService.getRealtimeData(
          tankId,
        );

        final String? savedName = prefs.getString('tank_name_$tankId');
        if (savedName != null) {
          _tankNames[tankId] = savedName;
        }

        final bool isAiControlled =
            prefs.getBool('ai_controlled_$tankId') ??
            realtimeData.isAiControlled;
        updatedTanks.add(realtimeData.copyWith(isAiControlled: isAiControlled));

        // 수조별 임계값 로드
        _tankThresholds.putIfAbsent(tankId, () => {});
        for (final String sensorKey in _defaultThresholds.keys) {
          final double? minValue = prefs.getDouble(
            '${tankId}_${sensorKey}_min',
          );
          final double? maxValue = prefs.getDouble(
            '${tankId}_${sensorKey}_max',
          );

          if (minValue != null && maxValue != null) {
            _tankThresholds[tankId]![sensorKey] = [minValue, maxValue];
          } else {
            _tankThresholds[tankId]![sensorKey] = List.from(
              _defaultThresholds[sensorKey]!,
            );
          }
        }
      }

      _tanks = updatedTanks;
      _updateAlerts();
      notifyListeners();
    } catch (e) {
      print('Main Polling Error: $e');
    }
  }

  void _trimHistory(String tankId) {
    final TankHistoryModel? history = _tankHistories[tankId];
    if (history == null || history.temperature.length <= _maxGraphPoints) {
      return;
    }

    final int removeCount = history.temperature.length - _maxGraphPoints;
    history.temperature.removeRange(0, removeCount);
    history.oxygen.removeRange(0, removeCount);
    history.ph.removeRange(0, removeCount);
    history.turbidity.removeRange(0, removeCount);
  }

  void _appendRealtimeToHistory(String tankId, TankModel newData) {
    final TankHistoryModel? history = _tankHistories[tankId];
    if (history == null) {
      return;
    }

    history.temperature.add(newData.temperature);
    history.oxygen.add(newData.oxygen);
    history.ph.add(newData.ph);
    history.turbidity.add(newData.turbidity);
    _trimHistory(tankId);
  }

  Future<void> _fetchSpecificRealtimeData(String tankId) async {
    try {
      final TankModel updatedData = await _apiService.getRealtimeData(tankId);
      final int tankIndex = _tanks.indexWhere((t) => t.id == tankId);

      if (tankIndex != -1) {
        _tanks[tankIndex] = updatedData.copyWith(
          isAiControlled: _tanks[tankIndex].isAiControlled,
        );
        _appendRealtimeToHistory(tankId, updatedData);
        notifyListeners();
      }
    } catch (e) {
      print('Detail Polling Error: $e');
    }
  }

  Future<void> toggleAiControl(String tankId, bool value) async {
    final int tankIndex = _tanks.indexWhere((t) => t.id == tankId);
    if (tankIndex != -1) {
      _tanks[tankIndex] = _tanks[tankIndex].copyWith(isAiControlled: value);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ai_controlled_$tankId', value);
      notifyListeners();
    }
  }

  TankHistoryModel? getHistory(String tankId) => _tankHistories[tankId];

  String getTankName(String tankId, int index) =>
      _tankNames[tankId] ?? '수조 $index';

  // 수조별 임계값 반환 (미설정 시 기본값 반환)
  List<double> getThreshold(String tankId, String sensorType) {
    if (_tankThresholds.containsKey(tankId) &&
        _tankThresholds[tankId]!.containsKey(sensorType)) {
      return _tankThresholds[tankId]![sensorType]!;
    }
    return _defaultThresholds[sensorType]!;
  }

  // 수조별 임계값 업데이트 및 로컬 저장
  Future<void> updateThreshold(
    String tankId,
    String sensorType,
    double min,
    double max,
  ) async {
    _tankThresholds.putIfAbsent(tankId, () => {});
    _tankThresholds[tankId]![sensorType] = [min, max];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('${tankId}_${sensorType}_min', min);
    await prefs.setDouble('${tankId}_${sensorType}_max', max);
    notifyListeners();
  }

  Future<void> updateTankName(String tankId, String newName) async {
    _tankNames[tankId] = newName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tank_name_$tankId', newName);
    notifyListeners();
  }

  // ──────────────────────────────────────────
  // 알림 관련
  // ──────────────────────────────────────────

  void _updateAlerts() {
    for (final TankModel tank in _tanks) {
      final TankAlert? alert = _computeAlertForTank(tank);
      final TankAlert? existing = _currentAlerts[tank.id];

      if (alert != null) {
        if (existing?.key != alert.key) {
          _dismissedAlertKeys.remove(existing?.key);
        }
        _currentAlerts[tank.id] = alert;
      } else {
        if (existing != null) {
          _dismissedAlertKeys.remove(existing.key);
          _currentAlerts.remove(tank.id);
        }
      }
    }
  }

  TankAlert? _computeAlertForTank(TankModel tank) {
    final List<double> turbidityT = getThreshold(tank.id, 'turbidity');
    if (tank.turbidity < turbidityT[0] || tank.turbidity > turbidityT[1]) {
      return TankAlert(
        tankId: tank.id,
        message: '탁도 이상 감지',
        severity: AlertSeverity.critical,
      );
    }

    final List<double> tempT = getThreshold(tank.id, 'temperature');
    if (tank.temperature < tempT[0] || tank.temperature > tempT[1]) {
      return TankAlert(
        tankId: tank.id,
        message: '수온 이상 감지',
        severity: AlertSeverity.warning,
      );
    }

    final List<double> phT = getThreshold(tank.id, 'ph');
    if (tank.ph < phT[0] || tank.ph > phT[1]) {
      return TankAlert(
        tankId: tank.id,
        message: 'pH 이상 감지',
        severity: AlertSeverity.warning,
      );
    }

    final List<double> oxygenT = getThreshold(tank.id, 'oxygen');
    if (tank.oxygen < oxygenT[0] || tank.oxygen > oxygenT[1]) {
      return TankAlert(
        tankId: tank.id,
        message: '용존산소량 이상 감지',
        severity: AlertSeverity.warning,
      );
    }

    return null;
  }

  void dismissAlert(String tankId) {
    final TankAlert? alert = _currentAlerts[tankId];
    if (alert != null) {
      _dismissedAlertKeys.add(alert.key);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _stopTimer();
    _stopBackgroundTimer();
    super.dispose();
  }
}
