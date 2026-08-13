import 'package:flutter/material.dart';
import 'package:azberry_customer/core/i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/order.dart';
import '../../../providers/providers.dart';
import '../../tracking/presentation/order_tracking_screen.dart' show statusColor;

/// "My orders" tab — active orders on top (tap to live-track), then past ones.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final ordersAsync = ref.watch(myOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr('طلباتي'))),
      body: user == null
          ? _Guest(onLogin: () => context.push('/login'))
          : ordersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('خطأ: $e')),
              data: (orders) {
                if (orders.isEmpty) {
                  return _Empty();
                }
                final active = orders
                    .where((o) =>
                        o.status != OrderStatus.delivered &&
                        o.status != OrderStatus.cancelled)
                    .toList();
                final past = orders
                    .where((o) =>
                        o.status == OrderStatus.delivered ||
                        o.status == OrderStatus.cancelled)
                    .toList();

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(myOrdersProvider),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (active.isNotEmpty) ...[
                        _SectionTitle(tr('الطلبات الحالية')),
                        for (final o in active) _OrderCard(order: o, live: true),
                        const SizedBox(height: 16),
                      ],
                      if (past.isNotEmpty) ...[
                        _SectionTitle(tr('طلبات سابقة')),
                        for (final o in past) _OrderCard(order: o, live: false),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final AppOrder order;
  final bool live;
  const _OrderCard({required this.order, required this.live});

  @override
  Widget build(BuildContext context) {
    final c = statusColor(order.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => context.push('/order/${order.id}'),
        leading: CircleAvatar(
          backgroundColor: c.withValues(alpha: 0.14),
          child: Text(live ? '🛵' : '🧾', style: const TextStyle(fontSize: 18)),
        ),
        title: Text('${tr('طلب')} #${order.id.substring(0, 8)}',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              _StatusPill(c, order.status.labelAr),
              const SizedBox(width: 8),
              Text(timeAgo(order.createdAt),
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ),
        trailing: Text(money(order.total),
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: AppColors.brandDark)),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final Color color;
  final String label;
  const _StatusPill(this.color, this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🧾', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 8),
          Text(tr('لا توجد طلبات بعد'),
              style: TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _Guest extends StatelessWidget {
  final VoidCallback onLogin;
  const _Guest({required this.onLogin});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🧾', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 12),
            Text(tr('سجّل الدخول لمتابعة طلباتك'),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onLogin, child: Text(tr('تسجيل الدخول'))),
          ],
        ),
      ),
    );
  }
}
