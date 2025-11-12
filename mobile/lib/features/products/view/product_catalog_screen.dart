import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../auth/data/auth_repository.dart';
import '../../auth/view/auth_flow.dart';
import '../../orders/view/orders_screen.dart';
import '../../shared/widgets/loading_view.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/storage/user_storage.dart';
import '../data/product_repository.dart';
import '../models/product.dart';
import 'my_products_screen.dart';
import 'product_detail_screen.dart';

class ProductCatalogScreen extends StatefulWidget {
  const ProductCatalogScreen({super.key});

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  final _repository = ProductRepository();
  final _authRepository = AuthRepository();
  late Future<List<Product>> _future;
  bool? _isFarmer;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _future = _repository.fetchProducts();
  }

  Future<void> _loadUserRole() async {
    final isFarmer = await UserStorage.isFarmer;
    setState(() {
      _isFarmer = isFarmer;
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _repository.fetchProducts();
    });
    await _future;
  }

  void _openOrders() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OrdersScreen()),
    );
  }

  void _openMyProducts() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MyProductsScreen()),
    );
  }

  void _openProduct(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
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
      // Но логируем для отладки
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Каталог продуктов'),
        actions: [
          if (_isFarmer == true)
            IconButton(
              icon: const Icon(Icons.inventory_2),
              tooltip: 'Мои товары',
              onPressed: _openMyProducts,
            ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Мои заказы',
            onPressed: _openOrders,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выход',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: FutureBuilder<List<Product>>(
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
                  const Text('Не удалось загрузить каталог'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Каталог пуст'),
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
                final product = products[index];
                return ListTile(
                  onTap: () => _openProduct(product),
                  leading: CircleAvatar(
                    child: Text(product.name.isNotEmpty ? product.name[0].toUpperCase() : '?'),
                  ),
                  title: Text(product.name),
                  subtitle: Text(
                    '${product.category} • ${product.price.toStringAsFixed(2)} сум/${product.unit}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: products.length,
            ),
          );
        },
      ),
    );
  }
}
