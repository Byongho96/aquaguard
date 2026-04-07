class TankSensorControlModel {
  final String sensorId;
  final bool state;

  const TankSensorControlModel({required this.sensorId, required this.state});

  factory TankSensorControlModel.fromJson(Map<String, dynamic> json) {
    return TankSensorControlModel(
      sensorId: json['sensorId'].toString(),
      state: json['state'] == true,
    );
  }
}

class TankSummaryModel {
  final String tankId;
  final List<TankSensorControlModel> sensors;

  const TankSummaryModel({required this.tankId, required this.sensors});

  factory TankSummaryModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> sensorList =
        json['sensors'] as List<dynamic>? ?? <dynamic>[];
    return TankSummaryModel(
      tankId: json['tankId'].toString(),
      sensors: sensorList
          .map(
            (sensor) =>
                TankSensorControlModel.fromJson(sensor as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class TankModel {
  final String id;
  final double temperature;
  final double oxygen;
  final double salt;
  final double turbidity;
  bool isAiControlled;

  TankModel({
    required this.id,
    required this.temperature,
    required this.oxygen,
    required this.salt,
    required this.turbidity,
    this.isAiControlled = false,
  });

  // API 응답을 화면에서 사용하는 모델로 변환합니다.
  factory TankModel.fromJson(String id, Map<String, dynamic> json) {
    return TankModel(
      id: id,
      temperature: (json['temperature'] as num).toDouble(),
      oxygen: (json['do'] as num).toDouble(),
      salt: (json['salt'] as num).toDouble(),
      turbidity: (json['ntu'] as num).toDouble(),
    );
  }

  // WebSocket(STOMP) 응답을 모델로 변환합니다.
  factory TankModel.fromWebSocket(String tankId, Map<String, dynamic> json) {
    return TankModel(
      id: tankId,
      temperature: (json['temperature'] as num).toDouble(),
      oxygen: (json['do'] as num).toDouble(),
      salt: (json['salt'] as num).toDouble(),
      turbidity: (json['ntu'] as num).toDouble(),
    );
  }

  TankModel copyWith({
    double? temperature,
    double? oxygen,
    double? salt,
    double? turbidity,
    bool? isAiControlled,
  }) {
    return TankModel(
      id: id,
      temperature: temperature ?? this.temperature,
      oxygen: oxygen ?? this.oxygen,
      salt: salt ?? this.salt,
      turbidity: turbidity ?? this.turbidity,
      isAiControlled: isAiControlled ?? this.isAiControlled,
    );
  }
}

// 상세 화면 그래프에 사용하는 시계열 데이터입니다.
class TankHistoryModel {
  final String id;
  final List<double> temperature;
  final List<double> oxygen;
  final List<double> salt;
  final List<double> turbidity;

  TankHistoryModel({
    required this.id,
    required this.temperature,
    required this.oxygen,
    required this.salt,
    required this.turbidity,
  });

  // 배열 형태의 센서 이력을 모델로 변환합니다.
  factory TankHistoryModel.fromJson(String id, Map<String, dynamic> json) {
    return TankHistoryModel(
      id: id,
      temperature: List<double>.from(
        json['temperature'].map((value) => value.toDouble()),
      ),
      oxygen: List<double>.from(json['do'].map((value) => value.toDouble())),
      salt: List<double>.from(json['salt'].map((value) => value.toDouble())),
      turbidity: List<double>.from(
        json['ntu'].map((value) => value.toDouble()),
      ),
    );
  }
}
