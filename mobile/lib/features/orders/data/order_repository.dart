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
    final response = await _client.post<Map<String, dynamic>>(
      '/orders',
      data: {
        'farmer_id': farmerId,
        'items': items,
        if (deliveryAddress != null) 'delivery_address': deliveryAddress,
        if (notes != null) 'notes': notes,
      },
    );

    final data = response.data ?? {};
    return Order.fromJson(data);
  }

  Future<List<Order>> fetchOrders() async {
    final response = await _client.get<Map<String, dynamic>>('/orders');
    final data = response.data ?? {};
    final items = data['items'] as List<dynamic>? ?? [];
    return items.map((item) => Order.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Order> fetchOrder(String id) async {
    final response = await _client.get<Map<String, dynamic>>('/orders/$id');
    final data = response.data ?? {};
    return Order.fromJson(data);
  }
}
