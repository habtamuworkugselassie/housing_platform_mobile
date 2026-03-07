class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  const NetworkException([String message = 'No internet connection'])
      : super(message);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([String message = 'Session expired. Please log in again.'])
      : super(message, statusCode: 401);
}

class ServerException extends ApiException {
  const ServerException([String message = 'Server error. Please try again later.'])
      : super(message, statusCode: 500);
}

class NotFoundException extends ApiException {
  const NotFoundException([String message = 'Resource not found.'])
      : super(message, statusCode: 404);
}

class ValidationException extends ApiException {
  final Map<String, dynamic>? errors;
  const ValidationException(String message, {this.errors})
      : super(message, statusCode: 400);
}
