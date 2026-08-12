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
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String label;
  final bool done;
  final bool isCurrent;
  final bool isLast;
  const _TimelineStep({
    required this.label,
    required this.done,
    required this.isCurrent,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = done ? AppColors.brand : AppColors.border;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(
                  done ? Icons.check : Icons.circle,
                  size: 16,
                  color: done ? Colors.white : AppColors.textMuted,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: color),
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
