import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/food_item.dart';
import '../widgets/food_item_card.dart';
import '../widgets/add_food_modal.dart';

enum _SortBy { name, expiry, added }

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchCtrl = TextEditingController();
  _SortBy _sortBy = _SortBy.expiry;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<FoodItem> _filter(List<FoodItem> items) {
    var result = _query.isEmpty
        ? items.toList()
        : items.where((i) => i.name.toLowerCase().contains(_query)).toList();
    switch (_sortBy) {
      case _SortBy.name:
        result.sort((a, b) => a.name.compareTo(b.name));
      case _SortBy.expiry:
        result.sort((a, b) {
          final da = a.daysUntilExpiry;
          final db = b.daysUntilExpiry;
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });
      case _SortBy.added:
        result.sort((a, b) => b.addedDate.compareTo(a.addedDate));
    }
    return result;
  }

  void _openEdit(BuildContext context, FoodItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddFoodModal(editItem: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use select to avoid rebuilding when unrelated provider fields change
    // (e.g. recipeCache, savedRecipes)
    final fridgeItems =
        context.select<AppProvider, List<FoodItem>>((p) => p.fridgeItems);
    final freezerItems =
        context.select<AppProvider, List<FoodItem>>((p) => p.freezerItems);
    final pantryItems =
        context.select<AppProvider, List<FoodItem>>((p) => p.pantryItems);
    final language = context.select<AppProvider, String>((p) => p.language);
    final t = context.select<AppProvider, String Function(String)>((p) => p.t);
    final cs = Theme.of(context).colorScheme;

    final filteredFridge = _filter(fridgeItems);
    final filteredFreezer = _filter(freezerItems);
    final filteredPantry = _filter(pantryItems);

    return Scaffold(
      appBar: AppBar(
        title: Text(t('inventory_title'),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(152),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withAlpha(110),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: cs.outlineVariant.withAlpha(110),
                    ),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: t('inventory_search'),
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      filled: false,
                    ),
                  ),
                ),
              ),
              // Sort chips + Tabs
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: cs.surfaceContainerHighest.withAlpha(85),
                    border: Border.all(color: cs.outlineVariant.withAlpha(95)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TabBar(
                          controller: _tabController,
                          dividerColor: Colors.transparent,
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelPadding: EdgeInsets.zero,
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: cs.secondary.withAlpha(34),
                            border: Border.all(
                              color: cs.secondary.withAlpha(120),
                            ),
                          ),
                          tabs: [
                            SizedBox(
                              height: 54,
                              child: Tab(
                                icon:
                                    const Icon(Icons.kitchen_rounded, size: 18),
                                text: t('inventory_fridge'),
                              ),
                            ),
                            SizedBox(
                              height: 54,
                              child: Tab(
                                icon:
                                    const Icon(Icons.ac_unit_rounded, size: 18),
                                text: t('inventory_freezer'),
                              ),
                            ),
                            SizedBox(
                              height: 54,
                              child: Tab(
                                icon: const Icon(Icons.inventory_2_rounded,
                                    size: 18),
                                text: t('inventory_pantry'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<_SortBy>(
                        tooltip: t('inventory_sort_expiry'),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: cs.primary.withAlpha(24),
                            border: Border.all(color: cs.primary.withAlpha(90)),
                          ),
                          child: Icon(Icons.sort_rounded,
                              color: cs.primary, size: 18),
                        ),
                        onSelected: (v) => setState(() => _sortBy = v),
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: _SortBy.name,
                            child: Text(t('inventory_sort_name')),
                          ),
                          PopupMenuItem(
                            value: _SortBy.expiry,
                            child: Text(t('inventory_sort_expiry')),
                          ),
                          PopupMenuItem(
                            value: _SortBy.added,
                            child: Text(t('inventory_sort_added')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: TabBarView(
          key: ValueKey('${_tabController.index}-$_query-${_sortBy.name}'),
          controller: _tabController,
          children: [
            _ItemList(
              items: filteredFridge,
              t: t,
              language: language,
              onEdit: (item) => _openEdit(context, item),
            ),
            _ItemList(
              items: filteredFreezer,
              t: t,
              language: language,
              onEdit: (item) => _openEdit(context, item),
            ),
            _ItemList(
              items: filteredPantry,
              t: t,
              language: language,
              onEdit: (item) => _openEdit(context, item),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemList extends StatelessWidget {
  final List<FoodItem> items;
  final String Function(String) t;
  final String language;
  final void Function(FoodItem) onEdit;

  const _ItemList({
    required this.items,
    required this.t,
    required this.language,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.kitchen_outlined,
                size: 64, color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(t('inventory_empty'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(t('inventory_empty_sub'),
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
      itemCount: items.length,
      itemBuilder: (_, i) => FoodItemCard(
        item: items[i],
        language: language,
        onEdit: () => onEdit(items[i]),
        onDelete: () => _confirmDelete(context, items[i], t),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, FoodItem item, String Function(String) t) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t('inventory_delete_confirm')),
        content: Text(item.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('common_cancel')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AppProvider>().removeFood(item.id);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(t('common_delete')),
          ),
        ],
      ),
    );
  }
}
