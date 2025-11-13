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
    // Handle ID fields safely
    String id;
    if (json['id'] is String) {
      id = json['id'] as String;
    } else {
      id = json['id']?.toString() ?? '';
    }
    
    String productId;
    if (json['product_id'] is String) {
      productId = json['product_id'] as String;
    } else {
      productId = json['product_id']?.toString() ?? '';
    }
    
    // Handle numeric fields safely
    double quantity;
    if (json['quantity'] is num) {
      quantity = (json['quantity'] as num).toDouble();
    } else {
      quantity = 0.0;
    }
    
    double price;
    if (json['price'] is num) {
      price = (json['price'] as num).toDouble();
    } else {
      price = 0.0;
    }
    
    return OrderItem(
      id: id,
      productId: productId,
      quantity: quantity,
      price: price,
      product: json['product'] != null && json['product'] is Map<String, dynamic>
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
    
    // Handle ID fields safely
    String id;
    if (json['id'] is String) {
      id = json['id'] as String;
    } else {
      id = json['id']?.toString() ?? '';
    }
    
    String shopId;
    if (json['shop_id'] is String) {
      shopId = json['shop_id'] as String;
    } else {
      shopId = json['shop_id']?.toString() ?? '';
    }
    
    String farmerId;
    if (json['farmer_id'] is String) {
      farmerId = json['farmer_id'] as String;
    } else {
      farmerId = json['farmer_id']?.toString() ?? '';
    }
    
    // Handle status safely
    String status;
    if (json['status'] is String) {
      status = json['status'] as String;
    } else {
      status = json['status']?.toString() ?? 'pending';
    }
    
    // Handle totalAmount safely
    double totalAmount;
    if (json['total_amount'] is num) {
      totalAmount = (json['total_amount'] as num).toDouble();
    } else {
      totalAmount = 0.0;
    }
    
    // Handle optional String fields safely
    String? deliveryAddress;
    if (json['delivery_address'] == null) {
      deliveryAddress = null;
    } else if (json['delivery_address'] is String) {
      deliveryAddress = json['delivery_address'] as String;
    } else if (json['delivery_address'] is List) {
      final list = json['delivery_address'] as List;
      deliveryAddress = list.isEmpty ? null : list.first.toString();
    } else {
      deliveryAddress = json['delivery_address'].toString();
    }
    
    String? notes;
    if (json['notes'] == null) {
      notes = null;
    } else if (json['notes'] is String) {
      notes = json['notes'] as String;
    } else if (json['notes'] is List) {
      final list = json['notes'] as List;
      notes = list.isEmpty ? null : list.first.toString();
    } else {
      notes = json['notes'].toString();
    }
    
    // Handle datetime safely
    DateTime createdAt;
    if (json['created_at'] is String) {
      createdAt = DateTime.parse(json['created_at'] as String);
    } else if (json['created_at'] is DateTime) {
      createdAt = json['created_at'] as DateTime;
    } else {
      createdAt = DateTime.now();
    }
    
    DateTime updatedAt;
    if (json['updated_at'] is String) {
      updatedAt = DateTime.parse(json['updated_at'] as String);
    } else if (json['updated_at'] is DateTime) {
      updatedAt = json['updated_at'] as DateTime;
    } else {
      updatedAt = DateTime.now();
    }
    
    return Order(
      id: id,
      shopId: shopId,
      farmerId: farmerId,
      status: status,
      totalAmount: totalAmount,
      deliveryAddress: deliveryAddress,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
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
