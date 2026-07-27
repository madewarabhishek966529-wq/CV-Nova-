/// Thrown by [ApiClient] for any non-2xx response. Carries the server's
/// `detail` message (FastAPI's standard error shape) when available, so UI
/// code can show it directly instead of a generic "something went wrong".
class ApiException implements Exception {
  const ApiException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  bool get isUnauthorized => statusCode == 401;
  bool get isConflict => statusCode == 409;
  bool get isValidationError => statusCode == 422;

  @override
  String toString() => message;
}

/// Thrown when a request fails before reaching the server — no connection,
/// DNS failure, timeout. Distinct from [ApiException] so the UI can show
/// "check your connection" instead of a server error message.
class NetworkException implements Exception {
  const NetworkException([this.message = 'Could not reach the server. Check your connection.']);

  final String message;

  @override
  String toString() => message;
}
