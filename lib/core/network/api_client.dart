import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'api_config.dart';
import 'api_exceptions.dart';

class ApiClient {
  /// Use shared config so release builds can point to Droplet via --dart-define=API_BASE_URL=...
  static String get baseUrl => ApiConfig.baseUrl;
  static String get baseOrigin => ApiConfig.baseOrigin;

  late final Dio _dio;
  final FlutterSecureStorage _storage;

  ApiClient({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Retrieve token and attach to requests
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401 && _isTokenExpiredError(e)) {
          // Attempt to refresh token
          final isRefreshed = await _refreshToken();
          if (isRefreshed) {
            try {
              // Retry the original request
              final cloneReq = await _retry(e.requestOptions);
              return handler.resolve(cloneReq);
            } on DioException catch (retryError) {
              return handler.next(_handleError(retryError));
            }
          } else {
            // Failed to refresh token, log out
            await _storage.deleteAll();
            return handler.next(DioException(
              requestOptions: e.requestOptions,
              error: const UnauthorizedException('Session expired. Please log in again.'),
            ));
          }
        }
        return handler.next(_handleError(e));
      },
    ));

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ));
    }
  }

  bool _isTokenExpiredError(DioException e) {
    // Customize logic based on your backend response if needed
    // Typically, receiving a 401 is treated as token expiration for guarded endpoints.
    final path = e.requestOptions.path;
    if (path.contains('/auth/login') || path.contains('/auth/refresh')) {
      return false; // Don't try to refresh if the refresh or login itself failed with 401
    }
    return true;
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;

      final response = await Dio(BaseOptions(baseUrl: ApiConfig.baseUrl)).post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['accessToken'];
        final newRefreshToken = response.data['refreshToken'];
        
        if (newAccessToken != null) {
          await _storage.write(key: 'access_token', value: newAccessToken);
          if (newRefreshToken != null) {
             await _storage.write(key: 'refresh_token', value: newRefreshToken);
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );
    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  DioException _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return DioException(
        requestOptions: e.requestOptions,
        error: const NetworkException('Please check your internet connection.'),
      );
    }
    
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;
      String message = 'An error occurred';

      if (data is Map<String, dynamic> && data.containsKey('message')) {
        message = data['message'].toString();
      }

      switch (statusCode) {
        case 400:
          return DioException(
            requestOptions: e.requestOptions,
            error: ValidationException(message, errors: data is Map<String, dynamic> ? data : null),
          );
        case 401:
          return DioException(
            requestOptions: e.requestOptions,
            error: const UnauthorizedException('Invalid credentials or session expired.'),
          );
        case 403:
          return DioException(
            requestOptions: e.requestOptions,
            error: ServerException('Access denied: $message'),
          );
        case 404:
          return DioException(
            requestOptions: e.requestOptions,
            error: NotFoundException(message),
          );
        case 500:
        default:
          return DioException(
            requestOptions: e.requestOptions,
            error: ServerException(message),
          );
      }
    }

    return e;
  }

  // HTTP Methods wrappers
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.post(path, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // Needed for file uploads
  Future<Response> postForm(String path, {required FormData data}) async {
     try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }
}
