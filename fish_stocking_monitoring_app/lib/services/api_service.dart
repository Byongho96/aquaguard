import 'package:dio/dio.dart';
import '../models/tank_model.dart';
import '../core/constants/app_constants.dart';

// UI와 상태 관리 계층이 공통으로 사용하는 API 인터페이스입니다.
abstract class ApiService {
  Future<List<String>> getTanks();
  Future<TankModel> getRealtimeData(String tankId);
  Future<TankHistoryModel> getHistoryData(String tankId);
}

class MockApiService implements ApiService {
  static const Duration _tankListDelay = Duration(milliseconds: 500);
  static const Duration _realtimeDelay = Duration(milliseconds: 300);
  static const Duration _historyDelay = Duration(milliseconds: 500);

  static const List<String> _mockTankIds = <String>[
    'uuid-001',
    'uuid-002',
    'uuid-003',
  ];

  @override
  Future<List<String>> getTanks() async {
    await Future.delayed(_tankListDelay);
    return _mockTankIds;
  }

  @override
  Future<TankModel> getRealtimeData(String tankId) async {
    await Future.delayed(_realtimeDelay);

    if (tankId == 'uuid-001') {
      return TankModel(
        id: tankId,
        temperature: 17.0,
        oxygen: 9.2,
        ph: 8.2,
        turbidity: 23,
        isAiControlled: false,
      );
    }

    if (tankId == 'uuid-002') {
      return TankModel(
        id: tankId,
        temperature: 18.3,
        oxygen: 7.0,
        ph: 7.6,
        turbidity: 5,
        isAiControlled: true,
      );
    }

    return TankModel(
      id: tankId,
      temperature: 14.0,
      oxygen: 8.6,
      ph: 8.2,
      turbidity: 12,
      isAiControlled: false,
    );
  }

  @override
  Future<TankHistoryModel> getHistoryData(String tankId) async {
    await Future.delayed(_historyDelay);

    return TankHistoryModel.fromJson(tankId, <String, List<num>>{
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
      'oxygen': <num>[
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
      'ph': <num>[
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
      'turbidity': <num>[
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
    });
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

  @override
  Future<List<String>> getTanks() async {
    try {
      final response = await _dio.get('/tanks');
      // 응답 예시: { "tanks": ["uuid-001", "uuid-002", "uuid-003"] }
      final List<dynamic> tankList = response.data['tanks'];
      return tankList.map((e) => e.toString()).toList();
    } catch (e) {
      print('수조 목록 불러오기 실패: $e');
      throw Exception('Failed to load tanks');
    }
  }

  @override
  Future<TankModel> getRealtimeData(String tankId) async {
    try {
      final response = await _dio.get('/tanks/$tankId/realtime');
      // 응답 데이터를 TankModel로 변환
      return TankModel.fromJson(tankId, response.data);
    } catch (e) {
      print('실시간 데이터 불러오기 실패 ($tankId): $e');
      throw Exception('Failed to load realtime data');
    }
  }

  @override
  Future<TankHistoryModel> getHistoryData(String tankId) async {
    try {
      final response = await _dio.get('/tanks/$tankId/history');
      // 응답 데이터를 TankHistoryModel로 변환
      return TankHistoryModel.fromJson(tankId, response.data);
    } catch (e) {
      print('과거 데이터 불러오기 실패 ($tankId): $e');
      throw Exception('Failed to load history data');
    }
  }
}
