import 'package:equatable/equatable.dart';

class Product extends Equatable {
  const Product({
    required this.id,
    required this.farmerId,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.quantity,
    required this.unit,
    required this.isActive,
    required this.imageUrl,
    this.imageUrls,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Handle UUID conversion (can be String or UUID object)
    String id;
    if (json['id'] is String) {
      id = json['id'] as String;
    } else {
      id = json['id'].toString();
    }
    
    String farmerId;
    if (json['farmer_id'] is String) {
      farmerId = json['farmer_id'] as String;
    } else {
      farmerId = json['farmer_id'].toString();
    }
    
    // Handle datetime conversion
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
    
    // Handle description - can be String, List, or null
    String? description;
    if (json['description'] == null) {
      description = null;
    } else if (json['description'] is String) {
      description = json['description'] as String;
    } else if (json['description'] is List) {
      // If it's a list, join it or take first element
      final list = json['description'] as List;
      description = list.isEmpty ? null : list.first.toString();
    } else {
      description = json['description'].toString();
    }
    
    // Handle imageUrl - can be String, List, or null
    String? imageUrl;
    if (json['image_url'] == null) {
      imageUrl = null;
    } else if (json['image_url'] is String) {
      imageUrl = json['image_url'] as String;
    } else if (json['image_url'] is List) {
      // If it's a list, take first element or null
      final list = json['image_url'] as List;
      imageUrl = list.isEmpty ? null : list.first.toString();
    } else {
      imageUrl = json['image_url'].toString();
    }
    
    // Handle category - ensure it's a string
    String category;
    if (json['category'] is String) {
      category = json['category'] as String;
    } else {
      category = json['category'].toString();
    }
    
    // Handle unit - ensure it's a string
    String unit;
    if (json['unit'] is String) {
      unit = json['unit'] as String;
    } else if (json['unit'] == null) {
      unit = 'kg';
    } else {
      unit = json['unit'].toString();
    }
    
    // Handle name - ensure it's a string
    String name;
    if (json['name'] is String) {
      name = json['name'] as String;
    } else if (json['name'] is List) {
      final list = json['name'] as List;
      name = list.isEmpty ? 'Unknown' : list.first.toString();
    } else {
      name = json['name']?.toString() ?? 'Unknown';
    }
    
    // Handle price and quantity safely
    double price;
    if (json['price'] is num) {
      price = (json['price'] as num).toDouble();
    } else {
      price = 0.0;
    }
    
    double quantity;
    if (json['quantity'] is num) {
      quantity = (json['quantity'] as num).toDouble();
    } else {
      quantity = 0.0;
    }
    
    // Handle isActive safely
    bool isActive;
    if (json['is_active'] is bool) {
      isActive = json['is_active'] as bool;
    } else {
      isActive = true;
    }
    
    // Handle imageUrls
    List<String>? imageUrls;
    if (json['image_urls'] == null) {
      imageUrls = null;
    } else if (json['image_urls'] is List) {
      imageUrls = (json['image_urls'] as List).map((e) => e.toString()).toList();
    } else if (json['image_urls'] is String) {
      // Try to parse as JSON string
      try {
        final parsed = json['image_urls'] as String;
        if (parsed.startsWith('[') && parsed.endsWith(']')) {
          // Simple JSON array parsing
          final cleaned = parsed.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').replaceAll(' ', '');
          imageUrls = cleaned.split(',').where((e) => e.isNotEmpty).toList();
        } else {
          imageUrls = null;
        }
      } catch (e) {
        imageUrls = null;
      }
    } else {
      imageUrls = null;
    }
    
    return Product(
      id: id,
      farmerId: farmerId,
      name: name,
      description: description,
      category: category,
      price: price,
      quantity: quantity,
      unit: unit,
      isActive: isActive,
      imageUrl: imageUrl,
      imageUrls: imageUrls,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmer_id': farmerId,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'quantity': quantity,
      'unit': unit,
      'is_active': isActive,
      'image_url': imageUrl,
    };
  }

  final String id;
  final String farmerId;
  final String name;
  final String? description;
  final String category;
  final double price;
  final double quantity;
  final String unit;
  final bool isActive;
  final String? imageUrl;
  final List<String>? imageUrls;  // Multiple images
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [id, name, category, price, quantity, unit, imageUrl, imageUrls, isActive, farmerId, createdAt, updatedAt];
}
