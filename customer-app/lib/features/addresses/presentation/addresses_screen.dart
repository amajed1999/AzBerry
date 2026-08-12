import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/address.dart';
import '../../../providers/providers.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(addressesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('عناويني')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref, null),
        backgroundColor: AppColors.brand,
        icon: const Icon(Icons.add),
        label: const Text('عنوان جديد'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (list) => list.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('📍', style: TextStyle(fontSize: 60)),
                    const SizedBox(height: 8),
                    Text('لا توجد عناوين محفوظة', style: TextStyle(color: AppColors.textMuted)),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _AddressTile(
                  address: list[i],
                  onEdit: () => _openEditor(context, ref, list[i]),
                  onDelete: () async {
                    await ref.read(accountRepoProvider).deleteAddress(list[i].id);
                    ref.invalidate(addressesProvider);
                  },
                ),
              ),
      ),
    );
  }

  void _openEditor(BuildContext context, WidgetRef ref, Address? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _AddressEditor(existing: existing),
      ),
    ).then((_) => ref.invalidate(addressesProvider));
  }
}

class _AddressTile extends StatelessWidget {
  final Address address;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;
  const _AddressTile({required this.address, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: address.isDefault ? AppColors.brand : AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.brand),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(address.label ?? 'عنوان', style: const TextStyle(fontWeight: FontWeight.w700)),
                    if (address.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.brandSurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('افتراضي',
                            style: TextStyle(fontSize: 11, color: AppColors.brandDark)),
                      ),
                    ],
                  ],
                ),
                if (address.addressText != null)
                  Text(address.addressText!, style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              ],
            ),
          ),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit, size: 20)),
          IconButton(
            onPressed: () => onDelete(),
            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}

class _AddressEditor extends ConsumerStatefulWidget {
  final Address? existing;
  const _AddressEditor({this.existing});
  @override
  ConsumerState<_AddressEditor> createState() => _AddressEditorState();
}

class _AddressEditorState extends ConsumerState<_AddressEditor> {
  late final TextEditingController _label;
  late final TextEditingController _text;
  late final TextEditingController _building;
  late final TextEditingController _notes;
  late final TextEditingController _lat;
  late final TextEditingController _lng;
  bool _default = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _label = TextEditingController(text: a?.label ?? '');
    _text = TextEditingController(text: a?.addressText ?? '');
    _building = TextEditingController(text: a?.building ?? '');
    _notes = TextEditingController(text: a?.notes ?? '');
    _lat = TextEditingController(text: a?.lat.toString() ?? '33.3152');
    _lng = TextEditingController(text: a?.lng.toString() ?? '44.3661');
    _default = a?.isDefault ?? false;
  }

  @override
  void dispose() {
    for (final c in [_label, _text, _building, _notes, _lat, _lng]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(accountRepoProvider).saveAddress(
          id: widget.existing?.id,
          label: _label.text.trim().isEmpty ? 'عنوان' : _label.text.trim(),
          lat: double.tryParse(_lat.text) ?? 33.3152,
          lng: double.tryParse(_lng.text) ?? 44.3661,
          addressText: _text.text.trim(),
          building: _building.text.trim(),
          notes: _notes.text.trim(),
          isDefault: _default,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.existing == null ? 'عنوان جديد' : 'تعديل العنوان',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(
              controller: _label,
              decoration: const InputDecoration(labelText: 'الاسم (البيت، العمل…)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _text,
              decoration: const InputDecoration(labelText: 'العنوان التفصيلي'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _building,
                    decoration: const InputDecoration(labelText: 'المبنى/الشقة'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _notes,
                    decoration: const InputDecoration(labelText: 'ملاحظات'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _lat,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'خط العرض'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _lng,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'خط الطول'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'ℹ️ اختيار الموقع من الخريطة يتطلب تفعيل Google Maps (مرحلة لاحقة).',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.brand,
              title: const Text('تعيين كعنوان افتراضي'),
              value: _default,
              onChanged: (v) => setState(() => _default = v),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'جارِ الحفظ…' : 'حفظ العنوان'),
            ),
          ],
        ),
      ),
    );
  }
}
