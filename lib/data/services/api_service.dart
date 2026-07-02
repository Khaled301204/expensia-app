import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../app.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/api_constants.dart';
import '../../routes/app_router.dart';
import 'storage_service.dart';

class ApiService {
  late final Dio _dio;
  final StorageService _storageService = StorageService();

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(milliseconds: AppConfig.apiTimeout),
        receiveTimeout: const Duration(milliseconds: AppConfig.apiTimeout),
        headers: {
          ApiConstants.contentType: ApiConstants.applicationJson,
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token to requests
          final token = await _storageService.getToken();
          if (token != null) {
            options.headers[ApiConstants.authorization] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == ApiConstants.unauthorized) {
            final path = error.requestOptions.path;
            // Don't redirect when the 401 comes from auth endpoints themselves
            // (e.g. wrong password on login returns 401 too).
            final isAuthCall = path.contains('/auth/');
            if (!isAuthCall) {
              await _storageService.clearAll();
              navigatorKey.currentState
                  ?.pushNamedAndRemoveUntil(AppRouter.login, (_) => false);
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  // GET Request
  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(
        endpoint,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // POST Request
  Future<Response> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PUT Request
  Future<Response> put(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PATCH Request
  Future<Response> patch(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.patch(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE Request
  Future<Response> delete(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.delete(
        endpoint,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Fetch raw bytes (for CSV/PDF export)
  Future<List<int>> fetchBytes(String endpoint) async {
    try {
      final response = await _dio.get<List<int>>(
        endpoint,
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Upload File (for voice expense)
  Future<Response> uploadFile(
    String endpoint,
    String filePath, {
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      FormData formData;
      if (kIsWeb) {
        // On web, record package returns a blob: URL.
        // _dio has a baseUrl so it can't fetch blob: URLs directly — use a
        // bare Dio instance instead (same-origin XHR can access blob: URLs).
        final blobDio = Dio();
        final blobRes = await blobDio.get<List<int>>(
          filePath,
          options: Options(responseType: ResponseType.bytes),
        );
        formData = FormData.fromMap({
          'audio': MultipartFile.fromBytes(
            blobRes.data ?? [],
            filename: 'recording.webm',
            contentType: DioMediaType('audio', 'webm'),
          ),
          ...?additionalData,
        });
      } else {
        formData = FormData.fromMap({
          'audio': await MultipartFile.fromFile(filePath),
          ...?additionalData,
        });
      }

      return await _dio.post(
        endpoint,
        data: formData,
        options: Options(
          headers: {
            ApiConstants.contentType: ApiConstants.multipartFormData,
          },
        ),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Error Handler
  String _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data['message'] ?? 'An error occurred';
        
        switch (statusCode) {
          case ApiConstants.badRequest:
            return message;
          case ApiConstants.unauthorized:
            return 'Unauthorized. Please login again.';
          case ApiConstants.forbidden:
            return 'Access forbidden.';
          case ApiConstants.notFound:
            return 'Resource not found.';
          case ApiConstants.serverError:
            return 'Server error. Please try again later.';
          default:
            return message;
        }
      
      case DioExceptionType.cancel:
        return 'Request cancelled.';
      
      default:
        return 'Network error. Please check your connection.';
    }
  }
}
