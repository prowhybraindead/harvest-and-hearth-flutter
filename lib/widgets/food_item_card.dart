import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../constants/categories.dart';
import '../utils/date_helper.dart';

class FoodItemCard extends StatelessWidget {
  final FoodItem item;
  final String language;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const FoodItemCard({
    super.key,
    required this.item,
    required this.language,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final info = AppCategories.forCategory(item.category);
    final days = item.daysUntilExpiry;
    final isExpired = item.isExpired;
    final isSoon = item.isExpiringSoon;
    final cs = Theme.of(context).colorScheme;

    Color statusColor = cs.onSurfaceVariant;
    if (isExpired) {
      statusColor = Colors.red;
    } else if (isSoon) {
      statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: cs.outlineVariant.withAlpha(95)),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Category icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: info.color.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(info.icon, color: info.color, size: 22),
              ),
              const SizedBox(width: 12),

              // Main info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + status badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                        if (isExpired)
                          _Badge(
                              label: language == 'VIE' ? 'Hết hạn' : 'Expired',
                              color: Colors.red)
                        else if (isSoon)
                          _Badge(
                              label: language == 'VIE' ? 'Sắp hết' : 'Expiring',
                              color: Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Category chip + quantity
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: info.color.withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _categoryLabel(info, language),
                            style: TextStyle(
                                fontSize: 10,
                                color: info.color,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_formatQty(item.quantity)} ${item.unit}',
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                    if (item.fromShoppingPlan ||
                        item.shoppingPlanMealNames.isNotEmpty ||
                        (item.planSourceLabel ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (item.fromShoppingPlan ||
                              (item.planSourceLabel ?? '').trim().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: cs.tertiaryContainer.withAlpha(170),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                language == 'VIE'
                                    ? 'Kế hoạch mua sắm'
                                    : 'Shopping plan',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: cs.onTertiaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ...item.shoppingPlanMealNames.map(
                            (meal) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer.withAlpha(175),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                meal,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: cs.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Expiry info
                    if (item.expiryDate != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded,
                              size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            DateHelper.format(item.expiryDate!),
                            style: TextStyle(fontSize: 11, color: statusColor),
                          ),
                          const SizedBox(width: 6),
                          if (days != null)
                            Text(
                              '· ${DateHelper.relativeLabel(days, language)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: statusColor,
                                fontWeight: (isExpired || isSoon)
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Actions
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    color: cs.primary.withAlpha(179),
                    onPressed: onEdit,
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      backgroundColor: cs.primary.withAlpha(18),
                      side: BorderSide(color: cs.primary.withAlpha(80)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    color: Colors.red.withAlpha(179),
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.withAlpha(18),
                      side: BorderSide(color: Colors.red.withAlpha(80)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatQty(double qty) =>
      qty % 1 == 0 ? qty.toInt().toString() : qty.toString();

  String _categoryLabel(CategoryInfo info, String lang) {
    // Map translationKey → display label without needing a BuildContext
    const vie = {
      'cat_vegetables': 'Rau củ',
      'cat_fruits': 'Trái cây',
      'cat_meat': 'Thịt',
      'cat_dairy': 'Sữa & Trứng',
      'cat_seafood': 'Hải sản',
      'cat_drinks': 'Đồ uống',
      'cat_snacks': 'Đồ ăn vặt',
      'cat_other': 'Khác',
    };
    const eng = {
      'cat_vegetables': 'Vegetables',
      'cat_fruits': 'Fruits',
      'cat_meat': 'Meat',
      'cat_dairy': 'Dairy & Eggs',
      'cat_seafood': 'Seafood',
      'cat_drinks': 'Drinks',
      'cat_snacks': 'Snacks',
      'cat_other': 'Other',
    };
    final map = lang == 'VIE' ? vie : eng;
    return map[info.translationKey] ?? info.translationKey;
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
