import 'package:flutter/material.dart';
import 'package:azberry_customer/core/i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/providers.dart';
import '../../home/presentation/widgets/product_card.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final async = ref.watch(favoriteProductsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr('المفضلة'))),
      body: user == null
          ? const _Guest()
          : async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('خطأ: $e')),
              data: (products) => products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🤍', style: TextStyle(fontSize: 60)),
                          const SizedBox(height: 8),
                          Text(tr('لا توجد منتجات مفضّلة بعد'),
                              style: TextStyle(color: AppColors.textMuted)),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: products.length,
                      itemBuilder: (_, i) => ProductCard(
                        product: products[i],
                        onTap: () => context.push('/product', extra: products[i]),
                      ),
                    ),
            ),
    );
  }
}

class _Guest extends StatelessWidget {
  const _Guest();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🤍', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 12),
            Text(tr('سجّل الدخول لعرض مفضّلتك'),
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/login'),
              child: Text(tr('تسجيل الدخول')),
            ),
          ],
        ),
      ),
    );
  }
}
