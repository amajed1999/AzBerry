import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/product/presentation/product_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/tracking/presentation/order_tracking_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/addresses/presentation/addresses_screen.dart';
import '../../features/favorites/presentation/favorites_screen.dart';
import '../../data/models/product.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(
      path: '/product',
      builder: (_, state) => ProductScreen(product: state.extra as Product),
    ),
    GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
    GoRoute(
      path: '/order/:id',
      builder: (_, state) =>
          OrderTrackingScreen(orderId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    GoRoute(path: '/addresses', builder: (_, __) => const AddressesScreen()),
    GoRoute(path: '/favorites', builder: (_, __) => const FavoritesScreen()),
  ],
);
