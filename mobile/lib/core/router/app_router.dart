import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/token_storage.dart';
import '../../features/auth/view/auth_flow.dart';
import '../../features/orders/view/orders_screen.dart';
import '../../features/products/view/create_product_screen.dart';
import '../../features/products/view/product_catalog_screen.dart';
import '../../features/products/view/product_detail_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/auth',
    redirect: (context, state) async {
      final isAuthenticated = await TokenStorage.accessToken != null;
      final isAuthRoute = state.matchedLocation == '/auth';

      if (!isAuthenticated && !isAuthRoute) {
        return '/auth';
      }
      if (isAuthenticated && isAuthRoute) {
        return '/products';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthFlowScreen(),
      ),
      GoRoute(
        path: '/products',
        builder: (context, state) => const ProductCatalogScreen(),
      ),
      GoRoute(
        path: '/products/:id',
        builder: (context, state) {
          final productId = state.pathParameters['id']!;
          // Note: We need to pass product data, but for MVP we'll fetch it in the screen
          return ProductDetailScreen(productId: productId);
        },
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/products/create',
        builder: (context, state) => const CreateProductScreen(),
      ),
    ],
  );
}

