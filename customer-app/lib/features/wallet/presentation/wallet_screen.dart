import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/providers.dart';

final pointTxProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  ref.watch(myProfileProvider); // refresh after referral rewards
  return ref.watch(accountRepoProvider).pointTransactions();
});

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider).asData?.value;
    final wallet = (profile?['wallet_balance'] as num?) ?? 0;
    final points = (profile?['points_balance'] as num?) ?? 0;
    final txAsync = ref.watch(pointTxProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr('المحفظة'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Balance card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.brand, AppColors.brandDark],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('رصيد المحفظة'),
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                Text(money(wallet),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.stars, color: Colors.amber, size: 20),
                    const SizedBox(width: 6),
                    Text('${tr('نقاط الولاء')}: $points',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(tr('شحن الرصيد قريباً — يتطلب بوابة دفع'))),
            ),
            icon: const Icon(Icons.add_card),
            label: Text(tr('شحن الرصيد')),
          ),
          const SizedBox(height: 24),
          Text(tr('سجل النقاط'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          txAsync.when(
            loading: () => const Center(
                child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
            error: (e, _) => Text('$e'),
            data: (rows) => rows.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                        child: Text(tr('لا توجد حركات بعد'),
                            style: TextStyle(color: AppColors.textMuted))),
                  )
                : Column(
                    children: rows.map((t) {
                      final amount = (t['amount'] as num?) ?? 0;
                      final reason = _reasonLabel(t['reason'] as String?);
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.brandSurface,
                            child: Text(amount >= 0 ? '+' : '-',
                                style: const TextStyle(
                                    color: AppColors.brandDark, fontWeight: FontWeight.w900)),
                          ),
                          title: Text(reason),
                          trailing: Text('${amount >= 0 ? '+' : ''}$amount',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, color: AppColors.brandDark)),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  String _reasonLabel(String? reason) => switch (reason) {
        'referral_signup' => tr('مكافأة استخدام كود إحالة'),
        'referral_reward' => tr('مكافأة دعوة صديق'),
        _ => tr('نقاط'),
      };
}
