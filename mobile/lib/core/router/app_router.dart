import 'package:go_router/go_router.dart';

import '../../core/storage/token_storage.dart';
import '../../features/auth/view/auth_flow.dart';
import '../../features/favorites/view/favorites_screen.dart';
import '../../features/orders/view/orders_screen.dart';
import '../../features/products/view/create_product_screen.dart';
import '../../features/products/view/product_catalog_screen.dart';
import '../../features/products/view/product_detail_screen.dart';
import '../../features/view_history/view/view_history_screen.dart';

class AppRouter {
  // Set to true to always show auth screen on startup (for testing)
  static const bool _forceAuthOnStartup = true;
  
  static final GoRouter router = GoRouter(
    initialLocation: '/auth',
    redirect: (context, state) async {
      final token = await TokenStorage.accessToken;
      final isAuthenticated = token != null && token.isNotEmpty;
      final isAuthRoute = state.matchedLocation == '/auth';

      // If not authenticated, always redirect to auth
      if (!isAuthenticated) {
        if (!isAuthRoute) {
          return '/auth';
        }
        return null; // Stay on auth route
      }
      
      // If force auth on startup is enabled, always show auth screen first
      // User can still navigate to products manually after auth
      if (_forceAuthOnStartup && isAuthRoute) {
        return null; // Stay on auth route even if authenticated
      }
      
      // If authenticated and trying to access auth route, redirect to products
      if (isAuthenticated && isAuthRoute && !_forceAuthOnStartup) {
        return '/products';
      }
      
      // If authenticated and accessing other routes, allow access
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
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/view-history',
        builder: (context, state) => const ViewHistoryScreen(),
      ),
    ],
  );
}

