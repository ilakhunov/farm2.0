import 'package:flutter/material.dart';

import '../../orders/view/orders_screen.dart';
import '../../shared/widgets/loading_view.dart';
import '../data/product_repository.dart';
import '../models/product.dart';
import 'product_detail_screen.dart';

class ProductCatalogScreen extends StatefulWidget {
  const ProductCatalogScreen({super.key});

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  final _repository = ProductRepository();
  late Future<List<Product>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.fetchProducts();
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

  void _openProduct(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Каталог продуктов'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Мои заказы',
            onPressed: _openOrders,
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
            return const Center(child: Text('Каталог пуст'));
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
