import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/token_storage.dart';
import '../../../core/storage/user_storage.dart';
import '../../../core/widgets/bottom_navigation.dart';
import '../../shared/widgets/loading_view.dart';
import '../data/product_repository.dart';
import '../models/product.dart';

class ProductCatalogScreen extends StatefulWidget {
  const ProductCatalogScreen({super.key});

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

enum ProductSortOption {
  nameAsc,
  nameDesc,
  priceAsc,
  priceDesc,
  quantityAsc,
  quantityDesc,
  dateNewest,
  dateOldest,
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  final _repository = ProductRepository();
  late Future<List<Product>> _future;
  bool _isFarmer = false;
  final _searchController = TextEditingController();
  String? _selectedCategory;
  ProductSortOption _sortOption = ProductSortOption.dateNewest;

  @override
  void initState() {
    super.initState();
    _future = _repository.fetchProducts().then((products) => _sortProducts(products));
    _checkUserRole();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-check user role when screen becomes visible again
    _checkUserRole();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    final isFarmer = await UserStorage.isFarmer;
    setState(() {
      _isFarmer = isFarmer;
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _repository.fetchProducts(
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
        category: _selectedCategory,
      ).then((products) => _sortProducts(products));
    });
    await _future;
  }

  void _onSearchChanged(String value) {
    setState(() {
      _future = _repository.fetchProducts(
        search: value.isNotEmpty ? value : null,
        category: _selectedCategory,
      ).then((products) => _sortProducts(products));
    });
  }

  List<Product> _sortProducts(List<Product> products) {
    final sorted = List<Product>.from(products);
    switch (_sortOption) {
      case ProductSortOption.nameAsc:
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
      case ProductSortOption.nameDesc:
        sorted.sort((a, b) => b.name.compareTo(a.name));
        break;
      case ProductSortOption.priceAsc:
        sorted.sort((a, b) => a.price.compareTo(b.price));
        break;
      case ProductSortOption.priceDesc:
        sorted.sort((a, b) => b.price.compareTo(a.price));
        break;
      case ProductSortOption.quantityAsc:
        sorted.sort((a, b) => a.quantity.compareTo(b.quantity));
        break;
      case ProductSortOption.quantityDesc:
        sorted.sort((a, b) => b.quantity.compareTo(a.quantity));
        break;
      case ProductSortOption.dateNewest:
        // API уже сортирует по дате создания desc
        break;
      case ProductSortOption.dateOldest:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
    }
    return sorted;
  }

  void _openOrders() {
    context.push('/orders');
  }

  void _openProduct(Product product) {
    context.push('/products/${product.id}');
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход из системы'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await TokenStorage.clear();
      if (!mounted) return;
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isFarmer ? 'Мои товары' : 'Каталог продуктов'),
        actions: [
          // Show "Create Product" button - check role when pressed
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Создать товар',
            onPressed: () async {
              // Double-check role before allowing creation
              final isFarmer = await UserStorage.isFarmer;
              if (!mounted) return;
              
              if (!isFarmer) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Только фермеры могут создавать товары'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 3),
                  ),
                );
                return;
              }
              
              final result = await context.push('/products/create');
              if (!mounted) return;
              
              if (result == true) {
                // Refresh products list
                _refresh();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Мои заказы',
            onPressed: _openOrders,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Профиль',
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text('Выйти'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Поиск товаров...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip('Все', null),
                      _buildCategoryChip('Овощи', 'vegetables'),
                      _buildCategoryChip('Фрукты', 'fruits'),
                      _buildCategoryChip('Зерновые', 'grains'),
                      _buildCategoryChip('Молочные', 'dairy'),
                      _buildCategoryChip('Мясо', 'meat'),
                      _buildCategoryChip('Другое', 'other'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Sort options
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[50],
            child: Row(
              children: [
                const Icon(Icons.sort, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                const Text('Сортировка:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ProductSortOption>(
                      value: _sortOption,
                      isDense: true,
                      style: const TextStyle(fontSize: 12),
                      items: const [
                        DropdownMenuItem(value: ProductSortOption.dateNewest, child: Text('Новинки')),
                        DropdownMenuItem(value: ProductSortOption.dateOldest, child: Text('Старые')),
                        DropdownMenuItem(value: ProductSortOption.nameAsc, child: Text('А-Я')),
                        DropdownMenuItem(value: ProductSortOption.nameDesc, child: Text('Я-А')),
                        DropdownMenuItem(value: ProductSortOption.priceAsc, child: Text('Цена ↑')),
                        DropdownMenuItem(value: ProductSortOption.priceDesc, child: Text('Цена ↓')),
                        DropdownMenuItem(value: ProductSortOption.quantityAsc, child: Text('Кол-во ↑')),
                        DropdownMenuItem(value: ProductSortOption.quantityDesc, child: Text('Кол-во ↓')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _sortOption = value;
                            _future = _future.then((products) => _sortProducts(products));
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ProductsLoadingView();
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _isFarmer ? 'У вас пока нет товаров' : 'Каталог пуст',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            // Double-check role before allowing creation
                            final isFarmer = await UserStorage.isFarmer;
                            if (!mounted) return;
                            
                            if (!isFarmer) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Только фермеры могут создавать товары'),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 3),
                                ),
                              );
                              return;
                            }
                            
                            final result = await context.push('/products/create');
                            if (!mounted) return;
                            
                            if (result == true) {
                              _refresh();
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Создать товар'),
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
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          onTap: () => _openProduct(product),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: Text(
                              product.name.isNotEmpty ? product.name[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.category, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    product.category,
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.attach_money, size: 14, color: Colors.green[700]),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${product.price.toStringAsFixed(2)} сум/${product.unit}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(Icons.inventory, size: 14, color: Colors.blue[700]),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${product.quantity.toStringAsFixed(1)} ${product.unit}',
                                    style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                                  ),
                                ],
                              ),
                              // Show farmer info for shops
                              if (!_isFarmer) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.person, size: 14, color: Colors.orange[700]),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Фермер: ${product.farmerId.substring(0, 8)}...',
                                      style: TextStyle(fontSize: 11, color: Colors.orange[700]),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: products.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigation(currentLocation: currentLocation),
    );
  }

  Widget _buildCategoryChip(String label, String? category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
            _future = _repository.fetchProducts(
              search: _searchController.text.isNotEmpty ? _searchController.text : null,
              category: _selectedCategory,
            ).then((products) => _sortProducts(products));
          });
        },
        selectedColor: Theme.of(context).colorScheme.primaryContainer,
        checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }
}
