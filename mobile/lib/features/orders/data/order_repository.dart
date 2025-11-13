import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/order.dart';

class OrderRepository {
  OrderRepository({Dio? client}) : _client = client ?? apiClient;

  final Dio _client;

  Future<Order> createOrder({
    required String farmerId,
    required List<Map<String, dynamic>> items,
    String? deliveryAddress,
    String? notes,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/orders',
        data: {
          'farmer_id': farmerId,
          'items': items,
          if (deliveryAddress != null) 'delivery_address': deliveryAddress,
          if (notes != null) 'notes': notes,
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
      return Order.fromJson(data);
    } on DioException catch (e) {
      final errorDetail = e.response?.data?['detail'] as String?;
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      }
      if (e.response?.statusCode == 403) {
        throw Exception('Only shops can create orders.');
      }
      throw Exception(errorDetail ?? 'Failed to create order: ${e.message}');
    }
  }

  Future<List<Order>> fetchOrders({String? status}) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/orders',
        queryParameters: {
          if (status != null) 'status': status,
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
      return items.map((item) => Order.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      }
      throw Exception('Failed to fetch orders: ${e.message}');
    }
  }

  Future<Order> fetchOrder(String id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/orders/$id');
      
      if (response.statusCode != null && response.statusCode! >= 400) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }

      final data = response.data ?? {};
      return Order.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Order not found');
      }
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      }
      throw Exception('Failed to fetch order: ${e.message}');
    }
  }

  Future<Order> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    try {
      final response = await _client.patch<Map<String, dynamic>>(
        '/orders/$orderId',
        data: {'status': status},
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
      return Order.fromJson(data);
    } on DioException catch (e) {
      final errorDetail = e.response?.data?['detail'] as String?;
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      }
      if (e.response?.statusCode == 403) {
        throw Exception('Not authorized to update this order.');
      }
      throw Exception(errorDetail ?? 'Failed to update order: ${e.message}');
    }
  }
}
