import 'package:equatable/equatable.dart';

import '../../products/models/product.dart';

class OrderItem extends Equatable {
  const OrderItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.price,
    this.product,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      product: json['product'] != null
          ? Product.fromJson(json['product'] as Map<String, dynamic>)
          : null,
    );
  }

  final String id;
  final String productId;
  final double quantity;
  final double price;
  final Product? product;

  @override
  List<Object?> get props => [id, productId, quantity, price, product];
}

class Order extends Equatable {
  const Order({
    required this.id,
    required this.shopId,
    required this.farmerId,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    this.deliveryAddress,
    this.notes,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return Order(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      farmerId: json['farmer_id'] as String,
      status: json['status'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      deliveryAddress: json['delivery_address'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      items: itemsJson.map((item) => OrderItem.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  final String id;
  final String shopId;
  final String farmerId;
  final String status;
  final double totalAmount;
  final String? deliveryAddress;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItem> items;

  @override
  List<Object?> get props => [id, status, totalAmount, createdAt, updatedAt, items];
}
