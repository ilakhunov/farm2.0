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
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/products',
        queryParameters: {
          'limit': limit,
          'offset': offset,
          if (category != null) 'category': category,
          if (farmerId != null) 'farmer_id': farmerId,
          if (search != null && search.isNotEmpty) 'search': search,
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
      
      // Safely parse each item with error handling
      final products = <Product>[];
      for (final item in items) {
        if (item is! Map<String, dynamic>) {
          continue; // Skip invalid items
        }
        
        try {
          // Ensure all String fields are safe (not List) before parsing
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
          // Log error but continue processing other items
          print('ERROR parsing product item: $e');
          print('Item data: $item');
          continue;
        }
      }
      
      return products;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      }
      final errorDetail = e.response?.data?['detail'] as String?;
      final errorMessage = errorDetail ?? 
          (e.message ?? '') ?? 
          (e.response?.statusMessage ?? 'Network error');
      throw Exception('Failed to fetch products: $errorMessage');
    }
  }

  Future<Product> fetchProduct(String id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/products/$id');
      
      if (response.statusCode != null && response.statusCode! >= 400) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }

      final data = response.data ?? {};
      return Product.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Product not found');
      }
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      }
      final errorDetail = e.response?.data?['detail'] as String?;
      final errorMessage = errorDetail ?? 
          (e.message ?? '') ?? 
          (e.response?.statusMessage ?? 'Network error');
      throw Exception('Failed to fetch product: $errorMessage');
    }
  }

  Future<Product> createProduct({
    required String name,
    String? description,
    required String category,
    required double price,
    required double quantity,
    required String unit,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/products',
        data: {
          'name': name,
          if (description != null && description.isNotEmpty) 'description': description,
          'category': category,
          'price': price,
          'quantity': quantity,
          'unit': unit,
        },
      );

      // Check response status
      final statusCode = response.statusCode;
      if (statusCode == null) {
        throw Exception('No response status code received');
      }
      
      if (statusCode >= 400) {
        final errorDetail = response.data?['detail'] as String?;
        final errorMessage = errorDetail ?? 'Server returned error status $statusCode';
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: errorMessage,
        );
      }

      // Check if response data exists
      if (response.data == null) {
        throw Exception('No response data received from server');
      }
      
      final data = response.data!;
      if (data.isEmpty) {
        throw Exception('Empty response data from server');
      }
      
      // Validate that we have required fields
      if (data['id'] == null) {
        throw Exception('Invalid product data: missing id. Response: ${data.toString()}');
      }
      
      // Convert UUID to string if needed and ensure all fields are safe
      final productData = Map<String, dynamic>.from(data);
      
      // Safely convert all fields that might be problematic
      if (productData['id'] != null && productData['id'] is! String) {
        productData['id'] = productData['id'].toString();
      }
      if (productData['farmer_id'] != null && productData['farmer_id'] is! String) {
        productData['farmer_id'] = productData['farmer_id'].toString();
      }
      
      // Ensure all String fields are safe (not List)
      final safeFields = ['name', 'category', 'unit', 'description', 'image_url'];
      for (final field in safeFields) {
        if (productData[field] != null && productData[field] is List) {
          final list = productData[field] as List;
          productData[field] = list.isEmpty ? null : list.first.toString();
        }
      }
      
      try {
        return Product.fromJson(productData);
      } catch (e) {
        // Log the problematic data for debugging
        print('ERROR parsing product data: $e');
        print('Product data: $productData');
        rethrow;
      }
    } on DioException catch (e) {
      final errorDetail = e.response?.data?['detail'] as String?;
      final statusCode = e.response?.statusCode;
      
      if (statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      }
      if (statusCode == 403) {
        throw Exception('Only farmers can create products.');
      }
      if (statusCode == 400) {
        throw Exception(errorDetail ?? 'Invalid request data');
      }
      if (statusCode == 500) {
        throw Exception(errorDetail ?? 'Server error. Please try again later.');
      }
      
      // More detailed error message
      final errorMessage = errorDetail ?? 
          (e.message ?? '') ?? 
          (e.response?.statusMessage ?? 'Unknown error');
      throw Exception('Failed to create product: $errorMessage');
    } catch (e) {
      // Catch any other exceptions (like JSON parsing errors)
      if (e is DioException) {
        final errorDetail = e.response?.data?['detail'] as String?;
        final errorMessage = errorDetail ?? 
            (e.message ?? '') ?? 
            (e.response?.statusMessage ?? 'Network error');
        throw Exception('Failed to create product: $errorMessage');
      }
      throw Exception('Failed to create product: ${e.toString()}');
    }
  }
}
