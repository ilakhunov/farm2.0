import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/product.dart';

class ProductRepository {
  ProductRepository({Dio? client}) : _client = client ?? apiClient;

  final Dio _client;

  Future<List<Product>> fetchProducts({
    int limit = 50,
    int offset = 0,
    String? category,
    String? farmerId,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (category != null) queryParams['category'] = category;
    if (farmerId != null) queryParams['farmer_id'] = farmerId;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await _client.get<Map<String, dynamic>>(
      '/products',
      queryParameters: queryParams,
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

  Future<Product> createProduct({
    required String name,
    String? description,
    required String category,
    required double price,
    required double quantity,
    required String unit,
    String? imageUrl,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/products',
      data: {
        'name': name,
        if (description != null && description.isNotEmpty) 'description': description,
        'category': category,
        'price': price,
        'quantity': quantity,
        'unit': unit,
        if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
      },
    );

    return Product.fromJson(response.data!);
  }

  Future<Product> updateProduct({
    required String id,
    String? name,
    String? description,
    String? category,
    double? price,
    double? quantity,
    String? unit,
    String? imageUrl,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (category != null) data['category'] = category;
    if (price != null) data['price'] = price;
    if (quantity != null) data['quantity'] = quantity;
    if (unit != null) data['unit'] = unit;
    if (imageUrl != null) data['image_url'] = imageUrl;

    final response = await _client.patch<Map<String, dynamic>>(
      '/products/$id',
      data: data,
    );

    return Product.fromJson(response.data!);
  }

  Future<void> deleteProduct(String id) async {
    await _client.delete('/products/$id');
  }
}
