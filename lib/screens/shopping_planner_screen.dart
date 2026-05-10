import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../providers/app_provider.dart';
import '../services/recipe_search_service.dart';

class ShoppingPlannerScreen extends StatefulWidget {
  const ShoppingPlannerScreen({super.key});

  @override
  State<ShoppingPlannerScreen> createState() => _ShoppingPlannerScreenState();
}

class _ShoppingPlannerScreenState extends State<ShoppingPlannerScreen> {
  final _searchCtrl = TextEditingController();
  bool _searching = false;
  bool _loadingRecipeDetail = false;
  List<Recipe> _searchResults = [];

  static const _weekDays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
  static const _slots = ['breakfast', 'lunch', 'afternoon', 'dinner'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchMeals(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    setState(() => _searching = true);
    final futures = await Future.wait([
      RecipeSearchService.instance.searchMealDB(q).catchError((_) => <Recipe>[]),
      RecipeSearchService.instance
          .searchDummyJson(q)
          .catchError((_) => <Recipe>[]),
    ]);
    if (!mounted) return;
    final dedup = <String, Recipe>{};
    for (final r in [...futures[0], ...futures[1]]) {
      dedup.putIfAbsent(r.name.toLowerCase().trim(), () => r);
    }
    setState(() {
      _searchResults = dedup.values.toList(growable: false);
      _searching = false;
    });
  }

  Future<void> _pickMealSlot(AppProvider provider, Recipe recipe) async {
    var dayKey = provider.shoppingPlanPeriod == 'week' ? 'mon' : 'day';
    var slot = 'breakfast';
    final t = provider.t;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(t('plan_pick_meal_title')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (provider.shoppingPlanPeriod == 'week')
                DropdownButtonFormField<String>(
                  initialValue: dayKey,
                  decoration: InputDecoration(labelText: t('plan_pick_day')),
                  items: _weekDays
                      .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text(t('plan_day_$d')),
                          ))
                      .toList(),
                  onChanged: (v) => setLocal(() => dayKey = v ?? dayKey),
                ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _slots
                    .map(
                      (s) => ChoiceChip(
                        selected: slot == s,
                        label: Text(t('plan_slot_$s')),
                        onSelected: (_) => setLocal(() => slot = s),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('common_cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(t('common_confirm')),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      await provider.addPlannedMeal(recipe: recipe, mealSlot: slot, dayKey: dayKey);
    }
  }

  Future<void> _previewAndPickMeal(AppProvider provider, Recipe recipe) async {
    if (_loadingRecipeDetail) return;
    final t = provider.t;
    setState(() => _loadingRecipeDetail = true);

    Recipe detailedRecipe = recipe;
    try {
      final detail = await _fetchRecipeDetail(recipe);
      if (detail != null) {
        detailedRecipe = detail;
      }
    } finally {
      if (mounted) setState(() => _loadingRecipeDetail = false);
    }

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 1.0,
        expand: false,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              detailedRecipe.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(detailedRecipe.description),
            const SizedBox(height: 12),
            Text(t('recipes_ingredients'),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...(detailedRecipe.ingredientsNeeded.isEmpty
                    ? ['Chưa có dữ liệu nguyên liệu']
                    : detailedRecipe.ingredientsNeeded)
                .map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $e'),
                )),
            const SizedBox(height: 12),
            Text(t('recipes_steps'),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...(detailedRecipe.instructions.isEmpty
                    ? ['Chưa có hướng dẫn chi tiết']
                    : detailedRecipe.instructions)
                .asMap()
                .entries
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('${e.key + 1}. ${e.value}'),
                  ),
                ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _pickMealSlot(provider, detailedRecipe);
              },
              icon: const Icon(Icons.playlist_add_check_rounded),
              label: Text(t('plan_choose_this_recipe')),
            ),
          ],
        ),
      ),
    );
  }

  Future<Recipe?> _fetchRecipeDetail(Recipe recipe) async {
    final id = recipe.id;
    if (id.startsWith('mealdb_')) {
      final mealId = id.substring('mealdb_'.length);
      return RecipeSearchService.instance.getMealById(mealId);
    }
    if (id.startsWith('dummy_')) {
      final rawId = id.substring('dummy_'.length);
      return RecipeSearchService.instance.getMealById('dj_$rawId');
    }
    return null;
  }

  Future<void> _confirmAddToInventory(
    BuildContext context,
    AppProvider provider,
  ) async {
    final selected = provider.shoppingPlanItems
        .where((e) => e.isPurchased && e.confirmedQty > 0)
        .toList(growable: false);
    if (selected.isEmpty) return;

    final t = provider.t;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t('plan_confirm_dialog_title')),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('plan_confirm_dialog_desc')),
                const SizedBox(height: 10),
                ...selected.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• ${e.name}: ${e.confirmedQty} ${e.unit}'),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('common_cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t('common_confirm')),
          ),
        ],
      ),
    );
    if (ok == true) {
      await provider.addPurchasedItemsToInventory();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('plan_added_inventory_success'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final t = provider.t;
    final cs = Theme.of(context).colorScheme;
    final isWeekly = provider.shoppingPlanPeriod == 'week';
    final items = provider.shoppingPlanItems;
    final planned = provider.plannedMealsForActivePeriod;
    final savedAt = provider.shoppingPlanSavedAt;
    final purchasedCount = items.where((e) => e.isPurchased).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('plan_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton.icon(
          onPressed: planned.isEmpty
              ? null
              : () async {
                  await provider.saveShoppingDraft();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t('plan_saved_success'))),
                  );
                },
          icon: const Icon(Icons.save_rounded),
          label: const Text('Lưu kế hoạch & tạo danh sách mua'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('plan_desc'), style: TextStyle(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(value: false, label: Text(t('plan_day'))),
                      ButtonSegment(value: true, label: Text(t('plan_week'))),
                    ],
                    selected: {isWeekly},
                    onSelectionChanged: (s) async {
                      await provider.generateShoppingPlan(weekly: s.first);
                    },
                  ),
                  if (savedAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${t('plan_saved_label')}: ${savedAt.toLocal()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SearchBar(
            controller: _searchCtrl,
            hintText: t('plan_search_meal_hint'),
            leading: const Icon(Icons.search_rounded),
            onSubmitted: _searchMeals,
            trailing: [
              if (_searchCtrl.text.isNotEmpty)
                IconButton(
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchResults = []);
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          if (_loadingRecipeDetail)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: LinearProgressIndicator(minHeight: 3),
              ),
            ),
          if (_searching)
            const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
          else if (_searchResults.isNotEmpty)
            ..._searchResults.take(8).map(
                  (r) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.restaurant_menu_rounded),
                    title: Text(r.name),
                    subtitle: Text(r.sourceName),
                    trailing: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility_outlined),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                    onTap: () => _previewAndPickMeal(provider, r),
                  ),
                ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t('plan_selected_meals'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: planned.isEmpty
                            ? null
                            : () => provider.clearPlannedMealsForActivePeriod(),
                        child: Text(t('plan_clear_meals')),
                      ),
                    ],
                  ),
                  if (planned.isEmpty)
                    Text(t('plan_selected_meals_empty'),
                        style: TextStyle(color: cs.onSurfaceVariant))
                  else
                    ...planned.map(
                      (e) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(e.recipeName),
                        subtitle: Text(
                          isWeekly
                              ? '${t('plan_day_${e.dayKey}')} • ${t('plan_slot_${e.mealSlot}')}'
                              : t('plan_slot_${e.mealSlot}'),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () => provider.removePlannedMeal(e.id),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${t('plan_progress')}: $purchasedCount/${items.length}',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ),
                  TextButton(
                    onPressed: items.isEmpty
                        ? null
                        : () async {
                            for (final item in items) {
                              await provider.setShoppingPurchased(item.id, true);
                            }
                          },
                    child: Text(t('plan_mark_all_purchased')),
                  ),
                  FilledButton(
                    onPressed: purchasedCount == 0
                        ? null
                        : () => _confirmAddToInventory(context, provider),
                    child: Text(t('plan_add_to_inventory')),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      IconButton(
                        onPressed: () => provider.setShoppingConfirmedQty(
                          item.id,
                          (item.confirmedQty - 0.5).clamp(0, 9999).toDouble(),
                        ),
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                      ),
                      Text('${item.confirmedQty} ${item.unit}'),
                      IconButton(
                        onPressed: () => provider.setShoppingConfirmedQty(
                          item.id,
                          item.confirmedQty + 0.5,
                        ),
                        icon: const Icon(Icons.add_circle_outline_rounded),
                      ),
                      Checkbox(
                        value: item.isPurchased,
                        onChanged: (v) => provider.setShoppingPurchased(item.id, v ?? false),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
