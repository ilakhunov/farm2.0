import 'package:flutter/material.dart';

import '../../shared/widgets/loading_view.dart';
import '../data/order_repository.dart';
import '../models/order.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _repository = OrderRepository();
  late Future<List<Order>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.fetchOrders();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _repository.fetchOrders();
    });
    await _future;
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Заказ #${order.id.substring(0, 8)}', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Text('Статус: ${order.status}'),
              Text('Сумма: ${order.totalAmount.toStringAsFixed(2)} сум'),
              if (order.deliveryAddress != null) Text('Адрес: ${order.deliveryAddress}'),
              const SizedBox(height: 12),
              const Text('Состав заказа:'),
              const SizedBox(height: 8),
              ...order.items.map(
                (item) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('Товар: ${item.product?.name ?? item.productId}'),
                  subtitle: Text('Кол-во: ${item.quantity}, цена: ${item.price} сум'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои заказы')),
      body: FutureBuilder<List<Order>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Не удалось загрузить заказы'),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: _refresh, child: const Text('Повторить')),
                ],
              ),
            );
          }

          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return const Center(child: Text('Заказы отсутствуют'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final order = orders[index];
                return ListTile(
                  onTap: () => _showOrderDetails(order),
                  leading: CircleAvatar(child: Text(order.status.isNotEmpty ? order.status[0].toUpperCase() : '?')),
                  title: Text('Заказ #${order.id.substring(0, 8)}'),
                  subtitle: Text('Статус: ${order.status}\nСумма: ${order.totalAmount.toStringAsFixed(2)} сум'),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: orders.length,
            ),
          );
        },
      ),
    );
  }
}
