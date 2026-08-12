import 'package:flutter/material.dart';
import 'package:azberry_customer/core/i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../providers/providers.dart';

class BranchSelectorSheet extends ConsumerWidget {
  const BranchSelectorSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(branchesProvider);
    final selected = ref.watch(selectedBranchProvider);

    return SafeArea(
      child: branchesAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Padding(padding: const EdgeInsets.all(24), child: Text('خطأ: $e')),
        data: (branches) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(tr('اختر الفرع'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: branches.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final b = branches[i];
                  final isSel = b.id == selected?.id;
                  return ListTile(
                    leading: const Icon(Icons.store, color: AppColors.brand),
                    title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${b.isBusy ? tr('🔴 مزدحم') : tr('🟢 مفتوح')}  •  توصيل ${money(b.deliveryFee)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: isSel ? const Icon(Icons.check_circle, color: AppColors.brand) : null,
                    onTap: () {
                      ref.read(selectedBranchProvider.notifier).state = b;
                      // reset filters for the new branch
                      ref.read(selectedCategoryProvider.notifier).state = null;
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
