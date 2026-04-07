import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../models/alert_model.dart';
import '../models/tank_model.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

class TankProvider with ChangeNotifier {
  final ApiService _apiService = AppConstants.useMockData
      ? MockApiService()
      : DioApiService();
  final WebSocketService _wsService = WebSocketService();

  List<TankModel> _tanks = [];
  bool _isLoading = false;

  String? _currentDetailTankId;

  // 현재 활성 상태의 알림 (alertKey -> TankAlert)
  final Map<String, TankAlert> _currentAlerts = {};
  // 사용자가 닫은 알림 키 (tankId:message)
  final Set<String> _dismissedAlertKeys = {};

  final Map<String, String> _tankNames = <String, String>{};
  final Map<String, TankHistoryModel> _tankHistories =
      <String, TankHistoryModel>{};
  final Map<String, Map<String, bool>> _tankSensorControlStates =
      <String, Map<String, bool>>{};
  static const int _maxGraphPoints = 20;

  // 🎯 전역 설정에서 수조별(tankId) 설정으로 변경
  final Map<String, Map<String, List<double>>> _tankThresholds = {};

  final Map<String, List<double>> _defaultThresholds = <String, List<double>>{
    'temperature': [10.0, 30.0],
    'oxygen': [5.0, 15.0],
    'salt': [0.0, 40.0],
    'turbidity': [0.0, 15.0],
  };
  static const List<String> _sensorKeys = <String>[
    'temperature',
    'oxygen',
    'salt',
    'turbidity',
  ];
  static const List<String> _controllableSensorKeys = <String>[
    'temperature',
    'oxygen',
    'turbidity',
  ];

  List<TankModel> get tanks => _tanks;
  bool get isLoading => _isLoading;

  /// 현재 활성 상태이며 아직 닫지 않은 알림 목록
  List<TankAlert> get pendingAlerts => _currentAlerts.values
      .where((a) => !_dismissedAlertKeys.contains(a.key))
      .toList();

  TankProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    // 수조 목록 불러오기
    try {
      final tankSummaries = await _apiService.getTanks();
      _tanks = tankSummaries
          .map(
            (tank) => TankModel(
              id: tank.tankId,
              temperature: 0,
              oxygen: 0,
              salt: 0,
              turbidity: 0,
            ),
          )
          .toList();

      for (final tank in tankSummaries) {
        _tankSensorControlStates[tank.tankId] = _sensorControlMapFromSummary(
          tank,
        );
      }

      await Future.wait(
        tankSummaries.map((tank) async {
          await Future.wait([
            _loadThresholdsForTank(tank.tankId),
            _loadAiEnableStateForTank(tank.tankId),
          ]);
        }),
      );
    } catch (e) {
      print('Tank list load error: $e');
    }

    // WebSocket 연결 및 구독
    _wsService.connect(onData: _onRealtimeData);

