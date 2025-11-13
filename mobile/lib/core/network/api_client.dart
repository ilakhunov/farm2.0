import 'package:dio/dio.dart';

import '../constants/env.dart';
import '../storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await TokenStorage.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle 401 Unauthorized - clear tokens and redirect to login
    if (err.response?.statusCode == 401) {
      TokenStorage.clear();
    }
    super.onError(err, handler);
  }
}

final Dio apiClient = Dio(
  BaseOptions(
    baseUrl: kApiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {
      'Content-Type': 'application/json',
    },
    validateStatus: (status) => status != null && status < 500, // Don't throw on 4xx
  ),
)..interceptors.add(AuthInterceptor());
