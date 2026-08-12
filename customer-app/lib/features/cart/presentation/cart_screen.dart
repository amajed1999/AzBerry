import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/address.dart';
import '../../../data/models/cart_item.dart';
import '../../../data/repositories/orders_repository.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/providers.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  String _orderType = 'delivery'; // delivery | pickup
  String _payment = 'cash';
  bool _placing = false;

  final _promoController = TextEditingController();
  bool _checkingPromo = false;
  String? _promoMessage;
  bool _promoValid = false;
  num _promoDiscount = 0;
  bool _promoDeliveryWaived = false;

  String? _selectedAddressId;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _applyPromo() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;
    final branch = ref.read(selectedBranchProvider);
    if (branch == null) return;

    setState(() => _checkingPromo = true);
    final result = await ref.read(ordersRepoProvider).validatePromo(
          code: code,
          branchId: branch.id,
          subtotal: ref.read(cartSubtotalProvider),
        );
    if (!mounted) return;
    setState(() {
      _checkingPromo = false;
      _promoValid = result.valid;
      _promoMessage = result.message;
      _promoDiscount = result.valid ? result.discount : 0;
      _promoDeliveryWaived = result.valid && result.deliveryWaived;
    });
  }

  Future<void> _checkout() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      // Guest: must sign in before placing an order (RLS requires auth).
      final go = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('تسجيل الدخول مطلوب'),
          content: const Text('لإتمام الطلب يجب تسجيل الدخول أولاً.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لاحقاً')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('تسجيل الدخول')),
          ],
        ),
      );
      if (go == true && mounted) context.push('/login');
      return;
    }

    final branch = ref.read(selectedBranchProvider);
    final items = ref.read(cartProvider);
    if (branch == null || items.isEmpty) return;

    // Delivery orders require a saved address.
    if (_orderType == 'delivery' && _selectedAddressId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('اختر عنوان التوصيل أولاً')));
      return;
    }

    final promo = _promoController.text.trim();

    setState(() => _placing = true);
    try {
      // Prices/discount/tax are all recomputed authoritatively by the server.
      final placed = await ref.read(ordersRepoProvider).placeOrder(
            branchId: branch.id,
            items: items,
            orderType: _orderType,
            paymentMethod: _payment,
            promoCode: promo.isEmpty ? null : promo,
            addressId: _orderType == 'delivery' ? _selectedAddressId : null,
          );
      ref.read(cartProvider.notifier).clear();
      if (mounted) context.go('/order/${placed.orderId}');
    } on PlaceOrderException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('تعذّر إنشاء الطلب: $e')));
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(cartProvider);
    final branch = ref.watch(selectedBranchProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final baseDelivery = _orderType == 'delivery' ? (branch?.deliveryFee ?? 0) : 0;
    final deliveryFee = _promoDeliveryWaived ? 0 : baseDelivery;
    final total = subtotal - _promoDiscount + deliveryFee;

    final user = ref.watch(currentUserProvider);
    final addressesAsync = user == null
        ? const AsyncValue<List<Address>>.data([])
        : ref.watch(addressesProvider);
    final addresses = addressesAsync.asData?.value ?? const <Address>[];
    // Auto-select the default (or first) address once loaded.
    if (_selectedAddressId == null && addresses.isNotEmpty) {
      final def = addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first);
      _selectedAddressId = def.id;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('السلة')),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🛒', style: TextStyle(fontSize: 60)),
                  const SizedBox(height: 8),
                  Text('سلتك فارغة', style: TextStyle(color: AppColors.textMuted)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _CartTile(item: items[i]),
                  ),
                ),
                _CheckoutPanel(
                  orderType: _orderType,
                  onOrderType: (v) => setState(() => _orderType = v),
                  payment: _payment,
                  onPayment: (v) => setState(() => _payment = v),
                  subtotal: subtotal,
                  deliveryFee: deliveryFee,
                  discount: _promoDiscount,
                  total: total,
                  minOrder: branch?.minOrder ?? 0,
                  placing: _placing,
                  onCheckout: _checkout,
                  promoController: _promoController,
                  promoMessage: _promoMessage,
                  promoValid: _promoValid,
                  checkingPromo: _checkingPromo,
                  onApplyPromo: _applyPromo,
                  isGuest: user == null,
                  addresses: addresses,
                  selectedAddressId: _selectedAddressId,
                  onSelectAddress: (id) => setState(() => _selectedAddressId = id),
                  onManageAddresses: () =>
                      context.push('/addresses').then((_) => ref.invalidate(addressesProvider)),
                ),
              ],
            ),
    );
  }
}

