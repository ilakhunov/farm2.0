import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../products/models/product.dart';

class FavoriteRepository {
  FavoriteRepository({Dio? client}) : _client = client ?? apiClient;

  final Dio _client;

  Future<void> addToFavorites(String productId) async {
    try {
      await _client.post(
        '/favorites',
        data: {'product_id': productId},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception('Товар уже в избранном');
      }
      if (e.response?.statusCode == 401) {
        throw Exception('Требуется авторизация');
      }
      final errorDetail = e.response?.data?['detail'] as String?;
      throw Exception(errorDetail ?? 'Не удалось добавить в избранное');
    }
  }

  Future<void> removeFromFavorites(String productId) async {
    try {
      await _client.delete('/favorites/$productId');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Товар не найден в избранном');
      }
      if (e.response?.statusCode == 401) {
        throw Exception('Требуется авторизация');
      }
      final errorDetail = e.response?.data?['detail'] as String?;
      throw Exception(errorDetail ?? 'Не удалось удалить из избранного');
    }
  }

  Future<List<Product>> getFavorites() async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/favorites');

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
          print('ERROR parsing favorite item: $e');
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
      throw Exception('Не удалось загрузить избранное: $errorMessage');
    }
  }

  Future<bool> isFavorite(String productId) async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/favorites/check/$productId');

      if (response.statusCode != null && response.statusCode! >= 400) {
        return false;
      }

      final data = response.data ?? {};
      return data['is_favorite'] as bool? ?? false;
    } catch (e) {
      return false;
    }
  }
}

