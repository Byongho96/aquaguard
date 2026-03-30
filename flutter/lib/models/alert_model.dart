enum AlertSeverity { warning, critical }

class TankAlert {
  final String tankId;
  final String message;
  final AlertSeverity severity;

  const TankAlert({
    required this.tankId,
    required this.message,
    required this.severity,
  });

  /// 같은 수조의 동일한 이상을 식별하는 키
  String get key => '$tankId:$message';
}
