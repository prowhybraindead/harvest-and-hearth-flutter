import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../constants/categories.dart';
import '../core/simulated_clock.dart';
import '../models/food_item.dart';
import '../providers/app_provider.dart';
import '../screens/barcode_scanner_screen.dart';
import '../theme/app_theme.dart';
import '../utils/date_helper.dart';

const _uuid = Uuid();

class AddFoodModal extends StatefulWidget {
  /// If provided, the modal opens in edit mode pre-filled with this item.
  final FoodItem? editItem;
  final String? initialScannedName;

  const AddFoodModal({
    super.key,
    this.editItem,
    this.initialScannedName,
  });

  bool get _isEdit => editItem != null;

  @override
  State<AddFoodModal> createState() => _AddFoodModalState();
}

class _AddFoodModalState extends State<AddFoodModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _bulkCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _warningDaysCtrl = TextEditingController();

  late CategoryTier1 _categoryTier1;
  late FoodCategory _category;
  late StorageType _storage;
  DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();
    final e = widget.editItem;
    if (e != null) {
      _nameCtrl.text = e.name;
      _quantityCtrl.text = e.quantity % 1 == 0
          ? e.quantity.toInt().toString()
          : e.quantity.toString();
      _unitCtrl.text = e.unit;
      _warningDaysCtrl.text = (e.warningDays ?? 3).toString();
      _categoryTier1 = AppCategories.tier1Of(e.category);
      _category = e.category;
      _storage = e.storage;
      _expiryDate = e.expiryDate;
    } else {
      final scanned = widget.initialScannedName?.trim();
      if (scanned != null && scanned.isNotEmpty) {
        _nameCtrl.text = scanned;
      }
      _quantityCtrl.text = '1';
      _unitCtrl.text = 'pcs';
      _warningDaysCtrl.text = '3';
      _categoryTier1 = CategoryTier1.produce;
      _category = FoodCategory.vegetables;
      _storage = StorageType.fridge;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bulkCtrl.dispose();
    _quantityCtrl.dispose();
    _unitCtrl.dispose();
    _warningDaysCtrl.dispose();
    super.dispose();
  }

  Future<void> _openScanner() async {
    final t = context.read<AppProvider>().t;
    final code = await Navigator.of(context, rootNavigator: true).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => BarcodeScannerScreen(t: t),
      ),
    );
    if (!mounted) return;
    if (code != null && code.isNotEmpty) {
      setState(() => _nameCtrl.text = code);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('food_scan_success'))),
      );
    }
  }

  Future<void> _pickExpiryDate() async {
    final initial =
        _expiryDate ?? SimulatedClock.now.add(const Duration(days: 7));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: SimulatedClock.now.subtract(const Duration(days: 30)),
      lastDate: SimulatedClock.now.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  void _clearExpiryDate() => setState(() => _expiryDate = null);

  void _submit() {
    final provider = context.read<AppProvider>();
    final bulkLines = _parseBulkIngredients(_bulkCtrl.text);
    final isBulk = !widget._isEdit && bulkLines.isNotEmpty;

    if (!isBulk && !_formKey.currentState!.validate()) return;
    final quantity = double.tryParse(_quantityCtrl.text) ?? 1;
    final warningDays = int.tryParse(_warningDaysCtrl.text) ?? 3;
    final expiry = _expiryDate ??
        SimulatedClock.now.add(
          Duration(days: provider.defaultExpiryDaysFor(_category)),
        );

    if (widget._isEdit) {
      final updated = widget.editItem!.copyWith(
        name: _nameCtrl.text.trim(),
        category: _category,
        storage: _storage,
        quantity: quantity,
        unit: _unitCtrl.text.trim(),
        expiryDate: _expiryDate ??
            SimulatedClock.now.add(
              Duration(days: provider.defaultExpiryDaysFor(_category)),
            ),
        warningDays: warningDays,
      );
      provider.updateFood(widget.editItem!.id, updated);
    } else if (isBulk) {
      for (final name in bulkLines) {
        final item = FoodItem(
          id: _uuid.v4(),
          name: name,
          category: _category,
          storage: _storage,
          quantity: quantity,
          unit: _unitCtrl.text.trim(),
          addedDate: SimulatedClock.now,
          expiryDate: expiry,
          warningDays: warningDays,
        );
        provider.addFood(item);
      }
    } else {
      final item = FoodItem(
        id: _uuid.v4(),
        name: _nameCtrl.text.trim(),
        category: _category,
        storage: _storage,
        quantity: quantity,
        unit: _unitCtrl.text.trim(),
        addedDate: SimulatedClock.now,
        expiryDate: expiry,
        warningDays: warningDays,
      );
      provider.addFood(item);
    }
    Navigator.pop(context);
  }

  List<String> _parseBulkIngredients(String input) {
    final parts = input
        .split(RegExp(r'[\n,;]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final seen = <String>{};
    final out = <String>[];
    for (final p in parts) {
      final key = p.toLowerCase();
      if (seen.add(key)) out.add(p);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final t = provider.t;
    final cs = Theme.of(context).colorScheme;
    final tier1Options =
        AppCategories.all.map((e) => e.tier1).toSet().toList(growable: false);
    final tier2Options = AppCategories.byTier1(_categoryTier1);
    if (tier2Options.any((e) => e.category == _category) == false &&
        tier2Options.isNotEmpty) {
      _category = tier2Options.first.category;
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: cs.outlineVariant,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          border: Border.all(
                            color: cs.secondary.withValues(alpha: 0.65),
                          ),
                        ),
                        child: Icon(
                          widget._isEdit
                              ? Icons.edit_note_rounded
                              : Icons.add_box_rounded,
                          color: cs.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget._isEdit
                                  ? t('food_edit_title')
                                  : t('add_food'),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              t('dashboard_quick_add'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (!widget._isEdit) ...[
                    _SectionCard(
                      child: FilledButton.tonalIcon(
                        onPressed: _openScanner,
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                        label: Text(t('food_barcode')),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  _SectionCard(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: InputDecoration(
                            labelText: t('food_name'),
                            hintText: t('food_name_hint'),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? t('food_name_required')
                              : null,
                        ),
                        if (!widget._isEdit) ...[
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: _bulkCtrl,
                            minLines: 2,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: t('food_bulk_ingredients'),
                              hintText: t('food_bulk_hint'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              t('food_frequent_suggestions'),
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: provider.frequentIngredientNames
                                .map(
                                  (name) => ActionChip(
                                    label: Text(name),
                                    onPressed: () {
                                      final existing = _bulkCtrl.text.trim();
                                      final next = existing.isEmpty
                                          ? name
                                          : '$existing\n$name';
                                      setState(() => _bulkCtrl.text = next);
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<CategoryTier1>(
                          initialValue: _categoryTier1,
                          decoration: InputDecoration(
                            labelText: t('food_category_level1'),
                          ),
                          items: tier1Options.map((tier1) {
                            return DropdownMenuItem(
                              value: tier1,
                              child: Text(
                                t(AppCategories.tier1TranslationKey(tier1)),
                              ),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() {
                              _categoryTier1 = v;
                              final opts = AppCategories.byTier1(v);
                              if (opts.isNotEmpty) {
                                _category = opts.first.category;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<FoodCategory>(
                          initialValue: _category,
                          decoration: InputDecoration(
                            labelText: t('food_category_level2'),
                          ),
                          items: tier2Options.map((info) {
                            return DropdownMenuItem(
                              value: info.category,
                              child: Row(
                                children: [
                                  Icon(info.icon, color: info.color, size: 20),
                                  const SizedBox(width: 8),
                                  Text(t(info.translationKey)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _category = v!),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                size: 16, color: cs.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Text(
                              '${t('food_expiry_default_days')}: ${provider.defaultExpiryDaysFor(_category)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          t('food_storage'),
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: _StorageChip(
                                label: t('storage_fridge'),
                                icon: Icons.kitchen_rounded,
                                selected: _storage == StorageType.fridge,
                                onTap: () => setState(
                                    () => _storage = StorageType.fridge),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: _StorageChip(
                                label: t('storage_freezer'),
                                icon: Icons.ac_unit_rounded,
                                selected: _storage == StorageType.freezer,
                                onTap: () => setState(
                                    () => _storage = StorageType.freezer),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: _StorageChip(
                                label: t('storage_pantry'),
                                icon: Icons.inventory_2_rounded,
                                selected: _storage == StorageType.pantry,
                                onTap: () => setState(
                                    () => _storage = StorageType.pantry),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _quantityCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: InputDecoration(
                                  labelText: t('food_quantity'),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _unitCtrl,
                                decoration: InputDecoration(
                                  labelText: t('food_unit'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _pickExpiryDate,
                                borderRadius:
                                    BorderRadius.circular(AppRadii.md),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: t('food_expiry'),
                                    suffixIcon: const Icon(
                                        Icons.calendar_month_outlined),
                                  ),
                                  child: Text(
                                    _expiryDate == null
                                        ? '-'
                                        : DateHelper.format(_expiryDate!),
                                  ),
                                ),
                              ),
                            ),
                            if (_expiryDate != null) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: _clearExpiryDate,
                                icon: const Icon(Icons.clear_rounded),
                                tooltip: t('food_no_expiry'),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextFormField(
                          controller: _warningDaysCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: t('food_warning_days'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: Text(t('food_cancel')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: _submit,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: Text(widget._isEdit
                              ? t('common_save')
                              : t('food_save')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: cs.outlineVariant, width: 1.2),
      ),
      child: child,
    );
  }
}

class _StorageChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _StorageChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: 0.14)
              : cs.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(
            color: selected ? cs.primary : cs.outline,
            width: selected ? 1.4 : 1.1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? cs.primary : cs.onSurfaceVariant,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? cs.primary : cs.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
