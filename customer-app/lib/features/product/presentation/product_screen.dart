import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/cart_item.dart';
import '../../../data/models/product.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/providers.dart';

class ProductScreen extends ConsumerStatefulWidget {
  final Product product;
  const ProductScreen({super.key, required this.product});

  @override
  ConsumerState<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen> {
  ProductSize? _size;
  final Set<String> _addonIds = {};
  int _qty = 1;
  double _sugar = 100;
  double _ice = 100;
  final _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.product.sizes.isNotEmpty) _size = widget.product.sizes.first;
  }

  num get _unitPrice {
    final sizeMod = _size?.priceModifier ?? 0;
    final addonsSum = widget.product.addons
        .where((a) => _addonIds.contains(a.id))
        .fold<num>(0, (s, a) => s + a.price);
    return widget.product.basePrice + sizeMod + addonsSum;
  }

  void _addToCart() {
    final p = widget.product;
    final item = CartItem(
      uid: DateTime.now().microsecondsSinceEpoch.toString(),
      product: p,
      size: _size,
      addons: p.addons.where((a) => _addonIds.contains(a.id)).toList(),
      quantity: _qty,
      sugarLevel: _sugar.round(),
      iceLevel: _ice.round(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );
    ref.read(cartProvider.notifier).add(item);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('أُضيف ${p.nameAr} إلى السلة'), backgroundColor: AppColors.brand),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            actions: [_FavoriteButton(productId: p.id)],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.brandSurface,
                child: p.imageUrl != null
                    ? CachedNetworkImage(imageUrl: p.imageUrl!, fit: BoxFit.cover)
                    : const Center(child: Text('🥤', style: TextStyle(fontSize: 90))),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.nameAr, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  if (p.calories != null)
                    Text('${p.calories} سعرة حرارية',
                        style: TextStyle(color: AppColors.textMuted)),
                  if (p.descriptionAr != null) ...[
                    const SizedBox(height: 8),
                    Text(p.descriptionAr!, style: TextStyle(color: AppColors.textMuted, height: 1.5)),
                  ],
                  const SizedBox(height: 20),

                  if (p.sizes.isNotEmpty) ...[
                    const _SectionTitle('الحجم'),
                    Wrap(
                      spacing: 10,
                      children: p.sizes.map((s) {
                        final sel = _size?.id == s.id;
                        return ChoiceChip(
                          label: Text('${s.labelAr}'
                              '${s.priceModifier > 0 ? ' +${money(s.priceModifier)}' : ''}'),
                          selected: sel,
                          onSelected: (_) => setState(() => _size = s),
                          selectedColor: AppColors.brand,
                          labelStyle: TextStyle(
                              color: sel ? Colors.white : AppColors.textDark,
                              fontWeight: FontWeight.w600),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (p.addons.isNotEmpty) ...[
                    const _SectionTitle('الإضافات'),
                    ...p.addons.map((a) => CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: _addonIds.contains(a.id),
                          activeColor: AppColors.brand,
                          title: Text(a.nameAr),
                          secondary: Text('+${money(a.price)}',
                              style: const TextStyle(color: AppColors.brandDark, fontWeight: FontWeight.w700)),
                          onChanged: (v) => setState(() {
                            if (v == true) {
                              _addonIds.add(a.id);
                            } else {
                              _addonIds.remove(a.id);
                            }
                          }),
                        )),
                    const SizedBox(height: 12),
                  ],

                  const _SectionTitle('مستوى السكر'),
                  _LevelSlider(value: _sugar, onChanged: (v) => setState(() => _sugar = v)),
                  const SizedBox(height: 8),
                  const _SectionTitle('مستوى الثلج'),
                  _LevelSlider(value: _ice, onChanged: (v) => setState(() => _ice = v)),
                  const SizedBox(height: 20),

                  const _SectionTitle('ملاحظات خاصة'),
                  TextField(
                    controller: _notes,
                    maxLines: 2,
                    decoration: const InputDecoration(hintText: 'مثال: بدون سكر إضافي…'),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _BottomBar(
        qty: _qty,
        total: _unitPrice * _qty,
        onDec: () => setState(() => _qty = (_qty - 1).clamp(1, 99)),
        onInc: () => setState(() => _qty = (_qty + 1).clamp(1, 99)),
        onAdd: _addToCart,
      ),
    );
  }
}

class _FavoriteButton extends ConsumerWidget {
  final String productId;
  const _FavoriteButton({required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteIdsProvider);
    final isFav = favorites.contains(productId);
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle),
      child: IconButton(
        icon: Icon(
          isFav ? Icons.favorite : Icons.favorite_border,
          color: isFav ? AppColors.danger : AppColors.textDark,
        ),
        onPressed: () {
          if (ref.read(currentUserProvider) == null) {
            context.push('/login');
            return;
          }
          ref.read(favoriteIdsProvider.notifier).toggle(productId);
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      );
}

class _LevelSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const _LevelSlider({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Slider(
            value: value,
            min: 0,
            max: 100,
            divisions: 4,
            activeColor: AppColors.brand,
            label: '${value.round()}%',
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: 44, child: Text('${value.round()}%', textAlign: TextAlign.center)),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int qty;
  final num total;
  final VoidCallback onDec, onInc, onAdd;
  const _BottomBar({
    required this.qty,
    required this.total,
    required this.onDec,
    required this.onInc,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(onPressed: onDec, icon: const Icon(Icons.remove)),
                Text('$qty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                IconButton(onPressed: onInc, icon: const Icon(Icons.add)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: onAdd,
              child: Text('أضف للسلة  •  ${money(total)}'),
            ),
          ),
        ],
      ),
    );
  }
}
