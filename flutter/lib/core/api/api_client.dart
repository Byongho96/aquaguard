class ApiClient {
  const ApiClient();

  static const Duration _mockDelay = Duration(milliseconds: 300);

  Future<Map<String, dynamic>> get(String path) async {
    await Future<void>.delayed(_mockDelay);

    return <String, dynamic>{
      'path': path,
      'message': 'Mock GET response',
    };
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    await Future<void>.delayed(_mockDelay);

    return <String, dynamic>{
      'path': path,
      'message': 'Mock POST response',
      'data': data ?? <String, dynamic>{},
    };
  }
}
