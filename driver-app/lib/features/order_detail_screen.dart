import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../data/models.dart';
import '../providers.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(orderByIdProvider(orderId));
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الطلب')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (o) => o == null
            ? const Center(child: Text('الطلب غير موجود'))
            : _Detail(order: o),
      ),
    );
  }
}

class _Detail extends ConsumerStatefulWidget {
  final DeliveryOrder order;
  const _Detail({required this.order});
  @override
  ConsumerState<_Detail> createState() => _DetailState();
}

class _DetailState extends ConsumerState<_Detail> {
  bool _busy = false;

  Future<void> _advance(String status) async {
    setState(() => _busy = true);
    await ref.read(driverRepoProvider).setStatus(widget.order.id, status);
    if (!mounted) return;
    setState(() => _busy = false);
    ref.invalidate(orderByIdProvider(widget.order.id));
    ref.invalidate(activeOrderProvider);
    ref.invalidate(summaryProvider);
    if (status == 'delivered' && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسليم الطلب ✅'), backgroundColor: AppColors.success),
      );
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // status banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.brandSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_shipping, color: AppColors.brand),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('طلب #${o.id.substring(0, 8)}',
                              style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text(o.status.labelAr,
                              style: const TextStyle(color: AppColors.brandDark, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    Text(timeAgo(o.createdAt),
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _InfoRow(icon: Icons.store, label: 'الفرع', value: o.branchName ?? '—'),
              _InfoRow(
                icon: Icons.payments,
                label: 'المبلغ',
                value: '${money(o.total)}  •  ${paymentLabels[o.paymentMethod] ?? o.paymentMethod}'
                    '${o.paymentStatus == 'paid' ? ' (مدفوع)' : ''}',
              ),
              if (o.orderType == 'pickup')
                const _InfoRow(icon: Icons.storefront, label: 'النوع', value: 'استلام من الفرع')
              else ...[
                _InfoRow(icon: Icons.person, label: 'الزبون', value: o.customerName ?? '—'),
                _InfoRow(
                  icon: Icons.location_on,
                  label: 'العنوان',
                  value: o.addressText ?? (o.addrLat != null ? '${o.addrLat}, ${o.addrLng}' : '—'),
                ),
              ],
              if (o.notes != null && o.notes!.isNotEmpty)
                _InfoRow(icon: Icons.sticky_note_2, label: 'ملاحظات', value: o.notes!),

              const SizedBox(height: 16),
              // Map placeholder
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map, size: 36, color: AppColors.textMuted),
                      SizedBox(height: 6),
                      Text('خريطة الوجهة',
                          style: TextStyle(color: AppColors.textMuted)),
                      Text('(تتطلب تفعيل Google Maps)',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ),

              if (o.customerPhone != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('اتصال بـ ${o.customerPhone} (يتطلب حزمة الاتصال)')),
                    );
                  },
                  icon: const Icon(Icons.phone),
                  label: Text('اتصال بالزبون ${o.customerPhone}'),
                ),
              ],
            ],
          ),
        ),
        _ActionBar(status: o.status, busy: _busy, onAdvance: _advance),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  final DStatus status;
  final bool busy;
  final void Function(String status) onAdvance;
  const _ActionBar({required this.status, required this.busy, required this.onAdvance});

  @override
  Widget build(BuildContext context) {
    Widget? button;
    if (status == DStatus.confirmed || status == DStatus.preparing || status == DStatus.ready) {
      button = ElevatedButton.icon(
        onPressed: busy ? null : () => onAdvance('on_the_way'),
        icon: const Icon(Icons.directions_bike),
        label: const Text('استلمت الطلب — بالطريق'),
      );
    } else if (status == DStatus.onTheWay) {
      button = ElevatedButton.icon(
        onPressed: busy ? null : () => onAdvance('delivered'),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
        icon: const Icon(Icons.check_circle),
        label: const Text('تم التسليم'),
      );
    }
    if (button == null) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SizedBox(width: double.infinity, child: button),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textMuted),
          const SizedBox(width: 12),
          SizedBox(
            width: 64,
            child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