    // 연결 완료 후 구독 (약간의 대기)
    await Future.delayed(const Duration(milliseconds: 500));
    for (final tank in _tanks) {
      _wsService.subscribeTank(tank.id);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _onRealtimeData(TankModel data) async {
    final prefs = await SharedPreferences.getInstance();

    // 수조 이름 로드
    final String? savedName = prefs.getString('tank_name_${data.id}');
    if (savedName != null) {
      _tankNames[data.id] = savedName;
    }

    // 기존 수조 항목의 AI 제어 상태를 유지합니다.
    final int idx = _tanks.indexWhere((t) => t.id == data.id);
    final bool isAiControlled = idx != -1
        ? _tanks[idx].isAiControlled
        : data.isAiControlled;
    final TankModel updatedData = data.copyWith(isAiControlled: isAiControlled);

    // 수조별 임계값은 서버에서 조회합니다.
    if (!_tankThresholds.containsKey(data.id)) {
      await _loadThresholdsForTank(data.id);
    }

    if (!_tankSensorControlStates.containsKey(data.id)) {
      await _loadSensorControlStatesForTank(data.id);
    }

    // 수조 목록 업데이트
    if (idx != -1) {
      _tanks[idx] = updatedData;
    } else {
      _tanks.add(updatedData);
      await _loadSensorControlStatesForTank(data.id);
      await _loadAiEnableStateForTank(data.id);
    }

    // 상세 페이지 히스토리 추가
    if (_currentDetailTankId == data.id) {
      _appendRealtimeToHistory(data.id, updatedData);
    }

    _updateAlerts();
    notifyListeners();
  }

  Future<void> startDetailView(String tankId) async {
    _currentDetailTankId = tankId;

    try {
      if (!_tankThresholds.containsKey(tankId)) {
        await _loadThresholdsForTank(tankId);
      }
      if (!_tankSensorControlStates.containsKey(tankId)) {
        await _loadSensorControlStatesForTank(tankId);
      }
      final history = await _apiService.getHistoryData(tankId);
      _tankHistories[tankId] = history;
      _trimHistory(tankId);
      notifyListeners();
    } catch (e) {
      print('History Load Error: $e');
    }
  }

  void stopDetailView() {
    _currentDetailTankId = null;
  }

  void _trimHistory(String tankId) {
    final TankHistoryModel? history = _tankHistories[tankId];
    if (history == null || history.temperature.length <= _maxGraphPoints) {
      return;
    }

    final int removeCount = history.temperature.length - _maxGraphPoints;
    history.temperature.removeRange(0, removeCount);
    history.oxygen.removeRange(0, removeCount);
    history.salt.removeRange(0, removeCount);
    history.turbidity.removeRange(0, removeCount);
  }

  void _appendRealtimeToHistory(String tankId, TankModel newData) {
    final TankHistoryModel? history = _tankHistories[tankId];
    if (history == null) {
      return;
    }

    history.temperature.add(newData.temperature);
    history.oxygen.add(newData.oxygen);
    history.salt.add(newData.salt);
    history.turbidity.add(newData.turbidity);
    _trimHistory(tankId);
  }

  Future<void> toggleAiControl(String tankId, bool value) async {
    final int tankIndex = _tanks.indexWhere((t) => t.id == tankId);
    if (tankIndex != -1) {
      final bool previousValue = _tanks[tankIndex].isAiControlled;
      _tanks[tankIndex] = _tanks[tankIndex].copyWith(isAiControlled: value);
      notifyListeners();

      try {
        final bool updatedState = await _apiService.updateAiEnableState(
          tankId,
          value,
        );
        _tanks[tankIndex] = _tanks[tankIndex].copyWith(
          isAiControlled: updatedState,
        );
      } catch (e) {
        _tanks[tankIndex] = _tanks[tankIndex].copyWith(
          isAiControlled: previousValue,
        );
        print('AI control update error ($tankId): $e');
      }
      notifyListeners();
    }
  }

  Future<void> _loadAiEnableStateForTank(String tankId) async {
    try {
      final bool state = await _apiService.getAiEnableState(tankId);
      final int tankIndex = _tanks.indexWhere((t) => t.id == tankId);
      if (tankIndex != -1) {
        _tanks[tankIndex] = _tanks[tankIndex].copyWith(isAiControlled: state);
      }
    } catch (_) {
      // 서버 조회 실패 시 기본값(false)을 유지합니다.
    }
  }

  Map<String, bool> _sensorControlMapFromSummary(TankSummaryModel tank) {
    final Map<String, bool> mapped = <String, bool>{
      'temperature': false,
      'oxygen': false,
      'turbidity': false,
    };

    for (final sensor in tank.sensors) {
      final String? key = _sensorKeyFromSensorId(sensor.sensorId);
      if (key != null && mapped.containsKey(key)) {
        mapped[key] = sensor.state;
      }
    }

    return mapped;
  }

  String? _sensorKeyFromSensorId(String sensorId) {
    switch (sensorId) {
      case 'temperature':
        return 'temperature';
      case 'do':
        return 'oxygen';
      case 'ntu':
        return 'turbidity';
      case 'salt':
        return 'salt';
      default:
        return null;
    }
  }

  bool getSensorControlState(String tankId, String sensorKey) {
    return _tankSensorControlStates[tankId]?[sensorKey] ?? false;
  }

  Future<void> toggleSensorControl(
    String tankId,
    String sensorKey,
    bool value,
  ) async {
    if (!_controllableSensorKeys.contains(sensorKey)) {
      return;
    }

    _tankSensorControlStates.putIfAbsent(tankId, () => <String, bool>{});
    final bool previous = _tankSensorControlStates[tankId]?[sensorKey] ?? false;
    _tankSensorControlStates[tankId]![sensorKey] = value;
    notifyListeners();

    try {
      final String sensorId = _sensorIdFromKey(sensorKey);
      final bool updated = await _apiService.updateSensorControlState(
        tankId,
        sensorId,
        value,
      );
      _tankSensorControlStates[tankId]![sensorKey] = updated;
    } catch (e) {
      _tankSensorControlStates[tankId]![sensorKey] = previous;
      print('Sensor control update error ($tankId/$sensorKey): $e');
      rethrow;
    }

    notifyListeners();
  }

  Future<void> _loadSensorControlStatesForTank(String tankId) async {
    _tankSensorControlStates.putIfAbsent(tankId, () => <String, bool>{});

    for (final String sensorKey in _controllableSensorKeys) {
      final String sensorId = _sensorIdFromKey(sensorKey);
      try {
        final bool state = await _apiService.getSensorControlState(
          tankId,
          sensorId,
        );
        _tankSensorControlStates[tankId]![sensorKey] = state;
      } catch (_) {
        _tankSensorControlStates[tankId]!.putIfAbsent(sensorKey, () => false);
      }
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
    final String sensorId = _sensorIdFromKey(sensorType);
    final List<double> updatedRange = await _apiService.updateSensorRange(
      tankId,
      sensorId,
      min,
      max,
    );
    _tankThresholds[tankId]![sensorType] = updatedRange;
    notifyListeners();
  }

  String _sensorIdFromKey(String sensorKey) {
    switch (sensorKey) {
      case 'oxygen':
        return 'do';
      case 'turbidity':
        return 'ntu';
      case 'salt':
        return 'salt';
      case 'temperature':
      default:
        return 'temperature';
    }
  }

  Future<void> _loadThresholdsForTank(String tankId) async {
    _tankThresholds.putIfAbsent(tankId, () => {});

    for (final String sensorKey in _sensorKeys) {
      final String sensorId = _sensorIdFromKey(sensorKey);
      try {
        final List<double> range = await _apiService.getSensorRange(
          tankId,
          sensorId,
        );
        _tankThresholds[tankId]![sensorKey] = range;
      } catch (_) {
        _tankThresholds[tankId]![sensorKey] = List<double>.from(
          _defaultThresholds[sensorKey]!,
        );
      }
    }
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
    final Map<String, TankAlert> nextAlerts = <String, TankAlert>{};

    for (final TankModel tank in _tanks) {
      for (final TankAlert alert in _computeAlertsForTank(tank)) {
        nextAlerts[alert.key] = alert;
      }
    }

    final List<String> removedKeys = _currentAlerts.keys
        .where((key) => !nextAlerts.containsKey(key))
        .toList();
    for (final key in removedKeys) {
      _dismissedAlertKeys.remove(key);
    }

    _currentAlerts
      ..clear()
      ..addAll(nextAlerts);
  }

  List<TankAlert> _computeAlertsForTank(TankModel tank) {
    final List<TankAlert> alerts = <TankAlert>[];

    final List<double> turbidityT = getThreshold(tank.id, 'turbidity');
    if (tank.turbidity < turbidityT[0] || tank.turbidity > turbidityT[1]) {
      alerts.add(
        TankAlert(
        tankId: tank.id,
        message: '탁도 이상 감지',
        severity: AlertSeverity.critical,
        ),
      );
    }

    final List<double> tempT = getThreshold(tank.id, 'temperature');
    if (tank.temperature < tempT[0] || tank.temperature > tempT[1]) {
      alerts.add(
        TankAlert(
        tankId: tank.id,
        message: '온도 이상 감지',
        severity: AlertSeverity.warning,
        ),
      );
    }

    final List<double> saltT = getThreshold(tank.id, 'salt');
    if (tank.salt < saltT[0] || tank.salt > saltT[1]) {
      alerts.add(
        TankAlert(
        tankId: tank.id,
        message: '염도 이상 감지',
        severity: AlertSeverity.warning,
        ),
      );
    }

    final List<double> oxygenT = getThreshold(tank.id, 'oxygen');
    if (tank.oxygen < oxygenT[0] || tank.oxygen > oxygenT[1]) {
      alerts.add(
        TankAlert(
        tankId: tank.id,
        message: '용존산소량 이상 감지',
        severity: AlertSeverity.warning,
        ),
      );
    }

    return alerts;
  }

  void dismissAlert(String alertKey) {
    if (_currentAlerts.containsKey(alertKey)) {
      _dismissedAlertKeys.add(alertKey);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _wsService.disconnect();
    super.dispose();
  }
}