class _CartTile extends ConsumerWidget {
  final CartItem item;
  const _CartTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.read(cartProvider.notifier);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Text('🥤', style: TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.nameAr, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  [
                    if (item.size != null) item.size!.labelAr,
                    if (item.addons.isNotEmpty) item.addons.map((a) => a.nameAr).join('، '),
                  ].join('  •  '),
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 4),
                Text(money(item.lineTotal),
                    style: const TextStyle(color: AppColors.brandDark, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Row(
            children: [
              _RoundBtn(icon: Icons.remove, onTap: () => cart.setQuantity(item.uid, item.quantity - 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              _RoundBtn(icon: Icons.add, onTap: () => cart.setQuantity(item.uid, item.quantity + 1)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18),
        ),
      );
}

class _AddressSelector extends StatelessWidget {
  final List<Address> addresses;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final VoidCallback onManage;
  const _AddressSelector({
    required this.addresses,
    required this.selectedId,
    required this.onSelect,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    if (addresses.isEmpty) {
      return InkWell(
        onTap: onManage,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.brand),
          ),
          child: Row(
            children: [
              const Icon(Icons.add_location_alt, color: AppColors.brand),
              const SizedBox(width: 8),
              const Expanded(child: Text('أضف عنوان توصيل', style: TextStyle(fontWeight: FontWeight.w600))),
              Icon(Icons.chevron_left, color: AppColors.textMuted),
            ],
          ),
        ),
      );
    }
    final selected = addresses.firstWhere(
      (a) => a.id == selectedId,
      orElse: () => addresses.first,
    );
    return InkWell(
      onTap: () => _pick(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: AppColors.brand),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(selected.label ?? 'عنوان',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (selected.addressText != null && selected.addressText!.isNotEmpty)
                    Text(selected.addressText!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Text('تغيير', style: TextStyle(color: AppColors.brandDark, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  void _pick(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('اختر عنوان التوصيل',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
            ...addresses.map((a) => ListTile(
                  leading: const Icon(Icons.location_on, color: AppColors.brand),
                  title: Text(a.label ?? 'عنوان'),
                  subtitle: a.addressText != null ? Text(a.addressText!) : null,
                  trailing: a.id == selectedId
                      ? const Icon(Icons.check_circle, color: AppColors.brand)
                      : null,
                  onTap: () {
                    onSelect(a.id);
                    Navigator.pop(context);
                  },
                )),
            ListTile(
              leading: const Icon(Icons.add, color: AppColors.brand),
              title: const Text('إدارة العناوين'),
              onTap: () {
                Navigator.pop(context);
                onManage();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _CheckoutPanel extends StatelessWidget {
  final String orderType;
  final ValueChanged<String> onOrderType;
  final String payment;
  final ValueChanged<String> onPayment;
  final num subtotal, deliveryFee, discount, total, minOrder;
  final bool placing;
  final VoidCallback onCheckout;
  final TextEditingController promoController;
  final String? promoMessage;
  final bool promoValid;
  final bool checkingPromo;
  final VoidCallback onApplyPromo;
  final bool isGuest;
  final List<Address> addresses;
  final String? selectedAddressId;
  final ValueChanged<String> onSelectAddress;
  final VoidCallback onManageAddresses;

  const _CheckoutPanel({
    required this.orderType,
    required this.onOrderType,
    required this.payment,
    required this.onPayment,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.minOrder,
    required this.placing,
    required this.onCheckout,
    required this.promoController,
    required this.promoMessage,
    required this.promoValid,
    required this.checkingPromo,
    required this.onApplyPromo,
    required this.isGuest,
    required this.addresses,
    required this.selectedAddressId,
    required this.onSelectAddress,
    required this.onManageAddresses,
  });

  @override
  Widget build(BuildContext context) {
    final belowMin = subtotal < minOrder;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Order type
          Row(
            children: [
              _Toggle(label: 'توصيل', selected: orderType == 'delivery', onTap: () => onOrderType('delivery')),
              const SizedBox(width: 10),
              _Toggle(label: 'استلام', selected: orderType == 'pickup', onTap: () => onOrderType('pickup')),
            ],
          ),
          const SizedBox(height: 12),

          // Delivery address (delivery only)
          if (orderType == 'delivery' && !isGuest) ...[
            _AddressSelector(
              addresses: addresses,
              selectedId: selectedAddressId,
              onSelect: onSelectAddress,
              onManage: onManageAddresses,
            ),
            const SizedBox(height: 12),
          ],
          // Payment method
          DropdownButtonFormField<String>(
            initialValue: payment,
            decoration: const InputDecoration(labelText: 'طريقة الدفع'),
            items: const [
              DropdownMenuItem(value: 'cash', child: Text('نقداً عند الاستلام')),
              DropdownMenuItem(value: 'zaincash', child: Text('ZainCash')),
              DropdownMenuItem(value: 'asiahawala', child: Text('AsiaHawala')),
              DropdownMenuItem(value: 'fastpay', child: Text('FastPay')),
              DropdownMenuItem(value: 'qicard', child: Text('Qi Card')),
              DropdownMenuItem(value: 'card', child: Text('بطاقة')),
              DropdownMenuItem(value: 'wallet', child: Text('المحفظة')),
            ],
            onChanged: (v) => onPayment(v ?? 'cash'),
          ),
          const SizedBox(height: 12),
          // Promo code
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: promoController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(hintText: 'كود الخصم'),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: checkingPromo ? null : onApplyPromo,
                  child: Text(checkingPromo ? '…' : 'تطبيق'),
                ),
              ),
            ],
          ),
          if (promoMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  promoMessage!,
                  style: TextStyle(
                    fontSize: 12,
                    color: promoValid ? AppColors.brandDark : AppColors.danger,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          _row('المجموع الفرعي', subtotal),
          if (discount > 0) _row('الخصم', -discount),
          if (orderType == 'delivery') _row('رسوم التوصيل', deliveryFee),
          const Divider(),
          _row('الإجمالي', total, bold: true),
          const SizedBox(height: 12),
          if (belowMin)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('الحد الأدنى للطلب ${money(minOrder)}',
                  style: const TextStyle(color: AppColors.danger, fontSize: 12)),
            ),
          ElevatedButton(
            onPressed: (placing || belowMin) ? null : onCheckout,
            child: Text(placing ? 'جارِ إرسال الطلب…' : 'تأكيد الطلب'),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, num value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                    fontSize: bold ? 16 : 14)),
            Text(money(value),
                style: TextStyle(
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                    fontSize: bold ? 16 : 14,
                    color: bold ? AppColors.brandDark : AppColors.textDark)),
          ],
        ),
      );
}

class _Toggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Toggle({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.brand : AppColors.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? AppColors.brand : AppColors.border),
            ),
            child: Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : AppColors.textDark,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      );
}
