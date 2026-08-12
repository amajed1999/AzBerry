import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/providers.dart';

class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});
  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  final _codeCtrl = TextEditingController();
  bool _applying = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() => _applying = true);
    try {
      final reward = await ref.read(accountRepoProvider).applyReferral(code);
      ref.invalidate(myProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr('تمت الإضافة!')} +$reward'), backgroundColor: AppColors.brand),
        );
        _codeCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);
    final profile = profileAsync.asData?.value;
    final code = (profile?['referral_code'] as String?) ?? '——';
    final alreadyReferred = profile?['referred_by'] != null;

    return Scaffold(
      appBar: AppBar(title: Text(tr('ادعُ صديقاً'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(child: Text('🎁', style: TextStyle(fontSize: 64))),
          const SizedBox(height: 12),
          Text(
            tr('شارك الكود مع أصدقائك — يحصل كلٌّ منكما على 50 نقطة.'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 24),
          // My code card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.brandSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.brand.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                Text(tr('كود الإحالة الخاص بك'),
                    style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 8),
                Text(
                  code,
                  style: const TextStyle(
                      fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 4, color: AppColors.brandDark),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr('تم نسخ الكود'))),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: Text(tr('نسخ الكود')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // Apply a friend's code
          if (!alreadyReferred) ...[
            Text(tr('هل لديك كود صديق؟'),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(hintText: tr('أدخل كود الإحالة')),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _applying ? null : _apply,
              child: Text(_applying ? tr('جارِ التطبيق…') : tr('تطبيق الكود')),
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.brand),
                  const SizedBox(width: 8),
                  Expanded(child: Text(tr('لقد استخدمت كود إحالة مسبقاً'))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
