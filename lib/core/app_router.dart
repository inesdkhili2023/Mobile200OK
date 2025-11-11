import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../modules/products/models/product_model.dart';
import '../modules/products/screens/product_form_screen.dart';
import '../modules/products/screens/product_list_screen.dart';
import '../modules/cart/screens/cart_screen.dart';
import '../modules/wishlist/screens/wishlist_screen.dart';
import '../widgets/main_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainScaffold(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const ProductListScreen(),
        ),
        GoRoute(
          path: '/wishlist',
          builder: (context, state) => const WishlistScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/cart',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: '/product-form',
      parentNavigatorKey: _rootNavigatorKey, // Display outside the ShellRoute
      builder: (context, state) {
        final product = state.extra as Product?;
        return ProductFormScreen(product: product);
      },
    ),
  ],
);
