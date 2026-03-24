class TankModel {
  final String id;
  final double temperature;
  final double oxygen;
  final double ph;
  final double turbidity;
  bool isAiControlled;

  TankModel({
    required this.id,
    required this.temperature,
    required this.oxygen,
    required this.ph,
    required this.turbidity,
    this.isAiControlled = false,
  });

  // API 응답을 화면에서 사용하는 모델로 변환합니다.
  factory TankModel.fromJson(String id, Map<String, dynamic> json) {
    return TankModel(
      id: id,
      temperature: (json['temperature'] as num).toDouble(),
      oxygen: (json['oxygen'] as num).toDouble(),
      ph: (json['ph'] as num).toDouble(),
      turbidity: (json['turbidity'] as num).toDouble(),
    );
  }

  TankModel copyWith({
    double? temperature,
    double? oxygen,
    double? ph,
    double? turbidity,
    bool? isAiControlled,
  }) {
    return TankModel(
      id: id,
      temperature: temperature ?? this.temperature,
      oxygen: oxygen ?? this.oxygen,
      ph: ph ?? this.ph,
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
  final List<double> ph;
  final List<double> turbidity;

  TankHistoryModel({
    required this.id,
    required this.temperature,
    required this.oxygen,
    required this.ph,
    required this.turbidity,
  });

  // 배열 형태의 센서 이력을 모델로 변환합니다.
  factory TankHistoryModel.fromJson(String id, Map<String, dynamic> json) {
    return TankHistoryModel(
      id: id,
      temperature: List<double>.from(
        json['temperature'].map((value) => value.toDouble()),
      ),
      oxygen: List<double>.from(json['oxygen'].map((value) => value.toDouble())),
      ph: List<double>.from(json['ph'].map((value) => value.toDouble())),
      turbidity: List<double>.from(
        json['turbidity'].map((value) => value.toDouble()),
      ),
    );
  }
}
