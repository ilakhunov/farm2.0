import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

enum PaymentProvider { payme, click, arca }

extension PaymentProviderExtension on PaymentProvider {
  String get value {
    switch (this) {
      case PaymentProvider.payme:
        return 'payme';
      case PaymentProvider.click:
        return 'click';
      case PaymentProvider.arca:
        return 'arca';
    }
  }
}

class PaymentInitResult {
  const PaymentInitResult({
    required this.transactionId,
    this.paymentUrl,
    this.paymentData,
  });

  factory PaymentInitResult.fromJson(Map<String, dynamic> json) {
    // Handle transactionId safely
    String transactionId;
    if (json['transaction_id'] is String) {
      transactionId = json['transaction_id'] as String;
    } else if (json['transaction_id'] is List) {
      final list = json['transaction_id'] as List;
      transactionId = list.isEmpty ? '' : list.first.toString();
    } else {
      transactionId = json['transaction_id']?.toString() ?? '';
    }
    
    // Handle paymentUrl safely
    String? paymentUrl;
    if (json['payment_url'] == null) {
      paymentUrl = null;
    } else if (json['payment_url'] is String) {
      paymentUrl = json['payment_url'] as String;
    } else if (json['payment_url'] is List) {
      final list = json['payment_url'] as List;
      paymentUrl = list.isEmpty ? null : list.first.toString();
    } else {
      paymentUrl = json['payment_url'].toString();
    }
    
    // Handle paymentData safely
    Map<String, dynamic>? paymentData;
    if (json['payment_data'] == null) {
      paymentData = null;
    } else if (json['payment_data'] is Map<String, dynamic>) {
      paymentData = json['payment_data'] as Map<String, dynamic>;
    } else {
      paymentData = null;
    }
    
    return PaymentInitResult(
      transactionId: transactionId,
      paymentUrl: paymentUrl,
      paymentData: paymentData,
    );
  }

  final String transactionId;
  final String? paymentUrl;
  final Map<String, dynamic>? paymentData;
}

class PaymentRepository {
  PaymentRepository({Dio? client}) : _client = client ?? apiClient;

  final Dio _client;

  Future<PaymentInitResult> initPayment({
    required String orderId,
    required PaymentProvider provider,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/payments/init',
      data: {
        'order_id': orderId,
        'provider': provider.value,
      },
    );

    final data = response.data ?? {};
    return PaymentInitResult.fromJson(data);
  }
}
