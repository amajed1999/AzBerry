import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../data/models.dart';
import '../providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const _NeedLogin();

    final driverAsync = ref.watch(myDriverProvider);
    return driverAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('خطأ: $e'))),
      data: (driver) {
        if (driver == null) return const _NotADriver();
        return _DriverHome(driver: driver);
      },
    );
  }
}

class _DriverHome extends ConsumerStatefulWidget {
  final Driver driver;
  const _DriverHome({required this.driver});
  @override
  ConsumerState<_DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends ConsumerState<_DriverHome> {
  late bool _online;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _online = widget.driver.isOnline;
  }

  Future<void> _setOnline(bool v) async {
    setState(() => _toggling = true);
    await ref.read(driverRepoProvider).setOnline(v);
    if (!mounted) return;
    setState(() {
      _online = v;
      _toggling = false;
    });
    ref.invalidate(availableOrdersProvider);
  }

  Future<void> _refresh() async {
    ref.invalidate(availableOrdersProvider);
    ref.invalidate(activeOrderProvider);
    ref.invalidate(summaryProvider);
  }

  Future<void> _accept(DeliveryOrder o) async {
    final ok = await ref.read(driverRepoProvider).accept(o.id, widget.driver.id);
    if (!mounted) return;
    if (ok) {
      _refresh();
      context.push('/order/${o.id}');
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('سبقك سائق آخر لهذا الطلب')));
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeAsync = ref.watch(activeOrderProvider);
    final availableAsync = ref.watch(availableOrdersProvider);
    final summaryAsync = ref.watch(summaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلباتي'),
        actions: [
          Row(
            children: [
              Text(_online ? 'متصل' : 'غير متصل',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _online ? AppColors.success : AppColors.textMuted)),
              Switch(
                value: _online,
                activeThumbColor: AppColors.success,
                onChanged: _toggling ? null : _setOnline,
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Daily summary
            summaryAsync.when(
              loading: () => const SizedBox(height: 90),
              error: (_, __) => const SizedBox(),
              data: (s) => Row(
                children: [
                  _SummaryChip(label: 'طلبات اليوم', value: '${s.count}', icon: Icons.check_circle),
                  const SizedBox(width: 10),
                  _SummaryChip(label: 'الأرباح', value: money(s.earnings), icon: Icons.payments),
                  const SizedBox(width: 10),
                  _SummaryChip(label: 'نقداً محصّل', value: money(s.cash), icon: Icons.attach_money),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Active order
            activeAsync.when(
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
              data: (active) {
                if (active == null) return const SizedBox();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('طلبك الحالي',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 8),
                    _OrderCard(
                      order: active,
                      highlight: true,
                      onTap: () => context.push('/order/${active.id}'),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),

            // Available orders
            const Text('الطلبات المتاحة', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            if (!_online)
              const _Hint(text: 'أنت غير متصل. فعّل الاتصال لاستقبال الطلبات.')
            else
              availableAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('خطأ: $e'),
                data: (orders) => orders.isEmpty
                    ? const _Hint(text: 'لا توجد طلبات متاحة حالياً.')
                    : Column(
                        children: orders
                            .map((o) => _OrderCard(
                                  order: o,
                                  onTap: () => context.push('/order/${o.id}'),
                                  onAccept: () => _accept(o),
                                ))
                            .toList(),
                      ),
              ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(supabaseProvider).auth.signOut();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout, color: AppColors.danger),
              label: const Text('تسجيل الخروج', style: TextStyle(color: AppColors.danger)),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final DeliveryOrder order;
  final bool highlight;
  final VoidCallback onTap;
  final VoidCallback? onAccept;
  const _OrderCard({
    required this.order,
    this.highlight = false,
    required this.onTap,
    this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: highlight ? AppColors.brand : AppColors.border, width: highlight ? 1.5 : 1),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: onTap,
            leading: const CircleAvatar(
              backgroundColor: AppColors.brandSurface,
              child: Icon(Icons.receipt_long, color: AppColors.brand),
            ),
            title: Text('طلب #${order.id.substring(0, 8)}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
              '${order.branchName ?? ''} • ${order.status.labelAr}\n'
              '${money(order.total)} • ${paymentLabels[order.paymentMethod] ?? order.paymentMethod}',
            ),
            isThreeLine: true,
            trailing: Text(timeAgo(order.createdAt),
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
          if (onAccept != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: onAccept, child: const Text('قبول الطلب')),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _SummaryChip({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.brand, size: 20),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;
  const _Hint({required this.text});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
      );
}

class _NeedLogin extends StatelessWidget {
  const _NeedLogin();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delivery_dining, size: 70, color: AppColors.brand),
            const SizedBox(height: 12),
            const Text('مرحباً بك سائق AzBerry',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton(
                onPressed: () => context.push('/login'),
                child: const Text('تسجيل الدخول'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotADriver extends ConsumerWidget {
  const _NotADriver();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🚫', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              const Text('هذا الحساب ليس سائقاً',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('تواصل مع الإدارة لتفعيل حسابك كسائق.',
                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () async {
                  await ref.read(supabaseProvider).auth.signOut();
                  if (context.mounted) context.go('/login');
                },
                child: const Text('تسجيل الخروج'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
