import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../auth/data/auth_repository.dart';
import '../../auth/view/auth_flow.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/storage/token_storage.dart';
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
  final _authRepository = AuthRepository();
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

  Future<void> _handleLogout() async {
    final strings = AppLocalizations.of(context);
    
    // Показываем диалог подтверждения
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.translate('logout') ?? 'Выход'),
        content: Text(strings.translate('logout_confirm') ?? 'Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.translate('cancel') ?? 'Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.translate('logout') ?? 'Выход'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Вызываем API logout
      await _authRepository.logout();
    } on DioException catch (e) {
      // Игнорируем ошибки при logout (токен может быть уже невалидным)
      debugPrint('Logout error: ${e.message}');
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      // Всегда очищаем токены и перенаправляем на экран авторизации
      await TokenStorage.clear();
      if (!mounted) return;
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthFlowScreen()),
        (route) => false,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.translate('logout_success') ?? 'Вы успешно вышли')),
      );
    }
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
      appBar: AppBar(
        title: const Text('Мои заказы'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выход',
            onPressed: _handleLogout,
          ),
        ],
      ),
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
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Не удалось загрузить заказы'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Заказы отсутствуют'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('Обновить'),
                  ),
                ],
              ),
            );
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
