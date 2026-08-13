import 'package:flutter/material.dart';
import 'package:azberry_customer/core/i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/order.dart';
import '../../../providers/providers.dart';

/// Realtime stream of a single order.
final orderStreamProvider =
    StreamProvider.family<AppOrder, String>((ref, id) {
  return ref.watch(ordersRepoProvider).watch(id);
});

const _timeline = [
  OrderStatus.pending,
  OrderStatus.confirmed,
  OrderStatus.preparing,
  OrderStatus.ready,
  OrderStatus.onTheWay,
  OrderStatus.delivered,
];

/// Canonical status → color, matching the admin dashboard board colors.
Color statusColor(OrderStatus s) {
  switch (s) {
    case OrderStatus.pending:
      return AppColors.statusPending;
    case OrderStatus.confirmed:
      return AppColors.statusConfirmed;
    case OrderStatus.preparing:
      return AppColors.statusPreparing;
    case OrderStatus.ready:
      return AppColors.statusReady;
    case OrderStatus.onTheWay:
      return AppColors.statusOnWay;
    case OrderStatus.delivered:
      return AppColors.statusDelivered;
    case OrderStatus.cancelled:
      return AppColors.statusCancelled;
  }
}

class OrderTrackingScreen extends ConsumerWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderStreamProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('تتبّع الطلب')),
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          onPressed: () => context.go('/'),
        ),
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (order) {
          if (order.status == OrderStatus.cancelled) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('❌', style: TextStyle(fontSize: 60)),
                  Text(tr('تم إلغاء الطلب'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
            );
          }
          final currentIndex = _timeline.indexOf(order.status);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.brandSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Text('🧾', style: TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${tr('طلب')} #${order.id.substring(0, 8)}',
                              style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text('الإجمالي ${money(order.total)}  •  ${timeAgo(order.createdAt)}',
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    _StatusPill(order.status),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ...List.generate(_timeline.length, (i) {
                final status = _timeline[i];
                final done = i <= currentIndex;
                final isCurrent = i == currentIndex;
                return _TimelineStep(
                  label: status.labelAr,
                  done: done,
                  isCurrent: isCurrent,
                  isLast: i == _timeline.length - 1,
                  accent: statusColor(status),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final OrderStatus status;
  const _StatusPill(this.status);

  @override
  Widget build(BuildContext context) {
    final c = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Text(
        status.labelAr,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c),
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String label;
  final bool done;
  final bool isCurrent;
  final bool isLast;
  final Color accent;
  const _TimelineStep({
    required this.label,
    required this.done,
    required this.isCurrent,
    required this.isLast,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    // Current step uses its status color; completed steps use brand; future grey.
    final dotColor =
        isCurrent ? accent : (done ? AppColors.brand : AppColors.border);
    final lineColor = done ? AppColors.brand : AppColors.border;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration:
                    BoxDecoration(color: dotColor, shape: BoxShape.circle),
                child: Icon(
                  done ? Icons.check : Icons.circle,
                  size: 16,
                  color: done ? Colors.white : AppColors.textMuted,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: lineColor),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Padding(
            padding: const EdgeInsets.only(top: 3, bottom: 24),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                color: done ? AppColors.textDark : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
