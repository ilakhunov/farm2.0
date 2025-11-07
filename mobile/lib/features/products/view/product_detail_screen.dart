import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../orders/data/order_repository.dart';
import '../../payments/data/payment_repository.dart';
import '../../products/models/product.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _orderRepository = OrderRepository();
  final _paymentRepository = PaymentRepository();
  final _quantityController = TextEditingController(text: '1');
  bool _isProcessing = false;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _createOrder() async {
    final quantity = double.tryParse(_quantityController.text.replaceAll(',', '.'));
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите корректное количество')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final order = await _orderRepository.createOrder(
        farmerId: widget.product.farmerId,
        items: [
          {
            'product_id': widget.product.id,
            'quantity': quantity,
          },
        ],
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заказ создан, инициируем платеж')),
      );

      final payment = await _paymentRepository.initPayment(
        orderId: order.id,
        provider: PaymentProvider.payme,
      );

      if (!mounted) return;

      if (payment.paymentUrl != null) {
        final uri = Uri.parse(payment.paymentUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Не удалось открыть ссылку: ${payment.paymentUrl}')),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Платеж инициирован. Проверьте список транзакций.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(product.imageUrl!, height: 220, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              ),
            const SizedBox(height: 16),
            Text(product.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              '${product.price.toStringAsFixed(2)} сум / ${product.unit}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.green[700]),
            ),
            const SizedBox(height: 16),
            Text(product.description ?? 'Описание отсутствует'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Количество',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(product.unit),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.shopping_cart_checkout),
                label: Text(_isProcessing ? 'Оформляем...' : 'Оформить заказ'),
                onPressed: _isProcessing ? null : _createOrder,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Примечание: после оформления откроется страница Payme. Выберите провайдера позже в настройках.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
