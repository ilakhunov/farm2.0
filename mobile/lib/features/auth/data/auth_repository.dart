import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/auth_models.dart';

class AuthRepository {
  AuthRepository({Dio? client}) : _client = client ?? apiClient;

  final Dio _client;

  Future<String?> sendOtp({
    required String phoneNumber,
    String? role,
    String? entityType,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/auth/send-otp',
      data: {
        'phone_number': phoneNumber,
        if (role != null) 'role': role,
        if (entityType != null) 'entity_type': entityType,
      },
    );
    return response.data?['debug']?['otp'] as String?;
  }

  Future<AuthResponse> verifyOtp({
    required String phoneNumber,
    required String code,
    String? role,
    String? entityType,
    String? taxId,
    String? legalName,
    String? legalAddress,
    String? bankAccount,
    String? email,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/verify-otp',
        data: {
          'phone_number': phoneNumber,
          'code': code,
          if (role != null) 'role': role,
          if (entityType != null) 'entity_type': entityType,
          if (taxId != null) 'tax_id': taxId,
          if (legalName != null) 'legal_name': legalName,
          if (legalAddress != null) 'legal_address': legalAddress,
          if (bankAccount != null) 'bank_account': bankAccount,
          if (email != null) 'email': email,
        },
      );

      final data = response.data ?? {};
      if (data.isEmpty) {
        throw Exception('Empty response from server');
      }
      
      return AuthResponse.fromJson(data);
    } on DioException {
      // Пробрасываем DioException дальше для обработки в UI
      rethrow;
    } catch (e) {
      // Оборачиваем другие ошибки в DioException для единообразной обработки
      throw DioException(
        requestOptions: RequestOptions(path: '/auth/verify-otp'),
        error: e,
        type: DioExceptionType.unknown,
      );
    }
  }

  Future<void> logout() async {
    try {
      await _client.post<Map<String, dynamic>>(
        '/auth/logout',
      );
    } on DioException {
      // Пробрасываем DioException дальше для обработки в UI
      rethrow;
    } catch (e) {
      // Оборачиваем другие ошибки в DioException для единообразной обработки
      throw DioException(
        requestOptions: RequestOptions(path: '/auth/logout'),
        error: e,
        type: DioExceptionType.unknown,
      );
    }
  }
}
