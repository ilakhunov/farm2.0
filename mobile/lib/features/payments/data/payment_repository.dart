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
    return PaymentInitResult(
      transactionId: json['transaction_id'] as String,
      paymentUrl: json['payment_url'] as String?,
      paymentData: json['payment_data'] as Map<String, dynamic>?,
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
