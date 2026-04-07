import 'package:dio/dio.dart';
import '../models/tank_model.dart';
import '../core/constants/app_constants.dart';

// UI와 상태 관리 계층이 공통으로 사용하는 API 인터페이스입니다.
abstract class ApiService {
  Future<List<TankSummaryModel>> getTanks();
  Future<TankHistoryModel> getHistoryData(String tankId);
  Future<List<double>> getSensorRange(String tankId, String sensorId);
  Future<List<double>> updateSensorRange(
    String tankId,
    String sensorId,
    double min,
    double max,
  );
  Future<bool> getAiEnableState(String tankId);
  Future<bool> updateAiEnableState(String tankId, bool state);
  Future<bool> getSensorControlState(String tankId, String sensorId);
  Future<bool> updateSensorControlState(
    String tankId,
    String sensorId,
    bool state,
  );
}

class MockApiService implements ApiService {
  static const Duration _tankListDelay = Duration(milliseconds: 500);
  static const Duration _historyDelay = Duration(milliseconds: 500);
  static const Duration _rangeDelay = Duration(milliseconds: 200);

  static const List<String> _mockTankIds = <String>['1', '2', '3'];

  final Map<String, Map<String, List<double>>> _mockRanges =
      <String, Map<String, List<double>>>{};
  final Map<String, bool> _mockAiEnableStates = <String, bool>{};
  final Map<String, Map<String, bool>> _mockSensorControlStates =
      <String, Map<String, bool>>{};

  void _logMockResponse(String method, String path, dynamic body) {
    print('[MOCK API] $method $path -> $body');
  }

  List<double> _defaultRangeForSensor(String sensorId) {
    switch (sensorId) {
      case 'temperature':
        return <double>[10.0, 30.0];
      case 'do':
        return <double>[5.0, 15.0];
      case 'salt':
        return <double>[0.0, 40.0];
      case 'ntu':
        return <double>[0.0, 15.0];
      default:
        return <double>[0.0, 100.0];
    }
  }

  Map<String, List<double>> _ensureTankRangeMap(String tankId) {
    return _mockRanges.putIfAbsent(tankId, () {
      return <String, List<double>>{
        'temperature': _defaultRangeForSensor('temperature'),
        'do': _defaultRangeForSensor('do'),
        'salt': _defaultRangeForSensor('salt'),
        'ntu': _defaultRangeForSensor('ntu'),
      };
    });
  }

  Map<String, bool> _ensureSensorControlMap(String tankId) {
    return _mockSensorControlStates.putIfAbsent(tankId, () {
      return <String, bool>{
        'temperature': true,
        'do': false,
        'salt': false,
        'ntu': false,
      };
    });
  }

  @override
  Future<List<TankSummaryModel>> getTanks() async {
    await Future.delayed(_tankListDelay);
    final List<TankSummaryModel> tanks = _mockTankIds.map((tankId) {
      final Map<String, bool> controls = _ensureSensorControlMap(tankId);
      return TankSummaryModel(
        tankId: tankId,
        sensors: controls.entries
            .map(
              (entry) => TankSensorControlModel(
                sensorId: entry.key,
                state: entry.value,
              ),
            )
            .toList(),
      );
    }).toList();
    _logMockResponse('GET', '/tanks', tanks);
    return tanks;
  }

