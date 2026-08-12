import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/order.dart';
import '../../../providers/providers.dart';
import '../../../providers/settings_provider.dart';
import '../../reviews/presentation/review_dialog.dart';

final myOrdersProvider = FutureProvider<List<AppOrder>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(ordersRepoProvider).myOrders(user.id);
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final mode = ref.watch(themeModeProvider);
    final isDark = mode == ThemeMode.dark ||
        (mode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابي'),
        actions: [
          IconButton(
            tooltip: isDark ? 'الوضع النهاري' : 'الوضع الليلي',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () =>
                ref.read(themeModeProvider.notifier).toggleDark(!isDark),
          ),
        ],
      ),
      body: user == null ? _GuestView(onLogin: () => context.push('/login')) : const _AccountView(),
    );
  }
}

class _GuestView extends StatelessWidget {
  final VoidCallback onLogin;
  const _GuestView({required this.onLogin});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👤', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 12),
            const Text('أنت تتصفّح كضيف',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('سجّل الدخول لحفظ طلباتك ونقاط الولاء',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onLogin, child: const Text('تسجيل الدخول')),
          ],
        ),
      ),
    );
  }
}

class _AccountView extends ConsumerWidget {
  const _AccountView();

  Future<void> _editName(BuildContext context, WidgetRef ref, String current) async {
    final controller = TextEditingController(text: current);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تعديل الاسم'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'اسمك'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(accountRepoProvider).updateProfile(name: controller.text.trim());
      ref.invalidate(myProfileProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(myProfileProvider);
    final ordersAsync = ref.watch(myOrdersProvider);

    final profile = profileAsync.asData?.value;
    final name = (profile?['name'] as String?) ?? user?.phone ?? user?.email ?? 'مستخدم';
    final points = (profile?['points_balance'] as num?) ?? 0;
    final wallet = (profile?['wallet_balance'] as num?) ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.brand.withValues(alpha: 0.35)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.brand,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(name,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.textDark)),
                  ),
                  IconButton(
                    onPressed: () => _editName(context, ref, name),
                    icon: const Icon(Icons.edit, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _StatChip(icon: Icons.stars, label: 'نقاط الولاء', value: '$points')),
                  const SizedBox(width: 10),
                  Expanded(child: _StatChip(icon: Icons.account_balance_wallet, label: 'المحفظة', value: money(wallet))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Menu
        _MenuTile(icon: Icons.location_on_outlined, label: 'عناويني', onTap: () => context.push('/addresses')),
        _MenuTile(icon: Icons.favorite_border, label: 'المفضلة', onTap: () => context.push('/favorites')),
        const SizedBox(height: 16),

        // Orders
        const Text('سجل الطلبات', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 8),
        ordersAsync.when(
          loading: () => const Center(
            child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('خطأ: $e'),
          data: (orders) => orders.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('لا توجد طلبات بعد', style: TextStyle(color: AppColors.textMuted))),
                )
              : Column(
                  children: orders.map((o) => _OrderTile(order: o)).toList(),
                ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () async {
            await ref.read(supabaseProvider).auth.signOut();
            if (context.mounted) context.go('/');
          },
          icon: const Icon(Icons.logout, color: AppColors.danger),
          label: const Text('تسجيل الخروج', style: TextStyle(color: AppColors.danger)),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatChip({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.brand, size: 22),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuTile({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.brand),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_left),
        onTap: onTap,
      ),
    );
  }
}

class _OrderTile extends ConsumerWidget {
  final AppOrder order;
  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delivered = order.status == OrderStatus.delivered;
    return Card(
      child: ListTile(
        onTap: () => context.push('/order/${order.id}'),
        title: Text('طلب #${order.id.substring(0, 8)}'),
        subtitle: Text('${order.status.labelAr}  •  ${timeAgo(order.createdAt)}'),
        trailing: delivered
            ? TextButton.icon(
                onPressed: () async {
                  final done = await showReviewDialog(context, ref, order.id);
                  if (done == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('شكراً لتقييمك!'), backgroundColor: AppColors.brand),
                    );
                  }
                },
                icon: const Icon(Icons.star, size: 18, color: AppColors.amber),
                label: const Text('قيّم'),
              )
            : Text(money(order.total),
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.brandDark)),
      ),
    );
  }
}
