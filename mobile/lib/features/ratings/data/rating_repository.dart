import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/rating.dart';

class RatingRepository {
  RatingRepository({Dio? client}) : _client = client ?? apiClient;

  final Dio _client;

  Future<Rating> createRating({
    required RatingType ratingType,
    String? productId,
    String? sellerId,
    required int rating,
    String? comment,
    List<String>? images,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/ratings',
        data: {
          'rating_type': ratingType.value,
          if (productId != null) 'product_id': productId,
          if (sellerId != null) 'seller_id': sellerId,
          'rating': rating,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
          if (images != null && images.isNotEmpty) 'images': images,
        },
      );

      if (response.statusCode != null && response.statusCode! >= 400) {
        final errorDetail = response.data?['detail'] as String?;
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: errorDetail,
        );
      }

      final data = response.data ?? {};
      return Rating.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorDetail = e.response?.data?['detail'] as String?;
        throw Exception(errorDetail ?? 'Неверные данные');
      }
      if (e.response?.statusCode == 401) {
        throw Exception('Требуется авторизация');
      }
      final errorDetail = e.response?.data?['detail'] as String?;
      throw Exception(errorDetail ?? 'Не удалось создать отзыв');
    }
  }

  Future<List<Rating>> getProductRatings(String productId) async {
    try {
      final response = await _client.get<List<dynamic>>('/ratings/product/$productId');

      if (response.statusCode != null && response.statusCode! >= 400) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }

      final items = response.data ?? [];
      return items.map((item) => Rating.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Требуется авторизация');
      }
      final errorDetail = e.response?.data?['detail'] as String?;
      throw Exception(errorDetail ?? 'Не удалось загрузить отзывы');
    }
  }

  Future<RatingStats> getProductRatingStats(String productId) async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/ratings/product/$productId/stats');

      if (response.statusCode != null && response.statusCode! >= 400) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }

      final data = response.data ?? {};
      return RatingStats.fromJson(data);
    } on DioException catch (e) {
      final errorDetail = e.response?.data?['detail'] as String?;
      throw Exception(errorDetail ?? 'Не удалось загрузить статистику');
    }
  }

  Future<void> replyToRating(String ratingId, String reply) async {
    try {
      await _client.patch(
        '/ratings/$ratingId/reply',
        data: {'reply': reply},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('Нет прав для ответа');
      }
      if (e.response?.statusCode == 401) {
        throw Exception('Требуется авторизация');
      }
      final errorDetail = e.response?.data?['detail'] as String?;
      throw Exception(errorDetail ?? 'Не удалось отправить ответ');
    }
  }
}

