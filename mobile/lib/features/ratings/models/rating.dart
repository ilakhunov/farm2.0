import 'package:equatable/equatable.dart';

enum RatingType {
  product('product'),
  seller('seller');

  final String value;
  const RatingType(this.value);
}

class Rating extends Equatable {
  const Rating({
    required this.id,
    required this.userId,
    required this.ratingType,
    this.productId,
    this.sellerId,
    required this.rating,
    this.comment,
    this.images,
    required this.isApproved,
    this.reply,
    this.repliedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    // Handle rating_type
    RatingType ratingType;
    if (json['rating_type'] is String) {
      final typeStr = json['rating_type'] as String;
      ratingType = typeStr == 'product' ? RatingType.product : RatingType.seller;
    } else {
      ratingType = RatingType.product;
    }
    
    // Handle IDs safely
    String id;
    if (json['id'] is String) {
      id = json['id'] as String;
    } else {
      id = json['id']?.toString() ?? '';
    }
    
    String userId;
    if (json['user_id'] is String) {
      userId = json['user_id'] as String;
    } else {
      userId = json['user_id']?.toString() ?? '';
    }
    
    String? productId;
    if (json['product_id'] == null) {
      productId = null;
    } else if (json['product_id'] is String) {
      productId = json['product_id'] as String;
    } else {
      productId = json['product_id'].toString();
    }
    
    String? sellerId;
    if (json['seller_id'] == null) {
      sellerId = null;
    } else if (json['seller_id'] is String) {
      sellerId = json['seller_id'] as String;
    } else {
      sellerId = json['seller_id'].toString();
    }
    
    // Handle images
    List<String>? images;
    if (json['images'] == null) {
      images = null;
    } else if (json['images'] is List) {
      images = (json['images'] as List).map((e) => e.toString()).toList();
    } else {
      images = null;
    }
    
    // Handle datetime
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
    
    DateTime? repliedAt;
    if (json['replied_at'] == null) {
      repliedAt = null;
    } else if (json['replied_at'] is String) {
      repliedAt = DateTime.parse(json['replied_at'] as String);
    } else if (json['replied_at'] is DateTime) {
      repliedAt = json['replied_at'] as DateTime;
    } else {
      repliedAt = null;
    }
    
    return Rating(
      id: id,
      userId: userId,
      ratingType: ratingType,
      productId: productId,
      sellerId: sellerId,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      images: images,
      isApproved: json['is_approved'] as bool? ?? false,
      reply: json['reply'] as String?,
      repliedAt: repliedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  final String id;
  final String userId;
  final RatingType ratingType;
  final String? productId;
  final String? sellerId;
  final int rating;
  final String? comment;
  final List<String>? images;
  final bool isApproved;
  final String? reply;
  final DateTime? repliedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        id,
        userId,
        ratingType,
        productId,
        sellerId,
        rating,
        comment,
        images,
        isApproved,
        reply,
        repliedAt,
        createdAt,
        updatedAt,
      ];
}

class RatingStats extends Equatable {
  const RatingStats({
    required this.averageRating,
    required this.totalRatings,
    required this.ratingDistribution,
  });

  factory RatingStats.fromJson(Map<String, dynamic> json) {
    // Handle rating_distribution
    Map<int, int> distribution = {};
    if (json['rating_distribution'] is Map) {
      final dist = json['rating_distribution'] as Map;
      for (final entry in dist.entries) {
        final key = int.tryParse(entry.key.toString()) ?? 0;
        final value = entry.value is int ? entry.value as int : int.tryParse(entry.value.toString()) ?? 0;
        distribution[key] = value;
      }
    }
    
    return RatingStats(
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: json['total_ratings'] as int? ?? 0,
      ratingDistribution: distribution,
    );
  }

  final double averageRating;
  final int totalRatings;
  final Map<int, int> ratingDistribution;

  @override
  List<Object?> get props => [averageRating, totalRatings, ratingDistribution];
}

