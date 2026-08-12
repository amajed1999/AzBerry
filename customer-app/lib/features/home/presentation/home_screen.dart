import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/branch.dart';
import '../../../data/models/product.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/providers.dart';
import 'widgets/branch_selector_sheet.dart';
import 'widgets/product_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(branchesProvider);
    final selectedBranch = ref.watch(selectedBranchProvider);
    final cartCount = ref.watch(cartCountProvider);

    // Auto-select first branch once loaded.
    ref.listen(branchesProvider, (_, next) {
      next.whenData((list) {
        if (list.isNotEmpty && ref.read(selectedBranchProvider) == null) {
          ref.read(selectedBranchProvider.notifier).state = list.first;
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: _BranchButton(
          branch: selectedBranch,
          onTap: () => showModalBottomSheet(
            context: context,
            builder: (_) => const BranchSelectorSheet(),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person_outline),
          ),
          _CartButton(count: cartCount, onTap: () => context.push('/cart')),
          const SizedBox(width: 8),
        ],
      ),
      body: branchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ في التحميل: $e')),
        data: (_) => const _MenuBody(),
      ),
    );
  }
}

class _BranchButton extends StatelessWidget {
  final Branch? branch;
  final VoidCallback onTap;
  const _BranchButton({required this.branch, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, color: AppColors.brand, size: 20),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('التوصيل من', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              Text(branch?.nameAr ?? 'اختر الفرع',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const Icon(Icons.keyboard_arrow_down, size: 20),
        ],
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _CartButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(onPressed: onTap, icon: const Icon(Icons.shopping_bag_outlined)),
        if (count > 0)
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
              child: Text('$count',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }
}

class _MenuBody extends ConsumerWidget {
  const _MenuBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(productsProvider);
    final selectedCat = ref.watch(selectedCategoryProvider);
    final query = ref.watch(searchQueryProvider);

    return CustomScrollView(
      slivers: [
        // Search
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
              decoration: const InputDecoration(
                hintText: 'ابحث عن مشروب…',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ),
        // Category chips
        SliverToBoxAdapter(
          child: categoriesAsync.when(
            loading: () => const SizedBox(height: 48),
            error: (_, __) => const SizedBox(),
            data: (cats) => SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _Chip(
                    label: 'الكل',
                    selected: selectedCat == null,
                    onTap: () => ref.read(selectedCategoryProvider.notifier).state = null,
                  ),
                  for (final c in cats)
                    _Chip(
                      label: c.nameAr,
                      selected: selectedCat == c.id,
                      onTap: () => ref.read(selectedCategoryProvider.notifier).state = c.id,
                    ),
                ],
              ),
            ),
          ),
        ),
        // Products grid
        productsAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('خطأ: $e'))),
          data: (products) {
            final filtered = _filter(products, selectedCat, query);
            if (filtered.isEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: Text('لا توجد منتجات', style: TextStyle(color: AppColors.textMuted))),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) => ProductCard(
                    product: filtered[i],
                    onTap: () => context.push('/product', extra: filtered[i]),
                  ),
                  childCount: filtered.length,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  List<Product> _filter(List<Product> products, String? cat, String query) {
    final q = query.trim().toLowerCase();
    return products.where((p) {
      final matchCat = cat == null || p.categoryId == cat;
      final matchQuery = q.isEmpty ||
          p.nameAr.toLowerCase().contains(q) ||
          p.nameEn.toLowerCase().contains(q);
      return matchCat && matchQuery;
    }).toList();
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.brand,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.textDark,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