  @override
  Future<TankHistoryModel> getHistoryData(String tankId) async {
    await Future.delayed(_historyDelay);

    final Map<String, List<num>> payload = <String, List<num>>{
      'temperature': <num>[
        36,
        32,
        50,
        42,
        46,
        36,
        32,
        50,
        42,
        46,
        36,
        32,
        50,
        42,
        46,
        36,
        32,
        50,
        42,
        46,
      ],
      'do': <num>[
        9.2,
        8.2,
        9.1,
        9.0,
        9.1,
        9.2,
        8.2,
        9.1,
        9.0,
        9.1,
        9.2,
        8.2,
        9.1,
        9.0,
        9.1,
        9.2,
        8.2,
        9.1,
        9.0,
        9.1,
      ],
      'salt': <num>[
        8.2,
        8.2,
        8.1,
        8.0,
        9.0,
        8.2,
        8.2,
        8.1,
        8.0,
        9.0,
        8.2,
        8.2,
        8.1,
        8.0,
        9.0,
        8.2,
        8.2,
        8.1,
        8.0,
        9.0,
      ],
      'ntu': <num>[
        23,
        22,
        23,
        21,
        24,
        23,
        22,
        23,
        21,
        24,
        23,
        22,
        23,
        21,
        24,
        23,
        22,
        23,
        21,
        24,
      ],
    };
    _logMockResponse('GET', '/tanks/$tankId/history', payload);
    return TankHistoryModel.fromJson(tankId, payload);
  }

  @override
  Future<List<double>> getSensorRange(String tankId, String sensorId) async {
    await Future.delayed(_rangeDelay);
    final Map<String, List<double>> ranges = _ensureTankRangeMap(tankId);
    final List<double> range =
        ranges[sensorId] ?? _defaultRangeForSensor(sensorId);
    final Map<String, double> payload = <String, double>{
      'min': range[0],
      'max': range[1],
    };
    _logMockResponse('GET', '/tanks/$tankId/$sensorId/range', payload);
    return <double>[range[0], range[1]];
  }

  @override
  Future<List<double>> updateSensorRange(
    String tankId,
    String sensorId,
    double min,
    double max,
  ) async {
    await Future.delayed(_rangeDelay);
    final Map<String, List<double>> ranges = _ensureTankRangeMap(tankId);
    ranges[sensorId] = <double>[min, max];
    _logMockResponse('POST', '/tanks/$tankId/$sensorId/range', <String, double>{
      'min': min,
      'max': max,
    });
    return <double>[min, max];
  }

  @override
  Future<bool> getAiEnableState(String tankId) async {
    await Future.delayed(_rangeDelay);
    final bool state = _mockAiEnableStates[tankId] ?? false;
    _logMockResponse('GET', '/tanks/$tankId/aienable', <String, bool>{
      'state': state,
    });
    return state;
  }

  @override
  Future<bool> updateAiEnableState(String tankId, bool state) async {
    await Future.delayed(_rangeDelay);
    _mockAiEnableStates[tankId] = state;
    _logMockResponse('POST', '/tanks/$tankId/aienable', <String, bool>{
      'state': state,
    });
    return state;
  }

  @override
  Future<bool> getSensorControlState(String tankId, String sensorId) async {
    await Future.delayed(_rangeDelay);
    final Map<String, bool> controls = _ensureSensorControlMap(tankId);
    final bool state = controls[sensorId] ?? false;
    _logMockResponse('GET', '/tanks/$tankId/$sensorId/control', <String, bool>{
      'state': state,
    });
    return state;
  }

  @override
  Future<bool> updateSensorControlState(
    String tankId,
    String sensorId,
    bool state,
  ) async {
    await Future.delayed(_rangeDelay);
    final Map<String, bool> controls = _ensureSensorControlMap(tankId);
    controls[sensorId] = state;
    _logMockResponse('POST', '/tanks/$tankId/$sensorId/control', <String, bool>{
      'state': state,
    });
    return state;
  }
}

