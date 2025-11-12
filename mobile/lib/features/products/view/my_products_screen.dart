import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/storage/user_storage.dart';
import '../../shared/widgets/loading_view.dart';
import '../data/product_repository.dart';
import '../models/product.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart';

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  final _repository = ProductRepository();
  late Future<List<Product>> _future;
  String? _farmerId;

  @override
  void initState() {
    super.initState();
    _loadFarmerId();
  }

  Future<void> _loadFarmerId() async {
    final userId = await UserStorage.userId;
    setState(() {
      _farmerId = userId;
    });
    _refresh();
  }

  Future<void> _refresh() async {
    if (_farmerId == null) return;
    setState(() {
      _future = _repository.fetchProducts(farmerId: _farmerId);
    });
    await _future;
  }

  Future<void> _createProduct() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ProductFormScreen()),
    );
    if (result == true) {
      _refresh();
    }
  }

  Future<void> _editProduct(Product product) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
    );
    if (result == true) {
      _refresh();
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить товар?'),
        content: Text('Вы уверены, что хотите удалить "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _repository.deleteProduct(product.id);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Товар удален')),
      );
      
      _refresh();
    } on DioException catch (e) {
      if (!mounted) return;
      String errorMessage = 'Ошибка при удалении товара';
      
      if (e.response != null) {
        final data = e.response!.data;
        if (data is Map<String, dynamic> && data.containsKey('detail')) {
          errorMessage = data['detail'].toString();
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openProduct(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_farmerId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Мои товары')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои товары'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Добавить товар',
            onPressed: _createProduct,
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
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Не удалось загрузить товары'),
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
                  const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('У вас пока нет товаров'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить товар'),
                    onPressed: _createProduct,
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
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${product.category} • ${product.price.toStringAsFixed(2)} сум/${product.unit}'),
                      Text('Остаток: ${product.quantity.toStringAsFixed(2)} ${product.unit}'),
                      if (!product.isActive)
                        const Text('Неактивен', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Редактировать'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Удалить', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editProduct(product);
                      } else if (value == 'delete') {
                        _deleteProduct(product);
                      }
                    },
                  ),
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

