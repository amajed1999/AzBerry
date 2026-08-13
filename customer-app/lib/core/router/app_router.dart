import 'package:go_router/go_router.dart';

import '../../features/splash/presentation/splash_screen.dart';
import '../../features/shell/presentation/main_shell.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/product/presentation/product_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/tracking/presentation/order_tracking_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/addresses/presentation/addresses_screen.dart';
import '../../features/favorites/presentation/favorites_screen.dart';
import '../../features/wallet/presentation/wallet_screen.dart';
import '../../features/referral/presentation/referral_screen.dart';
import '../../data/models/product.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    // Full-screen routes (no bottom navigation bar).
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
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
    GoRoute(path: '/addresses', builder: (_, __) => const AddressesScreen()),
    GoRoute(path: '/wallet', builder: (_, __) => const WalletScreen()),
    GoRoute(path: '/referral', builder: (_, __) => const ReferralScreen()),

    // Primary tabs with a persistent bottom navigation bar.
    StatefulShellRoute.indexedStack(
      builder: (_, __, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/orders', builder: (_, __) => const OrdersScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
              path: '/favorites', builder: (_, __) => const FavoritesScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ]),
      ],
    ),
  ],
);
