import 'package:flutter/material.dart';
import 'package:azberry_customer/core/i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/providers.dart';

/// Shows the rating dialog for a delivered order. Returns true if submitted.
Future<bool?> showReviewDialog(BuildContext context, WidgetRef ref, String orderId) {
  return showDialog<bool>(
    context: context,
    builder: (_) => _ReviewDialog(orderId: orderId, ref: ref),
  );
}

class _ReviewDialog extends StatefulWidget {
  final String orderId;
  final WidgetRef ref;
  const _ReviewDialog({required this.orderId, required this.ref});

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  int _rating = 5;
  final _comment = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    await widget.ref.read(accountRepoProvider).submitReview(
          orderId: widget.orderId,
          rating: _rating,
          comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
        );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(tr('قيّم طلبك')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < _rating;
              return IconButton(
                onPressed: () => setState(() => _rating = i + 1),
                icon: Icon(
                  filled ? Icons.star : Icons.star_border,
                  color: AppColors.amber,
                  size: 34,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _comment,
            maxLines: 3,
            decoration: InputDecoration(hintText: tr('اكتب تعليقاً (اختياري)…')),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(tr('لاحقاً')),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          style: ElevatedButton.styleFrom(minimumSize: const Size(88, 40)),
          child: Text(_saving ? '…' : tr('إرسال')),
        ),
      ],
    );
  }
}
