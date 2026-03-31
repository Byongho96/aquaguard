class AppConstants {
  // API 통신에 사용하는 기본 주소입니다.
  static const String baseUrl = 'http://163.152.172.77:8080';

  // WebSocket(STOMP) 접속 주소입니다.
  static const String wsUrl = 'ws://163.152.172.77:8080/ws';

  // 개발 단계에서는 목업 데이터를 사용합니다.
  static const bool useMockData = false;
}