class DioApiService implements ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl, // 'https://api.aquaguard.com' (예시)
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    ),
  );

  void _logDioResponse(Response<dynamic> response) {
    final method = response.requestOptions.method;
    final path = response.requestOptions.path;
    print('[API] $method $path -> ${response.data}');
  }

  @override
  Future<List<TankSummaryModel>> getTanks() async {
    try {
      final response = await _dio.get('/tanks');
      _logDioResponse(response);
      final Map<String, dynamic> json = response.data as Map<String, dynamic>;
      final List<dynamic> tankList = json['tanks'] as List<dynamic>;
      return tankList
          .map((e) => TankSummaryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('수조 목록 불러오기 실패: $e');
      throw Exception('Failed to load tanks');
    }
  }

  @override
  Future<TankHistoryModel> getHistoryData(String tankId) async {
    try {
      final response = await _dio.get('/tanks/$tankId/history');
      _logDioResponse(response);
      // 응답 데이터를 TankHistoryModel로 변환
      return TankHistoryModel.fromJson(tankId, response.data);
    } catch (e) {
      print('과거 데이터 불러오기 실패 ($tankId): $e');
      throw Exception('Failed to load history data');
    }
  }

  @override
  Future<List<double>> getSensorRange(String tankId, String sensorId) async {
    try {
      final response = await _dio.get('/tanks/$tankId/$sensorId/range');
      _logDioResponse(response);
      final Map<String, dynamic> json = response.data as Map<String, dynamic>;
      return <double>[
        (json['min'] as num).toDouble(),
        (json['max'] as num).toDouble(),
      ];
    } catch (e) {
      print('센서 범위 조회 실패 ($tankId/$sensorId): $e');
      throw Exception('Failed to load sensor range');
    }
  }

  @override
  Future<List<double>> updateSensorRange(
    String tankId,
    String sensorId,
    double min,
    double max,
  ) async {
    try {
      final response = await _dio.post(
        '/tanks/$tankId/$sensorId/range',
        data: <String, double>{'min': min, 'max': max},
      );
      _logDioResponse(response);
      final Map<String, dynamic> json = response.data as Map<String, dynamic>;
      return <double>[
        (json['min'] as num).toDouble(),
        (json['max'] as num).toDouble(),
      ];
    } catch (e) {
      print('센서 범위 업데이트 실패 ($tankId/$sensorId): $e');
      throw Exception('Failed to update sensor range');
    }
  }

  @override
  Future<bool> getAiEnableState(String tankId) async {
    try {
      final response = await _dio.get('/tanks/$tankId/aienable');
      _logDioResponse(response);
      final Map<String, dynamic> json = response.data as Map<String, dynamic>;
      return json['state'] as bool;
    } catch (e) {
      print('AI 제어 상태 조회 실패 ($tankId): $e');
      throw Exception('Failed to load AI enable state');
    }
  }

  @override
  Future<bool> updateAiEnableState(String tankId, bool state) async {
    try {
      final response = await _dio.post(
        '/tanks/$tankId/aienable',
        data: <String, bool>{'state': state},
      );
      _logDioResponse(response);
      final Map<String, dynamic> json = response.data as Map<String, dynamic>;
      return json['state'] as bool;
    } catch (e) {
      print('AI 제어 상태 업데이트 실패 ($tankId): $e');
      throw Exception('Failed to update AI enable state');
    }
  }

  @override
  Future<bool> getSensorControlState(String tankId, String sensorId) async {
    try {
      final response = await _dio.get('/tanks/$tankId/$sensorId/control');
      _logDioResponse(response);
      final Map<String, dynamic> json = response.data as Map<String, dynamic>;
      return json['state'] as bool;
    } catch (e) {
      print('센서 자동제어 상태 조회 실패 ($tankId/$sensorId): $e');
      throw Exception('Failed to load sensor control state');
    }
  }

  @override
  Future<bool> updateSensorControlState(
    String tankId,
    String sensorId,
    bool state,
  ) async {
    try {
      final response = await _dio.post(
        '/tanks/$tankId/$sensorId/control',
        data: <String, bool>{'state': state},
      );
      _logDioResponse(response);
      final Map<String, dynamic> json = response.data as Map<String, dynamic>;
      return json['state'] as bool;
    } catch (e) {
      print('센서 자동제어 상태 업데이트 실패 ($tankId/$sensorId): $e');
      throw Exception('Failed to update sensor control state');
    }
  }
}
