import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../products/models/product.dart';

class ViewHistoryRepository {
  ViewHistoryRepository({Dio? client}) : _client = client ?? apiClient;

  final Dio _client;

  Future<void> recordView(String productId) async {
    try {
      await _client.post('/view-history/$productId');
    } catch (e) {
      // Silently fail - view history is not critical
      print('Failed to record view: $e');
    }
  }

  Future<List<Product>> getViewHistory({int limit = 20, int offset = 0}) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/view-history',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode != null && response.statusCode! >= 400) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }

      final data = response.data ?? {};
      final items = data['items'] as List<dynamic>? ?? [];
      
      // Safely parse each item
      final products = <Product>[];
      for (final item in items) {
        if (item is! Map<String, dynamic>) continue;
        
        try {
          final safeItem = Map<String, dynamic>.from(item);
          final safeFields = ['name', 'category', 'unit', 'description', 'image_url'];
          for (final field in safeFields) {
            if (safeItem[field] != null && safeItem[field] is List) {
              final list = safeItem[field] as List;
              safeItem[field] = list.isEmpty ? null : list.first.toString();
            }
          }
          
          products.add(Product.fromJson(safeItem));
        } catch (e) {
          print('ERROR parsing view history item: $e');
          continue;
        }
      }
      
      return products;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Требуется авторизация');
      }
      final errorDetail = e.response?.data?['detail'] as String?;
      final errorMessage = errorDetail ?? 
          (e.message ?? '') ?? 
          (e.response?.statusMessage ?? 'Ошибка сети');
      throw Exception('Не удалось загрузить историю: $errorMessage');
    }
  }

  Future<void> clearHistory() async {
    try {
      await _client.delete('/view-history');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Требуется авторизация');
      }
      final errorDetail = e.response?.data?['detail'] as String?;
      throw Exception(errorDetail ?? 'Не удалось очистить историю');
    }
  }
}

