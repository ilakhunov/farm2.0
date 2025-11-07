import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/product.dart';

class ProductRepository {
  ProductRepository({Dio? client}) : _client = client ?? apiClient;

  final Dio _client;

  Future<List<Product>> fetchProducts({int limit = 50, int offset = 0}) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/products',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );

    final data = response.data ?? {};
    final items = data['items'] as List<dynamic>? ?? [];
    return items.map((item) => Product.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Product> fetchProduct(String id) async {
    final response = await _client.get<Map<String, dynamic>>('/products/$id');
    final data = response.data ?? {};
    return Product.fromJson(data);
  }
}
